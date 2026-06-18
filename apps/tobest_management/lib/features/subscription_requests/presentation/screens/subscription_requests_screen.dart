// ============================================================
// TO Best Management — subscription_requests_screen.dart
// عرض طلبات الاشتراك مع الموافقة/الرفض + صورة الإيصال
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/health_data.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_requests_provider.dart';

class SubscriptionRequestsScreen extends HookConsumerWidget {
  const SubscriptionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = useState('pending');
    final requestsAsync =
        ref.watch(subscriptionRequestsProvider(statusFilter.value));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الاشتراك'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 6),
            child: Row(
              children: [
                _FilterChip(
                  label: 'معلقة',
                  selected: statusFilter.value == 'pending',
                  onTap: () => statusFilter.value = 'pending',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'موافق عليها',
                  selected: statusFilter.value == 'approved',
                  onTap: () => statusFilter.value = 'approved',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'مرفوضة',
                  selected: statusFilter.value == 'rejected',
                  onTap: () => statusFilter.value = 'rejected',
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_rounded,
                      size: 64, color: AppColors.lightBorder),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات ${_statusLabel(statusFilter.value)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(subscriptionRequestsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: requests.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _RequestCard(
                  request: requests[i],
                  isDark: isDark,
                  onApprove: statusFilter.value == 'pending'
                      ? () => _showApproveDialog(ctx, ref, requests[i])
                      : null,
                  onReject: statusFilter.value == 'pending'
                      ? () => _showRejectDialog(ctx, ref, requests[i])
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    SubscriptionRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الموافقة على الاشتراك'),
        content: Text(
          'هل تريد الموافقة على اشتراك ${request.planName} '
          'لـ ${request.userName}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(subscriptionActionsProvider.notifier)
          .approve(request.id);
      ref.invalidate(subscriptionRequestsProvider);
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    SubscriptionRequest request,
  ) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الاشتراك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رفض طلب ${request.userName}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                hintText: 'أخبر المستخدم بسبب الرفض...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref
          .read(subscriptionActionsProvider.notifier)
          .reject(request.id, result);
      ref.invalidate(subscriptionRequestsProvider);
    }
  }

  String _statusLabel(String s) => switch (s) {
        'pending' => 'معلقة',
        'approved' => 'موافق عليها',
        'rejected' => 'مرفوضة',
        _ => s,
      };
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isDark,
    this.onApprove,
    this.onReject,
  });

  final SubscriptionRequest request;
  final bool isDark;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.15),
                  child: Text(
                    request.userName.isNotEmpty
                        ? request.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        request.userEmail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    _statusLabel(request.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _DetailRow('الخطة', request.planName),
                _DetailRow('السعر',
                    '${request.price.toStringAsFixed(0)} ر.س'),
                _DetailRow('المدة', '${request.duration} شهر'),
                _DetailRow(
                  'تاريخ الطلب',
                  DateFormat('dd/MM/yyyy – hh:mm a')
                      .format(request.createdAt),
                ),
                if (request.rejectionReason.isNotEmpty)
                  _DetailRow('سبب الرفض', request.rejectionReason,
                      valueColor: AppColors.error),
              ],
            ),
          ),

          // Payment Proof
          if (request.paymentProofUrl.isNotEmpty) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () {
                // عرض الإيصال
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Image.network(
                      request.paymentProofUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('تعذر تحميل الإيصال'),
                      ),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'عرض إيصال الدفع',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Actions
          if (onApprove != null || onReject != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('رفض'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  if (onReject != null && onApprove != null)
                    const SizedBox(width: 12),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('موافقة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'approved' => 'موافق عليه',
        'rejected' => 'مرفوض',
        _ => 'معلق',
      };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? color : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : null,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
