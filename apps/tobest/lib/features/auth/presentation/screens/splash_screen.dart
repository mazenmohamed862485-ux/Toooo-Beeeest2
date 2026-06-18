// ============================================================
// TO Best — splash_screen.dart
// شاشة البداية: Breathing Animation + تحديد المسار
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/config/app_config.dart';
import '../providers/auth_provider.dart';

/// شاشة البداية
///
/// تعرض Breathing Animation لمدة ثانيتين بينما يتحقق من حالة المصادقة
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // تأخير للـ Animation ثم التوجيه
    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    // الـ GoRouter Redirect يتولى التوجيه تلقائياً
    // نستدعي فقط invalidate لضمان تحميل Auth State
    ref.invalidate(authStateProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── شعار التطبيق ────────────────────────────────
            Image.asset(
              isDark
                  ? 'assets/images/tb_icon_black.png'
                  : 'assets/images/tb_icon_light.png',
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.fitness_center,
                size: 80,
                color: AppColors.brandGreen,
              ),
            ),

            const SizedBox(height: 32),

            // ── Breathing Animation ──────────────────────────
            const BreathingAnimation(
              type: BreathingAnimationType.compact,
              color: AppColors.brandGreen,
              showText: false,
            ),

            const SizedBox(height: 24),

            // ── اسم التطبيق ─────────────────────────────────
            Text(
              'TO Best',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkOnSurface
                    : AppColors.lightOnSurface,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'تدريبك، تغذيتك، تميّزك',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
