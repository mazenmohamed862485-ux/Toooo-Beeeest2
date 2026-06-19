// TO Best — domain/repositories/chat_repository.dart

import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<Conversation>> getConversations(String userId);

  Future<List<ChatMessage>> getMessages({
    required String roomId,
    DateTime? since,
    int limit,
  });

  Future<ChatMessage> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    required String messageType,
    String? replyToId,
    String? mediaUrl,
  });

  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newContent,
  });

  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  });

  Future<void> markAsRead({
    required String roomId,
    required String userId,
  });

  Future<void> addReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String reactionCode,
  });

  Future<void> saveAiMessage(AiMessage message);
  Future<List<AiMessage>> getAiHistory(String userId);
  Future<void> clearAiHistory(String userId);
}
