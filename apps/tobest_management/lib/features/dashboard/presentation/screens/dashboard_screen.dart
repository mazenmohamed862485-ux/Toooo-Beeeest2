// ============================================================
// dashboard_screen.dart (standalone)
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';
import '../providers/dashboard_provider.dart';

export '../providers/dashboard_provider.dart'
    show DashboardStats, RecentUser;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لوحة التحكم'),
            if (user != null)
              Text(
                _roleLabel(user.role),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accent2,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('فشل التحميل: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardStatsProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    label: 'إجمالي المستخدمين',
                    value: '${stats.totalUsers}',
                    icon: Icons.people_rounded,
                    color: AppColors.info,
                    isDark: isDark,
                    onTap: () => context.go(AppRoutes.mgmtUsers),
                  ),
                  _StatCard(
                    label: 'اشتراكات نشطة',
                    value: '${stats.activeSubscriptions}',
                    icon: Icons.card_membership_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: () =>
                        context.go(AppRoutes.mgmtSubscriptionRequests),
                  ),
                  _StatCard(
                    label: 'مستخدمون جدد',
                    value: '${stats.newUsersThisMonth}',
                    icon: Icons.person_add_rounded,
                    color: AppColors.accent2,
                    isDark: isDark,
                  ),
                  _StatCard(
                    label: 'الإيراد الشهري',
                    value: stats.monthlyRevenue > 0
                        ? '${stats.monthlyRevenue.toStringAsFixed(0)} ر.س'
                        : '--',
                    icon: Icons.attach_money_rounded,
                    color: AppColors.brandGreen,
                    isDark: isDark,
                    onTap: () =>
                        context.go(AppRoutes.mgmtReferralStats),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Alerts
              if (stats.pendingSubscriptions > 0)
                _AlertCard(
                  icon: Icons.pending_actions_rounded,
                  title: '${stats.pendingSubscriptions} طلب اشتراك معلق',
                  subtitle: 'يحتاج مراجعة',
                  color: AppColors.warning,
                  onTap: () =>
                      context.go(AppRoutes.mgmtSubscriptionRequests),
                ),

              if (stats.pendingProgramRequests > 0) ...[
                const SizedBox(height: AppSpacing.md),
                _AlertCard(
                  icon: Icons.fitness_center_rounded,
                  title: '${stats.pendingProgramRequests} طلب برنامج',
                  subtitle: 'ينتظر الرد',
                  color: AppColors.info,
                  onTap: () =>
                      context.go(AppRoutes.mgmtProgramRequests),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Weekly Activity Bar Chart
              _WeeklyBarChart(
                  data: stats.dailyActiveUsers, isDark: isDark),

              const SizedBox(height: AppSpacing.xl),

              // Recent Users
              if (stats.recentUsers.isNotEmpty)
                _RecentUsers(
                  users: stats.recentUsers,
                  isDark: isDark,
                  onUserTap: (uid) =>
                      context.push('/users/$uid'),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        AppRoles.manager => 'مدير عام',
        AppRoles.support => 'دعم فني',
        AppRoles.subscriptions => 'مسؤول اشتراكات',
        _ => role,
      };
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sm,
          border: onTap != null
              ? Border.all(color: color.withOpacity(0.2))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.data, required this.isDark});
  final List<int> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final max = data.reduce((a, b) => a > b ? a : b);
    final days = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المستخدمون النشطون (7 أيام)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(data.length.clamp(0, 7), (i) {
                final ratio = max > 0 ? data[i] / max : 0.0;
                final accent = Theme.of(context).colorScheme.primary;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${data[i]}',
                        style: const TextStyle(fontSize: 9)),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 400 + i * 50),
                      width: 26,
                      height: (80 * ratio).clamp(4.0, 80.0),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.6 + 0.4 * ratio),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(days[i % 7],
                        style: const TextStyle(fontSize: 11)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentUsers extends StatelessWidget {
  const _RecentUsers({
    required this.users,
    required this.isDark,
    required this.onUserTap,
  });
  final List<RecentUser> users;
  final bool isDark;
  final void Function(String uid) onUserTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('أحدث المسجلين',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: users.asMap().entries.map((entry) {
              final i = entry.key;
              final u = entry.value;
              final isLast = i == users.length - 1;
              final subColor = _subColor(u.subscriptionStatus);

              return Column(
                children: [
                  ListTile(
                    onTap: () => onUserTap(u.uid),
                    leading: CircleAvatar(
                      backgroundColor: subColor.withOpacity(0.15),
                      child: Text(
                        u.name.isNotEmpty
                            ? u.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: subColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(u.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(u.email,
                        overflow: TextOverflow.ellipsis),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: subColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _subLabel(u.subscriptionStatus),
                        style: TextStyle(
                            fontSize: 11,
                            color: subColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(right: 70),
                      child: Divider(height: 1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _subColor(String s) => switch (s) {
        'active' => AppColors.success,
        'pending' => AppColors.warning,
        _ => AppColors.error,
      };

  String _subLabel(String s) => switch (s) {
        'active' => 'نشط',
        'pending' => 'معلق',
        'rejected' => 'مرفوض',
        'expired' => 'منتهي',
        _ => 'بدون',
      };
}
