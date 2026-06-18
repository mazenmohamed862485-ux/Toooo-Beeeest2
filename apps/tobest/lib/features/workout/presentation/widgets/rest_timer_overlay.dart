// ============================================================
// TO Best — workout/widgets/rest_timer_overlay.dart
// Breathing Rest Timer يظهر في أسفل الشاشة بعد كل ست
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';

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

// ============================================================
// workout_completion_sheet.dart
// ملخص الجلسة عند الإنهاء
// ============================================================

import 'package:shared/utils/evaluator.dart';
import '../providers/workout_provider.dart';

/// Bottom Sheet ملخص الجلسة عند الإنهاء
class WorkoutCompletionSheet extends StatelessWidget {
  const WorkoutCompletionSheet({super.key, required this.session});
  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    // حساب الإحصائيات
    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;

    for (final ex in session.exercises) {
      totalSets += ex.sets.length;
      for (final s in ex.sets) {
        totalVolume += s.weight * s.reps;
        totalReps += s.reps;
      }
    }

    final duration = DateTime.now().difference(session.startTime);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.bottomSheetRadius,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            '🎉 أحسنت!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            session.sessionName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                ),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          Row(
            children: [
              _StatCard(
                label: 'المدة',
                value: '${duration.inMinutes}',
                unit: 'دقيقة',
                icon: Icons.timer_outlined,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'السيتات',
                value: '$totalSets',
                unit: 'ست',
                icon: Icons.fitness_center_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'الحجم',
                value: totalVolume >= 1000
                    ? '${(totalVolume / 1000).toStringAsFixed(1)}k'
                    : '${totalVolume.toStringAsFixed(0)}',
                unit: 'kg',
                icon: Icons.bar_chart_rounded,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('استمر'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('حفظ وإنهاء'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '$label ($unit)',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
