// ============================================================
// TO Best — utils/extensions.dart
// Extension Methods مفيدة عبر كل التطبيق
// ============================================================

import 'package:flutter/material.dart';

/// Extensions على String
extension StringExt on String {
  bool get isValidEmail =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(trim());

  bool get isValidSaudiPhone {
    final c = trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(?:\+?966|0)5[0-9]{8}$').hasMatch(c);
  }

  String truncate(int max, {String ellipsis = '...'}) {
    if (length <= max) return this;
    return '${substring(0, max - ellipsis.length)}$ellipsis';
  }

  /// تطبيع النص العربي للبحث
  String get normalizedArabic {
    return replaceAll(RegExp('[أإآاى]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp('[\u064B-\u065F\u0670]'), '')
        .toLowerCase()
        .trim();
  }

  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : w)
        .join(' ');
  }

  bool get isNullOrEmpty => trim().isEmpty;
}

/// Extensions على DateTime
extension DateTimeExt on DateTime {
  bool get isToday {
    final n = DateTime.now();
    return year == n.year && month == n.month && day == n.day;
  }

  bool get isYesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return year == y.year && month == y.month && day == y.day;
  }

  String get smartDate {
    if (isToday) return 'اليوم';
    if (isYesterday) return 'أمس';
    return '$day/$month/$year';
  }

  int get daysFromNow => DateTime.now().difference(this).inDays;

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeek {
    final d = weekday - 1;
    return subtract(Duration(days: d)).startOfDay;
  }
}

/// Extensions على double
extension DoubleExt on double {
  double roundToDecimal(int places) {
    final f = 10.0 * places;
    return (this * f).round() / f;
  }

  String get caloriesText {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toStringAsFixed(0);
  }
}

/// Extensions على int
extension IntExt on int {
  String get toMMSS {
    final m = this ~/ 60;
    final s = this % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get toHoursMinutes {
    if (this < 60) return '$this د';
    final h = this ~/ 60;
    final m = this % 60;
    return m > 0 ? '$h س $m د' : '$h ساعة';
  }
}

/// Extensions على BuildContext
extension ContextExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isTablet => screenWidth > 600;

  void showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showSuccessSnack(String message) =>
      showSnack(message, color: const Color(0xFF22C55E));

  void showErrorSnack(String message) =>
      showSnack(message, color: const Color(0xFFEF4444));
}

/// Extensions على List
extension ListExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  List<T> safeSublist(int start, [int? end]) {
    final e = end != null ? end.clamp(0, length) : length;
    final s = start.clamp(0, e);
    return sublist(s, e);
  }
}
