// ============================================================
// TO Best Management — lib/main.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/infrastructure/notification_service.dart';
import 'package:shared/infrastructure/background_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await NotificationService().init();
  await BackgroundService().init(enabled: true);

  runApp(const ProviderScope(child: TobestManagementApp()));
}
