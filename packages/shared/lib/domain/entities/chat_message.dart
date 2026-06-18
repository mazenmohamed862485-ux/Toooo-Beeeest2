// ============================================================
// TO Best — domain/entities/chat_message.dart
// كيانات الشات في طبقة Domain
// ============================================================

import 'package:equatable/equatable.dart';

/// محادثة (قناة شات)
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isGroup = false,
    this.groupName = '',
  });

  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isGroup;
  final String groupName;

  @override
  List<Object?> get props => [id];
}

/// رسالة شات
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.reactions = const {},
    this.mediaUrl = '',
    this.audioDurationSeconds = 0,
  });

  final String id;

  /// معرّف القناة (conversationId)
  final String roomId;

  final String senderId;
  final String senderName;
  final String content;

  /// text / image / voice / system
  final String messageType;

  final DateTime timestamp;
  final bool isRead;

  /// حُذفت الرسالة — تظهر "تم حذف هذه الرسالة"
  final bool isDeleted;

  final bool isEdited;
  final DateTime? editedAt;

  /// معرّف الرسالة التي يُرد عليها
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;

  /// التفاعلات: {emoji_code: [userId1, userId2]}
  final Map<String, List<String>> reactions;

  /// رابط الصورة أو الصوت
  final String mediaUrl;

  /// مدة الرسالة الصوتية (ثواني)
  final int audioDurationSeconds;

  @override
  List<Object?> get props => [id, roomId, timestamp];

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? content,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    bool? isDeleted,
    bool? isEdited,
    DateTime? editedAt,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    Map<String, List<String>>? reactions,
    String? mediaUrl,
    int? audioDurationSeconds,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      reactions: reactions ?? this.reactions,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
    );
  }
}

/// أنواع التفاعلات (6 reactions بأيقونات احترافية)
enum MessageReaction {
  thumbsUp(code: 'thumbs_up', icon: 'thumb_up'),
  heart(code: 'heart', icon: 'favorite'),
  laugh(code: 'laugh', icon: 'sentiment_very_satisfied'),
  surprised(code: 'surprised', icon: 'sentiment_neutral'),
  sad(code: 'sad', icon: 'sentiment_dissatisfied'),
  fire(code: 'fire', icon: 'local_fire_department');

  const MessageReaction({required this.code, required this.icon});

  final String code;
  final String icon;
}

/// رسالة AI Coach
class AiMessage extends Equatable {
  const AiMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.imageUrls = const [],
  });

  final String id;
  final String userId;

  /// 'user' / 'model'
  final String role;

  final String content;
  final DateTime timestamp;
  final List<String> imageUrls;

  @override
  List<Object?> get props => [id, userId, timestamp];
}
