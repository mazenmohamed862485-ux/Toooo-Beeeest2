// TO Best — domain/repositories/subscription_repository.dart

import '../entities/health_data.dart' show SubscriptionPlan, SubscriptionRequest;

abstract class SubscriptionRepository {
  Future<void> submitSubscriptionRequest({
    required String userId,
    required String planType,
    required String paymentProofBase64,
  });

  Future<List<SubscriptionPlan>> getAvailablePlans();

  Future<List<SubscriptionRequest>> getSubscriptionRequests({
    String status,
  });

  Future<void> approveRequest({
    required String requestId,
    required DateTime startDate,
    required String processedBy,
  });

  Future<void> rejectRequest({
    required String requestId,
    required String reason,
    required String processedBy,
  });
}
