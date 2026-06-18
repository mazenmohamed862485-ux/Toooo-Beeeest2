// ============================================================
// TO Best — data/models/subscription_model.dart
// Isar Schema لطلبات الاشتراك
// ============================================================

import 'package:isar/isar.dart';
import '../../domain/entities/health_data.dart'
    show SubscriptionRequest, SubscriptionPlan;

part 'subscription_model.g.dart';

@Collection()
class SubscriptionRequestIsarModel {
  SubscriptionRequestIsarModel({
    required this.requestId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.planType,
    required this.planName,
    required this.price,
    required this.duration,
    required this.status,
    required this.createdAtMs,
    this.paymentProofUrl = '',
    this.rejectionReason = '',
    this.approvedAtMs,
    this.processedBy = '',
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String requestId;

  @Index()
  final String userId;

  final String userName;
  final String userEmail;
  final String planType;
  final String planName;
  final double price;
  final int duration;

  @Index()
  String status;

  @Index()
  final int createdAtMs;

  final String paymentProofUrl;
  String rejectionReason;
  final int? approvedAtMs;
  final String processedBy;

  SubscriptionRequest toEntity() {
    return SubscriptionRequest(
      id: requestId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      planType: planType,
      planName: planName,
      price: price,
      duration: duration,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      paymentProofUrl: paymentProofUrl,
      rejectionReason: rejectionReason,
      approvedAt: approvedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(approvedAtMs!)
          : null,
      processedBy: processedBy,
    );
  }

  factory SubscriptionRequestIsarModel.fromJson(
      Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null || val.toString().isEmpty) return null;
      try {
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    return SubscriptionRequestIsarModel(
      requestId: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      planType: json['planType']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '1') ?? 1,
      status: json['status']?.toString() ?? 'pending',
      createdAtMs: parseDate(json['createdAt'])?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      paymentProofUrl: json['paymentProofUrl']?.toString() ?? '',
      rejectionReason: json['rejectionReason']?.toString() ?? '',
      approvedAtMs: parseDate(json['approvedAt'])?.millisecondsSinceEpoch,
      processedBy: json['processedBy']?.toString() ?? '',
    );
  }
}
