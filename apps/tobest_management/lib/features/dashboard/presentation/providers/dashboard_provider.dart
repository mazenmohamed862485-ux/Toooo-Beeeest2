// ============================================================
// dashboard_provider.dart
// ============================================================

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/infrastructure/gas_client.dart';
import '../../../auth/presentation/providers/mgmt_auth_provider.dart';

part 'dashboard_provider.g.dart';

class DashboardStats {
  const DashboardStats({
    this.totalUsers = 0,
    this.activeSubscriptions = 0,
    this.newUsersThisMonth = 0,
    this.monthlyRevenue = 0,
    this.pendingSubscriptions = 0,
    this.pendingProgramRequests = 0,
    this.dailyActiveUsers = const [],
    this.recentUsers = const [],
  });

  final int totalUsers;
  final int activeSubscriptions;
  final int newUsersThisMonth;
  final double monthlyRevenue;
  final int pendingSubscriptions;
  final int pendingProgramRequests;
  final List<int> dailyActiveUsers;
  final List<RecentUser> recentUsers;
}

class RecentUser {
  const RecentUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.subscriptionStatus,
  });

  final String uid;
  final String name;
  final String email;
  final String subscriptionStatus;
}

@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final user = ref.watch(mgmtAuthStateProvider).valueOrNull;
  if (user == null) return const DashboardStats();

  final gasClient = ref.read(mgmtGasClientProvider);
  final result = await gasClient.post(
    action: 'GET_DASHBOARD_STATS',
    data: {'uid': user.uid, 'role': user.role},
  );

  final recentRaw = result['recentUsers'] as List<dynamic>? ?? [];
  final recent = recentRaw.map((r) {
    final m = r as Map<String, dynamic>;
    return RecentUser(
      uid: m['uid']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      subscriptionStatus:
          m['subscriptionStatus']?.toString() ?? 'none',
    );
  }).toList();

  final dailyRaw = result['dailyActive'] as List<dynamic>? ?? [];
  final daily = dailyRaw.map((d) => (d as num).toInt()).toList();

  return DashboardStats(
    totalUsers: int.tryParse(result['totalUsers']?.toString() ?? '0') ?? 0,
    activeSubscriptions:
        int.tryParse(result['activeSubscriptions']?.toString() ?? '0') ?? 0,
    newUsersThisMonth:
        int.tryParse(result['newUsersThisMonth']?.toString() ?? '0') ?? 0,
    monthlyRevenue: double.tryParse(
            result['monthlyRevenue']?.toString() ?? '0') ??
        0,
    pendingSubscriptions:
        int.tryParse(result['pendingSubscriptions']?.toString() ?? '0') ?? 0,
    pendingProgramRequests:
        int.tryParse(result['pendingProgramRequests']?.toString() ?? '0') ?? 0,
    dailyActiveUsers: daily,
    recentUsers: recent,
  );
}
