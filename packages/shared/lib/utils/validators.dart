// ============================================================
// TO Best — utils/validators.dart
// Validators للفورم: Email, Phone, Password, OTP
// ============================================================

/// Validators لحقول الفورم
class AppValidators {
  AppValidators._();

  /// التحقق من البريد الإلكتروني
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) return 'بريد إلكتروني غير صالح';
    return null;
  }

  /// التحقق من رقم الهاتف السعودي
  static String? saudiPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الهاتف مطلوب';
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // يقبل: 05xxxxxxxx أو +9665xxxxxxxx أو 9665xxxxxxxx
    final regex = RegExp(r'^(?:\+?966|0)5[0-9]{8}$');
    if (!regex.hasMatch(cleaned)) return 'رقم هاتف سعودي غير صالح';
    return null;
  }

  /// التحقق من رقم هاتف أو بريد (للتسجيل والدخول)
  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني أو رقم الهاتف مطلوب';
    }
    final v = value.trim();

    // فحص إذا كان رقم هاتف
    final isPhone = RegExp(r'^[\d\+\-\s\(\)]+$').hasMatch(v);
    if (isPhone) return saudiPhone(v);

    // فحص إذا كان بريد
    return email(v);
  }

  /// التحقق من كلمة المرور
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

  /// التحقق من تطابق كلمتي المرور
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'أعد إدخال كلمة المرور';
      if (value != password) return 'كلمتا المرور غير متطابقتين';
      return null;
    };
  }

  /// التحقق من الـ OTP
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل الكود';
    if (value.trim().length != 6) return 'الكود يجب أن يكون 6 أرقام';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'الكود يجب أن يحتوي على أرقام فقط';
    }
    return null;
  }

  /// التحقق من الاسم الكامل
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'الاسم مطلوب';
    if (value.trim().length < 3) return 'الاسم قصير جداً';
    if (value.trim().length > 60) return 'الاسم طويل جداً';
    return null;
  }

  /// التحقق من الوزن
  static String? weight(String? value) {
    if (value == null || value.isEmpty) return 'الوزن مطلوب';
    final w = double.tryParse(value);
    if (w == null) return 'أدخل رقماً صحيحاً';
    if (w < 30 || w > 300) return 'الوزن يجب أن يكون بين 30 و300 كيلوغرام';
    return null;
  }

  /// التحقق من الطول
  static String? height(String? value) {
    if (value == null || value.isEmpty) return 'الطول مطلوب';
    final h = double.tryParse(value);
    if (h == null) return 'أدخل رقماً صحيحاً';
    if (h < 100 || h > 250) return 'الطول يجب أن يكون بين 100 و250 سنتيمتر';
    return null;
  }

  /// التحقق من العمر
  static String? age(String? value) {
    if (value == null || value.isEmpty) return 'العمر مطلوب';
    final a = int.tryParse(value);
    if (a == null) return 'أدخل رقماً صحيحاً';
    if (a < 14 || a > 80) return 'العمر يجب أن يكون بين 14 و80 سنة';
    return null;
  }

  /// حقل مطلوب عام
  static String? required(String? value, {String fieldName = 'الحقل'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName مطلوب';
    return null;
  }

  /// حقل اختياري — يُرجع null دائماً
  static String? optional(String? value) => null;
}

// ============================================================
// utils/extensions.dart
// Extension Methods مفيدة
// ============================================================

import 'package:flutter/material.dart';

/// Extensions على String
extension StringExt on String {
  /// هل هذا الـ String بريد إلكتروني صالح
  bool get isValidEmail {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(trim());
  }

  /// هل هذا الـ String رقم هاتف سعودي صالح
  bool get isValidSaudiPhone {
    final cleaned = trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(?:\+?966|0)5[0-9]{8}$').hasMatch(cleaned);
  }

  /// اقتطاع النص مع إضافة "..."
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// تطبيع النص العربي
  String get normalizedArabic {
    return replaceAll(RegExp('[أإآاى]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp('[\u064B-\u065F\u0670]'), '')
        .toLowerCase()
        .trim();
  }

  /// تحويل النص لعنوان (أول حرف كبير)
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : w)
        .join(' ');
  }

  /// هل النص فارغ أو null
  bool get isNullOrEmpty => trim().isEmpty;
}

/// Extensions على DateTime
extension DateTimeExt on DateTime {
  /// هل هذا التاريخ اليوم
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// هل هذا التاريخ أمس
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// نص مختصر للتاريخ
  String get smartDate {
    if (isToday) return 'اليوم';
    if (isYesterday) return 'أمس';
    return '$day/$month/$year';
  }

  /// الفرق بالأيام من اليوم
  int get daysFromNow => DateTime.now().difference(this).inDays;

  /// بداية اليوم (منتصف الليل)
  DateTime get startOfDay => DateTime(year, month, day);

  /// نهاية اليوم
  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);

  /// بداية الأسبوع (الإثنين)
  DateTime get startOfWeek {
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday)).startOfDay;
  }
}

/// Extensions على double
extension DoubleExt on double {
  /// تقريب لعدد محدد من الخانات العشرية
  double roundToDecimal(int places) {
    final factor = 10.0 * places;
    return (this * factor).round() / factor;
  }

  /// تحويل السعرات لنص مقروء
  String get caloriesText {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toStringAsFixed(0);
  }
}

/// Extensions على int
extension IntExt on int {
  /// تحويل الثواني لنص (mm:ss)
  String get toMMSS {
    final m = this ~/ 60;
    final s = this % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// تحويل الدقائق لنص
  String get toHoursMinutes {
    if (this < 60) return '$this د';
    final h = this ~/ 60;
    final m = this % 60;
    return m > 0 ? '$h س $m د' : '$h ساعة';
  }
}

/// Extensions على BuildContext
extension ContextExt on BuildContext {
  /// هل الثيم داكن
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// اللون الأساسي
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// عرض الشاشة
  double get screenWidth => MediaQuery.of(this).size.width;

  /// ارتفاع الشاشة
  double get screenHeight => MediaQuery.of(this).size.height;

  /// هل هذا Tablet
  bool get isTablet => screenWidth > 600;

  /// عرض SnackBar
  void showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
