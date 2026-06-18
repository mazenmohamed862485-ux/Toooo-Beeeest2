// ============================================================
// TO Best — secrets.dart
// ⚠️ هذا الملف في .gitignore — يُملأ عبر generate_secrets.sh
// ⚠️ لا ترفعه لأي Repository أو Cloud Storage
// ⚠️ للـ CI/CD: يُولَّد تلقائياً من GitHub Secrets
// ============================================================

/// أسرار التطبيق الحساسة
///
/// القيم الافتراضية فارغة — يجب تشغيل scripts/generate_secrets.sh
/// أو تمرير --dart-define عند البناء
class AppSecrets {
  AppSecrets._();

  /// رابط Google Apps Script الـ Backend
  static const String gasBaseUrl = String.fromEnvironment(
    'GAS_BASE_URL',
    defaultValue: '',
  );

  /// المفتاح السري للمصادقة مع GAS
  static const String gasSecretKey = String.fromEnvironment(
    'GAS_SECRET_KEY',
    defaultValue: '',
  );

  /// مفتاح Gemini API للـ AI Coach
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
