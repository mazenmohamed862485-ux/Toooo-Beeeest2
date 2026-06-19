// ============================================================
// subscription_requests_provider.dart
// ============================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/domain/entities/health_data.dart';
import 'package:shared/infrastructure/notification_service.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';

part 'subscription_requests_provider.g.dart';

@riverpod
Future<List<SubscriptionRequest>> subscriptionRequests(
  SubscriptionRequestsRef ref,
  String status,
) async {
  final user = ref.watch(mgmtAuthStateProvider).valueOrNull;
  if (user == null) return [];

  final gasClient = ref.read(mgmtGasClientProvider);
  final result = await gasClient.post(
    action: 'GET_SUBSCRIPTION_REQUESTS',
    data: {'uid': user.uid, 'status': status},
  );

  final list = result['requests'] as List<dynamic>? ?? [];
  return list
      .map((r) =>
          _requestFromJson(r as Map<String, dynamic>))
      .where((r) => r.id.isNotEmpty)
      .toList();
}

SubscriptionRequest _requestFromJson(Map<String, dynamic> json) {
  DateTime? parseDate(dynamic val) {
    if (val == null) return null;
    try {
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }

  return SubscriptionRequest(
    id: json['id']?.toString() ?? '',
    userId: json['userId']?.toString() ?? '',
    userName: json['userName']?.toString() ?? '',
    userEmail: json['userEmail']?.toString() ?? '',
    planType: json['planType']?.toString() ?? '',
    planName: json['planName']?.toString() ?? '',
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    duration: int.tryParse(json['duration']?.toString() ?? '1') ?? 1,
    status: json['status']?.toString() ?? 'pending',
    createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    paymentProofUrl: json['paymentProofUrl']?.toString() ?? '',
    rejectionReason: json['rejectionReason']?.toString() ?? '',
    approvedAt: parseDate(json['approvedAt']),
    processedBy: json['processedBy']?.toString() ?? '',
  );
}

@riverpod
class SubscriptionActions extends _$SubscriptionActions {
  @override
  void build() {}

  Future<void> approve(String requestId) async {
    final user = ref.read(mgmtAuthStateProvider).valueOrNull;
    if (user == null) return;

    final gasClient = ref.read(mgmtGasClientProvider);
    await gasClient.post(
      action: 'APPROVE_SUBSCRIPTION',
      data: {
        'requestId': requestId,
        'processedBy': user.uid,
        'startDate': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> reject(String requestId, String reason) async {
    final user = ref.read(mgmtAuthStateProvider).valueOrNull;
    if (user == null) return;

    final gasClient = ref.read(mgmtGasClientProvider);
    await gasClient.post(
      action: 'REJECT_SUBSCRIPTION',
      data: {
        'requestId': requestId,
        'reason': reason,
        'processedBy': user.uid,
      },
    );
  }
}
