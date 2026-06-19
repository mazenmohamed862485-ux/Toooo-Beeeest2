// ============================================================
// TO Best — infrastructure/notification_service.dart
// Local Notifications فقط — لا Push Notifications
// ============================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// خدمة الإشعارات المحلية
///
/// تستخدم flutter_local_notifications فقط — لا Firebase، لا Push
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Notification Channels ─────────────────────────────────
  static const String _chatChannelId = 'tobest_chat';
  static const String _subscriptionChannelId = 'tobest_subscription';
  static const String _systemChannelId = 'tobest_system';
  static const String _motivationChannelId = 'tobest_motivation';

  // ── تهيئة الخدمة ─────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannels([
      const AndroidNotificationChannel(
        _chatChannelId,
        'رسائل الشات',
        description: 'إشعارات رسائل الشات الجديدة',
        importance: Importance.high,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _subscriptionChannelId,
        'الاشتراكات',
        description: 'موافقة أو رفض طلبات الاشتراك',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _systemChannelId,
        'النظام',
        description: 'إشعارات النظام والأجهزة',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _motivationChannelId,
        'التحفيز',
        description: 'Streak وإنجازات وتذكيرات',
        importance: Importance.defaultImportance,
      ),
    ]);
  }

  // ── إرسال الإشعارات ──────────────────────────────────────

  /// إشعار رسالة جديدة في الشات
  Future<void> showChatNotification({
    required int id,
    required String senderName,
    required String message,
    String? payload,
  }) async {
    await _show(
      id: id,
      title: senderName,
      body: message,
      channelId: _chatChannelId,
      payload: payload,
    );
  }

  /// إشعار موافقة على الاشتراك
  Future<void> showSubscriptionApproved({
    required String planName,
  }) async {
    await _show(
      id: 2001,
      title: 'تم تفعيل اشتراكك',
      body: 'تهانينا! تم تفعيل اشتراك $planName بنجاح',
      channelId: _subscriptionChannelId,
    );
  }

  /// إشعار رفض الاشتراك
  Future<void> showSubscriptionRejected({required String reason}) async {
    await _show(
      id: 2002,
      title: 'تم رفض طلبك',
      body: reason.isNotEmpty ? 'السبب: $reason' : 'يمكنك إعادة التقديم',
      channelId: _subscriptionChannelId,
    );
  }

  /// إشعار محاولة دخول جهاز جديد (لـ SUPPORT و MANAGER)
  Future<void> showNewDeviceAlert({
    required String userName,
    required String deviceName,
  }) async {
    await _show(
      id: 3001,
      title: 'جهاز جديد',
      body: '$userName حاول الدخول من $deviceName',
      channelId: _systemChannelId,
    );
  }

  /// إشعار موافقة/رفض تغيير البرنامج
  Future<void> showProgramChangeResult({
    required bool approved,
    String? reason,
  }) async {
    await _show(
      id: 4001,
      title: approved ? 'تم تحديث برنامجك' : 'تم رفض طلب التغيير',
      body: !approved && reason != null ? 'السبب: $reason' : '',
      channelId: _subscriptionChannelId,
    );
  }

  /// إشعار Streak Milestone
  Future<void> showStreakMilestone({required int days}) async {
    await _show(
      id: 5001 + days,
      title: '$days يوم متواصل!',
      body: 'رائع! لقد حققت $days يوماً متواصلاً من التمرين 💪',
      channelId: _motivationChannelId,
    );
  }

  /// إشعار طلب اشتراك جديد (لـ SUBSCRIPTIONS)
  Future<void> showNewSubscriptionRequest({
    required String userName,
    required String planName,
  }) async {
    await _show(
      id: 6001,
      title: 'طلب اشتراك جديد',
      body: '$userName طلب خطة $planName',
      channelId: _subscriptionChannelId,
    );
  }

  // ── Private ───────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // التوجيه يُعالَج في الـ App Router
  }

  /// إلغاء إشعار
  Future<void> cancel(int id) async => _plugin.cancel(id);

  /// إلغاء كل الإشعارات
  Future<void> cancelAll() async => _plugin.cancelAll();
}
