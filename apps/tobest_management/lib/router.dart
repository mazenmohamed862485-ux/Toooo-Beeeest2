// ============================================================
// TO Best Management — lib/router.dart
// GoRouter مع فحص الأدوار الإدارية
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/config/app_config.dart';
import 'features/auth/presentation/screens/mgmt_login_screen.dart';
import 'features/auth/presentation/screens/mgmt_splash_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/user_management/presentation/screens/users_screen.dart';
import 'features/user_management/presentation/screens/user_profile_screen.dart';
import 'features/subscription_requests/presentation/screens/subscription_requests_screen.dart';
import 'features/program_requests/presentation/screens/program_requests_screen.dart';
import 'features/chat/presentation/screens/mgmt_chat_screen.dart';
import 'features/subscription_plans/presentation/screens/subscription_plans_screen.dart';
import 'features/connection_settings/presentation/screens/connection_settings_screen.dart';
import 'features/referral_stats/presentation/screens/referral_stats_screen.dart';
import 'features/auth/presentation/providers/mgmt_auth_provider.dart';
import 'features/dashboard/presentation/screens/mgmt_shell_screen.dart';

GoRouter managementRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: MgmtRouterNotifier(ref),
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const MgmtSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const MgmtLoginScreen(),
      ),

      // ── Shell مع Side Navigation ──────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => MgmtShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.mgmtDashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.mgmtUsers,
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/users/:id',
            builder: (_, state) => UserProfileScreen(
              userId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.mgmtSubscriptionRequests,
            builder: (_, __) => const SubscriptionRequestsScreen(),
          ),
          GoRoute(
            path: AppRoutes.mgmtProgramRequests,
            builder: (_, __) => const ProgramRequestsScreen(),
          ),
          GoRoute(
            path: AppRoutes.mgmtChat,
            builder: (_, __) => const MgmtChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.mgmtSubscriptionPlans,
            builder: (_, __) => const SubscriptionPlansScreen(),
          ),
          GoRoute(
            path: AppRoutes.mgmtConnectionSettings,
            builder: (_, __) => const ConnectionSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.mgmtReferralStats,
            builder: (_, __) => const ReferralStatsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('صفحة غير موجودة: ${state.error}')),
    ),
  );
}

String? _redirect(WidgetRef ref, GoRouterState state) {
  final authState = ref.read(mgmtAuthStateProvider);
  final path = state.matchedLocation;

  return authState.when(
    loading: () => null,
    error: (_, __) => AppRoutes.login,
    data: (user) {
      if (path == '/splash') return null;

      if (user == null) {
        return path == AppRoutes.login ? null : AppRoutes.login;
      }

      if (path == AppRoutes.login) return AppRoutes.mgmtDashboard;

      // فحص الصلاحيات بحسب الدور
      if (!AppConfig.management_allowedRoles.contains(user.role)) {
        return AppRoutes.login;
      }

      // صفحات MANAGER فقط
      final managerOnly = {
        AppRoutes.mgmtConnectionSettings,
        AppRoutes.mgmtSubscriptionPlans,
        AppRoutes.mgmtReferralStats,
      };
      if (managerOnly.contains(path) && user.role != AppRoles.manager) {
        return AppRoutes.mgmtDashboard;
      }

      // صفحات SUBSCRIPTIONS فقط
      if (path == AppRoutes.mgmtSubscriptionRequests &&
          user.role == AppRoles.support) {
        return AppRoutes.mgmtDashboard;
      }

      return null;
    },
  );
}

class MgmtRouterNotifier extends ChangeNotifier {
  MgmtRouterNotifier(this._ref) {
    _ref.listen(mgmtAuthStateProvider, (_, __) => notifyListeners());
  }
  final WidgetRef _ref;
}
