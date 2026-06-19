// ============================================================
// TO Best — workout/widgets/rest_timer_overlay.dart
// Breathing Rest Timer يظهر في أسفل الشاشة بعد كل ست
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:shared/utils/evaluator.dart';
import '../providers/workout_provider.dart';

/// Rest Timer يعمل كـ BottomSheet مع Breathing Animation
class RestTimerOverlay extends StatelessWidget {
  const RestTimerOverlay({
    super.key,
    required this.seconds,
    required this.onSkip,
    required this.onComplete,
  });

  final int seconds;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.bottomSheetRadius,
        boxShadow: AppShadows.lg,
      ),
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.massive,
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'وقت الراحة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          BreathingAnimation(
            type: BreathingAnimationType.restTimer,
            remainingSeconds: seconds,
            color: Theme.of(context).colorScheme.primary,
            onTimerComplete: onComplete,
            onSkip: onSkip,
          ),
        ],
      ),
    );
  }
}
