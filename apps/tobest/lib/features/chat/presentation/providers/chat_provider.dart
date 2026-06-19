// ============================================================
// TO Best — chat/presentation/providers/chat_provider.dart
// إدارة حالة الشات: Polling + Offline Queue + Media
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/domain/entities/chat_message.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/infrastructure/polling_service.dart';
import 'package:shared/infrastructure/notification_service.dart';
import 'package:shared/data/models/chat_model.dart';
import 'package:shared/config/app_config.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import 'package:isar/isar.dart';
part 'chat_provider.g.dart';

// ── Messages Provider ─────────────────────────────────────────

/// رسائل محادثة محددة (من Isar Cache)
@riverpod
Stream<List<ChatMessage>> conversationMessages(
  ConversationMessagesRef ref,
  String roomId,
) async* {
  final isar = ref.read(isarServiceProvider);
  final db = await isar.db;

  // بث تغييرات من Isar
  yield* db.chatMessageIsarModels
      .filter()
      .roomIdEqualTo(roomId)
      .isDeletedEqualTo(false)
      .sortByTimestampMs()
      .watch(fireImmediately: true)
      .map((models) => models.map((m) => m.toEntity()).toList());
}

/// قائمة المحادثات للمستخدم الحالي
@riverpod
Future<List<Conversation>> userConversations(
    UserConversationsRef ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final gasClient = ref.read(gasClientProvider);
  final result = await gasClient.post(
    action: 'GET_ROOMS',
    data: {'uid': user.uid},
  );

  final rooms = result['rooms'] as List<dynamic>? ?? [];
  return rooms.map((r) {
    final m = r as Map<String, dynamic>;
    return Conversation(
      id: m['id']?.toString() ?? '',
      participants: (m['participants'] as List<dynamic>? ?? [])
          .map((p) => p.toString())
          .toList(),
      participantNames: Map<String, String>.from(
          m['participantNames'] as Map? ?? {}),
      unreadCount: int.tryParse(m['unread']?.toString() ?? '0') ?? 0,
      lastMessageAt: _parseDate(m['lastMessageAt']),
    );
  }).toList();
}

DateTime? _parseDate(dynamic val) {
  if (val == null) return null;
  try {
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.parse(val.toString());
  } catch (_) {
    return null;
  }
}

// ── Polling Provider ──────────────────────────────────────────

/// Adaptive Polling لمحادثة محددة
@riverpod
class ChatPolling extends _$ChatPolling {
  final _polling = PollingService();

  @override
  void build(String roomId) {}

  void startPolling() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    _polling.startPolling(() async {
      await _fetchNewMessages(roomId, user.uid);
    });
  }

  void stopPolling() => _polling.stopPolling();

  void registerActivity() => _polling.registerActivity();

  Future<void> _fetchNewMessages(String roomId, String userId) async {
    try {
      final isar = ref.read(isarServiceProvider);
      final db = await isar.db;

      // آخر رسالة في Isar لهذه المحادثة
      final lastMsg = await db.chatMessageIsarModels
          .filter()
          .roomIdEqualTo(roomId)
          .sortByTimestampMsDesc()
          .findFirst();

      final since = lastMsg?.timestampMs;

      final gasClient = ref.read(gasClientProvider);
      final result = await gasClient.post(
        action: 'GET_MSGS',
        data: {
          'roomId': roomId,
          if (since != null) 'since': since,
        },
      );

      final messages = result['messages'] as List<dynamic>? ?? [];
      if (messages.isEmpty) return;

      final models = messages
          .map((m) => ChatMessageIsarModel.fromJson(
                m as Map<String, dynamic>,
                userId,
              ))
          .where((m) => m.messageId.isNotEmpty)
          .toList();

      await db.writeTxn(() async {
        await db.chatMessageIsarModels.putAll(models);
      });

      // إشعار للرسائل الجديدة من الطرف الآخر
      final newFromOthers =
          models.where((m) => m.senderId != userId).toList();
      if (newFromOthers.isNotEmpty) {
        final last = newFromOthers.last;
        await NotificationService().showChatNotification(
          id: last.timestampMs ~/ 1000,
          senderName: last.senderName,
          message: last.messageType == 'text'
              ? last.content
              : last.messageType == 'image'
                  ? '📷 صورة'
                  : '🎤 رسالة صوتية',
          payload: 'chat/$roomId',
        );
      }

      // تأشير كمقروء
      await gasClient.post(
        action: 'MARK_READ',
        data: {'roomId': roomId, 'uid': userId},
      );
    } catch (_) {
      // تجاهل أخطاء الـ Polling الفردية
    }
  }
}

// ── Chat Actions Provider ─────────────────────────────────────

@riverpod
class ChatActions extends _$ChatActions {
  @override
  void build() {}

  /// إرسال رسالة نصية
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    required String type,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final messageId = const Uuid().v4();
    final now = DateTime.now();

    // حفظ محلياً أولاً (Optimistic Update)
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final model = ChatMessageIsarModel(
      messageId: messageId,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      messageType: type,
      timestampMs: now.millisecondsSinceEpoch,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      userId: senderId,
      syncedToRemote: false,
    );

    await db.writeTxn(() async {
      await db.chatMessageIsarModels.put(model);
    });

    // إرسال لـ GAS
    try {
      final gasClient = ref.read(gasClientProvider);
      await gasClient.post(
        action: 'SEND_MSG',
        data: {
          'roomId': roomId,
          'msg': {
            'id': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'content': content,
            'type': type,
            'ts': now.millisecondsSinceEpoch,
            if (replyToId != null) 'replyToId': replyToId,
            if (replyToContent != null) 'replyToContent': replyToContent,
            if (replyToSenderName != null)
              'replyToSenderName': replyToSenderName,
          },
        },
      );

      // تحديث حالة المزامنة
      await db.writeTxn(() async {
        model.syncedToRemote = true;
        await db.chatMessageIsarModels.put(model);
      });
    } catch (_) {
      // تُحفَظ في Queue للمزامنة لاحقاً
    }
  }

  /// إرسال صورة
  Future<void> sendImage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String imagePath,
  }) async {
    try {
      final gasClient = ref.read(gasClientProvider);
      final bytes = await File(imagePath).readAsBytes();
      final base64 = base64Encode(bytes);

      final result = await gasClient.post(
        action: 'UPLOAD_CHAT_IMAGE',
        data: {
          'roomId': roomId,
          'senderId': senderId,
          'imageBase64': base64,
        },
      );

      final url = result['url']?.toString() ?? '';
      if (url.isEmpty) return;

      await sendMessage(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        content: url,
        type: 'image',
      );
    } catch (_) {}
  }

  /// إرسال رسالة صوتية
  Future<void> sendVoice({
    required String roomId,
    required String senderId,
    required String senderName,
    required String audioPath,
    required int durationSeconds,
  }) async {
    try {
      final gasClient = ref.read(gasClientProvider);
      final bytes = await File(audioPath).readAsBytes();
      final base64 = base64Encode(bytes);

      final result = await gasClient.post(
        action: 'UPLOAD_VOICE',
        data: {
          'roomId': roomId,
          'senderId': senderId,
          'audioBase64': base64,
          'duration': durationSeconds,
        },
      );

      final url = result['url']?.toString() ?? '';
      if (url.isEmpty) return;

      final isar = ref.read(isarServiceProvider);
      final db = await isar.db;
      final model = ChatMessageIsarModel(
        messageId: const Uuid().v4(),
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        content: url,
        messageType: 'voice',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        mediaUrl: url,
        audioDurationSeconds: durationSeconds,
        userId: senderId,
        syncedToRemote: true,
      );
      await db.writeTxn(() async {
        await db.chatMessageIsarModels.put(model);
      });
    } catch (_) {}
  }

  /// تعديل رسالة
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newContent,
  }) async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final model = await db.chatMessageIsarModels
        .filter()
        .messageIdEqualTo(messageId)
        .findFirst();
    if (model == null) return;

    await db.writeTxn(() async {
      model.content = newContent;
      model.isEdited = true;
      await db.chatMessageIsarModels.put(model);
    });

    try {
      final gasClient = ref.read(gasClientProvider);
      await gasClient.post(
        action: 'EDIT_MSG',
        data: {
          'roomId': roomId,
          'msgId': messageId,
          'newContent': newContent,
        },
      );
    } catch (_) {}
  }

  /// حذف رسالة
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final model = await db.chatMessageIsarModels
        .filter()
        .messageIdEqualTo(messageId)
        .findFirst();
    if (model == null) return;

    await db.writeTxn(() async {
      model.isDeleted = true;
      await db.chatMessageIsarModels.put(model);
    });

    try {
      final gasClient = ref.read(gasClientProvider);
      await gasClient.post(
        action: 'DEL_MSG',
        data: {'roomId': roomId, 'msgId': messageId},
      );
    } catch (_) {}
  }

  /// إضافة تفاعل
  Future<void> addReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String reactionCode,
  }) async {
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final model = await db.chatMessageIsarModels
        .filter()
        .messageIdEqualTo(messageId)
        .findFirst();
    if (model == null) return;

    // toggle reaction
    final reactions = Map<String, List<String>>.from(
        (jsonDecode(model.reactionsJson) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).cast<String>()),
    ));

    final users = reactions[reactionCode] ?? [];
    if (users.contains(userId)) {
      users.remove(userId);
    } else {
      users.add(userId);
    }
    reactions[reactionCode] = users;

    await db.writeTxn(() async {
      model.reactionsJson = jsonEncode(reactions);
      await db.chatMessageIsarModels.put(model);
    });

    try {
      final gasClient = ref.read(gasClientProvider);
      await gasClient.post(
        action: 'REACT_MSG',
        data: {
          'roomId': roomId,
          'msgId': messageId,
          'uid': userId,
          'reaction': reactionCode,
        },
      );
    } catch (_) {}
  }
}
