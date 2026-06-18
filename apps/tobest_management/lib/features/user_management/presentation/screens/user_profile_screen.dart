// ============================================================
// user_profile_screen.dart — ملف المستخدم الكامل
// ============================================================

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/data/models/user_model.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/providers/mgmt_auth_provider.dart';

part 'user_profile_screen.g.dart';

@riverpod
Future<UserEntity?> userDetail(UserDetailRef ref, String userId) async {
  final admin = ref.watch(mgmtAuthStateProvider).valueOrNull;
  if (admin == null) return null;

  final gas = ref.read(mgmtGasClientProvider);
  final result = await gas.post(
    action: 'GET_USER_DETAIL',
    data: {'uid': admin.uid, 'targetUid': userId},
  );

  final userData = result['user'] as Map<String, dynamic>?;
  if (userData == null) return null;
  return UserIsarModel.fromJson(userData).toEntity();
}

class UserProfileScreen extends HookConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userId));
    final admin = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف المستخدم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(userDetailProvider(userId)),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('المستخدم غير موجود'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── Header ────────────────────────────────────
              _ProfileHeader(user: user, isDark: isDark),
              const SizedBox(height: AppSpacing.lg),

              // ── Subscription Info ─────────────────────────
              _SectionCard(
                title: 'الاشتراك',
                isDark: isDark,
                child: _SubscriptionInfo(user: user),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Personal Info ─────────────────────────────
              _SectionCard(
                title: 'البيانات الشخصية',
                isDark: isDark,
                child: _PersonalInfo(user: user),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Devices ───────────────────────────────────
              if (user.deviceInfo.isNotEmpty) ...[
                _SectionCard(
                  title: 'الأجهزة المسجلة',
                  isDark: isDark,
                  child: _DeviceList(
                    devices: user.deviceInfo,
                    userId: userId,
                    adminUid: admin?.uid ?? '',
                    onForceLogout: () =>
                        _forceLogout(context, ref, userId, admin?.uid ?? ''),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Admin Actions ─────────────────────────────
              if (admin?.role == AppRoles.manager ||
                  admin?.role == AppRoles.support)
                _AdminActionsCard(
                  user: user,
                  adminRole: admin?.role ?? '',
                  isDark: isDark,
                  onBanChat: () =>
                      _setBanChat(context, ref, userId, !user.chatBanned),
                  onBanUser: () =>
                      _setBanUser(context, ref, userId, user.status != 'banned'),
                  onForceLogout: () =>
                      _forceLogout(context, ref, userId, admin?.uid ?? ''),
                  onAssignCoach: () =>
                      _showAssignCoach(context, ref, userId),
                  onChangeProgram: () =>
                      _showChangeProgram(context, ref, user),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _forceLogout(
      BuildContext ctx, WidgetRef ref, String targetUid, String adminUid) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('تسجيل خروج إجباري؟'),
        content: const Text('سيُسجَّل المستخدم خروجاً من كل أجهزته'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirm != true) return;

    await ref.read(mgmtGasClientProvider).post(
      action: 'FORCE_LOGOUT',
      data: {'uid': adminUid, 'targetUid': targetUid},
    );
    ref.invalidate(userDetailProvider(targetUid));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الخروج الإجباري')),
      );
    }
  }

  Future<void> _setBanChat(
      BuildContext ctx, WidgetRef ref, String targetUid, bool ban) async {
    await ref.read(mgmtGasClientProvider).post(
      action: 'BAN_CHAT',
      data: {'targetUid': targetUid, 'ban': ban},
    );
    ref.invalidate(userDetailProvider(targetUid));
  }

  Future<void> _setBanUser(
      BuildContext ctx, WidgetRef ref, String targetUid, bool ban) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(ban ? 'حظر المستخدم؟' : 'رفع الحظر؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ban ? AppColors.error : AppColors.success),
              child: Text(ban ? 'حظر' : 'رفع الحظر')),
        ],
      ),
    );
    if (confirm != true) return;

    await ref.read(mgmtGasClientProvider).post(
      action: 'BAN_USER',
      data: {'targetUid': targetUid, 'ban': ban},
    );
    ref.invalidate(userDetailProvider(targetUid));
  }

  Future<void> _showAssignCoach(
      BuildContext ctx, WidgetRef ref, String targetUid) async {
    final coachUidCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('تعيين مدرب'),
        content: TextField(
          controller: coachUidCtrl,
          decoration: const InputDecoration(labelText: 'معرّف المدرب (UID)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(c, coachUidCtrl.text.trim()),
              child: const Text('تعيين')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(mgmtGasClientProvider).post(
        action: 'ASSIGN_COACH',
        data: {'targetUid': targetUid, 'coachUid': result},
      );
      ref.invalidate(userDetailProvider(targetUid));
    }
  }

  Future<void> _showChangeProgram(
      BuildContext ctx, WidgetRef ref, UserEntity user) async {
    const programs = ['AP', 'PPL', 'UL', 'FB', 'CARDIO', 'WL', 'HYP', 'REHAB'];
    final selected = await showDialog<String>(
      context: ctx,
      builder: (c) => SimpleDialog(
        title: const Text('تغيير البرنامج'),
        children: programs.map((p) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(c, p),
            child: Text(p,
                style: TextStyle(
                    fontWeight: p == user.program ? FontWeight.bold : null,
                    color: p == user.program ? AppColors.accent2 : null)),
          );
        }).toList(),
      ),
    );
    if (selected != null && selected != user.program) {
      await ref.read(mgmtGasClientProvider).post(
        action: 'CHANGE_PROGRAM',
        data: {'targetUid': user.uid, 'program': selected},
      );
      ref.invalidate(userDetailProvider(user.uid));
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.isDark});
  final UserEntity user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subColor = _subColor(user.subscription.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: subColor.withOpacity(0.15),
            child: user.picture.isNotEmpty
                ? null
                : Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: subColor,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                Text(user.email,
                    style: Theme.of(context).textTheme.bodySmall),
                if (user.phone.isNotEmpty)
                  Text(user.phone,
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusBadge(
                        label: user.role == 'COACH' ? 'مدرب' : 'مستخدم',
                        color: AppColors.info),
                    const SizedBox(width: 6),
                    _StatusBadge(
                      label: _subLabel(user.subscription.status),
                      color: subColor,
                    ),
                    if (user.status == 'banned') ...[
                      const SizedBox(width: 6),
                      _StatusBadge(
                          label: 'محظور',
                          color: AppColors.error),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.child, required this.isDark});
  final String title;
  final Widget child;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _SubscriptionInfo extends StatelessWidget {
  const _SubscriptionInfo({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final sub = user.subscription;
    return Column(
      children: [
        _InfoRow('الخطة', sub.type.isEmpty ? '—' : sub.type),
        _InfoRow('الحالة', _statusAr(sub.status)),
        if (sub.startDate != null)
          _InfoRow('البداية',
              DateFormat('dd/MM/yyyy').format(sub.startDate!)),
        if (sub.endDate != null)
          _InfoRow('الانتهاء',
              DateFormat('dd/MM/yyyy').format(sub.endDate!)),
        if (sub.rejectionReason.isNotEmpty)
          _InfoRow('سبب الرفض', sub.rejectionReason),
      ],
    );
  }

  String _statusAr(String s) => switch (s) {
        'active' => 'نشط',
        'pending' => 'معلق',
        'rejected' => 'مرفوض',
        'expired' => 'منتهي',
        _ => 'بدون',
      };
}

class _PersonalInfo extends StatelessWidget {
  const _PersonalInfo({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow('الجنس', user.gender.arabicLabel),
        _InfoRow('العمر', '${user.age} سنة'),
        _InfoRow('الوزن', '${user.weight} كيلو'),
        _InfoRow('الطول', '${user.height} سم'),
        _InfoRow('الهدف', _goalAr(user.goal)),
        _InfoRow('البرنامج',
            user.program.isNotEmpty ? user.program : '—'),
        _InfoRow('المدرب',
            user.assignedCoach.isNotEmpty ? user.assignedCoach : '—'),
        _InfoRow('السعرات', '${user.dailyCalories} سعرة/يوم'),
        _InfoRow('كود الإحالة',
            user.referralCode.isNotEmpty ? user.referralCode : '—'),
      ],
    );
  }

  String _goalAr(String g) => switch (g) {
        'loseWeight' => 'خسارة الوزن',
        'gainMuscle' => 'بناء العضلات',
        'maintain' => 'الحفاظ على الوزن',
        _ => g,
      };
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({
    required this.devices,
    required this.userId,
    required this.adminUid,
    required this.onForceLogout,
  });
  final List<DeviceInfo> devices;
  final String userId, adminUid;
  final VoidCallback onForceLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...devices.map((d) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                d.platform == 'ios'
                    ? Icons.phone_iphone_rounded
                    : Icons.android_rounded,
                color: d.platform == 'ios'
                    ? AppColors.info
                    : AppColors.success,
              ),
              title: Text(d.deviceName,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'آخر دخول: ${d.lastLoginAt != null ? DateFormat('dd/MM/yyyy').format(d.lastLoginAt!) : "—"}'),
            )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onForceLogout,
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: const Text('تسجيل خروج إجباري من كل الأجهزة'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning),
          ),
        ),
      ],
    );
  }
}

class _AdminActionsCard extends StatelessWidget {
  const _AdminActionsCard({
    required this.user,
    required this.adminRole,
    required this.isDark,
    required this.onBanChat,
    required this.onBanUser,
    required this.onForceLogout,
    required this.onAssignCoach,
    required this.onChangeProgram,
  });

  final UserEntity user;
  final String adminRole;
  final bool isDark;
  final VoidCallback onBanChat, onBanUser, onForceLogout,
      onAssignCoach, onChangeProgram;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Text('إجراءات إدارية',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        )),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              user.chatBanned
                  ? Icons.chat_rounded
                  : Icons.block_rounded,
              color: user.chatBanned ? AppColors.success : AppColors.error,
            ),
            title: Text(user.chatBanned
                ? 'رفع حظر الشات'
                : 'حظر الشات'),
            onTap: onBanChat,
          ),
          ListTile(
            leading: Icon(
              user.status == 'banned'
                  ? Icons.person_rounded
                  : Icons.person_off_rounded,
              color: user.status == 'banned'
                  ? AppColors.success
                  : AppColors.error,
            ),
            title: Text(user.status == 'banned'
                ? 'رفع الحظر عن الحساب'
                : 'حظر الحساب'),
            onTap: onBanUser,
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded,
                color: AppColors.warning),
            title: const Text('تسجيل خروج إجباري'),
            onTap: onForceLogout,
          ),
          if (adminRole == AppRoles.manager ||
              adminRole == AppRoles.support) ...[
            ListTile(
              leading: const Icon(Icons.sports_rounded,
                  color: AppColors.info),
              title: const Text('تعيين مدرب'),
              onTap: onAssignCoach,
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center_rounded,
                  color: AppColors.accent2),
              title: const Text('تغيير البرنامج'),
              subtitle:
                  Text('الحالي: ${user.program.isNotEmpty ? user.program : "—"}'),
              onTap: onChangeProgram,
            ),
          ],
        ],
      ),
    );
  }
}
