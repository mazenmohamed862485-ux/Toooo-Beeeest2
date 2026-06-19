// ============================================================
// subscription_plans_screen.dart (standalone)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';

part 'subscription_plans_screen.g.dart';

// ── Plans Provider ─────────────────────────────────────────────

class PlanData {
  const PlanData({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    required this.durationMonths,
    required this.features,
    required this.isActive,
  });
  final String id, nameAr, nameEn;
  final double price;
  final int durationMonths;
  final List<String> features;
  final bool isActive;
}

@riverpod
Future<List<PlanData>> subscriptionPlans(SubscriptionPlansRef ref) async {
  final admin = ref.watch(mgmtAuthStateProvider).valueOrNull;
  if (admin == null) return [];

  final gas = ref.read(mgmtGasClientProvider);
  final result = await gas.post(
    action: 'GET_PLANS',
    data: {'uid': admin.uid},
  );

  final list = result['plans'] as List<dynamic>? ?? [];
  return list.map((p) {
    final m = p as Map<String, dynamic>;
    return PlanData(
      id: m['id']?.toString() ?? '',
      nameAr: m['nameAr']?.toString() ?? '',
      nameEn: m['nameEn']?.toString() ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0,
      durationMonths:
          int.tryParse(m['duration']?.toString() ?? '1') ?? 1,
      features: (m['features'] as List<dynamic>? ?? [])
          .map((f) => f.toString())
          .toList(),
      isActive: m['isActive'] == true || m['isActive'] == 'true',
    );
  }).toList();
}

// ── Screen ─────────────────────────────────────────────────────

class SubscriptionPlansScreen extends HookConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('خطط الاشتراك'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(subscriptionPlansProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('خطة جديدة'),
        backgroundColor: AppColors.accent2,
      ),
      body: plansAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_outlined,
                      size: 64, color: AppColors.lightBorder),
                  SizedBox(height: 12),
                  Text('لا توجد خطط بعد'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: plans.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PlanCard(
                plan: plans[i],
                isDark: isDark,
                onToggle: (active) =>
                    _togglePlan(ref, plans[i].id, active),
                onEdit: () => _showPlanDialog(
                  context,
                  ref,
                  existingPlan: plans[i],
                ),
                onDelete: () => _deletePlan(context, ref, plans[i].id),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPlanDialog(
    BuildContext context,
    WidgetRef ref, {
    PlanData? existingPlan,
  }) async {
    final nameArCtrl = TextEditingController(
        text: existingPlan?.nameAr ?? '');
    final nameEnCtrl = TextEditingController(
        text: existingPlan?.nameEn ?? '');
    final priceCtrl = TextEditingController(
        text: existingPlan?.price.toString() ?? '');
    final durationCtrl = TextEditingController(
        text: existingPlan?.durationMonths.toString() ?? '1');
    final featuresCtrl = TextEditingController(
        text: existingPlan?.features.join('\n') ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existingPlan == null ? 'خطة جديدة' : 'تعديل الخطة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameArCtrl,
                decoration: const InputDecoration(labelText: 'الاسم بالعربي *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameEnCtrl,
                decoration: const InputDecoration(labelText: 'الاسم بالإنجليزي'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'السعر (ر.س) *',
                    suffixText: 'ر.س'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'المدة (أشهر) *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: featuresCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'المميزات (سطر لكل ميزة)',
                  alignLabelWithHint: true,
                  hintText: 'وصول كامل للبرامج\nشات مع المدرب\n...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ')),
        ],
      ),
    );

    if (confirmed != true) return;

    final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
    final features = featuresCtrl.text
        .split('\n')
        .where((f) => f.trim().isNotEmpty)
        .toList();

    await ref.read(mgmtGasClientProvider).post(
      action: existingPlan == null ? 'ADD_PLAN' : 'UPDATE_PLAN',
      data: {
        'uid': admin?.uid ?? '',
        if (existingPlan != null) 'planId': existingPlan.id,
        'nameAr': nameArCtrl.text.trim(),
        'nameEn': nameEnCtrl.text.trim(),
        'price': double.tryParse(priceCtrl.text) ?? 0,
        'duration': int.tryParse(durationCtrl.text) ?? 1,
        'features': features,
      },
    );

    ref.invalidate(subscriptionPlansProvider);
  }

  Future<void> _togglePlan(
      WidgetRef ref, String planId, bool active) async {
    final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
    await ref.read(mgmtGasClientProvider).post(
      action: 'TOGGLE_PLAN',
      data: {
        'uid': admin?.uid ?? '',
        'planId': planId,
        'isActive': active,
      },
    );
    ref.invalidate(subscriptionPlansProvider);
  }

  Future<void> _deletePlan(
      BuildContext context, WidgetRef ref, String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الخطة؟'),
        content: const Text(
            'سيتم حذف هذه الخطة نهائياً. الاشتراكات الحالية لن تتأثر.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;

    final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
    await ref.read(mgmtGasClientProvider).post(
      action: 'DELETE_PLAN',
      data: {'uid': admin?.uid ?? '', 'planId': planId},
    );
    ref.invalidate(subscriptionPlansProvider);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final PlanData plan;
  final bool isDark;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: plan.isActive
              ? AppColors.accent2.withOpacity(0.4)
              : AppColors.lightBorder,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.nameAr,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (plan.nameEn.isNotEmpty)
                        Text(plan.nameEn,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${plan.price.toStringAsFixed(0)} ر.س',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent2,
                      ),
                    ),
                    Text('${plan.durationMonths} شهر',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),

          // Features
          if (plan.features.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: plan.features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )).toList(),
              ),
            ),
          ],

          // Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                // Toggle Active
                Row(
                  children: [
                    Switch(
                      value: plan.isActive,
                      onChanged: onToggle,
                      activeColor: AppColors.success,
                    ),
                    Text(
                      plan.isActive ? 'مفعّلة' : 'معطّلة',
                      style: TextStyle(
                        fontSize: 12,
                        color: plan.isActive
                            ? AppColors.success
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  color: AppColors.info,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20),
                  onPressed: onDelete,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
