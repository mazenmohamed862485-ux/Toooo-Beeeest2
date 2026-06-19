// ============================================================
// users_screen.dart — قائمة المستخدمين مع بحث وفلترة
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';

part 'users_screen.g.dart';

// ── Provider ──────────────────────────────────────────────────

class UserSummary {
  const UserSummary({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.subscriptionStatus,
    required this.program,
    required this.createdAt,
  });
  final String uid, name, email, role, status, subscriptionStatus, program;
  final DateTime createdAt;
}

@riverpod
Future<List<UserSummary>> allUsers(
  AllUsersRef ref, {
  String search = '',
  String filterRole = '',
  String filterSub = '',
}) async {
  final user = ref.watch(mgmtAuthStateProvider).valueOrNull;
  if (user == null) return [];

  final gas = ref.read(mgmtGasClientProvider);
  final result = await gas.post(
    action: 'GET_ALL_USERS',
    data: {
      'uid': user.uid,
      if (search.isNotEmpty) 'search': search,
      if (filterRole.isNotEmpty) 'role': filterRole,
      if (filterSub.isNotEmpty) 'subStatus': filterSub,
    },
  );

  final list = result['users'] as List<dynamic>? ?? [];
  return list.map((u) {
    final m = u as Map<String, dynamic>;
    return UserSummary(
      uid: m['uid']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      role: m['role']?.toString() ?? 'TRAINEE',
      status: m['status']?.toString() ?? 'active',
      subscriptionStatus: m['subscriptionStatus']?.toString() ?? 'none',
      program: m['program']?.toString() ?? '',
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }).toList();
}

// ── Screen ────────────────────────────────────────────────────

class UsersScreen extends HookConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final searchText = useState('');
    final filterRole = useState('');
    final filterSub = useState('');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final usersAsync = ref.watch(allUsersProvider(
      search: searchText.value,
      filterRole: filterRole.value,
      filterSub: filterSub.value,
    ));

    useEffect(() {
      void listener() {
        searchText.value = searchCtrl.text;
      }
      searchCtrl.addListener(listener);
      return () => searchCtrl.removeListener(listener);
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: searchText.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          searchText.value = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SubFilterChip(
                  label: 'الكل',
                  selected: filterSub.value.isEmpty,
                  onTap: () => filterSub.value = '',
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                _SubFilterChip(
                  label: 'نشط',
                  selected: filterSub.value == 'active',
                  onTap: () => filterSub.value = 'active',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _SubFilterChip(
                  label: 'معلق',
                  selected: filterSub.value == 'pending',
                  onTap: () => filterSub.value = 'pending',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _SubFilterChip(
                  label: 'منتهي',
                  selected: filterSub.value == 'expired',
                  onTap: () => filterSub.value = 'expired',
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                _SubFilterChip(
                  label: 'مدربون',
                  selected: filterRole.value == 'COACH',
                  onTap: () => filterRole.value =
                      filterRole.value == 'COACH' ? '' : 'COACH',
                  color: AppColors.accent2,
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: usersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off_rounded,
                            size: 64, color: AppColors.lightBorder),
                        const SizedBox(height: 12),
                        Text('لا توجد نتائج',
                            style:
                                Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allUsersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    itemBuilder: (ctx, i) => _UserTile(
                      user: users[i],
                      isDark: isDark,
                      onTap: () => context.push(
                        '/users/${users[i].uid}',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile(
      {required this.user, required this.isDark, required this.onTap});
  final UserSummary user;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subColor = _subColor(user.subscriptionStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: subColor.withOpacity(0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: subColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${user.email} • ${user.program.isNotEmpty ? user.program : "—"}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: subColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                _subLabel(user.subscriptionStatus),
                style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.role == 'COACH' ? 'مدرب' : 'مستخدم',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Color _subColor(String s) => switch (s) {
        'active' => AppColors.success,
        'pending' => AppColors.warning,
        'rejected' || 'expired' => AppColors.error,
        _ => AppColors.lightOnSurfaceVariant,
      };

  String _subLabel(String s) => switch (s) {
        'active' => 'نشط',
        'pending' => 'معلق',
        'rejected' => 'مرفوض',
        'expired' => 'منتهي',
        _ => 'بدون',
      };
}

class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: selected ? color : AppColors.lightBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : null,
            fontWeight: selected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
