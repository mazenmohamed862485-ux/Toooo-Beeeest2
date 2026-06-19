// ============================================================
// TO Best — features/auth/presentation/providers/auth_provider.dart
// Auth State Management بـ Riverpod
// ============================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/data/models/user_model.dart';
import 'package:uuid/uuid.dart';

part 'auth_provider.g.dart';
import 'package:shared/design/themes.dart';
import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';

// ── Providers للاعتماديات ──────────────────────────────────

@riverpod
GasClient gasClient(GasClientRef ref) => GasClient();

@riverpod
IsarService isarService(IsarServiceRef ref) => IsarService();

@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) =>
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

// ── Auth State Provider ────────────────────────────────────

/// حالة المصادقة — AsyncValue<UserEntity?>
///
/// null = غير مسجّل
/// UserEntity = مسجّل
@riverpod
class AuthState extends _$AuthState {
  static const String _deviceIdKey = 'device_id';
  static const String _forceLogoutTokenKey = 'force_logout_token';

  @override
  Future<UserEntity?> build() async {
    return _loadCurrentUser();
  }

  /// تحميل المستخدم الحالي من Isar
  Future<UserEntity?> _loadCurrentUser() async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final userModel = await db.userIsarModels.where().findFirst();
    if (userModel == null) return null;

    final user = userModel.toEntity();

    // التحقق من Force Logout
    try {
      final gasClient = ref.read(gasClientProvider);
      final result = await gasClient.post(
        action: 'CHECK_FORCE_LOGOUT',
        data: {'uid': user.uid},
      );

      final serverToken = result['forceLogoutToken']?.toString() ?? '';
      final storage = ref.read(secureStorageProvider);
      final localToken =
          await storage.read(key: _forceLogoutTokenKey) ?? '';

      if (serverToken.isNotEmpty && serverToken != localToken) {
        await logout();
        return null;
      }
    } catch (_) {
      // استمر حتى لو فشل الفحص (offline)
    }

    return user;
  }

  // ── تسجيل الدخول ─────────────────────────────────────────

  /// تسجيل الدخول بالبريد/الهاتف وكلمة المرور
  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = const AsyncLoading();

    final deviceInfo = await _getDeviceInfo();
    final gasClient = ref.read(gasClientProvider);

    state = await AsyncValue.guard(() async {
      final result = await gasClient.post(
        action: 'LOGIN',
        data: {
          'email': emailOrPhone,
          'password': password,
          'deviceId': deviceInfo.deviceId,
          'deviceName': deviceInfo.deviceName,
          'platform': deviceInfo.platform,
        },
      );

      final userData = result['user'] as Map<String, dynamic>?;
      if (userData == null) throw Exception('Invalid response from server');

      final userModel = UserIsarModel.fromJson(userData);

      // التحقق من الدور
      if (!AppConfig.tobest_allowedRoles.contains(userModel.role)) {
        throw Exception('unauthorized_role');
      }

      // حفظ في Isar
      final isar = ref.read(isarServiceProvider);
      final db = await isar.db;
      await db.writeTxn(() async {
        await db.userIsarModels.put(userModel);
      });

      // حفظ Force Logout Token
      final storage = ref.read(secureStorageProvider);
      await storage.write(
        key: _forceLogoutTokenKey,
        value: userModel.forceLogoutToken,
      );

      return userModel.toEntity();
    });
  }

  /// تسجيل الدخول بـ Google
  Future<GoogleSignInResult> googleSignIn() async {
    state = const AsyncLoading();

    final deviceInfo = await _getDeviceInfo();
    final gasClient = ref.read(gasClientProvider);

    try {
      // Step 1: الحصول على Google Token
      // (يُستكمَل في google_signin_completion_screen إذا كان حساباً جديداً)
      final result = await gasClient.post(
        action: 'GOOGLE_LOGIN',
        data: {
          'deviceId': deviceInfo.deviceId,
          'deviceName': deviceInfo.deviceName,
          'platform': deviceInfo.platform,
        },
      );

      if (result['newUser'] == true) {
        // حساب جديد — يحتاج إكمال البيانات
        state = const AsyncData(null);
        return GoogleSignInResult.newUser(
          googleData: result['googleData'] as Map<String, dynamic>? ?? {},
        );
      }

      final userData = result['user'] as Map<String, dynamic>?;
      if (userData == null) throw Exception('Invalid server response');

      final userModel = UserIsarModel.fromJson(userData);

      if (!AppConfig.tobest_allowedRoles.contains(userModel.role)) {
        throw Exception('unauthorized_role');
      }

      final isar = ref.read(isarServiceProvider);
      final db = await isar.db;
      await db.writeTxn(() async {
        await db.userIsarModels.put(userModel);
      });

      final storage = ref.read(secureStorageProvider);
      await storage.write(
        key: _forceLogoutTokenKey,
        value: userModel.forceLogoutToken,
      );

      state = AsyncData(userModel.toEntity());
      return GoogleSignInResult.existingUser(user: userModel.toEntity());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ── إنشاء حساب ───────────────────────────────────────────

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    required String goal,
    String referralCode = '',
  }) async {
    state = const AsyncLoading();

    final gasClient = ref.read(gasClientProvider);

    state = await AsyncValue.guard(() async {
      final result = await gasClient.post(
        action: 'REGISTER',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'gender': gender,
          'weight': weight,
          'height': height,
          'age': age,
          'activityLevel': activityLevel,
          'goal': goal,
          if (referralCode.isNotEmpty) 'referralCode': referralCode,
        },
      );

      final userData = result['user'] as Map<String, dynamic>?;
      if (userData == null) throw Exception('Registration failed');

      final userModel = UserIsarModel.fromJson(userData);

      final isar = ref.read(isarServiceProvider);
      final db = await isar.db;
      await db.writeTxn(() async {
        await db.userIsarModels.put(userModel);
      });

      return userModel.toEntity();
    });
  }

  // ── تسجيل الخروج ─────────────────────────────────────────

  Future<void> logout() async {
    final currentUser = state.valueOrNull;

    try {
      if (currentUser != null) {
        final gasClient = ref.read(gasClientProvider);
        await gasClient.post(
          action: 'LOGOUT',
          data: {'uid': currentUser.uid},
        );
      }
    } catch (_) {
      // تجاهل أخطاء الشبكة عند تسجيل الخروج
    }

    // مسح البيانات المحلية
    final isar = ref.read(isarServiceProvider);
    await isar.clearAll();

    final storage = ref.read(secureStorageProvider);
    await storage.deleteAll();

    state = const AsyncData(null);
  }

  // ── تحديث بيانات المستخدم ────────────────────────────────

  Future<void> refreshUser() async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    try {
      final gasClient = ref.read(gasClientProvider);
      final result = await gasClient.post(
        action: 'GET_PROFILE',
        data: {'uid': currentUser.uid},
      );

      final userData = result['user'] as Map<String, dynamic>?;
      if (userData == null) return;

      final userModel = UserIsarModel.fromJson(userData);

      final isar = ref.read(isarServiceProvider);
      final db = await isar.db;
      await db.writeTxn(() async {
        await db.userIsarModels.put(userModel);
      });

      state = AsyncData(userModel.toEntity());
    } catch (_) {
      // استمر بالبيانات المحلية في حال عدم الاتصال
    }
  }

  // ── Helper ───────────────────────────────────────────────

  Future<_DeviceInfo> _getDeviceInfo() async {
    final storage = ref.read(secureStorageProvider);

    // الحصول على deviceId أو توليده
    var deviceId = await storage.read(key: _deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await storage.write(key: _deviceIdKey, value: deviceId);
    }

    final plugin = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';
    String platform = 'android';

    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await plugin.androidInfo;
      deviceName = '${info.brand} ${info.model}';
      platform = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await plugin.iosInfo;
      deviceName = info.name ?? info.model ?? 'iPhone';
      platform = 'ios';
    }

    return _DeviceInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
    );
  }
}

// ── Helper Classes ────────────────────────────────────────────

class _DeviceInfo {
  const _DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
}

/// نتيجة Google Sign In
class GoogleSignInResult {
  const GoogleSignInResult._({
    required this.isNewUser,
    this.user,
    this.googleData = const {},
  });

  factory GoogleSignInResult.existingUser({required UserEntity user}) {
    return GoogleSignInResult._(isNewUser: false, user: user);
  }

  factory GoogleSignInResult.newUser({
    required Map<String, dynamic> googleData,
  }) {
    return GoogleSignInResult._(isNewUser: true, googleData: googleData);
  }

  final bool isNewUser;
  final UserEntity? user;
  final Map<String, dynamic> googleData;
}

// ── Settings Provider ─────────────────────────────────────────
// (في ملف منفصل لكن مُعرَّف هنا للاستخدام في router.dart)


/// إعدادات التطبيق المحلية
class AppSettings {
  const AppSettings({
    this.theme = AppTheme.auto,
    this.accentColor = AppColors.accent1,
    this.locale = const Locale('ar', 'SA'),
    this.fontSize = 1.0,
    this.notificationsEnabled = true,
    this.backgroundSyncEnabled = true,
  });

  final AppTheme theme;
  final Color accentColor;
  final Locale locale;
  final double fontSize;
  final bool notificationsEnabled;
  final bool backgroundSyncEnabled;

  AppSettings copyWith({
    AppTheme? theme,
    Color? accentColor,
    Locale? locale,
    double? fontSize,
    bool? notificationsEnabled,
    bool? backgroundSyncEnabled,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      locale: locale ?? this.locale,
      fontSize: fontSize ?? this.fontSize,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      backgroundSyncEnabled:
          backgroundSyncEnabled ?? this.backgroundSyncEnabled,
    );
  }
}

