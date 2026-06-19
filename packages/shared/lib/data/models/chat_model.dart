// TO Best — data/models/chat_model.dart

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
      timestampMs: _parseTs(json['timestamp'] ?? json['ts']) ?? 0,
      isRead: json['read'] == true || json['isRead'] == true,
      isDeleted: json['deleted'] == true || json['isDeleted'] == true,
      isEdited: json['edited'] == true || json['isEdited'] == true,
      editedAtMs: _parseTs(json['editedAt']),
      replyToId: json['replyToId']?.toString(),
      replyToContent: json['replyToContent']?.toString(),
      replyToSenderName: json['replyToSenderName']?.toString(),
      reactionsJson: jsonEncode(reactions),
      mediaUrl:
          json['mediaUrl']?.toString() ?? json['fileUrl']?.toString() ?? '',
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
