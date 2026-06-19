// TO Best — workout/presentation/widgets/workout_completion_sheet.dart
  import 'package:flutter/material.dart';
  import 'package:shared/design/tokens.dart';
  import '../providers/workout_provider.dart';

  class WorkoutCompletionSheet extends StatelessWidget {
    const WorkoutCompletionSheet({super.key, required this.session});
    final WorkoutSessionState session;

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accent = Theme.of(context).colorScheme.primary;
      double totalVolume = 0;
      int totalSets = 0;
      for (final ex in session.exercises) {
        totalSets += ex.sets.length;
        for (final s in ex.sets) { totalVolume += s.weight * s.reps; }
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('أحسنت!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(session.sessionName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accent)),
            const SizedBox(height: 24),
            Row(children: [
              _Stat(label: 'المدة', value: '${duration.inMinutes}', unit: 'دقيقة', icon: Icons.timer_outlined, isDark: isDark),
              const SizedBox(width: 12),
              _Stat(label: 'السيتات', value: '$totalSets', unit: 'ست', icon: Icons.fitness_center_rounded, isDark: isDark),
              const SizedBox(width: 12),
              _Stat(
                label: 'الحجم',
                value: totalVolume >= 1000 ? '${(totalVolume/1000).toStringAsFixed(1)}k' : '${totalVolume.toStringAsFixed(0)}',
                unit: 'kg', icon: Icons.bar_chart_rounded, isDark: isDark,
              ),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('استمر'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: const Text('حفظ وإنهاء'),
              )),
            ]),
          ],
        ),
      );
    }
  }

  class _Stat extends StatelessWidget {
    const _Stat({required this.label, required this.value, required this.unit, required this.icon, required this.isDark});
    final String label, value, unit;
    final IconData icon;
    final bool isDark;
    @override
    Widget build(BuildContext context) {
      return Expanded(child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('$label ($unit)', style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
        ]),
      ));
    }
  }
  