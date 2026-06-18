// ============================================================
// TO Best — infrastructure/sync_service.dart
// خدمة المزامنة بين Isar وGAS Backend
// ============================================================

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'gas_client.dart';
import 'isar_service.dart';
import '../data/models/workout_model.dart';
import '../data/models/food_model.dart';
import '../data/models/chat_model.dart';
import '../data/models/health_model.dart';

/// خدمة المزامنة مع GAS Backend
///
/// تدير sync queue وتُنفِّذ Weekly Cleanup بالترتيب الصحيح
class SyncService {
  SyncService({
    required this.gasClient,
    required this.isarService,
    required Connectivity connectivity,
  }) : _connectivity = connectivity;

  final GasClient gasClient;
  final IsarService isarService;
  final Connectivity _connectivity;

  // ── فحص الاتصال ─────────────────────────────────────────

  Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // ── Weekly Cleanup ────────────────────────────────────────

  /// تنظيف أسبوعي — يسير بالترتيب المحدد:
  /// 1. Sync محلي → Remote  2. مسح Isar  3. Sync Remote → محلي
  ///
  /// إذا فشلت أي خطوة يُجدول إعادة المحاولة ولا يُمسح Isar
  Future<void> runWeeklyCleanup(String userId) async {
    if (!await hasInternet()) {
      _log('Cleanup skipped — no internet');
      await _scheduleRetry(userId, 'weekly_cleanup');
      return;
    }

    try {
      // الخطوة 1: رفع التغييرات المحلية أولاً
      await syncLocalChangesToRemote(userId);

      // الخطوة 2: مسح Isar (يشمل كاش الفيديو)
      await isarService.clearUserData(userId);

      // الخطوة 3: سحب البيانات من GAS
      await syncAllDataFromRemote(userId);

      _log('Weekly cleanup completed for $userId');
    } catch (e) {
      _log('Weekly cleanup failed: $e');
      await _scheduleRetry(userId, 'weekly_cleanup');
      // ⚠️ لا تُمسح Isar إذا فشل الـ Sync
    }
  }

  // ── Sync To Remote ────────────────────────────────────────

  /// مزامنة كل التغييرات المحلية غير المُزامَنة مع GAS
  Future<void> syncLocalChangesToRemote(String userId) async {
    final db = await isarService.db;

    // مزامنة جلسات التمرين
    final unSyncedWorkouts = await db.workoutSessionIsarModels
        .filter()
        .userIdEqualTo(userId)
        .syncedToRemoteEqualTo(false)
        .findAll();

    for (final session in unSyncedWorkouts) {
      try {
        await gasClient.post(
          action: 'SAVE_LOG',
          data: {
            'uid': userId,
            'key': session.sessionId,
            'data': jsonDecode(session.exercisesJson),
          },
        );
        await db.writeTxn(() async {
          session.syncedToRemote = true;
          await db.workoutSessionIsarModels.put(session);
        });
      } catch (e) {
        _log('Failed to sync workout ${session.sessionId}: $e');
      }
    }

    // مزامنة الوجبات
    final unSyncedMeals = await db.mealLogIsarModels
        .filter()
        .userIdEqualTo(userId)
        .syncedToRemoteEqualTo(false)
        .findAll();

    for (final meal in unSyncedMeals) {
      try {
        await gasClient.post(
          action: 'SAVE_MEALS',
          data: {
            'uid': userId,
            'key': meal.mealId,
            'data': jsonDecode(meal.itemsJson),
          },
        );
        await db.writeTxn(() async {
          meal.syncedToRemote = true;
          await db.mealLogIsarModels.put(meal);
        });
      } catch (e) {
        _log('Failed to sync meal ${meal.mealId}: $e');
      }
    }

    // مزامنة بيانات الصحة
    final unSyncedHealth = await db.healthDataIsarModels
        .filter()
        .userIdEqualTo(userId)
        .syncedToRemoteEqualTo(false)
        .findAll();

    for (final health in unSyncedHealth) {
      try {
        await gasClient.post(
          action: 'SAVE_ATT',
          data: {
            'uid': userId,
            'key': DateTime.fromMillisecondsSinceEpoch(health.dateMs)
                .toIso8601String()
                .substring(0, 10),
            'data': {
              'steps': health.steps,
              'distanceKm': health.distanceKm,
              'burnedCalories': health.burnedCalories,
              'sleepHours': health.sleepHours,
              'sleepMinutes': health.sleepMinutes,
              'sleepQuality': health.sleepQuality,
            },
          },
        );
        await db.writeTxn(() async {
          health.syncedToRemote = true;
          await db.healthDataIsarModels.put(health);
        });
      } catch (e) {
        _log('Failed to sync health data: $e');
      }
    }

    // مزامنة رسائل الشات
    final unSyncedMsgs = await db.chatMessageIsarModels
        .filter()
        .userIdEqualTo(userId)
        .syncedToRemoteEqualTo(false)
        .findAll();

    for (final msg in unSyncedMsgs) {
      try {
        await gasClient.post(
          action: 'SEND_MSG',
          data: {
            'roomId': msg.roomId,
            'msg': {
              'id': msg.messageId,
              'senderId': msg.senderId,
              'senderName': msg.senderName,
              'content': msg.content,
              'type': msg.messageType,
              'ts': msg.timestampMs,
            },
          },
        );
        await db.writeTxn(() async {
          msg.syncedToRemote = true;
          await db.chatMessageIsarModels.put(msg);
        });
      } catch (e) {
        _log('Failed to sync message ${msg.messageId}: $e');
      }
    }
  }

  // ── Sync From Remote ──────────────────────────────────────

  /// سحب كل بيانات المستخدم من GAS وحفظها في Isar
  Future<void> syncAllDataFromRemote(String userId) async {
    try {
      final result = await gasClient.post(
        action: 'FULL_SYNC_PULL',
        data: {'uid': userId},
      );

      final db = await isarService.db;

      // حفظ جلسات التمرين
      final logs = result['logs'] as List<dynamic>? ?? [];
      if (logs.isNotEmpty) {
        final sessions = logs
            .map((l) => _workoutFromRemote(l as Map<String, dynamic>, userId))
            .where((s) => s != null)
            .cast<WorkoutSessionIsarModel>()
            .toList();

        await db.writeTxn(() async {
          await db.workoutSessionIsarModels.putAll(sessions);
        });
      }

      // حفظ الوجبات
      final meals = result['meals'] as List<dynamic>? ?? [];
      if (meals.isNotEmpty) {
        final mealModels = meals
            .map((m) => _mealFromRemote(m as Map<String, dynamic>, userId))
            .where((m) => m != null)
            .cast<MealLogIsarModel>()
            .toList();

        await db.writeTxn(() async {
          await db.mealLogIsarModels.putAll(mealModels);
        });
      }

      // حفظ بيانات الصحة
      final health = result['health'] as List<dynamic>? ?? [];
      if (health.isNotEmpty) {
        final healthModels = health
            .map((h) => _healthFromRemote(h as Map<String, dynamic>, userId))
            .where((h) => h != null)
            .cast<HealthDataIsarModel>()
            .toList();

        await db.writeTxn(() async {
          await db.healthDataIsarModels.putAll(healthModels);
        });
      }

      _log('Full sync from remote completed for $userId');
    } catch (e) {
      _log('Full sync from remote failed: $e');
      rethrow;
    }
  }

  // ── Field Level Merge ─────────────────────────────────────

  /// مزامنة حقل واحد فقط مع GAS (Field Level)
  ///
  /// كل حقل له updatedAt — الأحدث يكسب دائماً
  Future<void> syncField({
    required String userId,
    required String fieldName,
    required dynamic value,
    required DateTime updatedAt,
  }) async {
    await gasClient.post(
      action: 'SYNC_FIELDS',
      data: {
        'uid': userId,
        'fields': [
          {
            'fieldName': fieldName,
            'value': value,
            'updatedAt': updatedAt.toIso8601String(),
          }
        ],
      },
    );
  }

  // ── إضافة للـ Sync Queue ──────────────────────────────────

  /// إضافة عملية لطابور المزامنة (للـ Offline support)
  Future<void> addToQueue({
    required String entityType,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final db = await isarService.db;
    final item = SyncQueueItem(
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    );
    await db.writeTxn(() async {
      await db.syncQueueItems.put(item);
    });
  }

  /// معالجة طابور المزامنة (يُستدعى عند عودة الإنترنت)
  Future<void> processQueue() async {
    if (!await hasInternet()) return;

    final db = await isarService.db;
    final queue = await db.syncQueueItems
        .filter()
        .retryCountLessThan(5)
        .sortByCreatedAt()
        .findAll();

    for (final item in queue) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        await gasClient.post(action: item.action, data: payload);
        await db.writeTxn(() async {
          await db.syncQueueItems.delete(item.id);
        });
      } catch (e) {
        await db.writeTxn(() async {
          item.retryCount++;
          await db.syncQueueItems.put(item);
        });
        _log('Queue item ${item.id} failed (retry ${item.retryCount}): $e');
      }
    }
  }

  // ── Private Helpers ───────────────────────────────────────

  Future<void> _scheduleRetry(String userId, String operation) async {
    await addToQueue(
      entityType: 'system',
      entityId: operation,
      action: 'RETRY_$operation',
      payload: {'uid': userId},
    );
  }

  WorkoutSessionIsarModel? _workoutFromRemote(
      Map<String, dynamic> json, String userId) {
    try {
      final sessionId = json['key']?.toString() ?? '';
      if (sessionId.isEmpty) return null;

      return WorkoutSessionIsarModel(
        sessionId: sessionId,
        userId: userId,
        sessionName: json['sessionName']?.toString() ?? '',
        programId: json['programId']?.toString() ?? '',
        dateMs: DateTime.tryParse(json['date']?.toString() ?? '')
                    ?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
        exercisesJson: jsonEncode(json['exercises'] ?? []),
        warmupsJson: jsonEncode(json['warmups'] ?? []),
        isCompleted: json['completed'] == true,
        durationMinutes:
            int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
        syncedToRemote: true,
      );
    } catch (_) {
      return null;
    }
  }

  MealLogIsarModel? _mealFromRemote(
      Map<String, dynamic> json, String userId) {
    try {
      final mealId = json['key']?.toString() ?? '';
      if (mealId.isEmpty) return null;

      return MealLogIsarModel(
        mealId: mealId,
        userId: userId,
        dateMs: DateTime.tryParse(json['date']?.toString() ?? '')
                    ?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
        mealType: json['mealType']?.toString() ?? 'meal',
        itemsJson: jsonEncode(json['items'] ?? []),
        syncedToRemote: true,
      );
    } catch (_) {
      return null;
    }
  }

  HealthDataIsarModel? _healthFromRemote(
      Map<String, dynamic> json, String userId) {
    try {
      return HealthDataIsarModel(
        userId: userId,
        dateMs: DateTime.tryParse(json['date']?.toString() ?? '')
                    ?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
        steps: int.tryParse(json['steps']?.toString() ?? '0') ?? 0,
        distanceKm:
            double.tryParse(json['distanceKm']?.toString() ?? '0') ?? 0,
        burnedCalories:
            double.tryParse(json['burnedCalories']?.toString() ?? '0') ?? 0,
        sleepHours:
            int.tryParse(json['sleepHours']?.toString() ?? '0') ?? 0,
        sleepMinutes:
            int.tryParse(json['sleepMinutes']?.toString() ?? '0') ?? 0,
        sleepQuality: json['sleepQuality']?.toString() ?? 'fair',
        syncedToRemote: true,
      );
    } catch (_) {
      return null;
    }
  }

  static void _log(String message) {
    // ignore: avoid_print
    print('[SyncService] $message');
  }
}
