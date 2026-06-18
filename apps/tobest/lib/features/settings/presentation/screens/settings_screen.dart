// ============================================================
// TO Best — settings/presentation/screens/settings_screen.dart
// إعدادات التطبيق: ثيم + لغة + لون + حجم خط + حساب
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/themes.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/infrastructure/gas_client.dart';
import '../providers/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppBar(title: Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Profile Header ────────────────────────────────
          if (user != null)
            _ProfileCard(user: user, isDark: isDark),

          const SizedBox(height: AppSpacing.xl),

          // ── المظهر ───────────────────────────────────────
          _SettingsSection(
            title: 'المظهر',
            children: [
              // الثيم
              _SettingTile(
                icon: Icons.palette_outlined,
                title: 'الثيم',
                trailing: DropdownButton<AppTheme>(
                  value: settings.theme,
                  underline: const SizedBox.shrink(),
                  items: AppTheme.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.arabicLabel),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(settingsProvider.notifier).setTheme(v);
                    }
                  },
                ),
              ),

              // لون التمييز (5 ألوان)
              _SettingTile(
                icon: Icons.color_lens_outlined,
                title: 'لون التمييز',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppColors.accent1,
                    AppColors.accent2,
                    AppColors.accent3,
                    AppColors.accent4,
                    AppColors.accent5,
                  ].map((c) {
                    final isSelected = settings.accentColor == c;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setAccentColor(c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white, width: 2)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.withOpacity(0.5),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // حجم الخط
              _SettingTile(
                icon: Icons.format_size_rounded,
                title: 'حجم الخط',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [0.9, 1.0, 1.1, 1.2].map((size) {
                    final isSelected =
                        (settings.fontSize - size).abs() < 0.01;
                    return GestureDetector(
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setFontSize(size),
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              fontSize: 13 * size,
                              color: isSelected ? Colors.white : null,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── اللغة ────────────────────────────────────────
          _SettingsSection(
            title: 'اللغة',
            children: [
              _SettingTile(
                icon: Icons.language_rounded,
                title: 'لغة التطبيق',
                trailing: DropdownButton<Locale>(
                  value: settings.locale,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: Locale('ar', 'SA'),
                      child: Text('العربية'),
                    ),
                    DropdownMenuItem(
                      value: Locale('en', 'US'),
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(settingsProvider.notifier).setLocale(v);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── الإشعارات والتزامن ────────────────────────────
          _SettingsSection(
            title: 'الإشعارات والمزامنة',
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                value: settings.notificationsEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(v),
              ),
              _SwitchTile(
                icon: Icons.sync_rounded,
                title: 'المزامنة في الخلفية',
                subtitle: 'يحافظ على بيانات الشات والتمارين محدّثة',
                value: settings.backgroundSyncEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setBackgroundSyncEnabled(v),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── الحساب ───────────────────────────────────────
          _SettingsSection(
            title: 'الحساب',
            children: [
              _SettingTile(
                icon: Icons.lock_outline_rounded,
                title: 'تغيير كلمة المرور',
                onTap: () => context.push(AppRoutes.changePassword),
              ),
              _SettingTile(
                icon: Icons.wifi_rounded,
                title: 'اختبار الاتصال بـ GAS',
                onTap: () async {
                  final gas = ref.read(gasClientProvider);
                  final ok = await gas.ping();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'الاتصال ناجح ✓'
                            : 'فشل الاتصال ✗'),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
              ),
              _SettingTile(
                icon: Icons.logout_rounded,
                title: 'تسجيل الخروج',
                titleColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          child: const Text('خروج'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(authStateProvider.notifier)
                        .logout();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── الإصدار ───────────────────────────────────────
          Center(
            child: Text(
              'TO Best v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Sub-Widgets ───────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.isDark});
  final dynamic user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(right: 56),
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
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title,
          style: TextStyle(
              color: titleColor, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios_rounded, size: 14)
              : null),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

// ============================================================
// change_password_screen.dart
// ============================================================

class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final oldPassCtrl = useTextEditingController();
    final newPassCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);
    final isOldVisible = useState(false);
    final isNewVisible = useState(false);

    final user = ref.watch(authStateProvider).valueOrNull;

    Future<void> changePassword() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      errorMsg.value = null;

      try {
        final gasClient = ref.read(gasClientProvider);
        await gasClient.post(
          action: 'CHANGE_PASSWORD',
          data: {
            'uid': user?.uid ?? '',
            'oldPassword': oldPassCtrl.text,
            'newPassword': newPassCtrl.text,
          },
        );
        if (!context.mounted) return;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        errorMsg.value = e.toString().contains('wrong_password')
            ? 'كلمة المرور القديمة غير صحيحة'
            : 'حدث خطأ. حاول مجدداً';
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: const AppBar(title: Text('تغيير كلمة المرور')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: oldPassCtrl,
                  obscureText: !isOldVisible.value,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(isOldVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          isOldVisible.value = !isOldVisible.value,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: newPassCtrl,
                  obscureText: !isNewVisible.value,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(isNewVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          isNewVisible.value = !isNewVisible.value,
                    ),
                  ),
                  validator: AppValidators.password,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) {
                    if (v != newPassCtrl.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                if (errorMsg.value != null) ...[
                  Text(
                    errorMsg.value!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ElevatedButton(
                  onPressed: isLoading.value ? null : changePassword,
                  child: isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('تغيير كلمة المرور'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
