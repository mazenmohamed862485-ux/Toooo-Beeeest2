// ============================================================
// referral_stats_screen.dart (standalone)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';

part 'referral_stats_screen.g.dart';

// ── Data Models ───────────────────────────────────────────────

class ReferralStatsData {
  const ReferralStatsData({
    this.totalReferrals = 0,
    this.monthlyReferrals = 0,
    this.conversionRate = 0,
    this.topReferrers = const [],
    this.monthlyTrend = const [],
  });

  final int totalReferrals;
  final int monthlyReferrals;

  /// معدل التحويل من إحالة → اشتراك فعّال (0-100)
  final double conversionRate;

  final List<ReferrerEntry> topReferrers;
  final List<MonthlyReferral> monthlyTrend;
}

class ReferrerEntry {
  const ReferrerEntry({
    required this.uid,
    required this.name,
    required this.referralCode,
    required this.referralCount,
    required this.convertedCount,
  });

  final String uid, name, referralCode;
  final int referralCount, convertedCount;

  double get conversionRate =>
      referralCount > 0 ? convertedCount / referralCount * 100 : 0;
}

class MonthlyReferral {
  const MonthlyReferral({
    required this.month,
    required this.count,
  });
  final String month;
  final int count;
}

// ── Provider ──────────────────────────────────────────────────

@riverpod
Future<ReferralStatsData> referralStats(ReferralStatsRef ref) async {
  final admin = ref.watch(mgmtAuthStateProvider).valueOrNull;
  if (admin == null) return const ReferralStatsData();

  final gas = ref.read(mgmtGasClientProvider);
  final result = await gas.post(
    action: 'GET_REFERRAL_STATS',
    data: {'uid': admin.uid},
  );

  final topRaw = result['topReferrers'] as List<dynamic>? ?? [];
  final topReferrers = topRaw.map((r) {
    final m = r as Map<String, dynamic>;
    return ReferrerEntry(
      uid: m['uid']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      referralCode: m['code']?.toString() ?? '',
      referralCount: int.tryParse(m['count']?.toString() ?? '0') ?? 0,
      convertedCount:
          int.tryParse(m['converted']?.toString() ?? '0') ?? 0,
    );
  }).toList();

  final trendRaw = result['monthlyTrend'] as List<dynamic>? ?? [];
  final trend = trendRaw.map((t) {
    final m = t as Map<String, dynamic>;
    return MonthlyReferral(
      month: m['month']?.toString() ?? '',
      count: int.tryParse(m['count']?.toString() ?? '0') ?? 0,
    );
  }).toList();

  return ReferralStatsData(
    totalReferrals:
        int.tryParse(result['totalReferrals']?.toString() ?? '0') ?? 0,
    monthlyReferrals:
        int.tryParse(result['monthlyReferrals']?.toString() ?? '0') ?? 0,
    conversionRate:
        double.tryParse(result['conversionRate']?.toString() ?? '0') ?? 0,
    topReferrers: topReferrers,
    monthlyTrend: trend,
  );
}

// ── Screen ─────────────────────────────────────────────────────

class ReferralStatsScreen extends ConsumerWidget {
  const ReferralStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(referralStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات الإحالة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(referralStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('خطأ في التحميل: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(referralStatsProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(referralStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── Overview Cards ──────────────────────────────
              Row(
                children: [
                  _StatCard(
                    label: 'إجمالي الإحالات',
                    value: '${stats.totalReferrals}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.brandGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StatCard(
                    label: 'هذا الشهر',
                    value: '${stats.monthlyReferrals}',
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // معدل التحويل
              _ConversionCard(
                rate: stats.conversionRate,
                isDark: isDark,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Monthly Trend ───────────────────────────────
              if (stats.monthlyTrend.isNotEmpty) ...[
                Text(
                  'الإحالات الشهرية',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                _MonthlyTrendChart(
                  trend: stats.monthlyTrend,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Top Referrers ────────────────────────────────
              if (stats.topReferrers.isNotEmpty) ...[
                Text(
                  'أكثر المحيلين',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                _TopReferrersList(
                  referrers: stats.topReferrers,
                  isDark: isDark,
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
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
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversionCard extends StatelessWidget {
  const _ConversionCard({required this.rate, required this.isDark});
  final double rate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = rate >= 50
        ? AppColors.success
        : rate >= 25
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: (rate / 100).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: AppColors.lightBorder,
                  color: color,
                ),
              ),
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معدل التحويل',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نسبة الإحالات التي تحوّلت لاشتراكات فعّالة',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart(
      {required this.trend, required this.isDark});
  final List<MonthlyReferral> trend;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final maxVal = trend
        .map((t) => t.count)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: trend.map((t) {
            final ratio = maxVal > 0 ? t.count / maxVal : 0.0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${t.count}',
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 24,
                  height: (90 * ratio).clamp(4.0, 90.0),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen
                        .withOpacity(0.4 + 0.6 * ratio),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.month.length > 3 ? t.month.substring(0, 3) : t.month,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopReferrersList extends StatelessWidget {
  const _TopReferrersList(
      {required this.referrers, required this.isDark});
  final List<ReferrerEntry> referrers;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: referrers.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final isLast = i == referrers.length - 1;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _rankColor(i).withOpacity(0.15),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _rankColor(i),
                    ),
                  ),
                ),
                title: Text(r.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'الكود: ${r.referralCode}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.referralCount} إحالة',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandGreen,
                      ),
                    ),
                    Text(
                      '${r.convertedCount} مشترك',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.lightOnSurfaceVariant),
                    ),
                  ],
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
    );
  }

  Color _rankColor(int rank) => switch (rank) {
        0 => const Color(0xFFFFD700), // ذهبي
        1 => const Color(0xFFC0C0C0), // فضي
        2 => const Color(0xFFCD7F32), // برونزي
        _ => AppColors.lightOnSurfaceVariant,
      };
}
