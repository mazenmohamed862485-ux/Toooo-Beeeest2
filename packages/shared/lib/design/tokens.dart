// ============================================================
// TO Best — design/tokens.dart
// Design Tokens: ألوان، spacing، typography، border radius
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان التطبيق الثابتة
class AppColors {
  AppColors._();

  // ── Accent Colors (5 خيارات للمستخدم) ───────────────────
  /// Slate Indigo — تقنية، محايدة، عصرية
  static const Color accent1 = Color(0xFF4F46E5);

  /// Deep Teal — هادئة، طبيعية، احترافية
  static const Color accent2 = Color(0xFF0F766E);

  /// Warm Amber — دافئة، مرحّبة، واضحة
  static const Color accent3 = Color(0xFFD97706);

  /// Dusty Rose — عصرية، ناعمة
  static const Color accent4 = Color(0xFFE11D48);

  /// Slate Gray — محايدة، مهنية، كلاسيكية
  static const Color accent5 = Color(0xFF475569);

  // ── Green Brand ───────────────────────────────────────────
  /// اللون الأخضر الرئيسي للعلامة التجارية
  static const Color brandGreen = Color(0xFF22C55E);

  /// أخضر فاتح
  static const Color brandGreenLight = Color(0xFF4ADE80);

  /// أخضر داكن
  static const Color brandGreenDark = Color(0xFF15803D);

  // ── Semantic Colors ───────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Eval Colors (للتقييم) ─────────────────────────────────
  static const Color evalOutstanding = Color(0xFF7C3AED); // s1
  static const Color evalExcellent = Color(0xFF2563EB);   // s2
  static const Color evalGreat = Color(0xFF0D9488);       // s3
  static const Color evalRestored = Color(0xFF0891B2);    // rv
  static const Color evalGood = Color(0xFF16A34A);        // gd
  static const Color evalStagnant = Color(0xFFCA8A04);    // st
  static const Color evalWarning = Color(0xFFEA580C);     // ws
  static const Color evalDecline = Color(0xFFDC2626);     // dn
  static const Color evalBeginning = Color(0xFF6B7280);   // beg

  // ── Light Theme ───────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOnSurfaceVariant = Color(0xFF475569);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFCBD5E1);

  // ── Dark Theme ────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);

  // ── Chat Bubble Colors ────────────────────────────────────
  static const Color chatBubbleSent = Color(0xFF22C55E);
  static const Color chatBubbleReceived = Color(0xFFF1F5F9);
  static const Color chatBubbleSentDark = Color(0xFF15803D);
  static const Color chatBubbleReceivedDark = Color(0xFF1E293B);

  // ── Sleep Quality Colors ──────────────────────────────────
  static const Color sleepPoor = Color(0xFFEF4444);
  static const Color sleepFair = Color(0xFFF59E0B);
  static const Color sleepGood = Color(0xFF22C55E);
  static const Color sleepExcellent = Color(0xFF3B82F6);

  // ── Heatmap ───────────────────────────────────────────────
  static const Color heatmapNone = Color(0xFFE2E8F0);
  static const Color heatmapLow = Color(0xFF86EFAC);
  static const Color heatmapMedium = Color(0xFF22C55E);
  static const Color heatmapHigh = Color(0xFF15803D);
  static const Color heatmapRest = Color(0xFF93C5FD); // يوم راحة مجدول
}

/// Spacing ثوابت المسافات
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
}

/// Border Radius ثوابت الاستدارة
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static BorderRadius get cardRadius =>
      BorderRadius.circular(md);

  static BorderRadius get buttonRadius =>
      BorderRadius.circular(lg);

  static BorderRadius get chipRadius =>
      BorderRadius.circular(full);

  static BorderRadius get inputRadius =>
      BorderRadius.circular(md);

  static BorderRadius get bottomSheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(xxl));

  static BorderRadius get dialogRadius =>
      BorderRadius.circular(xl);

  /// Chat Bubble Radius
  static BorderRadius chatBubbleSent(bool isFirst, bool isLast) {
    return BorderRadius.only(
      topLeft: const Radius.circular(lg),
      topRight: Radius.circular(isFirst ? lg : sm),
      bottomLeft: const Radius.circular(lg),
      bottomRight: Radius.circular(isLast ? xs : sm),
    );
  }

  static BorderRadius chatBubbleReceived(bool isFirst, bool isLast) {
    return BorderRadius.only(
      topLeft: Radius.circular(isFirst ? lg : sm),
      topRight: const Radius.circular(lg),
      bottomLeft: Radius.circular(isLast ? xs : sm),
      bottomRight: const Radius.circular(lg),
    );
  }
}

/// Typography ثوابت الخطوط
class AppTypography {
  AppTypography._();

  /// خط Cairo للعربي
  static TextStyle cairo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// خط Inter للإنجليزي
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// اختيار الخط بناءً على الـ Locale
  static TextStyle adaptive({
    required Locale locale,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    final isArabic = locale.languageCode == 'ar';
    return isArabic
        ? cairo(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          )
        : inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
          );
  }
}

/// Shadow ثوابت الظلال
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> cardShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.06),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
}

/// ثوابت الـ Animation
class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration breathing = Duration(seconds: 4);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
}

/// ثوابت حماية الشاشة
class AppScreenSecurity {
  AppScreenSecurity._();

  /// الشاشات المحمية من التقاط الشاشة (FLAG_SECURE)
  static const Set<String> protectedRoutes = {
    '/workout',
    '/nutrition',
    '/change-password',
    '/otp',
  };
}
