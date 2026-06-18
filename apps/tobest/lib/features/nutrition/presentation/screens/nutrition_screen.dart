// ============================================================
// TO Best — nutrition/presentation/screens/nutrition_screen.dart
// شاشة التغذية: Macro Summary + وجبات اليوم + بحث + AI Parse
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/nutrition.dart';
import 'package:shared/utils/evaluator.dart';
import '../providers/nutrition_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class NutritionScreen extends HookConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final summaryAsync = ref.watch(dailyNutritionProvider());
    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');
    final selectedMealType = useState('breakfast');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    useEffect(() {
      void listener() => searchQuery.value = searchCtrl.text;
      searchCtrl.addListener(listener);
      return () => searchCtrl.removeListener(listener);
    }, []);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('تغذيتي'),
            actions: [
              // AI Parse Button
              IconButton(
                icon: const Icon(Icons.auto_awesome_rounded),
                tooltip: 'تحليل وجبة بالنص',
                onPressed: () => _showAiParseSheet(context, ref, user?.uid ?? ''),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (summary) => Column(
                children: [
                  // ── Macro Ring Cards ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _MacroSummaryCard(
                      summary: summary,
                      isDark: isDark,
                      accent: accent,
                    ),
                  ),

                  // ── Meal Type Tabs ────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        _MealTab(
                          label: 'الإفطار',
                          icon: Icons.wb_sunny_outlined,
                          value: 'breakfast',
                          selected: selectedMealType.value,
                          onTap: () =>
                              selectedMealType.value = 'breakfast',
                        ),
                        _MealTab(
                          label: 'الغداء',
                          icon: Icons.restaurant_rounded,
                          value: 'lunch',
                          selected: selectedMealType.value,
                          onTap: () =>
                              selectedMealType.value = 'lunch',
                        ),
                        _MealTab(
                          label: 'العشاء',
                          icon: Icons.nights_stay_outlined,
                          value: 'dinner',
                          selected: selectedMealType.value,
                          onTap: () =>
                              selectedMealType.value = 'dinner',
                        ),
                        _MealTab(
                          label: 'وجبة خفيفة',
                          icon: Icons.cookie_outlined,
                          value: 'snack',
                          selected: selectedMealType.value,
                          onTap: () =>
                              selectedMealType.value = 'snack',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── وجبات اليوم للنوع المحدد ─────────────────
                  ..._buildMealItems(
                    context,
                    ref,
                    summary.meals
                        .where((m) =>
                            m.mealType == selectedMealType.value)
                        .toList(),
                    isDark,
                    user?.uid ?? '',
                  ),

                  // ── Add Food Button ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddFoodSheet(
                        context,
                        ref,
                        selectedMealType.value,
                        user?.uid ?? '',
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة طعام'),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealItems(
    BuildContext context,
    WidgetRef ref,
    List<MealLog> meals,
    bool isDark,
    String userId,
  ) {
    if (meals.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Text(
              'لم تسجّل أي طعام بعد',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
            ),
          ),
        ),
      ];
    }

    return meals.expand((meal) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 2),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                // Meal Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${meal.totalCalories.toStringAsFixed(0)} سعرة'
                          ' • ${meal.totalProtein.toStringAsFixed(1)}g بروتين',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        onPressed: () async {
                          await ref
                              .read(mealActionsProvider.notifier)
                              .deleteMeal(meal.id);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                // Items
                ...meal.items.map((item) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.foodName,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${item.amount.toStringAsFixed(0)}g'
                            ' • ${item.calories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ];
    }).toList();
  }

  void _showAddFoodSheet(
    BuildContext context,
    WidgetRef ref,
    String mealType,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFoodSheet(
        mealType: mealType,
        userId: userId,
        onAdded: () {
          ref.invalidate(dailyNutritionProvider);
        },
      ),
    );
  }

  void _showAiParseSheet(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AiParseSheet(userId: userId),
    );
  }
}

// ── Sub-Widgets ───────────────────────────────────────────────

class _MacroSummaryCard extends StatelessWidget {
  const _MacroSummaryCard({
    required this.summary,
    required this.isDark,
    required this.accent,
  });
  final DailyNutritionSummary summary;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          // Calories Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السعرات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${summary.consumedCalories.toStringAsFixed(0)}'
                ' / ${summary.targetCalories.toStringAsFixed(0)} kcal',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.completionRatio,
              minHeight: 10,
              backgroundColor: AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.completionRatio > 1.05
                    ? AppColors.error
                    : accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Macro breakdown
          Row(
            children: [
              _MacroItem(
                label: 'بروتين',
                consumed: summary.consumedProtein,
                target: summary.targetProtein,
                color: AppColors.info,
                unit: 'g',
              ),
              _MacroItem(
                label: 'كارب',
                consumed: summary.consumedCarbs,
                target: summary.targetCarbs,
                color: AppColors.warning,
                unit: 'g',
              ),
              _MacroItem(
                label: 'دهون',
                consumed: summary.consumedFat,
                target: summary.targetFat,
                color: AppColors.error,
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.unit,
  });
  final String label, unit;
  final double consumed, target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Column(
        children: [
          Text(
            '${consumed.toStringAsFixed(0)}/${ target.toStringAsFixed(0)}$unit',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.lightOnSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MealTab extends StatelessWidget {
  const _MealTab({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label, value, selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? accent : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : null),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFoodSheet extends HookConsumerWidget {
  const _AddFoodSheet({
    required this.mealType,
    required this.userId,
    required this.onAdded,
  });
  final String mealType, userId;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');
    final selectedItems = useState<List<MealItemLog>>([]);
    final amountCtrl = useTextEditingController(text: '100');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchAsync = ref.watch(foodSearchProvider(searchQuery.value));

    useEffect(() {
      void l() => searchQuery.value = searchCtrl.text;
      searchCtrl.addListener(l);
      return () => searchCtrl.removeListener(l);
    }, []);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: AppRadius.bottomSheetRadius,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ابحث عن طعام...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: searchAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (foods) => ListView.builder(
                  controller: scrollCtrl,
                  itemCount: foods.length,
                  itemBuilder: (c, i) {
                    final f = foods[i];
                    return ListTile(
                      title: Text(f.name),
                      subtitle: Text(
                        '${f.calories.toStringAsFixed(0)} kcal / ${f.amount.toStringAsFixed(0)}g',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: AppColors.brandGreen),
                        onPressed: () {
                          final amt = double.tryParse(amountCtrl.text) ?? 100;
                          final adjusted = Evaluator.adjustByAmount(f, amt);
                          selectedItems.value = [
                            ...selectedItems.value,
                            MealItemLog(
                              foodId: f.id,
                              foodName: f.name,
                              amount: amt,
                              calories: adjusted.calories,
                              protein: adjusted.protein,
                              carbs: adjusted.carbs,
                              fat: adjusted.fat,
                              fiber: adjusted.fiber,
                            ),
                          ];
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            if (selectedItems.value.isNotEmpty) ...[
              const Divider(),
              Text(
                '${selectedItems.value.length} عناصر مختارة',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(mealActionsProvider.notifier).addMeal(
                        userId: userId,
                        mealType: mealType,
                        items: selectedItems.value,
                        date: DateTime.now(),
                      );
                  onAdded();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('إضافة الوجبة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiParseSheet extends HookConsumerWidget {
  const _AiParseSheet({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textCtrl = useTextEditingController();
    final result = useState<MealParseResult?>(null);
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: AppRadius.bottomSheetRadius,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('تحليل وجبة بالنص',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 4),
            Text(
              'اكتب مكونات وجبتك وسنحسب السعرات تلقائياً',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'مثال:\n200 جرام أرز\n100 جرام دجاج مشوي\nخضروات',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      isLoading.value = true;
                      result.value =
                          await ref.read(mealActionsProvider.notifier).parseMealText(
                                textCtrl.text,
                                userId,
                              );
                      isLoading.value = false;
                    },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('تحليل'),
            ),
            if (result.value != null) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ParseResult('سعرات',
                      result.value!.calories.toStringAsFixed(0), AppColors.warning),
                  _ParseResult('بروتين',
                      '${result.value!.protein.toStringAsFixed(1)}g', AppColors.info),
                  _ParseResult('كارب',
                      '${result.value!.carbs.toStringAsFixed(1)}g', AppColors.success),
                  _ParseResult('دهون',
                      '${result.value!.fat.toStringAsFixed(1)}g', AppColors.error),
                ],
              ),
              if (result.value!.unmatched.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'لم يتعرف على: ${result.value!.unmatched.join(', ')}',
                  style: const TextStyle(
                      color: AppColors.warning, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () async {
                  final items = result.value!.items.map((f) {
                    return MealItemLog(
                      foodId: f.id,
                      foodName: f.name,
                      amount: f.amount,
                      calories: f.calories,
                      protein: f.protein,
                      carbs: f.carbs,
                      fat: f.fat,
                      fiber: f.fiber,
                    );
                  }).toList();

                  await ref.read(mealActionsProvider.notifier).addMeal(
                        userId: userId,
                        mealType: 'meal',
                        items: items,
                        date: DateTime.now(),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('حفظ الوجبة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParseResult extends StatelessWidget {
  const _ParseResult(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
