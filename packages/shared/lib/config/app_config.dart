// ============================================================
// TO Best — app_config.dart
// الإعدادات المركزية للتطبيق — غيّر من هنا فقط
// ============================================================

/// إعدادات التطبيق المركزية
///
/// كل الأسماء والإعدادات العامة تُغيَّر من هنا فقط
/// بحيث لا تنتشر في الكود
class AppConfig {
  AppConfig._();

  // ── أسماء التطبيقات ─────────────────────────────────────
  /// اسم التطبيق الرئيسي
  static const String appName = 'TO Best';

  /// اسم تطبيق الإدارة
  static const String managementAppName = 'TO Best Management';

  // ── Package IDs ──────────────────────────────────────────
  /// معرّف حزمة التطبيق الرئيسي
  static const String appPackageId = 'com.tobest.app';

  /// معرّف حزمة تطبيق الإدارة
  static const String managementPackageId = 'com.tobest.management';

  // ── إصدارات SDK ──────────────────────────────────────────
  /// الحد الأدنى لـ Android SDK
  static const int minAndroidSdk = 24;

  /// الـ Target Android SDK
  static const int targetAndroidSdk = 35;

  // ── الأدوار — قابلة للتوسع مستقبلاً ────────────────────
  /// أدوار المستخدمين المسموح بها في TO Best
  static const List<String> tobest_allowedRoles = [
    AppRoles.user,
    AppRoles.coach,
  ];

  /// أدوار المستخدمين المسموح بها في TO Best Management
  static const List<String> management_allowedRoles = [
    AppRoles.manager,
    AppRoles.support,
    AppRoles.subscriptions,
  ];

  // ── Polling Intervals (بالثواني) ────────────────────────
  /// فترة الـ Polling الافتراضية (foreground + نشط)
  static const int pollingIntervalActiveSeconds = 5;

  /// فترة الـ Polling القصوى (foreground + خامل)
  static const int pollingIntervalIdleSeconds = 30;

  /// فترة الـ Background Sync (بالدقائق)
  static const int backgroundSyncMinutes = 15;

  // ── Cache ────────────────────────────────────────────────
  /// الحد الأقصى لذاكرة التخزين المؤقت للفيديو (500 MB)
  static const int videoCacheMaxMb = 500;

  // ── إعدادات الـ OTP ──────────────────────────────────────
  /// مدة صلاحية الـ OTP (10 دقائق)
  static const int otpExpiryMinutes = 10;

  /// حد إعادة الإرسال (ثواني)
  static const int otpResendSeconds = 60;

  /// الحد الأقصى لطلبات الـ OTP في الساعة
  static const int otpMaxRequestsPerHour = 3;

  // ── Streak ───────────────────────────────────────────────
  /// Milestones للـ Streak
  static const List<int> streakMilestones = [7, 30, 100];

  // ── الشاشات المحمية (FLAG_SECURE) ───────────────────────
  /// مسارات go_router للشاشات المحمية من التقاط الشاشة
  static const List<String> protectedRoutes = [
    '/workout',
    '/nutrition',
    '/change-password',
    '/otp',
  ];
}

/// أكواد الأدوار — Single source of truth
class AppRoles {
  AppRoles._();

  /// مستخدم عادي (في TO Best)
  static const String user = 'TRAINEE';

  /// مدرب (في TO Best)
  static const String coach = 'COACH';

  /// مدير (في Management)
  static const String manager = 'MANAGER';

  /// دعم فني (في Management)
  static const String support = 'SUPPORT';

  /// مسؤول اشتراكات (في Management)
  static const String subscriptions = 'SUBSCRIPTIONS';
}

/// حالات الاشتراك
class SubscriptionStatus {
  SubscriptionStatus._();

  static const String pending = 'pending';
  static const String active = 'active';
  static const String rejected = 'rejected';
  static const String expired = 'expired';
  static const String none = 'none';
}

/// أسماء الشاشات المحمية
class AppRoutes {
  AppRoutes._();

  // ── Shared ───────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';

  // ── TO Best ──────────────────────────────────────────────
  static const String home = '/home';
  static const String workout = '/workout';
  static const String nutrition = '/nutrition';
  static const String progress = '/progress';
  static const String chat = '/chat';
  static const String conversation = '/chat/conversation';
  static const String aiCoach = '/ai-coach';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String subscriptionPending = '/subscription-pending';
  static const String subscriptionRejected = '/subscription-rejected';
  static const String subscriptionExpired = '/subscription-expired';
  static const String googleSignInCompletion = '/google-signin-completion';
  static const String guestMode = '/guest';

  // ── Management ───────────────────────────────────────────
  static const String mgmtDashboard = '/dashboard';
  static const String mgmtUsers = '/users';
  static const String mgmtUserProfile = '/users/:id';
  static const String mgmtSubscriptionRequests = '/subscription-requests';
  static const String mgmtProgramRequests = '/program-requests';
  static const String mgmtChat = '/chat';
  static const String mgmtSubscriptionPlans = '/subscription-plans';
  static const String mgmtConnectionSettings = '/connection-settings';
  static const String mgmtReferralStats = '/referral-stats';
}
