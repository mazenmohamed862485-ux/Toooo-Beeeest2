// ============================================================
  // TO Best — features/home/presentation/screens/home_screen.dart
  // ============================================================

  import 'package:flutter/material.dart';
  import 'package:hooks_riverpod/hooks_riverpod.dart';
  import 'main_shell_screen.dart';

  /// الشاشة الرئيسية — تُغلّف MainShellScreen
  class HomeScreen extends ConsumerWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return const MainShellScreen();
    }
  }
  