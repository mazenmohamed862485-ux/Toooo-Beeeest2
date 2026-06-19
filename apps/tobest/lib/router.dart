// ============================================================
// TO Best — apps/tobest/lib/router.dart
// GoRouter: كل المسارات + Auth Guards + Redirect Logic
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared/config/app_config.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';
import 'features/auth/presentation/screens/subscription_pending_screen.dart';
import 'features/auth/presentation/screens/google_signin_completion_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/workout/presentation/screens/workout_screen.dart';
import 'features/nutrition/presentation/screens/nutrition_screen.dart';
import 'features/progress/presentation/screens/progress_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/chat/presentation/screens/conversation_screen.dart';
import 'features/ai_coach/presentation/screens/ai_coach_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/screens/change_password_screen.dart';
import 'features/home/presentation/screens/main_shell_screen.dart';

/// بناء GoRouter مع ProviderRef للاستماع لحالة المصادقة
GoRouter appRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: RouterNotifier(ref),
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      // ── Splash ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (ctx, state) => const SplashScreen(),
      ),

      // ── Auth Routes ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (ctx, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (ctx, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            email: extra['email'] as String? ?? '',
            purpose: extra['purpose'] as OtpPurpose? ?? OtpPurpose.resetPassword,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.googleSignInCompletion,
        name: 'google-signin-completion',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return GoogleSignInCompletionScreen(
            googleData: extra,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.guestMode,
        name: 'guest',
        builder: (ctx, state) => const GuestScreen(),
      ),

      // ── Subscription Status ───────────────────────────────
      GoRoute(
        path: AppRoutes.subscriptionPending,
        name: 'subscription-pending',
        builder: (ctx, state) => const SubscriptionPendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionRejected,
        name: 'subscription-rejected',
        builder: (ctx, state) {
          final reason = state.uri.queryParameters['reason'] ?? '';
          return SubscriptionRejectedScreen(reason: reason);
        },
      ),
      GoRoute(
        path: AppRoutes.subscriptionExpired,
        name: 'subscription-expired',
        builder: (ctx, state) => const SubscriptionExpiredScreen(),
      ),

      // ── Main Shell (Bottom Nav) ───────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (ctx, state) => _noTransitionPage(
              state,
              const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.workout,
            name: 'workout',
            pageBuilder: (ctx, state) => _securedPage(
              state,
              const WorkoutScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.nutrition,
            name: 'nutrition',
            pageBuilder: (ctx, state) => _securedPage(
              state,
              const NutritionScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.progress,
            name: 'progress',
            pageBuilder: (ctx, state) => _noTransitionPage(
              state,
              const ProgressScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.chat,
            name: 'chat',
            pageBuilder: (ctx, state) => _noTransitionPage(
              state,
              const ChatScreen(),
            ),
          ),
        ],
      ),

      // ── Standalone Routes (خارج Shell) ───────────────────
      GoRoute(
        path: AppRoutes.conversation,
        name: 'conversation',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ConversationScreen(
            roomId: extra['roomId'] as String? ?? '',
            participantName: extra['name'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.aiCoach,
        name: 'ai-coach',
        builder: (ctx, state) => const AiCoachScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (ctx, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change-password',
        builder: (ctx, state) => const ChangePasswordScreen(),
      ),
    ],

    // ── Error Handler ─────────────────────────────────────
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Text('الصفحة غير موجودة: ${state.error}'),
      ),
    ),
  );
}

/// منطق الـ Redirect الرئيسي
String? _redirect(WidgetRef ref, GoRouterState state) {
  final authState = ref.read(authStateProvider);
  final path = state.matchedLocation;

  return authState.when(
    loading: () => null, // لا تعديل خلال التحميل

    error: (_, __) => AppRoutes.login,

    data: (user) {
      // ── Splash — غير مكتمل بعد ─────────────────────────
      if (path == AppRoutes.splash) return null;

      // ── Public Routes (لا تحتاج تسجيل دخول) ─────────────
      final publicRoutes = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.otp,
        AppRoutes.guestMode,
      };

      if (user == null) {
        // غير مسجّل — فقط اسمح بالـ Public Routes
        return publicRoutes.contains(path) ? null : AppRoutes.login;
      }

      // ── مستخدم مسجّل ─────────────────────────────────────

      // إذا كان على صفحة تسجيل الدخول وهو مسجّل، وجِّهه
      if (publicRoutes.contains(path)) {
        return _getHomeRoute(user.role, user.subscription.status);
      }

      // ── فحص الدور — TO Best فقط ──────────────────────────
      if (!AppConfig.tobest_allowedRoles.contains(user.role)) {
        // دور خاطئ (MANAGER/SUPPORT/SUBSCRIPTIONS) — أخرجه
        return AppRoutes.login;
      }

      // ── فحص حالة الاشتراك ────────────────────────────────
      final subStatus = user.subscription.status;
      final subscriptionRoutes = {
        AppRoutes.subscriptionPending,
        AppRoutes.subscriptionRejected,
        AppRoutes.subscriptionExpired,
      };

      if (subStatus == SubscriptionStatus.pending &&
          !subscriptionRoutes.contains(path) &&
          path != AppRoutes.settings &&
          path != AppRoutes.changePassword) {
        return AppRoutes.subscriptionPending;
      }

      if (subStatus == SubscriptionStatus.rejected &&
          !subscriptionRoutes.contains(path) &&
          path != AppRoutes.settings) {
        return '${AppRoutes.subscriptionRejected}'
            '?reason=${Uri.encodeComponent(user.subscription.rejectionReason)}';
      }

      if (subStatus == SubscriptionStatus.expired &&
          !subscriptionRoutes.contains(path) &&
          path != AppRoutes.settings) {
        return AppRoutes.subscriptionExpired;
      }

      // كل شيء تمام — لا إعادة توجيه
      return null;
    },
  );
}

/// الصفحة الرئيسية بحسب الدور وحالة الاشتراك
String _getHomeRoute(String role, String subscriptionStatus) {
  if (subscriptionStatus == SubscriptionStatus.pending) {
    return AppRoutes.subscriptionPending;
  }
  if (subscriptionStatus == SubscriptionStatus.rejected) {
    return AppRoutes.subscriptionRejected;
  }
  if (subscriptionStatus == SubscriptionStatus.expired) {
    return AppRoutes.subscriptionExpired;
  }
  return AppRoutes.home;
}

// ── Page Builders ─────────────────────────────────────────────

/// صفحة بدون انتقال (Bottom Nav tabs)
NoTransitionPage<void> _noTransitionPage(
    GoRouterState state, Widget child) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

/// صفحة محمية بـ FLAG_SECURE
Page<void> _securedPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: _SecuredWrapper(child: child),
    transitionsBuilder: (ctx, animation, _, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Wrapper يفعِّل FLAG_SECURE عند الدخول ويوقفه عند الخروج
class _SecuredWrapper extends StatefulWidget {
  const _SecuredWrapper({required this.child});
  final Widget child;

  @override
  State<_SecuredWrapper> createState() => _SecuredWrapperState();
}

class _SecuredWrapperState extends State<_SecuredWrapper> {
  @override
  void initState() {
    super.initState();
    FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  void dispose() {
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Router Notifier (للتحديث عند تغيير Auth State) ───────────

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  final WidgetRef _ref;
}
