// ============================================================
// TO Best Management — mgmt_splash_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:shared/config/app_config.dart';
import '../providers/mgmt_auth_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MgmtSplashScreen extends ConsumerStatefulWidget {
  const MgmtSplashScreen({super.key});

  @override
  ConsumerState<MgmtSplashScreen> createState() => _MgmtSplashScreenState();
}

class _MgmtSplashScreenState extends ConsumerState<MgmtSplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    ref.invalidate(mgmtAuthStateProvider);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    context.go(AppRoutes.mgmtDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/tom_icon_light.png',
              width: 100,
              height: 100,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.admin_panel_settings_rounded,
                size: 80,
                color: AppColors.accent2,
              ),
            ),
            const SizedBox(height: 24),
            const BreathingAnimation(
              type: BreathingAnimationType.compact,
              color: AppColors.accent2,
              showText: false,
            ),
            const SizedBox(height: 20),
            const Text(
              'TO Best Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'لوحة التحكم الإدارية',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

