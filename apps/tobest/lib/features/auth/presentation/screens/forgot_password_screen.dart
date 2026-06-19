// ============================================================
// TO Best — forgot_password_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';
import 'package:shared/infrastructure/gas_client.dart';
import '../providers/auth_provider.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/design/widgets/breathing_animation.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailCtrl = useTextEditingController();
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> sendOtp() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      errorMsg.value = null;

      try {
        final gasClient = ref.read(gasClientProvider);
        await gasClient.post(
          action: 'FORGOT_PASSWORD',
          data: {'contact': emailCtrl.text.trim()},
        );
        if (!context.mounted) return;
        context.push(
          AppRoutes.otp,
          extra: {
            'email': emailCtrl.text.trim(),
            'purpose': OtpPurpose.resetPassword,
          },
        );
      } catch (e) {
        errorMsg.value = e.toString().contains('not_found')
            ? 'لا يوجد حساب بهذا البريد أو الهاتف'
            : 'حدث خطأ. حاول مجدداً';
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('نسيت كلمة المرور')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const Icon(Icons.lock_reset_rounded,
                    size: 64, color: AppColors.brandGreen),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'أدخل بريدك الإلكتروني أو رقم هاتفك\nوسنرسل لك كود التحقق',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني أو رقم الهاتف',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: AppValidators.emailOrPhone,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (errorMsg.value != null) ...[
                  Text(errorMsg.value!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ElevatedButton(
                  onPressed: isLoading.value ? null : sendOtp,
                  child: isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('إرسال كود التحقق'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// otp_screen.dart
// ============================================================

enum OtpPurpose { resetPassword, verifyEmail, verifyPhone }

class OtpScreen extends HookConsumerWidget {
  const OtpScreen({super.key, required this.email, required this.purpose});
  final String email;
  final OtpPurpose purpose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpCtrl = useTextEditingController();
    final newPassCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final step = useState(0); // 0=OTP، 1=كلمة المرور الجديدة
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);
    final secondsLeft = useState(AppConfig.otpResendSeconds);

    // Countdown timer للإعادة
    useEffect(() {
      Future<void> countdown() async {
        while (secondsLeft.value > 0) {
          await Future.delayed(const Duration(seconds: 1));
          if (secondsLeft.value > 0) secondsLeft.value--;
        }
      }
      countdown();
      return null;
    }, []);

    Future<void> verifyOtp() async {
      if (otpCtrl.text.trim().length != 6) {
        errorMsg.value = 'الكود يجب أن يكون 6 أرقام';
        return;
      }
      isLoading.value = true;
      errorMsg.value = null;

      try {
        final gasClient = ref.read(gasClientProvider);
        await gasClient.post(
          action: 'VERIFY_OTP',
          data: {
            'contact': email,
            'code': otpCtrl.text.trim(),
          },
        );
        if (purpose == OtpPurpose.resetPassword) {
          step.value = 1;
        } else {
          if (context.mounted) context.go(AppRoutes.home);
        }
      } catch (e) {
        errorMsg.value = e.toString().contains('invalid_otp')
            ? 'الكود غير صحيح أو منتهي الصلاحية'
            : 'حدث خطأ. حاول مجدداً';
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    Future<void> resetPassword() async {
      if (newPassCtrl.text != confirmCtrl.text) {
        errorMsg.value = 'كلمتا المرور غير متطابقتين';
        return;
      }
      if (AppValidators.password(newPassCtrl.text) != null) {
        errorMsg.value = AppValidators.password(newPassCtrl.text);
        return;
      }
      isLoading.value = true;
      errorMsg.value = null;

      try {
        final gasClient = ref.read(gasClientProvider);
        await gasClient.post(
          action: 'RESET_PASSWORD',
          data: {
            'contact': email,
            'code': otpCtrl.text.trim(),
            'newPassword': newPassCtrl.text,
          },
        );
        if (!context.mounted) return;
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        errorMsg.value = 'حدث خطأ. حاول مجدداً';
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(step.value == 0
            ? 'كود التحقق'
            : 'كلمة المرور الجديدة'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Icon(Icons.mark_email_read_rounded,
                  size: 56, color: AppColors.brandGreen),
              const SizedBox(height: AppSpacing.lg),
              Text(
                step.value == 0
                    ? 'أدخل الكود المرسل إلى\n$email'
                    : 'أدخل كلمة المرور الجديدة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),

              if (step.value == 0) ...[
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                  decoration: const InputDecoration(
                    hintText: '------',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (errorMsg.value != null) ...[
                  Text(errorMsg.value!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ElevatedButton(
                  onPressed: isLoading.value ? null : verifyOtp,
                  child: isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('تحقق'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: secondsLeft.value > 0
                      ? null
                      : () async {
                          secondsLeft.value = AppConfig.otpResendSeconds;
                          final gas = ref.read(gasClientProvider);
                          await gas.post(
                              action: 'FORGOT_PASSWORD',
                              data: {'contact': email});
                        },
                  child: Text(
                    secondsLeft.value > 0
                        ? 'إعادة الإرسال (${secondsLeft.value}s)'
                        : 'إعادة إرسال الكود',
                  ),
                ),
              ] else ...[
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (errorMsg.value != null) ...[
                  Text(errorMsg.value!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ElevatedButton(
                  onPressed: isLoading.value ? null : resetPassword,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// subscription_pending_screen.dart
// ============================================================

class SubscriptionPendingScreen extends ConsumerWidget {
  const SubscriptionPendingScreen({super.key});

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
              const BreathingAnimation(
                type: BreathingAnimationType.full,
                color: AppColors.warning,
                showText: false,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'طلبك قيد المراجعة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'سيتم مراجعة طلب اشتراكك من قِبل فريقنا\nسنُبلِّغك فور الموافقة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.huge),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).refreshUser();
                },
                child: const Text('تحديث الحالة'),
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
              const Icon(Icons.cancel_rounded,
                  size: 72, color: AppColors.error),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'تم رفض طلبك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    'السبب: $reason',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.huge),
              ElevatedButton(
                onPressed: () =>
                    context.push(AppRoutes.subscriptionPending),
                child: const Text('إعادة التقديم'),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'جدِّد اشتراكك للاستمرار في الاستفادة من كل المميزات',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.huge),
              ElevatedButton(
                onPressed: () =>
                    context.push(AppRoutes.subscriptionPending),
                child: const Text('تجديد الاشتراك'),
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
// google_signin_completion_screen.dart
// ============================================================

class GoogleSignInCompletionScreen extends HookConsumerWidget {
  const GoogleSignInCompletionScreen({super.key, required this.googleData});
  final Map<String, dynamic> googleData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneCtrl = useTextEditingController();
    final weightCtrl = useTextEditingController();
    final heightCtrl = useTextEditingController();
    final ageCtrl = useTextEditingController();
    final gender = useState(Gender.male);
    final activityLevel = useState(ActivityLevel.moderate);
    final goal = useState('maintain');
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);

    Future<void> complete() async {
      isLoading.value = true;
      errorMsg.value = null;
      try {
        final gasClient = ref.read(gasClientProvider);
        final result = await gasClient.post(
          action: 'COMPLETE_GOOGLE_REGISTER',
          data: {
            ...googleData,
            'phone': phoneCtrl.text.trim(),
            'weight': double.tryParse(weightCtrl.text) ?? 70,
            'height': double.tryParse(heightCtrl.text) ?? 170,
            'age': int.tryParse(ageCtrl.text) ?? 25,
            'gender': gender.value.name,
            'activityLevel': activityLevel.value.key,
            'goal': goal.value,
          },
        );
        final userData = result['user'] as Map<String, dynamic>?;
        if (userData == null) throw Exception('invalid_response');
        // يُعاد التوجيه تلقائياً عبر GoRouter
      } catch (e) {
        errorMsg.value = 'حدث خطأ. حاول مجدداً';
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('أكمل بياناتك')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              'مرحباً ${googleData['name'] ?? ''}!\nنحتاج بعض المعلومات الإضافية',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الوزن (كيلو)'),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: TextFormField(
                    controller: heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الطول (سم)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'العمر'),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (errorMsg.value != null)
              Text(errorMsg.value!,
                  style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: isLoading.value ? null : complete,
              child: const Text('إنهاء'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// guest_screen.dart — وضع الضيف (محدود)
// ============================================================

class GuestScreen extends ConsumerWidget {
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('وضع الضيف')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 80, color: AppColors.lightBorder),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'أنت في وضع الضيف',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'يمكنك الاطلاع على معلومات محدودة.\nسجّل دخولك للاستفادة من كل المميزات',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.huge),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('تسجيل الدخول'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('إنشاء حساب مجاني'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
