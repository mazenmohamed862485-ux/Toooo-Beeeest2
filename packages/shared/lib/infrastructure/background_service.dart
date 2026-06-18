// ============================================================
// TO Best — infrastructure/background_service.dart
// Background Tasks via WorkManager
// ============================================================

import 'package:workmanager/workmanager.dart';

/// معرّفات مهام الـ Background
class BackgroundTaskNames {
  static const String syncTask = 'tobest_sync_task';
  static const String pollChatTask = 'tobest_poll_chat';
  static const String weeklyCleanup = 'tobest_weekly_cleanup';
  static const String checkNotifications = 'tobest_check_notifications';
}

/// خدمة الـ Background Tasks
///
/// تستخدم workmanager (iOS + Android)
class BackgroundService {
  BackgroundService._internal();
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;

  bool _enabled = true;

  /// تهيئة workmanager
  Future<void> init({required bool enabled}) async {
    _enabled = enabled;
    await Workmanager().initialize(
      _backgroundCallbackDispatcher,
      isInDebugMode: false,
    );

    if (enabled) {
      await registerTasks();
    }
  }

  /// تسجيل كل المهام الدورية
  Future<void> registerTasks() async {
    // مزامنة دورية كل 15 دقيقة
    await Workmanager().registerPeriodicTask(
      BackgroundTaskNames.syncTask,
      BackgroundTaskNames.syncTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 2),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // فحص الإشعارات كل 5 دقائق
    await Workmanager().registerPeriodicTask(
      BackgroundTaskNames.checkNotifications,
      BackgroundTaskNames.checkNotifications,
      frequency: const Duration(minutes: 5),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    // Weekly Cleanup كل أسبوع
    await Workmanager().registerPeriodicTask(
      BackgroundTaskNames.weeklyCleanup,
      BackgroundTaskNames.weeklyCleanup,
      frequency: const Duration(days: 7),
      initialDelay: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// تعطيل كل المهام
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// تمكين/تعطيل Background Service
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (enabled) {
      await registerTasks();
    } else {
      await cancelAll();
    }
  }

  bool get isEnabled => _enabled;
}

/// نقطة دخول مهام الـ Background (Top-level function — must stay top-level)
@pragma('vm:entry-point')
void _backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case BackgroundTaskNames.syncTask:
        // مزامنة البيانات المعلقة
        return Future.value(true);

      case BackgroundTaskNames.checkNotifications:
        // فحص الإشعارات الجديدة
        return Future.value(true);

      case BackgroundTaskNames.weeklyCleanup:
        // Weekly Cleanup
        return Future.value(true);

      default:
        return Future.value(false);
    }
  });
}
