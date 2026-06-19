// ============================================================
// TO Best Management — mgmt_shell_screen.dart
// Shell مع NavigationRail (Tablet) أو BottomNav (Phone)
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';

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

