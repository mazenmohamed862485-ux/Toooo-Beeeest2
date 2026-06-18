// ============================================================
// TO Best — data/models/user_model.dart
// Isar Schema + JSON Model للمستخدم
// ============================================================

import 'package:isar/isar.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// Isar Schema للمستخدم
@Collection()
class UserIsarModel {
  UserIsarModel({
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
    this.gender = 'male',
    this.weight = 0,
    this.height = 0,
    this.age = 0,
    this.subscriptionType = 'none',
    this.subscriptionStatus = 'none',
    this.subscriptionStartMs,
    this.subscriptionEndMs,
    this.subscriptionRejectionReason = '',
    this.subscriptionDuration = 1,
    this.chatBanned = false,
    this.chatMutedUntil = 0,
    this.forceLogoutToken = '',
    this.referralCode = '',
    this.activityLevel = 'moderate',
    this.createdAtMs,
    this.updatedAtMs,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String uid;

  @Index()
  final String email;

  final String name;
  final String role;
  final String status;
  final String phone;
  final String picture;
  final String program;
  final int programDays;
  final String assignedCoach;
  final int dailyCalories;
  final String goal;
  final String gender;
  final double weight;
  final double height;
  final int age;

  // ── Subscription ──────────────────────────────────────────
  final String subscriptionType;
  final String subscriptionStatus;
  final int? subscriptionStartMs;
  final int? subscriptionEndMs;
  final String subscriptionRejectionReason;
  final int subscriptionDuration;

  // ── Chat & Security ───────────────────────────────────────
  final bool chatBanned;
  final int chatMutedUntil;
  final String forceLogoutToken;
  final String referralCode;
  final String activityLevel;

  final int? createdAtMs;
  final int? updatedAtMs;

  // ── Conversions ───────────────────────────────────────────

  /// تحويل إلى Domain Entity
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      role: role,
      status: status,
      phone: phone,
      picture: picture,
      program: program,
      programDays: programDays,
      assignedCoach: assignedCoach,
      dailyCalories: dailyCalories,
      goal: goal,
      gender: gender == 'female' ? Gender.female : Gender.male,
      weight: weight,
      height: height,
      age: age,
      subscription: SubscriptionInfo(
        type: subscriptionType,
        status: subscriptionStatus,
        startDate: subscriptionStartMs != null
            ? DateTime.fromMillisecondsSinceEpoch(subscriptionStartMs!)
            : null,
        endDate: subscriptionEndMs != null
            ? DateTime.fromMillisecondsSinceEpoch(subscriptionEndMs!)
            : null,
        rejectionReason: subscriptionRejectionReason,
        duration: subscriptionDuration,
      ),
      chatBanned: chatBanned,
      chatMutedUntil: chatMutedUntil,
      forceLogoutToken: forceLogoutToken,
      referralCode: referralCode,
      activityLevel: ActivityLevel.fromKey(activityLevel),
      createdAt: createdAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs!)
          : null,
    );
  }

  /// بناء من Domain Entity
  factory UserIsarModel.fromEntity(UserEntity entity) {
    return UserIsarModel(
      uid: entity.uid,
      email: entity.email,
      name: entity.name,
      role: entity.role,
      status: entity.status,
      phone: entity.phone,
      picture: entity.picture,
      program: entity.program,
      programDays: entity.programDays,
      assignedCoach: entity.assignedCoach,
      dailyCalories: entity.dailyCalories,
      goal: entity.goal,
      gender: entity.gender.name,
      weight: entity.weight,
      height: entity.height,
      age: entity.age,
      subscriptionType: entity.subscription.type,
      subscriptionStatus: entity.subscription.status,
      subscriptionStartMs:
          entity.subscription.startDate?.millisecondsSinceEpoch,
      subscriptionEndMs: entity.subscription.endDate?.millisecondsSinceEpoch,
      subscriptionRejectionReason: entity.subscription.rejectionReason,
      subscriptionDuration: entity.subscription.duration,
      chatBanned: entity.chatBanned,
      chatMutedUntil: entity.chatMutedUntil,
      forceLogoutToken: entity.forceLogoutToken,
      referralCode: entity.referralCode,
      activityLevel: entity.activityLevel.key,
      createdAtMs: entity.createdAt?.millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// بناء من JSON (GAS Response)
  factory UserIsarModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null || val.toString().isEmpty) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    final sub = json['subscription'] as Map<String, dynamic>? ?? {};

    return UserIsarModel(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'TRAINEE',
      status: json['status']?.toString() ?? 'active',
      phone: json['phone']?.toString() ?? '',
      picture: json['picture']?.toString() ?? '',
      program: json['program']?.toString() ?? '',
      programDays: int.tryParse(json['programDays']?.toString() ?? '4') ?? 4,
      assignedCoach: json['assignedCoach']?.toString() ?? '',
      dailyCalories:
          int.tryParse(json['dailyCalories']?.toString() ?? '2000') ?? 2000,
      goal: json['goal']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'male',
      weight: double.tryParse(json['weight']?.toString() ?? '0') ?? 0,
      height: double.tryParse(json['height']?.toString() ?? '0') ?? 0,
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      subscriptionType:
          sub['type']?.toString() ?? json['subscriptionType']?.toString() ?? 'none',
      subscriptionStatus:
          sub['status']?.toString() ?? json['subscriptionStatus']?.toString() ?? 'none',
      subscriptionStartMs:
          parseDate(sub['startDate'] ?? json['subscriptionStart'])
              ?.millisecondsSinceEpoch,
      subscriptionEndMs:
          parseDate(sub['endDate'] ?? json['subscriptionEnd'])
              ?.millisecondsSinceEpoch,
      subscriptionRejectionReason:
          sub['rejectionReason']?.toString() ?? '',
      subscriptionDuration:
          int.tryParse(sub['duration']?.toString() ?? '1') ?? 1,
      chatBanned: json['chatBanned'] == true || json['chatBanned'] == 'true',
      chatMutedUntil:
          int.tryParse(json['chatMutedUntil']?.toString() ?? '0') ?? 0,
      forceLogoutToken: json['forceLogoutToken']?.toString() ?? '',
      referralCode: json['referralCode']?.toString() ?? '',
      activityLevel: json['activityLevel']?.toString() ?? 'moderate',
      createdAtMs: parseDate(json['createdAt'])?.millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'phone': phone,
      'picture': picture,
      'program': program,
      'programDays': programDays,
      'assignedCoach': assignedCoach,
      'dailyCalories': dailyCalories,
      'goal': goal,
      'gender': gender,
      'weight': weight,
      'height': height,
      'age': age,
      'subscriptionType': subscriptionType,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionStart': subscriptionStartMs != null
          ? DateTime.fromMillisecondsSinceEpoch(subscriptionStartMs!)
              .toIso8601String()
          : '',
      'subscriptionEnd': subscriptionEndMs != null
          ? DateTime.fromMillisecondsSinceEpoch(subscriptionEndMs!)
              .toIso8601String()
          : '',
      'referralCode': referralCode,
      'activityLevel': activityLevel,
    };
  }
}
