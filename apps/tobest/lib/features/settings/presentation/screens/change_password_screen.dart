// ============================================================
  // TO Best — features/settings/presentation/screens/change_password_screen.dart
  // ============================================================

  import 'package:flutter/material.dart';
  import 'package:hooks_riverpod/hooks_riverpod.dart';

  /// شاشة تغيير كلمة المرور
  class ChangePasswordScreen extends ConsumerWidget {
    const ChangePasswordScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Scaffold(
        appBar: AppBar(title: const Text('تغيير كلمة المرور')),
        body: const Center(child: Text('قريباً')),
      );
    }
  }
  