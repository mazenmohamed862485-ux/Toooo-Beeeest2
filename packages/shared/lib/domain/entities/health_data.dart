// ============================================================
// TO Best — domain/entities/health_data.dart
// كيانات بيانات الصحة في طبقة Domain
// ============================================================

import 'package:equatable/equatable.dart';

/// بيانات الصحة اليومية
class HealthData extends Equatable {
  const HealthData({
    required this.userId,
    required this.date,
    this.steps = 0,
    this.distanceKm = 0,
    this.burnedCalories = 0,
    this.walkingMinutes = 0,
    this.sleep,
    this.updatedAt,
  });

  final String userId;
  final DateTime date;

  /// عدد الخطوات
  final int steps;

  /// المسافة بالكيلومتر
  final double distanceKm;

  /// السعرات المحروقة من المشي
  final double burnedCalories;

  /// دقائق المشي
  final int walkingMinutes;

  /// بيانات النوم
  final SleepData? sleep;

  final DateTime? updatedAt;

  @override
  List<Object?> get props => [userId, date];

  HealthData copyWith({
    String? userId,
    DateTime? date,
    int? steps,
    double? distanceKm,
    double? burnedCalories,
    int? walkingMinutes,
    SleepData? sleep,
    DateTime? updatedAt,
  }) {
    return HealthData(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      burnedCalories: burnedCalories ?? this.burnedCalories,
      walkingMinutes: walkingMinutes ?? this.walkingMinutes,
      sleep: sleep ?? this.sleep,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// بيانات النوم
class SleepData extends Equatable {
  const SleepData({
    required this.durationHours,
    required this.durationMinutes,
    required this.quality,
    this.bedtime,
    this.wakeTime,
  });

  final int durationHours;
  final int durationMinutes;

  /// جودة النوم: poor / fair / good / excellent
  final SleepQuality quality;

  final DateTime? bedtime;
  final DateTime? wakeTime;

  /// إجمالي المدة بالساعات
  double get totalHours => durationHours + durationMinutes / 60;

  /// هل النوم أقل من 6 ساعات (تحذير)
  bool get isInsufficient => totalHours < 6;

  @override
  List<Object?> get props => [durationHours, durationMinutes, quality];
}

/// جودة النوم
enum SleepQuality {
  poor(arabicLabel: 'سيئ', value: 1),
  fair(arabicLabel: 'عادي', value: 2),
  good(arabicLabel: 'جيد', value: 3),
  excellent(arabicLabel: 'ممتاز', value: 4);

  const SleepQuality({required this.arabicLabel, required this.value});

  final String arabicLabel;
  final int value;
}

/// هدف المشي (يومي وأسبوعي)
class WalkingGoal extends Equatable {
  const WalkingGoal({
    this.dailySteps = 8000,
    this.weeklySteps = 50000,
    this.dailyDistanceKm = 5,
    this.weeklyDistanceKm = 30,
  });

  final int dailySteps;
  final int weeklySteps;
  final double dailyDistanceKm;
  final double weeklyDistanceKm;

  @override
  List<Object?> get props => [dailySteps, weeklySteps];
}

// ============================================================
// subscription.dart — كيانات الاشتراكات
// ============================================================

/// طلب اشتراك
class SubscriptionRequest extends Equatable {
  const SubscriptionRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.planType,
    required this.planName,
    required this.price,
    required this.duration,
    required this.status,
    required this.createdAt,
    this.paymentProofUrl = '',
    this.rejectionReason = '',
    this.approvedAt,
    this.startDate,
    this.endDate,
    this.processedBy = '',
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String planType;
  final String planName;
  final double price;

  /// المدة بالأشهر
  final int duration;

  /// pending / approved / rejected
  final String status;

  final DateTime createdAt;
  final String paymentProofUrl;
  final String rejectionReason;
  final DateTime? approvedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String processedBy;

  @override
  List<Object?> get props => [id, userId, status];
}

/// خطة اشتراك ديناميكية
class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    required this.durationMonths,
    required this.features,
    this.isActive = true,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double price;
  final int durationMonths;
  final List<String> features;
  final bool isActive;

  @override
  List<Object?> get props => [id];
}

/// طلب دعم لتعديل اشتراك (من SUPPORT → SUBSCRIPTIONS)
class SupportSubscriptionRequest extends Equatable {
  const SupportSubscriptionRequest({
    required this.id,
    required this.userId,
    required this.requestedBy,
    required this.changeType,
    required this.newPlan,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.rejectionNote = '',
    this.resolvedAt,
  });

  final String id;
  final String userId;
  final String requestedBy; // uid of SUPPORT agent
  final String changeType;  // extend / upgrade / downgrade
  final String newPlan;
  final String reason;

  /// pending / approved / rejected
  final String status;

  final DateTime createdAt;
  final String rejectionNote;
  final DateTime? resolvedAt;

  @override
  List<Object?> get props => [id, status];
}

// ============================================================
// video_metadata.dart — كيانات الفيديو
// ============================================================

/// بيانات فيديو تمرين
class VideoMetadata extends Equatable {
  const VideoMetadata({
    required this.videoId,
    required this.exerciseId,
    required this.title,
    required this.durationSeconds,
    this.thumbnailUrl = '',
    this.driveFileId = '',
    this.orderIndex = 0,
  });

  final String videoId;
  final String exerciseId;
  final String title;
  final int durationSeconds;
  final String thumbnailUrl;

  /// معرّف الملف في Google Drive (مُخفى عن المستخدم)
  final String driveFileId;

  /// ترتيب الفيديو في Carousel
  final int orderIndex;

  @override
  List<Object?> get props => [videoId, exerciseId];
}
