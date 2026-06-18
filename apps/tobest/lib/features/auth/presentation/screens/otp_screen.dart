// ============================================================
// TO Best — otp_screen.dart (standalone)
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

/// أغراض الـ OTP
enum OtpPurpose { resetPassword, verifyEmail, verifyPhone }

/// شاشة التحقق من الـ OTP
///
/// تُستخدم في:
/// - إعادة تعيين كلمة المرور
/// - التحقق من البريد الإلكتروني
/// - التحقق من رقم الهاتف
class OtpScreen extends HookConsumerWidget {
  const OtpScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllers = List.generate(6, (_) => useTextEditingController());
    final focusNodes = List.generate(6, (_) => useFocusNode());
    final newPassCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final step = useState(0); // 0=OTP، 1=كلمة مرور جديدة
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);
    final secondsLeft = useState(AppConfig.otpResendSeconds);
    final isNewVisible = useState(false);

    // Countdown
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

    String get6DigitCode() =>
        controllers.map((c) => c.text).join();

    Future<void> verifyOtp() async {
      final code = get6DigitCode();
      if (code.length != 6) {
        errorMsg.value = 'أدخل جميع الأرقام الستة';
        return;
      }
      isLoading.value = true;
      errorMsg.value = null;

      try {
        final gasClient = ref.read(gasClientProvider);
        await gasClient.post(
          action: 'VERIFY_OTP',
          data: {'contact': email, 'code': code},
        );
        if (purpose == OtpPurpose.resetPassword) {
          step.value = 1;
        } else {
          if (context.mounted) context.go(AppRoutes.home);
        }
      } catch (e) {
        errorMsg.value = e.toString().contains('invalid_otp')
            ? 'الكود غير صحيح أو منتهي الصلاحية'
            : 'حدث خطأ، حاول مجدداً';
        // مسح الحقول عند الخطأ
        for (final c in controllers) {
          c.clear();
        }
        focusNodes.first.requestFocus();
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    Future<void> resetPassword() async {
      final passErr = AppValidators.password(newPassCtrl.text);
      if (passErr != null) {
        errorMsg.value = passErr;
        return;
      }
      if (newPassCtrl.text != confirmCtrl.text) {
        errorMsg.value = 'كلمتا المرور غير متطابقتين';
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
            'code': get6DigitCode(),
            'newPassword': newPassCtrl.text,
          },
        );
        if (!context.mounted) return;
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (_) {
        errorMsg.value = 'حدث خطأ، حاول مجدداً';
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(step.value == 0 ? 'كود التحقق' : 'كلمة المرور الجديدة'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                // OTP Input (6 boxes)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Container(
                      width: 46,
                      height: 56,
                      margin: EdgeInsets.only(
                          left: i < 5 ? 8 : 0),
                      child: TextField(
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.length == 1 && i < 5) {
                            focusNodes[i + 1].requestFocus();
                          } else if (val.isEmpty && i > 0) {
                            focusNodes[i - 1].requestFocus();
                          }
                          // Auto-verify عند اكتمال الأرقام
                          if (get6DigitCode().length == 6 &&
                              !isLoading.value) {
                            verifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: AppSpacing.xl),

                if (errorMsg.value != null)
                  Text(
                    errorMsg.value!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: AppSpacing.lg),

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

                Center(
                  child: TextButton(
                    onPressed: secondsLeft.value > 0
                        ? null
                        : () async {
                            secondsLeft.value =
                                AppConfig.otpResendSeconds;
                            final gas = ref.read(gasClientProvider);
                            await gas.post(
                              action: 'FORGOT_PASSWORD',
                              data: {'contact': email},
                            );
                          },
                    child: Text(
                      secondsLeft.value > 0
                          ? 'إعادة الإرسال (${secondsLeft.value}s)'
                          : 'إعادة إرسال الكود',
                    ),
                  ),
                ),
              ] else ...[
                // New Password
                TextField(
                  controller: newPassCtrl,
                  obscureText: !isNewVisible.value,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(isNewVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          isNewVisible.value = !isNewVisible.value,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded),
                  ),
                  onSubmitted: (_) => resetPassword(),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (errorMsg.value != null)
                  Text(
                    errorMsg.value!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSpacing.lg),
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
