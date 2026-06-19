// ============================================================
// program_requests_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/domain/entities/workout_session.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';

part 'program_requests_screen.g.dart';

@riverpod
Future<List<ProgramChangeRequest>> programRequests(
    ProgramRequestsRef ref) async {
  final admin = ref.watch(mgmtAuthStateProvider).valueOrNull;
  if (admin == null) return [];

  final gas = ref.read(mgmtGasClientProvider);
  final result = await gas.post(
    action: 'GET_PROGRAM_REQUESTS',
    data: {'uid': admin.uid},
  );

  final list = result['requests'] as List<dynamic>? ?? [];
  return list.map((r) {
    final m = r as Map<String, dynamic>;
    return ProgramChangeRequest(
      id: m['id']?.toString() ?? '',
      userId: m['userId']?.toString() ?? '',
      userName: m['userName']?.toString() ?? '',
      requestType: m['requestType']?.toString() ?? 'change',
      requestedProgram: m['requestedProgram']?.toString() ?? '',
      reason: m['reason']?.toString() ?? '',
      status: m['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      responseNote: m['responseNote']?.toString() ?? '',
    );
  }).where((r) => r.id.isNotEmpty).toList();
}

class ProgramRequestsScreen extends ConsumerWidget {
  const ProgramRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(programRequestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات البرامج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(programRequestsProvider),
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (requests) {
          final pending = requests.where((r) => r.status == 'pending').toList();
          final others = requests.where((r) => r.status != 'pending').toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(programRequestsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (pending.isNotEmpty) ...[
                  Text('معلقة (${pending.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          )),
                  const SizedBox(height: 8),
                  ...pending.map((r) => _ProgramRequestCard(
                        request: r,
                        isDark: isDark,
                        onApprove: () =>
                            _respond(context, ref, r, true),
                        onReject: () =>
                            _respond(context, ref, r, false),
                      )),
                  const SizedBox(height: 16),
                ],
                if (others.isNotEmpty) ...[
                  Text('السابقة',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...others.map((r) => _ProgramRequestCard(
                        request: r,
                        isDark: isDark,
                      )),
                ],
                if (requests.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('لا توجد طلبات'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _respond(BuildContext ctx, WidgetRef ref,
      ProgramChangeRequest request, bool approve) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(approve ? 'الموافقة على الطلب' : 'رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${request.userName}: ${request.requestedProgram}'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختيارية)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: approve ? AppColors.success : AppColors.error),
            child: Text(approve ? 'موافقة' : 'رفض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
    await ref.read(mgmtGasClientProvider).post(
      action: 'RESPOND_PROGRAM_REQUEST',
      data: {
        'requestId': request.id,
        'approved': approve,
        'note': noteCtrl.text.trim(),
        'processedBy': admin?.uid ?? '',
      },
    );
    ref.invalidate(programRequestsProvider);
  }
}

class _ProgramRequestCard extends StatelessWidget {
  const _ProgramRequestCard({
    required this.request,
    required this.isDark,
    this.onApprove,
    this.onReject,
  });
  final ProgramChangeRequest request;
  final bool isDark;
  final VoidCallback? onApprove, onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(request.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99)),
                child: Text(
                  _statusAr(request.status),
                  style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'البرنامج المطلوب: ${request.requestedProgram}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text('السبب: ${request.reason}',
              style: const TextStyle(fontSize: 13)),
          Text(
            DateFormat('dd/MM/yyyy').format(request.createdAt),
            style: const TextStyle(
                fontSize: 11, color: AppColors.lightOnSurfaceVariant),
          ),
          if (request.responseNote.isNotEmpty)
            Text('ملاحظة: ${request.responseNote}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.info)),
          if (onApprove != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error)),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                    child: const Text('موافقة'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusAr(String s) => switch (s) {
        'approved' => 'موافق',
        'rejected' => 'مرفوض',
        _ => 'معلق',
      };
}

// ============================================================
// subscription_plans_screen.dart
// ============================================================

class SubscriptionPlansScreen extends HookConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطط الاشتراك')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlanDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('خطة جديدة'),
      ),
      body: const _PlansList(),
    );
  }

  Future<void> _showAddPlanDialog(
      BuildContext ctx, WidgetRef ref) async {
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '1');

    await showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('إضافة خطة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameArCtrl,
                decoration: const InputDecoration(labelText: 'الاسم عربي')),
            TextField(
                controller: nameEnCtrl,
                decoration: const InputDecoration(labelText: 'الاسم إنجليزي')),
            TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر (ر.س)')),
            TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المدة (أشهر)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
              await ref.read(mgmtGasClientProvider).post(
                action: 'ADD_PLAN',
                data: {
                  'uid': admin?.uid,
                  'nameAr': nameArCtrl.text.trim(),
                  'nameEn': nameEnCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'duration': int.tryParse(durationCtrl.text) ?? 1,
                },
              );
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _PlansList extends ConsumerWidget {
  const _PlansList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // بيانات مباشرة من GAS — لا يوجد Isar cache للخطط
    return FutureBuilder(
      future: _loadPlans(ref),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final plans = snapshot.data ?? [];
        if (plans.isEmpty) {
          return const Center(child: Text('لا توجد خطط'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: plans.length,
          itemBuilder: (c, i) {
            final p = plans[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.card_membership_rounded,
                    color: AppColors.accent2),
                title: Text(p['nameAr']?.toString() ?? ''),
                subtitle: Text(
                    '${p['price']} ر.س · ${p['duration']} شهر'),
                trailing: Switch(
                  value: p['isActive'] == true,
                  onChanged: (val) {
                    // تفعيل/تعطيل الخطة
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadPlans(WidgetRef ref) async {
    final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
    if (admin == null) return [];
    final result = await ref.read(mgmtGasClientProvider).post(
      action: 'GET_PLANS',
      data: {'uid': admin.uid},
    );
    return (result['plans'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }
}

// ============================================================
// referral_stats_screen.dart
// ============================================================

class ReferralStatsScreen extends ConsumerWidget {
  const ReferralStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات الإحالة')),
      body: FutureBuilder(
        future: _loadStats(ref),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data as Map<String, dynamic>? ?? {};
          final topReferrers =
              data['topReferrers'] as List<dynamic>? ?? [];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // إجماليات
              Row(
                children: [
                  _ReferralStat(
                    label: 'إجمالي الإحالات',
                    value: '${data['totalReferrals'] ?? 0}',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _ReferralStat(
                    label: 'إحالات هذا الشهر',
                    value: '${data['monthlyReferrals'] ?? 0}',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('أكثر المحيلين',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 8),
              ...topReferrers.asMap().entries.map((e) {
                final r = e.value as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.brandGreen.withOpacity(0.15),
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandGreen)),
                  ),
                  title: Text(r['name']?.toString() ?? ''),
                  subtitle: Text(r['code']?.toString() ?? ''),
                  trailing: Text(
                    '${r['count']} إحالة',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandGreen),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStats(WidgetRef ref) async {
    final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
    if (admin == null) return {};
    return ref.read(mgmtGasClientProvider).post(
      action: 'GET_REFERRAL_STATS',
      data: {'uid': admin.uid},
    );
  }
}

class _ReferralStat extends StatelessWidget {
  const _ReferralStat(
      {required this.label, required this.value, required this.isDark});
  final String label, value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGreen,
                    )),
            Text(label, style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// mgmt_chat_screen.dart — شاشة الشات الإداري
// ============================================================

class MgmtChatScreen extends ConsumerWidget {
  const MgmtChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('الشات')),
      body: FutureBuilder(
        future: _loadRooms(ref, admin?.uid ?? ''),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) {
            return const Center(child: Text('لا توجد محادثات'));
          }
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (c, i) {
              final r = rooms[i] as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (r['otherName']?.toString() ?? '?')[0].toUpperCase(),
                  ),
                ),
                title: Text(r['otherName']?.toString() ?? ''),
                subtitle: Text(
                  r['lastMessage']?.toString() ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: r['unread'] != null && (r['unread'] as int) > 0
                    ? Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${r['unread']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : null,
                onTap: () => context.push(
                  '/chat/room/${r['id']}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _loadRooms(WidgetRef ref, String uid) async {
    if (uid.isEmpty) return [];
    final result = await ref.read(mgmtGasClientProvider).post(
      action: 'GET_ROOMS',
      data: {'uid': uid},
    );
    return result['rooms'] as List<dynamic>? ?? [];
  }
}
