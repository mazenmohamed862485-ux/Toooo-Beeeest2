// TO Best — utils/extensions.dart

import 'package:flutter/material.dart';

extension StringExt on String {
  bool get isValidEmail {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(trim());
  }

  bool get isValidSaudiPhone {
    final cleaned = trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(?:\+?966|0)5[0-9]{8}$').hasMatch(cleaned);
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

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

extension DateTimeExt on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
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
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday)).startOfDay;
  }
}

extension DoubleExt on double {
  double roundToDecimal(int places) {
    final factor = 10.0 * places;
    return (this * factor).round() / factor;
  }

  String get caloriesText {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toStringAsFixed(0);
  }
}

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
      ),
    );
  }
}
