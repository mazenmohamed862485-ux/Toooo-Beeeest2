// ============================================================
// subscription_pending_screen.dart
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/design/widgets/breathing_animation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/infrastructure/gas_client.dart';
import '../providers/auth_provider.dart';

/// شاشة انتظار الموافقة على الاشتراك
class SubscriptionPendingScreen extends ConsumerStatefulWidget {
  const SubscriptionPendingScreen({super.key});

  @override
  ConsumerState<SubscriptionPendingScreen> createState() =>
      _SubscriptionPendingScreenState();
}

class _SubscriptionPendingScreenState
    extends ConsumerState<SubscriptionPendingScreen> {
  bool _isCheckingStatus = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Breathing Animation كـ حالة انتظار
              const BreathingAnimation(
                type: BreathingAnimationType.full,
                color: AppColors.warning,
                showText: false,
              ),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                'طلبك قيد المراجعة ⏳',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'سيتم مراجعة طلب اشتراكك من قِبل فريقنا\nسنُبلِّغك فور الموافقة عليه',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
              ),

              const SizedBox(height: AppSpacing.huge),

              // رفع إيصال جديد
              OutlinedButton.icon(
                onPressed: () => _uploadPaymentProof(context),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('رفع إيصال الدفع'),
              ),

              const SizedBox(height: AppSpacing.md),

              // تحقق من الحالة
              ElevatedButton(
                onPressed: _isCheckingStatus ? null : _checkStatus,
                child: _isCheckingStatus
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تحديث الحالة'),
              ),

              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: () =>
                    ref.read(authStateProvider.notifier).logout(),
                child: Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkStatus() async {
    setState(() => _isCheckingStatus = true);
    await ref.read(authStateProvider.notifier).refreshUser();
    if (mounted) setState(() => _isCheckingStatus = false);
    // GoRouter يُعيد التوجيه تلقائياً إذا تغيرت الحالة
  }

  Future<void> _uploadPaymentProof(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || !context.mounted) return;

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final bytes = await image.readAsBytes();
      final base64 =
          // ignore: avoid_dynamic_calls
          (await _toBase64(bytes));

      final gasClient = ref.read(gasClientProvider);
      await gasClient.post(
        action: 'UPLOAD_PAYMENT_PROOF',
        data: {'uid': user.uid, 'proofBase64': base64},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الإيصال بنجاح ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الرفع. حاول مجدداً'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String> _toBase64(List<int> bytes) async {
    return base64Encode(bytes);
  }
}

// ============================================================
// subscription_rejected_screen.dart
// ============================================================

class SubscriptionRejectedScreen extends ConsumerWidget {
  const SubscriptionRejectedScreen({super.key, required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cancel_outlined,
                  size: 72, color: AppColors.error),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'تم رفض طلبك',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'نأسف لإخبارك بأنه تم رفض طلب الاشتراك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('سبب الرفض:',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(reason,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.huge),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.subscriptionPending),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة التقديم'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(authStateProvider.notifier).logout(),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// subscription_expired_screen.dart
// ============================================================

class SubscriptionExpiredScreen extends ConsumerWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.timer_off_rounded,
                  size: 72, color: AppColors.warning),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'انتهى اشتراكك',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'جدِّد اشتراكك للاستمرار في الاستفادة من جميع الميزات',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.huge),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.subscriptionPending),
                icon: const Icon(Icons.autorenew_rounded),
                label: const Text('تجديد الاشتراك الآن'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(authStateProvider.notifier).logout(),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
