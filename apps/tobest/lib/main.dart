// ============================================================
// TO Best — apps/tobest/lib/main.dart
// نقطة دخول التطبيق
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/infrastructure/notification_service.dart';
import 'package:shared/infrastructure/background_service.dart';
import 'app.dart';

/// نقطة دخول TO Best
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── إعداد توجيه الشاشة ──────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── إعداد شريط الحالة ───────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── تهيئة الإشعارات المحلية ──────────────────────────────
  await NotificationService().init();

  // ── تهيئة Background Tasks ───────────────────────────────
  await BackgroundService().init(enabled: true);

  // ── تشغيل التطبيق ────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: TobestApp(),
    ),
  );
}
