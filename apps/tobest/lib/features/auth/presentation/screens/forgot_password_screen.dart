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
import 'otp_screen.dart';
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
