// ============================================================
// TO Best — chat/presentation/screens/chat_screen.dart
// شاشة قائمة المحادثات
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/extensions.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// شاشة قائمة المحادثات
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final convsAsync = ref.watch(userConversationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشات'),
        actions: [
          // AI Coach Button
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Coach',
            onPressed: () => context.push(AppRoutes.aiCoach),
          ),
        ],
      ),
      body: convsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('$e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(userConversationsProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return _EmptyState(isDark: isDark);
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(userConversationsProvider),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 70,
              ),
              itemBuilder: (ctx, i) {
                final conv = conversations[i];

                // اسم المشارك الآخر
                final otherName = conv.participantNames.entries
                    .firstWhere(
                      (e) => e.key != user?.uid,
                      orElse: () => const MapEntry('?', 'محادثة'),
                    )
                    .value;

                final lastMsg = conv.lastMessage;
                final hasUnread = conv.unreadCount > 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                        child: Text(
                          otherName.isNotEmpty
                              ? otherName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                conv.unreadCount > 9
                                    ? '9+'
                                    : '${conv.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    otherName,
                    style: TextStyle(
                      fontWeight: hasUnread
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: lastMsg != null
                      ? Text(
                          lastMsg.isDeleted
                              ? 'تم حذف هذه الرسالة'
                              : lastMsg.messageType == 'image'
                                  ? '📷 صورة'
                                  : lastMsg.messageType == 'voice'
                                      ? '🎤 رسالة صوتية'
                                      : lastMsg.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : null,
                          ),
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (conv.lastMessageAt != null)
                        Text(
                          conv.lastMessageAt!.smartDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? Theme.of(context).colorScheme.primary
                                : (isDark
                                    ? AppColors.darkOnSurfaceVariant
                                    : AppColors.lightOnSurfaceVariant),
                          ),
                        ),
                      if (hasUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => context.push(
                    AppRoutes.conversation,
                    extra: {
                      'roomId': conv.id,
                      'name': otherName,
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 72,
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightBorder,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'لا توجد محادثات بعد',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'سيظهر هنا تواصلك مع مدربك',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.aiCoach),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('تحدث مع AI Coach'),
          ),
        ],
      ),
    );
  }
}
