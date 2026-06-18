// ============================================================
// TO Best — design/themes.dart
// 5 ثيمات: Auto, Light, Dark, Blue, Pink
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// خيارات الثيم
enum AppTheme {
  auto('Auto', 'تلقائي'),
  light('Light', 'فاتح'),
  dark('Dark', 'داكن'),
  blue('Blue', 'أزرق'),
  pink('Pink', 'وردي');

  const AppTheme(this.englishLabel, this.arabicLabel);
  final String englishLabel;
  final String arabicLabel;
}

/// بناء الثيمات
class AppThemes {
  AppThemes._();

  /// الـ ThemeMode بناءً على خيار الثيم
  static ThemeMode themeMode(AppTheme theme) {
    return switch (theme) {
      AppTheme.auto => ThemeMode.system,
      AppTheme.light || AppTheme.blue || AppTheme.pink => ThemeMode.light,
      AppTheme.dark => ThemeMode.dark,
    };
  }

  // ── Light Theme ───────────────────────────────────────────

  static ThemeData light(Color accentColor) {
    final colorScheme = ColorScheme.light(
      primary: accentColor,
      onPrimary: Colors.white,
      primaryContainer: accentColor.withOpacity(0.1),
      secondary: AppColors.brandGreen,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: _buildTextTheme(AppColors.lightOnSurface),
      cardTheme: _buildCardTheme(AppColors.lightSurface),
      appBarTheme: _buildAppBarTheme(
        AppColors.lightSurface,
        AppColors.lightOnSurface,
      ),
      bottomNavigationBarTheme: _buildBottomNavTheme(
        AppColors.lightSurface,
        accentColor,
        AppColors.lightOnSurfaceVariant,
      ),
      inputDecorationTheme: _buildInputTheme(accentColor),
      elevatedButtonTheme: _buildElevatedButtonTheme(accentColor),
      textButtonTheme: _buildTextButtonTheme(accentColor),
      outlinedButtonTheme: _buildOutlinedButtonTheme(accentColor),
      chipTheme: _buildChipTheme(accentColor),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightOnSurfaceVariant),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────

  static ThemeData dark(Color accentColor) {
    final colorScheme = ColorScheme.dark(
      primary: accentColor,
      onPrimary: Colors.white,
      primaryContainer: accentColor.withOpacity(0.2),
      secondary: AppColors.brandGreen,
      onSecondary: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(AppColors.darkOnSurface),
      cardTheme: _buildCardTheme(AppColors.darkSurface),
      appBarTheme: _buildAppBarTheme(
        AppColors.darkSurface,
        AppColors.darkOnSurface,
      ),
      bottomNavigationBarTheme: _buildBottomNavTheme(
        AppColors.darkSurface,
        accentColor,
        AppColors.darkOnSurfaceVariant,
      ),
      inputDecorationTheme: _buildInputTheme(accentColor),
      elevatedButtonTheme: _buildElevatedButtonTheme(accentColor),
      textButtonTheme: _buildTextButtonTheme(accentColor),
      outlinedButtonTheme: _buildOutlinedButtonTheme(accentColor),
      chipTheme: _buildChipTheme(accentColor),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkOnSurfaceVariant),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  // ── Blue Theme ────────────────────────────────────────────

  static ThemeData blue() {
    const primaryBlue = Color(0xFF1E40AF);
    const bgBlue = Color(0xFFF0F4FF);
    const surfaceBlue = Color(0xFFFFFFFF);
    const onSurface = Color(0xFF0F172A);

    final colorScheme = ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDBEAFE),
      secondary: const Color(0xFF0369A1),
      surface: surfaceBlue,
      onSurface: onSurface,
      surfaceContainerHighest: const Color(0xFFE0EAFF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgBlue,
      textTheme: _buildTextTheme(onSurface),
      cardTheme: _buildCardTheme(surfaceBlue),
      appBarTheme: _buildAppBarTheme(surfaceBlue, onSurface),
      bottomNavigationBarTheme: _buildBottomNavTheme(
        surfaceBlue,
        primaryBlue,
        const Color(0xFF64748B),
      ),
      inputDecorationTheme: _buildInputTheme(primaryBlue),
      elevatedButtonTheme: _buildElevatedButtonTheme(primaryBlue),
      textButtonTheme: _buildTextButtonTheme(primaryBlue),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primaryBlue),
      chipTheme: _buildChipTheme(primaryBlue),
    );
  }

  // ── Pink Theme ────────────────────────────────────────────

  static ThemeData pink() {
    const primaryPink = Color(0xFFBE185D);
    const bgPink = Color(0xFFFFF0F6);
    const surfacePink = Color(0xFFFFFFFF);
    const onSurface = Color(0xFF0F172A);

    final colorScheme = ColorScheme.light(
      primary: primaryPink,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFE4EF),
      secondary: const Color(0xFF9D174D),
      surface: surfacePink,
      onSurface: onSurface,
      surfaceContainerHighest: const Color(0xFFFFD6E8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgPink,
      textTheme: _buildTextTheme(onSurface),
      cardTheme: _buildCardTheme(surfacePink),
      appBarTheme: _buildAppBarTheme(surfacePink, onSurface),
      bottomNavigationBarTheme: _buildBottomNavTheme(
        surfacePink,
        primaryPink,
        const Color(0xFF64748B),
      ),
      inputDecorationTheme: _buildInputTheme(primaryPink),
      elevatedButtonTheme: _buildElevatedButtonTheme(primaryPink),
      textButtonTheme: _buildTextButtonTheme(primaryPink),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primaryPink),
      chipTheme: _buildChipTheme(primaryPink),
    );
  }

  // ── Private Builders ──────────────────────────────────────

  static TextTheme _buildTextTheme(Color onSurface) {
    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onSurface.withOpacity(0.7),
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurface.withOpacity(0.7),
      ),
    );
  }

  static CardTheme _buildCardTheme(Color surface) {
    return CardTheme(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static AppBarTheme _buildAppBarTheme(Color surface, Color onSurface) {
    return AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(
    Color surface,
    Color selected,
    Color unselected,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: selected,
      unselectedItemColor: unselected,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(Color accent) {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      isDense: true,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color accent) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        textStyle: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(Color accent) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color accent) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        textStyle: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ChipThemeData _buildChipTheme(Color accent) {
    return ChipThemeData(
      backgroundColor: accent.withOpacity(0.1),
      labelStyle: GoogleFonts.cairo(fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
