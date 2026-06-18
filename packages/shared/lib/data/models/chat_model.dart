// ============================================================
// TO Best — data/models/chat_model.dart
// ============================================================

import 'dart:convert';
import 'package:isar/isar.dart';
import '../../domain/entities/chat_message.dart';

part 'chat_model.g.dart';

@Collection()
class ChatMessageIsarModel {
  ChatMessageIsarModel({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.timestampMs,
    this.isRead = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAtMs,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.reactionsJson = '{}',
    this.mediaUrl = '',
    this.audioDurationSeconds = 0,
    this.userId = '',
    this.syncedToRemote = false,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String messageId;

  @Index()
  final String roomId;

  final String senderId;
  final String senderName;
  String content;
  final String messageType;

  @Index()
  final int timestampMs;

  bool isRead;
  bool isDeleted;
  bool isEdited;
  final int? editedAtMs;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;
  String reactionsJson;
  final String mediaUrl;
  final int audioDurationSeconds;

  /// للتصفية بالمستخدم
  @Index()
  final String userId;

  bool syncedToRemote;

  ChatMessage toEntity() {
    final reactions = (jsonDecode(reactionsJson) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
    );

    return ChatMessage(
      id: messageId,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      messageType: messageType,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      isRead: isRead,
      isDeleted: isDeleted,
      isEdited: isEdited,
      editedAt: editedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(editedAtMs!)
          : null,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      reactions: reactions,
      mediaUrl: mediaUrl,
      audioDurationSeconds: audioDurationSeconds,
    );
  }

  factory ChatMessageIsarModel.fromEntity(
      ChatMessage entity, String currentUserId) {
    return ChatMessageIsarModel(
      messageId: entity.id,
      roomId: entity.roomId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      content: entity.content,
      messageType: entity.messageType,
      timestampMs: entity.timestamp.millisecondsSinceEpoch,
      isRead: entity.isRead,
      isDeleted: entity.isDeleted,
      isEdited: entity.isEdited,
      editedAtMs: entity.editedAt?.millisecondsSinceEpoch,
      replyToId: entity.replyToId,
      replyToContent: entity.replyToContent,
      replyToSenderName: entity.replyToSenderName,
      reactionsJson: jsonEncode(entity.reactions),
      mediaUrl: entity.mediaUrl,
      audioDurationSeconds: entity.audioDurationSeconds,
      userId: currentUserId,
    );
  }

  factory ChatMessageIsarModel.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    Map<String, List<String>> reactions = {};
    if (json['reactions'] is Map) {
      reactions = (json['reactions'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
      );
    }

    return ChatMessageIsarModel(
      messageId: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      messageType: json['type']?.toString() ?? 'text',
      timestampMs: _parseTs(json['timestamp'] ?? json['ts']),
      isRead: json['read'] == true || json['isRead'] == true,
      isDeleted: json['deleted'] == true || json['isDeleted'] == true,
      isEdited: json['edited'] == true || json['isEdited'] == true,
      editedAtMs: _parseTs(json['editedAt']),
      replyToId: json['replyToId']?.toString(),
      replyToContent: json['replyToContent']?.toString(),
      replyToSenderName: json['replyToSenderName']?.toString(),
      reactionsJson: jsonEncode(reactions),
      mediaUrl: json['mediaUrl']?.toString() ?? json['fileUrl']?.toString() ?? '',
      audioDurationSeconds:
          int.tryParse(json['audioDuration']?.toString() ?? '0') ?? 0,
      userId: currentUserId,
    );
  }

  static int? _parseTs(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is String) {
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;
      try {
        return DateTime.parse(val).millisecondsSinceEpoch;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// سجل رسائل AI
@Collection()
class AiMessageIsarModel {
  AiMessageIsarModel({
    required this.messageId,
    required this.userId,
    required this.role,
    required this.content,
    required this.timestampMs,
    this.imageUrlsJson = '[]',
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String messageId;

  @Index()
  final String userId;

  final String role;
  final String content;

  @Index()
  final int timestampMs;

  final String imageUrlsJson;

  AiMessage toEntity() {
    final images = (jsonDecode(imageUrlsJson) as List<dynamic>).cast<String>();
    return AiMessage(
      id: messageId,
      userId: userId,
      role: role,
      content: content,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      imageUrls: images,
    );
  }

  factory AiMessageIsarModel.fromEntity(AiMessage entity) {
    return AiMessageIsarModel(
      messageId: entity.id,
      userId: entity.userId,
      role: entity.role,
      content: entity.content,
      timestampMs: entity.timestamp.millisecondsSinceEpoch,
      imageUrlsJson: jsonEncode(entity.imageUrls),
    );
  }
}

// ============================================================
// health_model.dart
// ============================================================

part 'health_model.g.dart';

import '../../domain/entities/health_data.dart';

@Collection()
class HealthDataIsarModel {
  HealthDataIsarModel({
    required this.userId,
    required this.dateMs,
    this.steps = 0,
    this.distanceKm = 0,
    this.burnedCalories = 0,
    this.walkingMinutes = 0,
    this.sleepHours = 0,
    this.sleepMinutes = 0,
    this.sleepQuality = 'fair',
    this.syncedToRemote = false,
    this.updatedAtMs,
  });

  Id id = Isar.autoIncrement;

  @Index(
    composite: [CompositeIndex('dateMs')],
    unique: true,
  )
  final String userId;

  @Index()
  final int dateMs;

  int steps;
  double distanceKm;
  double burnedCalories;
  int walkingMinutes;
  int sleepHours;
  int sleepMinutes;
  String sleepQuality;
  bool syncedToRemote;
  final int? updatedAtMs;

  HealthData toEntity() {
    SleepData? sleep;
    if (sleepHours > 0 || sleepMinutes > 0) {
      sleep = SleepData(
        durationHours: sleepHours,
        durationMinutes: sleepMinutes,
        quality: SleepQuality.values.firstWhere(
          (q) => q.name == sleepQuality,
          orElse: () => SleepQuality.fair,
        ),
      );
    }
    return HealthData(
      userId: userId,
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      steps: steps,
      distanceKm: distanceKm,
      burnedCalories: burnedCalories,
      walkingMinutes: walkingMinutes,
      sleep: sleep,
      updatedAt: updatedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs!)
          : null,
    );
  }

  factory HealthDataIsarModel.fromEntity(HealthData entity) {
    return HealthDataIsarModel(
      userId: entity.userId,
      dateMs: entity.date.millisecondsSinceEpoch,
      steps: entity.steps,
      distanceKm: entity.distanceKm,
      burnedCalories: entity.burnedCalories,
      walkingMinutes: entity.walkingMinutes,
      sleepHours: entity.sleep?.durationHours ?? 0,
      sleepMinutes: entity.sleep?.durationMinutes ?? 0,
      sleepQuality: entity.sleep?.quality.name ?? 'fair',
      updatedAtMs: entity.updatedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// ============================================================
// subscription_model.dart
// ============================================================

part 'subscription_model.g.dart';

import '../../domain/entities/health_data.dart'
    show SubscriptionRequest, SubscriptionPlan;

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

  factory SubscriptionRequestIsarModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null || val.toString().isEmpty) return null;
      try {
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
