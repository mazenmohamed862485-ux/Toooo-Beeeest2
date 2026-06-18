// ============================================================
// TO Best Management — lib/app.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/themes.dart';
import 'package:shared/design/tokens.dart';
import 'router.dart';

class TobestManagementApp extends ConsumerWidget {
  const TobestManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TO Best Management',
      debugShowCheckedModeBanner: false,
      routerConfig: managementRouter(ref),
      // ثيم ثابت للإدارة: داكن احترافي
      themeMode: ThemeMode.dark,
      theme: AppThemes.light(AppColors.accent2),
      darkTheme: AppThemes.dark(AppColors.accent2),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}
