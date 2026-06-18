// ============================================================
// TO Best — home/presentation/screens/main_shell_screen.dart
// Bottom Navigation Shell
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';

/// Shell الرئيسي مع Bottom Navigation
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFromRoute(location),
        onTap: (index) => _navigateTo(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center_rounded),
            label: 'تمريني',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'تغذيتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'تقدمي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'الشات',
          ),
        ],
      ),
    );
  }

  int _indexFromRoute(String route) {
    if (route.startsWith(AppRoutes.workout)) return 1;
    if (route.startsWith(AppRoutes.nutrition)) return 2;
    if (route.startsWith(AppRoutes.progress)) return 3;
    if (route.startsWith(AppRoutes.chat)) return 4;
    return 0;
  }

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.workout);
      case 2:
        context.go(AppRoutes.nutrition);
      case 3:
        context.go(AppRoutes.progress);
      case 4:
        context.go(AppRoutes.chat);
    }
  }
}

// ============================================================
// home_screen.dart — شاشة الرئيسية
// ============================================================

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:intl/intl.dart';
import '../providers/home_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// شاشة الرئيسية
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final streakAsync = ref.watch(currentStreakProvider);
    final todayAsync = ref.watch(todayWorkoutProvider);
    final homeData = ref.watch(homeDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────
          SliverAppBar(
            floating: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(now.hour),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  user?.name ?? 'مرحباً',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            actions: [
              // Streak Badge
              streakAsync.when(
                data: (streak) => streak > 0
                    ? Padding(
                        padding:
                            const EdgeInsets.only(right: AppSpacing.sm),
                        child: _StreakChip(days: streak),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // Settings
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Date ──────────────────────────────────────
                Text(
                  DateFormat('EEEE, d MMMM', 'ar').format(now),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Today's Workout Card ───────────────────────
                todayAsync.when(
                  loading: () => const _ShimmerCard(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (today) => _TodayWorkoutCard(
                    today: today,
                    isDark: isDark,
                    accent: accent,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Quick Stats Row ───────────────────────────
                homeData.when(
                  loading: () => const _ShimmerCard(height: 80),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => _QuickStatsRow(
                    data: data,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── AI Coach Banner ───────────────────────────
                _AiCoachBanner(isDark: isDark, accent: accent),

                const SizedBox(height: AppSpacing.lg),

                // ── Weekly Heatmap ────────────────────────────
                _WeeklyOverview(isDark: isDark),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'مساء الخير 🌤️';
    return 'مساء النور 🌙';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({
    required this.today,
    required this.isDark,
    required this.accent,
  });

  final TodayWorkout? today;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (today == null) return const SizedBox.shrink();

    if (today!.isRestDay) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brandGreen.withOpacity(0.15),
              AppColors.brandGreenLight.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.brandGreen.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Text('💤', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يوم الراحة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandGreen,
                        ),
                  ),
                  Text(
                    'جسمك يتعافى ويبني العضلات',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.go(AppRoutes.workout),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent,
              accent.withOpacity(0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تمرين اليوم',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              today!.sessionName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${today!.exercises.length} تمرين',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  'ابدأ التمرين ←',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.data, required this.isDark});
  final HomeData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.directions_walk_rounded,
          value: '${data.todaySteps}',
          label: 'خطوة',
          color: AppColors.info,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.md),
        _StatItem(
          icon: Icons.local_fire_department_rounded,
          value: '${data.todayCalories}',
          label: 'سعرة',
          color: AppColors.warning,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.md),
        _StatItem(
          icon: Icons.bedtime_rounded,
          value: data.lastSleepHours > 0
              ? '${data.lastSleepHours}h'
              : '--',
          label: 'نوم',
          color: AppColors.accent2,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiCoachBanner extends StatelessWidget {
  const _AiCoachBanner({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.aiCoach),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accent.withOpacity(0.3)),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: accent),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Coach',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'اسأل مدربك الذكي عن أي شيء',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _WeeklyOverview extends StatelessWidget {
  const _WeeklyOverview({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    final today = DateTime.now().weekday % 7; // 0=Sun

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
            'الأسبوع',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i == today;
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : (isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        days[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isToday ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}
