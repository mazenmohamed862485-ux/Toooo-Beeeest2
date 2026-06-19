// ============================================================
// TO Best — progress/presentation/screens/progress_screen.dart
// شاشة التقدم: Heatmap + Charts + Personal Records + Health
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/data/models/workout_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import 'package:isar/isar.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final streakAsync = ref.watch(currentStreakProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: const AppBar(title: Text('تقدّمي')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Streak Card ───────────────────────────────────
          streakAsync.when(
            data: (streak) => _StreakCard(
                streak: streak, isDark: isDark, accent: accent),
            loading: () =>
                const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Activity Heatmap ──────────────────────────────
          _HeatmapSection(userId: user?.uid ?? '', isDark: isDark),

          const SizedBox(height: AppSpacing.lg),

          // ── Volume Chart ──────────────────────────────────
          _VolumeChart(userId: user?.uid ?? '', isDark: isDark, accent: accent),

          const SizedBox(height: AppSpacing.lg),

          // ── Personal Records ──────────────────────────────
          _PersonalRecordsSection(userId: user?.uid ?? '', isDark: isDark),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.isDark, required this.accent});
  final int streak;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak يوم متواصل',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(
                streak >= 30
                    ? 'إنجاز رائع! استمر 💪'
                    : streak >= 7
                        ? 'أسبوع كامل! رائع'
                        : 'واصل التمرين!',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapSection extends ConsumerWidget {
  const _HeatmapSection({required this.userId, required this.isDark});
  final String userId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<DateTime, bool>>(
      future: _loadMonthActivity(ref, userId),
      builder: (ctx, snap) {
        final data = snap.data ?? {};
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

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
              Text('نشاط هذا الشهر',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(daysInMonth, (i) {
                  final d = DateTime(now.year, now.month, i + 1);
                  final didWork = data[DateTime(d.year, d.month, d.day)] ?? false;
                  final isToday = d.day == now.day;

                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : didWork
                              ? AppColors.brandGreen
                              : (isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.heatmapNone),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: (isToday || didWork)
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.lightOnSurfaceVariant),
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<DateTime, bool>> _loadMonthActivity(
      WidgetRef ref, String userId) async {
    if (userId.isEmpty) return {};
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    final now = DateTime.now();
    final startMs =
        DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final endMs =
        DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch;

    final logs = await db.workoutSessionIsarModels
        .filter()
        .userIdEqualTo(userId)
        .dateMsGreaterThan(startMs - 1)
        .dateMsLessThan(endMs)
        .findAll();

    final result = <DateTime, bool>{};
    for (final log in logs) {
      final d = DateTime.fromMillisecondsSinceEpoch(log.dateMs);
      result[DateTime(d.year, d.month, d.day)] = true;
    }
    return result;
  }
}

class _VolumeChart extends ConsumerWidget {
  const _VolumeChart({
    required this.userId,
    required this.isDark,
    required this.accent,
  });
  final String userId;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<FlSpot>>(
      future: _loadVolumeData(ref, userId),
      builder: (ctx, snap) {
        final spots = snap.data ?? [];

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
              Text('حجم التدريب (آخر 4 أسابيع)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 160,
                child: spots.isEmpty
                    ? const Center(child: Text('لا توجد بيانات كافية'))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: accent,
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                show: true,
                                color: accent.withOpacity(0.1),
                              ),
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<FlSpot>> _loadVolumeData(
      WidgetRef ref, String userId) async {
    if (userId.isEmpty) return [];
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 28))
        .millisecondsSinceEpoch;

    final logs = await db.workoutSessionIsarModels
        .filter()
        .userIdEqualTo(userId)
        .dateMsGreaterThan(cutoff)
        .sortByDateMs()
        .findAll();

    return logs.asMap().entries.map((e) {
      final session = e.value.toEntity();
      double vol = 0;
      for (final ex in session.exercises) {
        for (final s in ex.sets) {
          vol += s.weight * s.reps;
        }
      }
      return FlSpot(e.key.toDouble(), vol);
    }).toList();
  }
}

class _PersonalRecordsSection extends ConsumerWidget {
  const _PersonalRecordsSection(
      {required this.userId, required this.isDark});
  final String userId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<_PR>>(
      future: _loadPRs(ref, userId),
      builder: (ctx, snap) {
        final prs = snap.data ?? [];
        if (prs.isEmpty) return const SizedBox.shrink();

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
              Text('أرقامك القياسية',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: AppSpacing.lg),
              ...prs.map((pr) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(pr.exerciseName)),
                        Text(
                          '${pr.weight}kg × ${pr.reps}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1RM: ${pr.oneRM.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.lightOnSurfaceVariant),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<List<_PR>> _loadPRs(WidgetRef ref, String userId) async {
    if (userId.isEmpty) return [];
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;

    final logs = await db.exerciseLogIsarModels
        .filter()
        .userIdEqualTo(userId)
        .sortByBest1RMDesc()
        .distinctByExerciseName()
        .limit(10)
        .findAll();

    return logs.map((l) => _PR(
          exerciseName: l.exerciseName,
          weight: l.bestWeight,
          reps: l.bestReps,
          oneRM: l.best1RM,
        )).toList();
  }
}

class _PR {
  const _PR({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.oneRM,
  });
  final String exerciseName;
  final double weight, oneRM;
  final int reps;
}

// ============================================================
// chat/presentation/screens/chat_screen.dart
// ============================================================

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
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Coach',
            onPressed: () => context.push(AppRoutes.aiCoach),
          ),
        ],
      ),
      body: convsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: AppColors.lightBorder),
                  const SizedBox(height: 16),
                  const Text('لا توجد محادثات بعد'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.aiCoach),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('تحدث مع AI Coach'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(userConversationsProvider),
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (ctx, i) {
                final conv = conversations[i];
                final otherName = conv.participantNames.entries
                    .firstWhere(
                      (e) => e.key != user?.uid,
                      orElse: () =>
                          MapEntry('?', 'محادثة'),
                    )
                    .value;

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                        child: Text(
                          otherName.isNotEmpty
                              ? otherName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${conv.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(otherName,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: conv.lastMessage != null
                      ? Text(
                          conv.lastMessage!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: conv.lastMessageAt != null
                      ? Text(
                          conv.lastMessageAt!.smartDate,
                          style: const TextStyle(fontSize: 11),
                        )
                      : null,
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
