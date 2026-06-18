// ============================================================
// TO Best — domain/entities/user.dart
// كيان المستخدم في طبقة Domain
// ============================================================

import 'package:equatable/equatable.dart';

/// كيان المستخدم — طبقة Domain
///
/// يمثل بيانات المستخدم الأساسية بدون اعتماديات على
/// أي framework أو persistence layer
class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    this.phone = '',
    this.picture = '',
    this.program = '',
    this.programDays = 4,
    this.assignedCoach = '',
    this.dailyCalories = 2000,
    this.goal = '',
    this.gender = Gender.male,
    this.weight = 0,
    this.height = 0,
    this.age = 0,
    this.subscription = const SubscriptionInfo(),
    this.deviceInfo = const [],
    this.createdAt,
    this.chatBanned = false,
    this.chatMutedUntil = 0,
    this.forceLogoutToken = '',
    this.referralCode = '',
    this.activityLevel = ActivityLevel.moderate,
  });

  /// معرّف المستخدم الفريد
  final String uid;

  /// البريد الإلكتروني
  final String email;

  /// الاسم الكامل
  final String name;

  /// دور المستخدم (TRAINEE / COACH / MANAGER / SUPPORT / SUBSCRIPTIONS)
  final String role;

  /// حالة الحساب (active / banned / suspended)
  final String status;

  /// رقم الهاتف
  final String phone;

  /// رابط الصورة الشخصية
  final String picture;

  /// البرنامج التدريبي المعيَّن
  final String program;

  /// عدد أيام التدريب الأسبوعية
  final int programDays;

  /// uid المدرب المعيَّن (للمستخدمين فقط)
  final String assignedCoach;

  /// السعرات الحرارية اليومية
  final int dailyCalories;

  /// الهدف (loseWeight / maintain / gainMuscle)
  final String goal;

  /// الجنس
  final Gender gender;

  /// الوزن بالكيلوغرام
  final double weight;

  /// الطول بالسنتيمتر
  final double height;

  /// العمر بالسنوات
  final int age;

  /// بيانات الاشتراك
  final SubscriptionInfo subscription;

  /// الأجهزة المسجلة
  final List<DeviceInfo> deviceInfo;

  /// تاريخ الإنشاء
  final DateTime? createdAt;

  /// هل محظور من الشات
  final bool chatBanned;

  /// وقت انتهاء كتم الشات (Unix timestamp بالمللي ثانية)
  final int chatMutedUntil;

  /// Token إجبار تسجيل الخروج
  final String forceLogoutToken;

  /// كود الإحالة
  final String referralCode;

  /// مستوى النشاط
  final ActivityLevel activityLevel;

  /// هل المستخدم نشط في الاشتراك
  bool get isSubscriptionActive =>
      subscription.status == 'active' &&
      (subscription.endDate?.isAfter(DateTime.now()) ?? false);

  /// هل الشات مكتوم الآن
  bool get isChatMuted =>
      chatMutedUntil > DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [uid, email, name, role, status];

  UserEntity copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? status,
    String? phone,
    String? picture,
    String? program,
    int? programDays,
    String? assignedCoach,
    int? dailyCalories,
    String? goal,
    Gender? gender,
    double? weight,
    double? height,
    int? age,
    SubscriptionInfo? subscription,
    List<DeviceInfo>? deviceInfo,
    DateTime? createdAt,
    bool? chatBanned,
    int? chatMutedUntil,
    String? forceLogoutToken,
    String? referralCode,
    ActivityLevel? activityLevel,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      picture: picture ?? this.picture,
      program: program ?? this.program,
      programDays: programDays ?? this.programDays,
      assignedCoach: assignedCoach ?? this.assignedCoach,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      goal: goal ?? this.goal,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      subscription: subscription ?? this.subscription,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      createdAt: createdAt ?? this.createdAt,
      chatBanned: chatBanned ?? this.chatBanned,
      chatMutedUntil: chatMutedUntil ?? this.chatMutedUntil,
      forceLogoutToken: forceLogoutToken ?? this.forceLogoutToken,
      referralCode: referralCode ?? this.referralCode,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}

/// بيانات الاشتراك
class SubscriptionInfo extends Equatable {
  const SubscriptionInfo({
    this.type = 'none',
    this.status = 'none',
    this.startDate,
    this.endDate,
    this.requestedAt,
    this.rejectionReason = '',
    this.duration = 1,
  });

  /// نوع الخطة (light / standard / premium)
  final String type;

  /// حالة الاشتراك
  final String status;

  /// تاريخ البدء
  final DateTime? startDate;

  /// تاريخ الانتهاء
  final DateTime? endDate;

  /// تاريخ تقديم الطلب
  final DateTime? requestedAt;

  /// سبب الرفض (إن وجد)
  final String rejectionReason;

  /// المدة بالأشهر
  final int duration;

  @override
  List<Object?> get props => [type, status, startDate, endDate];
}

/// بيانات الجهاز
class DeviceInfo extends Equatable {
  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.registeredAt,
    this.lastLoginAt,
  });

  final String deviceId;
  final String deviceName;
  final String platform; // android / ios
  final DateTime registeredAt;
  final DateTime? lastLoginAt;

  @override
  List<Object?> get props => [deviceId];
}

/// الجنس
enum Gender {
  male,
  female;

  String get arabicLabel => switch (this) {
        Gender.male => 'ذكر',
        Gender.female => 'أنثى',
      };
}

/// مستوى النشاط
enum ActivityLevel {
  sedentary(factor: 1.2, arabicLabel: 'خامل', key: 'sedentary'),
  light(factor: 1.375, arabicLabel: 'خفيف', key: 'light'),
  moderate(factor: 1.55, arabicLabel: 'معتدل', key: 'moderate'),
  active(factor: 1.725, arabicLabel: 'نشيط', key: 'active'),
  veryActive(factor: 1.9, arabicLabel: 'نشيط جداً', key: 'veryActive');

  const ActivityLevel({
    required this.factor,
    required this.arabicLabel,
    required this.key,
  });

  final double factor;
  final String arabicLabel;
  final String key;

  static ActivityLevel fromKey(String key) =>
      ActivityLevel.values.firstWhere(
        (e) => e.key == key,
        orElse: () => ActivityLevel.moderate,
      );
}
