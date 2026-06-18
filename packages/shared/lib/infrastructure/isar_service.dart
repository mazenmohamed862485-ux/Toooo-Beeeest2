// ============================================================
// TO Best — infrastructure/isar_service.dart
// خدمة قاعدة البيانات المحلية (Isar)
// ============================================================

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/user_model.dart';
import '../data/models/workout_model.dart';
import '../data/models/food_model.dart';
import '../data/models/chat_model.dart';
import '../data/models/health_model.dart';
import '../data/models/subscription_model.dart';

/// Singleton لخدمة Isar — نقطة وصول واحدة لقاعدة البيانات المحلية
///
/// كل Schema مُسجَّل هنا بشكل صريح
class IsarService {
  IsarService._internal();
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;

  Isar? _isar;

  /// الحصول على Isar instance (يُهيَّأ عند أول استدعاء)
  Future<Isar> get db async {
    _isar ??= await _openIsar();
    return _isar!;
  }

  /// هل قاعدة البيانات مفتوحة
  bool get isOpen => _isar?.isOpen ?? false;

  // ── فتح قاعدة البيانات ───────────────────────────────────
  Future<Isar> _openIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        UserIsarModelSchema,
        WorkoutSessionIsarModelSchema,
        ExerciseLogIsarModelSchema,
        FoodItemIsarModelSchema,
        MealLogIsarModelSchema,
        ChatMessageIsarModelSchema,
        AiMessageIsarModelSchema,
        HealthDataIsarModelSchema,
        SubscriptionRequestIsarModelSchema,
        SyncQueueItemSchema,
        AppSettingsIsarModelSchema,
      ],
      directory: dir.path,
      name: 'tobest_db',
    );
  }

  // ── مسح كل البيانات ─────────────────────────────────────

  /// مسح كل البيانات (يُستخدم في Weekly Cleanup بعد Sync)
  ///
  /// ⚠️ لا تستدعِ هذه الدالة إلا بعد نجاح syncLocalChangesToGAS()
  Future<void> clearAll() async {
    final db = await this.db;
    await db.writeTxn(() async {
      await db.userIsarModels.clear();
      await db.workoutSessionIsarModels.clear();
      await db.exerciseLogIsarModels.clear();
      await db.foodItemIsarModels.clear();
      await db.mealLogIsarModels.clear();
      await db.chatMessageIsarModels.clear();
      await db.healthDataIsarModels.clear();
      await db.subscriptionRequestIsarModels.clear();
      await db.syncQueueItems.clear();
      // AppSettings يُحتفظ به — لا يُمسح
    });
  }

  /// مسح بيانات مستخدم محدد فقط
  Future<void> clearUserData(String userId) async {
    final db = await this.db;
    await db.writeTxn(() async {
      await db.workoutSessionIsarModels
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
      await db.mealLogIsarModels.filter().userIdEqualTo(userId).deleteAll();
      await db.healthDataIsarModels.filter().userIdEqualTo(userId).deleteAll();
      await db.chatMessageIsarModels.filter().userIdEqualTo(userId).deleteAll();
      await db.aiMessageIsarModels.filter().userIdEqualTo(userId).deleteAll();
    });
  }

  // ── إغلاق قاعدة البيانات ────────────────────────────────
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}

// ── Sync Queue ────────────────────────────────────────────────

/// عنصر في طابور المزامنة (للتغييرات التي لم تُزامَن بعد)
@Collection()
class SyncQueueItem {
  SyncQueueItem({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Id id = Isar.autoIncrement;

  /// نوع الكيان (workout / meal / health / chat)
  final String entityType;

  /// معرّف الكيان
  final String entityId;

  /// العملية (create / update / delete)
  final String action;

  /// البيانات JSON
  final String payload;

  final DateTime createdAt;

  /// عدد محاولات الإرسال الفاشلة
  int retryCount;
}

/// إعدادات التطبيق المحلية
@Collection()
class AppSettingsIsarModel {
  AppSettingsIsarModel({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String key;

  final String value;
  final DateTime updatedAt;
}
