// ============================================================
// TO Best Management — mgmt_shell_screen.dart
// Shell مع NavigationRail (Tablet) أو BottomNav (Phone)
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import '../../auth/presentation/providers/mgmt_auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/infrastructure/gas_client.dart';
import '../providers/dashboard_provider.dart';

class MgmtShellScreen extends ConsumerWidget {
  const MgmtShellScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;
    final isTablet = MediaQuery.of(context).size.width > 600;

    // بناء قائمة التنقل بحسب الدور
    final navItems = _buildNavItems(user?.role ?? '');

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _indexFromRoute(location, navItems),
              onDestinationSelected: (i) =>
                  context.go(navItems[i].route),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Image.asset(
                  'assets/images/tom_icon_light.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 36,
                    color: AppColors.accent2,
                  ),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () =>
                          ref.read(mgmtAuthStateProvider.notifier).logout(),
                      tooltip: 'تسجيل الخروج',
                    ),
                  ),
                ),
              ),
              destinations: navItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFromRoute(location, navItems),
        onTap: (i) => context.go(navItems[i].route),
        items: navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  List<_NavItem> _buildNavItems(String role) {
    final items = <_NavItem>[
      _NavItem(
        label: 'الرئيسية',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        route: AppRoutes.mgmtDashboard,
      ),
      _NavItem(
        label: 'المستخدمون',
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        route: AppRoutes.mgmtUsers,
      ),
    ];

    // الاشتراكات — MANAGER و SUBSCRIPTIONS
    if (role == AppRoles.manager || role == AppRoles.subscriptions) {
      items.add(_NavItem(
        label: 'الاشتراكات',
        icon: Icons.card_membership_outlined,
        activeIcon: Icons.card_membership_rounded,
        route: AppRoutes.mgmtSubscriptionRequests,
      ));
    }

    // طلبات البرامج — MANAGER و SUPPORT
    if (role == AppRoles.manager || role == AppRoles.support) {
      items.add(_NavItem(
        label: 'البرامج',
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center_rounded,
        route: AppRoutes.mgmtProgramRequests,
      ));
    }

    items.add(_NavItem(
      label: 'الشات',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      route: AppRoutes.mgmtChat,
    ));

    // MANAGER فقط
    if (role == AppRoles.manager) {
      items.addAll([
        _NavItem(
          label: 'الخطط',
          icon: Icons.layers_outlined,
          activeIcon: Icons.layers_rounded,
          route: AppRoutes.mgmtSubscriptionPlans,
        ),
        _NavItem(
          label: 'الإعدادات',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          route: AppRoutes.mgmtConnectionSettings,
        ),
      ]);
    }

    return items;
  }

  int _indexFromRoute(String location, List<_NavItem> items) {
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}

// ============================================================
// dashboard_screen.dart — لوحة التحكم الرئيسية
// ============================================================


/// لوحة التحكم الرئيسية
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
          // تحديث البيانات
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRefresh(
          error: e.toString(),
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── Stats Grid ────────────────────────────────
              _StatsGrid(stats: stats, isDark: isDark),
              const SizedBox(height: AppSpacing.xl),

              // ── طلبات الاشتراك المعلقة ─────────────────
              if (stats.pendingSubscriptions > 0)
                _AlertCard(
                  icon: Icons.pending_actions_rounded,
                  title: '${stats.pendingSubscriptions} طلب اشتراك معلق',
                  subtitle: 'يحتاج مراجعة',
                  color: AppColors.warning,
                  onTap: () =>
                      context.go(AppRoutes.mgmtSubscriptionRequests),
                ),

              const SizedBox(height: AppSpacing.md),

              // ── طلبات البرامج المعلقة ──────────────────
              if (stats.pendingProgramRequests > 0)
                _AlertCard(
                  icon: Icons.fitness_center_rounded,
                  title: '${stats.pendingProgramRequests} طلب برنامج',
                  subtitle: 'ينتظر الرد',
                  color: AppColors.info,
                  onTap: () =>
                      context.go(AppRoutes.mgmtProgramRequests),
                ),

              const SizedBox(height: AppSpacing.xl),

              // ── رسم بياني للنشاط ──────────────────────
              _ActivityChart(stats: stats, isDark: isDark),

              const SizedBox(height: AppSpacing.xl),

              // ── أحدث المستخدمين ───────────────────────
              _RecentUsersList(users: stats.recentUsers, isDark: isDark),
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

// ── Dashboard Widgets ─────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.isDark});
  final DashboardStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
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
        ),
        _StatCard(
          label: 'اشتراكات نشطة',
          value: '${stats.activeSubscriptions}',
          icon: Icons.card_membership_rounded,
          color: AppColors.success,
          isDark: isDark,
        ),
        _StatCard(
          label: 'مستخدمون جدد (شهر)',
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
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
              ),
            ],
          ),
        ],
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
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.stats, required this.isDark});
  final DashboardStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'نشاط المستخدمين (آخر 7 أيام)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final val = stats.dailyActiveUsers.length > i
                    ? stats.dailyActiveUsers[i]
                    : 0;
                final max = stats.dailyActiveUsers.isNotEmpty
                    ? stats.dailyActiveUsers.reduce((a, b) => a > b ? a : b)
                    : 1;
                final ratio = max > 0 ? val / max : 0.0;
                final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 100 * ratio + 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7 + 0.3 * ratio),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[i],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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

class _RecentUsersList extends StatelessWidget {
  const _RecentUsersList(
      {required this.users, required this.isDark});
  final List<RecentUser> users;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أحدث المسجلين',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...users.map((u) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                child: Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(u.name),
              subtitle: Text(u.email),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(u.subscriptionStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _statusLabel(u.subscriptionStatus),
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(u.subscriptionStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Color _statusColor(String s) => switch (s) {
        'active' => AppColors.success,
        'pending' => AppColors.warning,
        'rejected' => AppColors.error,
        'expired' => AppColors.error,
        _ => AppColors.lightOnSurfaceVariant,
      };

  String _statusLabel(String s) => switch (s) {
        'active' => 'نشط',
        'pending' => 'معلق',
        'rejected' => 'مرفوض',
        'expired' => 'منتهي',
        _ => 'بدون',
      };
}

class _ErrorRefresh extends StatelessWidget {
  const _ErrorRefresh({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('فشل تحميل البيانات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
