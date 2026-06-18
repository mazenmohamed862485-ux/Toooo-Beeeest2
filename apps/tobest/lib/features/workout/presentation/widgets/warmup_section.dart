// ============================================================
// TO Best — workout/widgets/warmup_section.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/workout_session.dart';

/// قسم تمارين الإحماء
class WarmupSection extends StatelessWidget {
  const WarmupSection({
    super.key,
    required this.warmups,
    required this.onWarmupDone,
  });

  final List<WarmupLog> warmups;
  final void Function(int index, bool done) onWarmupDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.brandGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.self_improvement_rounded,
                  size: 18,
                  color: AppColors.brandGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'إحماء',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${warmups.where((w) => w.isDone).length}/${warmups.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── قائمة الإحماء ─────────────────────────────────
          ...warmups.asMap().entries.map((e) {
            final idx = e.key;
            final w = e.value;
            return InkWell(
              onTap: () => onWarmupDone(idx, !w.isDone),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: w.isDone
                            ? AppColors.brandGreen
                            : Colors.transparent,
                        border: Border.all(
                          color: w.isDone
                              ? AppColors.brandGreen
                              : AppColors.lightBorder,
                          width: 2,
                        ),
                      ),
                      child: w.isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: w.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: w.isDone
                                  ? (isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.lightOnSurfaceVariant)
                                  : null,
                            ),
                      ),
                    ),
                    Text(
                      w.reps,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
