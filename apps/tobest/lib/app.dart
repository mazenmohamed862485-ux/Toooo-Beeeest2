// ============================================================
// TO Best — apps/tobest/lib/app.dart
// Root Widget: Theme + Locale + Router
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/themes.dart';
import 'router.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

/// Root Widget لتطبيق TO Best
class TobestApp extends ConsumerWidget {
  const TobestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // استماع لإعدادات الثيم واللغة
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      // ── معلومات التطبيق ─────────────────────────────────
      title: 'TO Best',
      debugShowCheckedModeBanner: false,

      // ── Router ───────────────────────────────────────────
      routerConfig: appRouter(ref),

      // ── الثيم ────────────────────────────────────────────
      themeMode: AppThemes.themeMode(settings.theme),
      theme: _buildLightTheme(settings),
      darkTheme: _buildDarkTheme(settings),

      // ── اللغة والاتجاه ───────────────────────────────────
      locale: settings.locale,
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        // AppLocalizations.delegate, — يضاف عند بناء L10n
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],

      // ── الاتجاه الافتراضي (RTL للعربي) ───────────────────
      builder: (context, child) {
        return Directionality(
          textDirection: settings.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }

  ThemeData _buildLightTheme(AppSettings settings) {
    return switch (settings.theme) {
      AppTheme.blue => AppThemes.blue(),
      AppTheme.pink => AppThemes.pink(),
      _ => AppThemes.light(settings.accentColor),
    };
  }

  ThemeData _buildDarkTheme(AppSettings settings) {
    return AppThemes.dark(settings.accentColor);
  }
}
