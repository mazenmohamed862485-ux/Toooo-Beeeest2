// ============================================================
// TO Best — workout_screen.dart
// شاشة التمرين الرئيسية
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import '../providers/workout_provider.dart';
import '../widgets/exercise_card.dart';
import '../widgets/warmup_section.dart';
import '../widgets/workout_completion_sheet.dart';
import '../widgets/rest_timer_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// شاشة التمرين الرئيسية
class WorkoutScreen extends HookConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final todayAsync = ref.watch(todayWorkoutProvider);
    final activeSession = ref.watch(activeWorkoutSessionProvider);
    final restTimerVisible = useState(false);
    final restSeconds = useState(120);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: todayAsync.when(
        loading: () => const Center(
          child: BreathingAnimation(
            type: BreathingAnimationType.compact,
            color: AppColors.brandGreen,
          ),
        ),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (today) {
          if (today == null || user == null) {
            return const Center(child: Text('جاري التحميل...'));
          }

          // يوم راحة
          if (today.isRestDay) {
            return _RestDayView(isDark: isDark);
          }

          // إذا لا توجد جلسة نشطة
          if (activeSession == null) {
            return _PreWorkoutView(
              today: today,
              user: user,
              isDark: isDark,
            );
          }

          // جلسة نشطة
          return _ActiveWorkoutView(
            session: activeSession,
            isDark: isDark,
            onRequestRestTimer: (seconds) {
              restSeconds.value = seconds;
              restTimerVisible.value = true;
            },
          );
        },
      ),

      // ── Rest Timer Overlay ────────────────────────────────
      bottomSheet: restTimerVisible.value
          ? RestTimerOverlay(
              seconds: restSeconds.value,
              onSkip: () => restTimerVisible.value = false,
              onComplete: () => restTimerVisible.value = false,
            )
          : null,
    );
  }
}

// ── Pre-Workout View ──────────────────────────────────────────

class _PreWorkoutView extends ConsumerWidget {
  const _PreWorkoutView({
    required this.today,
    required this.user,
    required this.isDark,
  });

  final TodayWorkout today;
  final dynamic user;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);

    return CustomScrollView(
      slivers: [
        // ── App Bar ─────────────────────────────────────────
        SliverAppBar(
          floating: true,
          title: Column(
            children: [
              Text(
                today.sessionName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'اليوم',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            // Streak Badge
            streakAsync.when(
              data: (streak) => streak > 0
                  ? _StreakBadge(days: streak)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // ── قسم الإحماء ─────────────────────────────────────
        if (today.warmups.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: WarmupSection(
                warmups: today.warmups,
                onWarmupDone: (_, __) {}, // قبل بدء الجلسة — عرض فقط
              ),
            ),
          ),

        // ── نظرة عامة على التمارين ───────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.builder(
            itemCount: today.exercises.length,
            itemBuilder: (ctx, i) {
              final ex = today.exercises[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ExercisePreviewCard(
                  exercise: ex,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Active Workout View ───────────────────────────────────────

class _ActiveWorkoutView extends ConsumerWidget {
  const _ActiveWorkoutView({
    required this.session,
    required this.isDark,
    required this.onRequestRestTimer,
  });

  final WorkoutSessionState session;
  final bool isDark;
  final void Function(int seconds) onRequestRestTimer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Column(
      children: [
        // ── AppBar ───────────────────────────────────────────
        AppBar(
          title: Text(session.sessionName),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmCancel(context, ref),
          ),
          actions: [
            TextButton(
              onPressed: () => _finishWorkout(context, ref),
              child: Text(
                'إنهاء',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // ── قائمة التمارين ────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: session.exercises.length,
            itemBuilder: (ctx, i) {
              final exState = session.exercises[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ExerciseCard(
                  exerciseIndex: i,
                  exerciseState: exState,
                  userId: user?.uid ?? '',
                  onSetLogged: (weight, reps, rpe, rir) {
                    ref
                        .read(activeWorkoutSessionProvider.notifier)
                        .logSet(
                          exerciseIndex: i,
                          weight: weight,
                          reps: reps,
                          rpe: rpe,
                          rir: rir,
                        );

                    // تشغيل Rest Timer تلقائياً
                    final restRange = exState.definition.rest;
                    final defaultRest = _parseRestSeconds(restRange);
                    onRequestRestTimer(defaultRest);
                  },
                  onSetEdited: (setIdx, weight, reps, rpe, rir) {
                    ref
                        .read(activeWorkoutSessionProvider.notifier)
                        .editSet(
                          exerciseIndex: i,
                          setIndex: setIdx,
                          weight: weight,
                          reps: reps,
                          rpe: rpe,
                          rir: rir,
                        );
                  },
                  onSetDeleted: (setIdx) {
                    ref
                        .read(activeWorkoutSessionProvider.notifier)
                        .deleteSet(
                          exerciseIndex: i,
                          setIndex: setIdx,
                        );
                  },
                  onAlternativeSelected: (alt) {
                    ref
                        .read(activeWorkoutSessionProvider.notifier)
                        .useAlternative(
                          exerciseIndex: i,
                          alternative: alt,
                        );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  int _parseRestSeconds(String restRange) {
    // نطاق مثل "2~3" — نأخذ الوسط
    final parts = restRange.split('~');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0]) ?? 2;
      final max = int.tryParse(parts[1]) ?? 3;
      return ((min + max) / 2 * 60).round();
    }
    final mins = int.tryParse(parts[0]) ?? 2;
    return mins * 60;
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الجلسة؟'),
        content: const Text('لن يتم حفظ البيانات إذا ألغيت الجلسة'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('استمر'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(activeWorkoutSessionProvider.notifier).cancelSession();
    }
  }

  Future<void> _finishWorkout(BuildContext context, WidgetRef ref) async {
    // عرض ملخص قبل الإنهاء
    final shouldFinish = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkoutCompletionSheet(session: session),
    );

    if (shouldFinish == true) {
      await ref.read(activeWorkoutSessionProvider.notifier).finishSession();
    }
  }
}

// ── Rest Day View ─────────────────────────────────────────────

class _RestDayView extends StatelessWidget {
  const _RestDayView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BreathingAnimation(
            type: BreathingAnimationType.full,
            color: AppColors.brandGreen,
            showText: true,
          ),
          const SizedBox(height: 32),
          Text(
            'يوم الراحة 💤',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'جسمك يتعافى ويبني العضلات الآن\nاستمتع بيومك',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.brandGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.brandGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePreviewCard extends StatelessWidget {
  const _ExercisePreviewCard({
    required this.exercise,
    required this.isDark,
  });

  final dynamic exercise; // ExerciseDefinition
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Primary/Secondary indicator
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: exercise.isPrimary
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.sets} × ${exercise.reps} | ${exercise.muscle}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل التمرين',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
