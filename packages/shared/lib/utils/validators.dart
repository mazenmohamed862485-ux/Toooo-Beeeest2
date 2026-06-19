// TO Best — utils/validators.dart

class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) return 'بريد إلكتروني غير صالح';
    return null;
  }

  static String? saudiPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الهاتف مطلوب';
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final regex = RegExp(r'^(?:\+?966|0)5[0-9]{8}$');
    if (!regex.hasMatch(cleaned)) return 'رقم هاتف سعودي غير صالح';
    return null;
  }

  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني أو رقم الهاتف مطلوب';
    }
    final v = value.trim();
    final isPhone = RegExp(r'^[\d\+\-\s\(\)]+$').hasMatch(v);
    if (isPhone) return saudiPhone(v);
    return email(v);
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 8) return 'يجب أن تكون 8 أحرف على الأقل';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'يجب احتواؤها على حرف كبير واحد على الأقل';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'يجب احتواؤها على رقم واحد على الأقل';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'أعد إدخال كلمة المرور';
      if (value != password) return 'كلمتا المرور غير متطابقتين';
      return null;
    };
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل الكود';
    if (value.trim().length != 6) return 'الكود يجب أن يكون 6 أرقام';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'الكود يجب أن يحتوي على أرقام فقط';
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'الاسم مطلوب';
    if (value.trim().length < 3) return 'الاسم قصير جداً';
    if (value.trim().length > 60) return 'الاسم طويل جداً';
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.isEmpty) return 'الوزن مطلوب';
    final w = double.tryParse(value);
    if (w == null) return 'أدخل رقماً صحيحاً';
    if (w < 30 || w > 300) return 'الوزن يجب أن يكون بين 30 و300 كيلوغرام';
    return null;
  }

  static String? height(String? value) {
    if (value == null || value.isEmpty) return 'الطول مطلوب';
    final h = double.tryParse(value);
    if (h == null) return 'أدخل رقماً صحيحاً';
    if (h < 100 || h > 250) return 'الطول يجب أن يكون بين 100 و250 سنتيمتر';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.isEmpty) return 'العمر مطلوب';
    final a = int.tryParse(value);
    if (a == null) return 'أدخل رقماً صحيحاً';
    if (a < 14 || a > 80) return 'العمر يجب أن يكون بين 14 و80 سنة';
    return null;
  }

  static String? required(String? value, {String fieldName = 'الحقل'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName مطلوب';
    return null;
  }

  static String? optional(String? value) => null;
}
