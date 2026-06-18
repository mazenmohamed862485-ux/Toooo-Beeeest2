// ============================================================
// TO Best — domain/repositories/auth_repository.dart
// واجهة مستودع المصادقة
// ============================================================

import '../entities/user.dart';

/// واجهة مجردة لمستودع المصادقة
///
/// تعرّف العقد الذي يجب أن تلتزم به الطبقة الفعلية (data layer)
abstract class AuthRepository {
  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<UserEntity> login({
    required String emailOrPhone,
    required String password,
    required String deviceId,
    required String deviceName,
    required String platform,
  });

  /// تسجيل الدخول بـ Google
  Future<UserEntity> googleSignIn({
    required String deviceId,
    required String deviceName,
    required String platform,
  });

  /// إنشاء حساب جديد
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String gender,
    required double weight,
    required double height,
    required int age,
    String referralCode,
  });

  /// إرسال OTP لإعادة تعيين كلمة المرور
  Future<void> sendOtp(String contact);

  /// التحقق من الـ OTP
  Future<void> verifyOtp({required String email, required String code});

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  });

  /// تغيير كلمة المرور (لمستخدم مسجّل)
  Future<void> changePassword({
    required String uid,
    required String oldPassword,
    required String newPassword,
  });

  /// تسجيل الخروج
  Future<void> logout();

  /// الحصول على المستخدم الحالي من Isar
  Future<UserEntity?> getCurrentUser();

  /// حفظ المستخدم محلياً
  Future<void> saveUserLocally(UserEntity user);

  /// التحقق من حالة الـ Force Logout
  Future<bool> checkForceLogout(String uid, String currentToken);
}
