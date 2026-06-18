// ============================================================
// TO Best — chat/presentation/screens/conversation_screen.dart
// شاشة المحادثة: رسائل + صور + صوت + Reply + Reactions
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/chat_message.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// شاشة المحادثة الثنائية
class ConversationScreen extends HookConsumerWidget {
  const ConversationScreen({
    super.key,
    required this.roomId,
    required this.participantName,
  });

  final String roomId;
  final String participantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final messageCtrl = useTextEditingController();
    final scrollCtrl = useScrollController();
    final replyTo = useState<ChatMessage?>(null);
    final isRecording = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // بدء الـ Polling عند فتح المحادثة
    useEffect(() {
      ref.read(chatPollingProvider(roomId).notifier).startPolling();
      return () =>
          ref.read(chatPollingProvider(roomId).notifier).stopPolling();
    }, [roomId]);

    final messagesAsync = ref.watch(conversationMessagesProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: Text(
                participantName.isNotEmpty
                    ? participantName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(participantName),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── قائمة الرسائل ────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Text('خطأ في تحميل الرسائل: $e'),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('ابدأ المحادثة 👋'),
                  );
                }

                // Scroll للأسفل عند وصول رسائل جديدة
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollCtrl.hasClients) {
                    scrollCtrl.animateTo(
                      scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMine = msg.senderId == user?.uid;
                    final isFirst = i == 0 ||
                        messages[i - 1].senderId != msg.senderId;
                    final isLast = i == messages.length - 1 ||
                        messages[i + 1].senderId != msg.senderId;

                    return _MessageBubble(
                      message: msg,
                      isMine: isMine,
                      isFirst: isFirst,
                      isLast: isLast,
                      isDark: isDark,
                      currentUserId: user?.uid ?? '',
                      onReply: () => replyTo.value = msg,
                      onReact: (code) {
                        ref
                            .read(chatActionsProvider.notifier)
                            .addReaction(
                              roomId: roomId,
                              messageId: msg.id,
                              userId: user?.uid ?? '',
                              reactionCode: code,
                            );
                      },
                      onDelete: isMine
                          ? () {
                              ref
                                  .read(chatActionsProvider.notifier)
                                  .deleteMessage(
                                    roomId: roomId,
                                    messageId: msg.id,
                                  );
                            }
                          : null,
                      onEdit: isMine
                          ? () => _showEditDialog(
                                context,
                                ref,
                                msg,
                                roomId,
                              )
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // ── Reply Preview ──────────────────────────────────
          if (replyTo.value != null)
            _ReplyPreview(
              message: replyTo.value!,
              onDismiss: () => replyTo.value = null,
            ),

          // ── Input Bar ─────────────────────────────────────
          _MessageInputBar(
            controller: messageCtrl,
            isRecording: isRecording.value,
            isDark: isDark,
            onSend: () {
              final text = messageCtrl.text.trim();
              if (text.isEmpty) return;
              ref.read(chatActionsProvider.notifier).sendMessage(
                    roomId: roomId,
                    senderId: user?.uid ?? '',
                    senderName: user?.name ?? '',
                    content: text,
                    type: 'text',
                    replyToId: replyTo.value?.id,
                    replyToContent: replyTo.value?.content,
                    replyToSenderName: replyTo.value?.senderName,
                  );
              messageCtrl.clear();
              replyTo.value = null;
            },
            onPickImage: () async {
              final picker = ImagePicker();
              final img = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 75,
              );
              if (img == null || !context.mounted) return;
              // رفع الصورة وإرسالها
              ref.read(chatActionsProvider.notifier).sendImage(
                    roomId: roomId,
                    senderId: user?.uid ?? '',
                    senderName: user?.name ?? '',
                    imagePath: img.path,
                  );
            },
            onStartRecord: () => isRecording.value = true,
            onStopRecord: (path, duration) {
              isRecording.value = false;
              if (path == null) return;
              ref.read(chatActionsProvider.notifier).sendVoice(
                    roomId: roomId,
                    senderId: user?.uid ?? '',
                    senderName: user?.name ?? '',
                    audioPath: path,
                    durationSeconds: duration,
                  );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ChatMessage message,
    String roomId,
  ) async {
    final ctrl = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      ref.read(chatActionsProvider.notifier).editMessage(
            roomId: roomId,
            messageId: message.id,
            newContent: result,
          );
    }
  }
}

// ── Message Bubble ────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.currentUserId,
    required this.onReply,
    required this.onReact,
    this.onDelete,
    this.onEdit,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final String currentUserId;
  final VoidCallback onReply;
  final void Function(String code) onReact;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _DeletedBubble(isMine: isMine);

    final bubbleColor = isMine
        ? (isDark ? AppColors.chatBubbleSentDark : AppColors.chatBubbleSent)
        : (isDark
            ? AppColors.chatBubbleReceivedDark
            : AppColors.chatBubbleReceived);

    final textColor = isMine ? Colors.white : null;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? AppSpacing.sm : 2,
        bottom: isLast ? AppSpacing.sm : 2,
        left: isMine ? 48 : 0,
        right: isMine ? 0 : 48,
      ),
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar للطرف الآخر
            if (!isMine && isLast) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.15),
                child: Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else if (!isMine) ...[
              const SizedBox(width: 34),
            ],

            // Bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name (للمجموعات)
                  if (!isMine && isFirst)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 2, left: 12, right: 12),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: isMine
                          ? AppRadius.chatBubbleSent(isFirst, isLast)
                          : AppRadius.chatBubbleReceived(isFirst, isLast),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reply Preview
                        if (message.replyToId != null)
                          _ReplyPreviewInBubble(
                            senderName:
                                message.replyToSenderName ?? '',
                            content: message.replyToContent ?? '',
                            isMine: isMine,
                          ),

                        // Content by type
                        switch (message.messageType) {
                          'image' => _ImageContent(
                              url: message.mediaUrl,
                              content: message.content,
                            ),
                          'voice' => _VoiceContent(
                              url: message.mediaUrl,
                              durationSeconds:
                                  message.audioDurationSeconds,
                              isMine: isMine,
                            ),
                          _ => Text(
                              message.content,
                              style: TextStyle(color: textColor),
                            ),
                        },

                        // Timestamp + Read
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isEdited)
                              Text(
                                'معدَّل ',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isMine
                                      ? Colors.white70
                                      : AppColors.lightOnSurfaceVariant,
                                ),
                              ),
                            Text(
                              DateFormat('hh:mm a')
                                  .format(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMine
                                    ? Colors.white70
                                    : AppColors.lightOnSurfaceVariant,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 3),
                              Icon(
                                message.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 13,
                                color: message.isRead
                                    ? Colors.lightBlueAccent
                                    : Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reactions
                  if (message.reactions.isNotEmpty)
                    _ReactionsRow(
                      reactions: message.reactions,
                      currentUserId: currentUserId,
                      isMine: isMine,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reactions Row
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: MessageReaction.values.map((r) {
                  return GestureDetector(
                    onTap: () {
                      onReact(r.code);
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      _reactionEmoji(r.code),
                      style: const TextStyle(fontSize: 28),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('رد'),
              onTap: () {
                Navigator.pop(ctx);
                onReply();
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('تعديل'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('نسخ'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ')),
                );
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text('حذف',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _reactionEmoji(String code) => switch (code) {
        'thumbs_up' => '👍',
        'heart' => '❤️',
        'laugh' => '😂',
        'surprised' => '😮',
        'sad' => '😢',
        'fire' => '🔥',
        _ => '👍',
      };
}

// ── Sub-widgets ───────────────────────────────────────────────

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.isMine});
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 48 : 0,
        right: isMine ? 0 : 48,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded,
                    size: 14, color: AppColors.lightOnSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'تم حذف هذه الرسالة',
                  style: TextStyle(
                    color: AppColors.lightOnSurfaceVariant,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyPreviewInBubble extends StatelessWidget {
  const _ReplyPreviewInBubble({
    required this.senderName,
    required this.content,
    required this.isMine,
  });
  final String senderName;
  final String content;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withOpacity(0.2)
            : AppColors.lightBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(
          right: BorderSide(
            color: isMine ? Colors.white : Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color:
                  isMine ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMine ? Colors.white70 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({required this.url, required this.content});
  final String url;
  final String content;

  @override
  Widget build(BuildContext context) {
    return ClipRoundedRect(
      radius: AppRadius.md,
      child: Image.network(
        url,
        width: 200,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 200,
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 200,
          height: 100,
          child: Center(
              child: Icon(Icons.broken_image_outlined, size: 40)),
        ),
      ),
    );
  }
}

class ClipRoundedRect extends StatelessWidget {
  const ClipRoundedRect({super.key, required this.radius, required this.child});
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child,
    );
  }
}

class _VoiceContent extends StatelessWidget {
  const _VoiceContent({
    required this.url,
    required this.durationSeconds,
    required this.isMine,
  });
  final String url;
  final int durationSeconds;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_filled_rounded,
          color: isMine ? Colors.white : Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 2,
              color: isMine
                  ? Colors.white54
                  : AppColors.lightOnSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: isMine ? Colors.white70 : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  const _ReactionsRow({
    required this.reactions,
    required this.currentUserId,
    required this.isMine,
  });
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final nonEmpty =
        reactions.entries.where((e) => e.value.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 4,
        children: nonEmpty.map((e) {
          final isReacted = e.value.contains(currentUserId);
          final emoji = _emoji(e.key);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isReacted
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: isReacted
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              '$emoji ${e.value.length}',
              style: const TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _emoji(String code) => switch (code) {
        'thumbs_up' => '👍',
        'heart' => '❤️',
        'laugh' => '😂',
        'surprised' => '😮',
        'sad' => '😢',
        'fire' => '🔥',
        _ => '👍',
      };
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.onDismiss});
  final ChatMessage message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  message.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.isRecording,
    required this.isDark,
    required this.onSend,
    required this.onPickImage,
    required this.onStartRecord,
    required this.onStopRecord,
  });

  final TextEditingController controller;
  final bool isRecording;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onStartRecord;
  final void Function(String? path, int duration) onStopRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attach Image
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: onPickImage,
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),

            // Text Field
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: isRecording ? 'جاري التسجيل...' : 'اكتب رسالة...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  isDense: true,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Voice / Send
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final hasText = controller.text.trim().isNotEmpty;
                return hasText
                    ? IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: onSend,
                      )
                    : GestureDetector(
                        onLongPressStart: (_) => onStartRecord(),
                        onLongPressEnd: (_) =>
                            onStopRecord(null, 0),
                        child: Icon(
                          isRecording ? Icons.stop_circle_rounded : Icons.mic_outlined,
                          color: isRecording
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.lightOnSurfaceVariant),
                          size: 28,
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
