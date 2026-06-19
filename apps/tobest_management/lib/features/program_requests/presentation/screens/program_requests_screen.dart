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

