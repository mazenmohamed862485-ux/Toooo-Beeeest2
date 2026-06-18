// ============================================================
// TO Best — workout/widgets/exercise_card.dart
// بطاقة التمرين مع تسجيل السيتات والتقييم
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/evaluator.dart';
import '../providers/workout_provider.dart';

/// بطاقة تمرين واحد مع كل سيتاته
class ExerciseCard extends HookConsumerWidget {
  const ExerciseCard({
    super.key,
    required this.exerciseIndex,
    required this.exerciseState,
    required this.userId,
    required this.onSetLogged,
    required this.onSetEdited,
    required this.onSetDeleted,
    required this.onAlternativeSelected,
  });

  final int exerciseIndex;
  final ExerciseState exerciseState;
  final String userId;
  final void Function(double weight, int reps, int? rpe, int? rir) onSetLogged;
  final void Function(int idx, double weight, int reps, int? rpe, int? rir)
      onSetEdited;
  final void Function(int idx) onSetDeleted;
  final void Function(String alt) onAlternativeSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightCtrl = useTextEditingController();
    final repsCtrl = useTextEditingController();
    final isExpanded = useState(exerciseState.definition.isPrimary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    // جلب تقييم التمرين
    final evalAsync = ref.watch(exerciseEvalProvider(
      ExerciseEvalParams(
        userId: userId,
        exerciseName: exerciseState.alternativeUsed.isNotEmpty
            ? exerciseState.alternativeUsed
            : exerciseState.definition.name,
      ),
    ));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: exerciseState.definition.isPrimary
            ? Border.all(color: accent.withOpacity(0.3))
            : Border.all(color: AppColors.lightBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Primary indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: exerciseState.definition.isPrimary
                          ? accent
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exerciseState.alternativeUsed.isNotEmpty
                                    ? exerciseState.alternativeUsed
                                    : exerciseState.definition.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            // Eval Badge
                            evalAsync.when(
                              data: (eval) => eval != null
                                  ? _EvalBadge(eval: eval)
                                  : const SizedBox.shrink(),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${exerciseState.definition.sets} × '
                          '${exerciseState.definition.reps} reps | '
                          '${exerciseState.definition.muscle}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    isExpanded.value
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Alternatives ─────────────────────────────────
          if (isExpanded.value &&
              (exerciseState.definition.alt1.isNotEmpty ||
                  exerciseState.definition.alt2.isNotEmpty)) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 6),
                  Text(
                    'البدائل: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (exerciseState.definition.alt1.isNotEmpty)
                    _AltChip(
                      label: exerciseState.definition.alt1,
                      onTap: () => onAlternativeSelected(
                          exerciseState.definition.alt1),
                      isSelected: exerciseState.alternativeUsed ==
                          exerciseState.definition.alt1,
                    ),
                  const SizedBox(width: 6),
                  if (exerciseState.definition.alt2.isNotEmpty)
                    _AltChip(
                      label: exerciseState.definition.alt2,
                      onTap: () => onAlternativeSelected(
                          exerciseState.definition.alt2),
                      isSelected: exerciseState.alternativeUsed ==
                          exerciseState.definition.alt2,
                    ),
                ],
              ),
            ),
          ],

          // ── Sets List ─────────────────────────────────────
          if (isExpanded.value) ...[
            const Divider(height: 1),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('ست', style: _headerStyle(context)),
                  ),
                  Expanded(
                    child: Text('وزن (kg)', style: _headerStyle(context)),
                  ),
                  Expanded(
                    child: Text('تكرارات', style: _headerStyle(context)),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('تقييم', style: _headerStyle(context)),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            // Existing Sets
            ...exerciseState.sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final repSugg = Evaluator.repSuggestion(s.reps);

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${idx + 1}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${s.weight}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${s.reps}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (repSugg != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              repSugg.type == 'up'
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: repSugg.type == 'up'
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${Evaluator.epley(s.weight, s.reps).toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accent,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.error),
                      onPressed: () => onSetDeleted(idx),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            }),

            // Input Row
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'وزن',
                        isDense: true,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'تكرار',
                        isDense: true,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final w = double.tryParse(weightCtrl.text);
                      final r = int.tryParse(repsCtrl.text);
                      if (w == null || r == null) return;
                      onSetLogged(w, r, null, null);
                      weightCtrl.clear();
                      repsCtrl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(64, 42),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle? _headerStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );
  }
}

// ── Eval Badge ────────────────────────────────────────────────

class _EvalBadge extends StatelessWidget {
  const _EvalBadge({required this.eval});
  final EvalResult eval;

  @override
  Widget build(BuildContext context) {
    final color = _evalColor(eval.code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        eval.arabicLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _evalColor(String code) {
    return switch (code) {
      's1' => AppColors.evalOutstanding,
      's2' => AppColors.evalExcellent,
      's3' => AppColors.evalGreat,
      'rv' => AppColors.evalRestored,
      'gd' => AppColors.evalGood,
      'st' => AppColors.evalStagnant,
      'ws' => AppColors.evalWarning,
      'dn' => AppColors.evalDecline,
      _ => AppColors.evalBeginning,
    };
  }
}

// ── Alternative Chip ──────────────────────────────────────────

class _AltChip extends StatelessWidget {
  const _AltChip({
    required this.label,
    required this.onTap,
    required this.isSelected,
  });
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? accent : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? accent : AppColors.lightOnSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
