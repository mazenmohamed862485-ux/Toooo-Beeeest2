// ============================================================
// TO Best Management — chat/presentation/screens/mgmt_chat_screen.dart
// شاشة الشات الإداري
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/utils/extensions.dart';
import '../../auth/presentation/providers/mgmt_auth_provider.dart';

/// شاشة الشات في تطبيق الإدارة
///
/// يعرض كل المحادثات حسب الدور:
/// - MANAGER: كل المحادثات
/// - SUPPORT: محادثاته مع المستخدمين
/// - SUBSCRIPTIONS: محادثات الاشتراكات فقط
class MgmtChatScreen extends ConsumerWidget {
  const MgmtChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشات'),
        actions: [
          // فتح محادثة جديدة مع مستخدم
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'محادثة جديدة',
            onPressed: () => _showNewChatDialog(context, ref),
          ),
        ],
      ),
      body: FutureBuilder<List<_ConvItem>>(
        future: _loadRooms(ref, admin?.uid ?? '', admin?.role ?? ''),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
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
                    'لا توجد محادثات',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستظهر هنا محادثاتك مع المستخدمين',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 70),
            itemBuilder: (c, i) {
              final room = rooms[i];
              final hasUnread = room.unreadCount > 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accent2.withOpacity(0.15),
                      child: Text(
                        room.otherName.isNotEmpty
                            ? room.otherName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent2,
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
                              room.unreadCount > 9
                                  ? '9+'
                                  : '${room.unreadCount}',
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
                  room.otherName,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                subtitle: room.lastMessage.isNotEmpty
                    ? Text(
                        room.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              hasUnread ? FontWeight.w600 : null,
                          color: hasUnread ? AppColors.accent2 : null,
                        ),
                      )
                    : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (room.lastAt != null)
                      Text(
                        room.lastAt!.smartDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.accent2
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
                        decoration: const BoxDecoration(
                          color: AppColors.accent2,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  // التوجيه لشاشة المحادثة
                  context.push(
                    '/chat/room/${room.id}',
                    extra: {
                      'roomId': room.id,
                      'name': room.otherName,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_ConvItem>> _loadRooms(
    WidgetRef ref,
    String uid,
    String role,
  ) async {
    if (uid.isEmpty) return [];

    try {
      final result = await ref.read(mgmtGasClientProvider).post(
        action: 'GET_ROOMS',
        data: {'uid': uid, 'role': role},
      );

      final rooms = result['rooms'] as List<dynamic>? ?? [];
      return rooms.map((r) {
        final m = r as Map<String, dynamic>;
        DateTime? lastAt;
        try {
          final ts = m['lastMessageAt'];
          if (ts != null) {
            if (ts is int) {
              lastAt = DateTime.fromMillisecondsSinceEpoch(ts);
            } else {
              lastAt = DateTime.tryParse(ts.toString());
            }
          }
        } catch (_) {}

        return _ConvItem(
          id: m['id']?.toString() ?? '',
          otherName: m['otherName']?.toString() ??
              m['participantName']?.toString() ??
              'محادثة',
          lastMessage: m['lastMessage']?.toString() ?? '',
          unreadCount:
              int.tryParse(m['unread']?.toString() ?? '0') ?? 0,
          lastAt: lastAt,
        );
      }).where((r) => r.id.isNotEmpty).toList()
        ..sort((a, b) {
          if (a.lastAt == null && b.lastAt == null) return 0;
          if (a.lastAt == null) return 1;
          if (b.lastAt == null) return -1;
          return b.lastAt!.compareTo(a.lastAt!);
        });
    } catch (_) {
      return [];
    }
  }

  Future<void> _showNewChatDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final admin = ref.read(mgmtAuthStateProvider).valueOrNull;
    if (admin == null) return;

    final emailCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('محادثة جديدة'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'بريد المستخدم أو معرّفه',
            hintText: 'user@example.com أو UID',
            prefixIcon: Icon(Icons.person_search_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, emailCtrl.text.trim()),
            child: const Text('بدء المحادثة'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final gas = ref.read(mgmtGasClientProvider);
      final response = await gas.post(
        action: 'START_CHAT',
        data: {'uid': admin.uid, 'targetEmail': result},
      );

      final roomId = response['roomId']?.toString() ?? '';
      if (roomId.isNotEmpty && context.mounted) {
        context.push(
          '/chat/room/$roomId',
          extra: {'roomId': roomId, 'name': result},
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// بيانات محادثة مبسّطة للعرض في القائمة
class _ConvItem {
  const _ConvItem({
    required this.id,
    required this.otherName,
    required this.lastMessage,
    required this.unreadCount,
    this.lastAt,
  });

  final String id;
  final String otherName;
  final String lastMessage;
  final int unreadCount;
  final DateTime? lastAt;
}
