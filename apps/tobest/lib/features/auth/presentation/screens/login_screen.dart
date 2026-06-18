// ============================================================
// TO Best — login_screen.dart
// شاشة تسجيل الدخول الكاملة
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/utils/validators.dart';
import '../providers/auth_provider.dart';

/// شاشة تسجيل الدخول
///
/// تدعم: Email/Phone + Password، Google Sign In، Guest Mode
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final isPasswordVisible = useState(false);
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;
      errorMessage.value = null;
      isLoading.value = true;

      try {
        await ref.read(authStateProvider.notifier).login(
              emailOrPhone: emailCtrl.text.trim(),
              password: passwordCtrl.text,
            );
        // التوجيه يتم تلقائياً عبر GoRouter Redirect
      } catch (e) {
        errorMessage.value = _mapError(e.toString());
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    Future<void> handleGoogleSignIn() async {
      isLoading.value = true;
      errorMessage.value = null;

      try {
        final result = await ref
            .read(authStateProvider.notifier)
            .googleSignIn();

        if (!context.mounted) return;

        if (result.isNewUser) {
          // حساب Google جديد — اكمل البيانات
          context.push(
            AppRoutes.googleSignInCompletion,
            extra: result.googleData,
          );
        }
        // إذا كان existing user، GoRouter يوجّهه تلقائياً
      } catch (e) {
        errorMessage.value = _mapError(e.toString());
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // ── الشعار ──────────────────────────────────────
              Center(
                child: Image.asset(
                  isDark
                      ? 'assets/images/tb_icon_black.png'
                      : 'assets/images/tb_icon_light.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.fitness_center,
                    size: 60,
                    color: accent,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'مرحباً بعودتك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'سجّل دخولك للمتابعة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 40),

              // ── Form ─────────────────────────────────────────
              Form(
                key: formKey,
                child: Column(
                  children: [
                    // Email / Phone
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني أو رقم الهاتف',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: !isPasswordVisible.value,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            isPasswordVisible.value =
                                !isPasswordVisible.value;
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                        if (v.length < 8) return 'كلمة المرور قصيرة جداً';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // ── نسيت كلمة المرور ─────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),

              const SizedBox(height: 8),

              // ── رسالة الخطأ ──────────────────────────────────
              if (errorMessage.value != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.value!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── زر تسجيل الدخول ──────────────────────────────
              ElevatedButton(
                onPressed: isLoading.value ? null : handleLogin,
                child: isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('تسجيل الدخول'),
              ),

              const SizedBox(height: 20),

              // ── أو ────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'أو',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // ── Google Sign In ────────────────────────────────
              OutlinedButton.icon(
                onPressed: isLoading.value ? null : handleGoogleSignIn,
                icon: Image.asset(
                  'assets/icons/google.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata,
                      size: 24),
                ),
                label: const Text('الدخول بحساب Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),

              const SizedBox(height: 12),

              // ── Guest Mode ────────────────────────────────────
              TextButton(
                onPressed: () => context.push(AppRoutes.guestMode),
                child: Text(
                  'تصفح كضيف',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── إنشاء حساب ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ليس لديك حساب؟'),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('إنشاء حساب'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _mapError(String error) {
    if (error.contains('wrong_password') || error.contains('invalid_login')) {
      return 'بيانات الدخول غير صحيحة';
    }
    if (error.contains('user_not_found')) {
      return 'لا يوجد حساب بهذا البريد أو الهاتف';
    }
    if (error.contains('unauthorized_role')) {
      return 'هذا الحساب مخصص لتطبيق الإدارة فقط';
    }
    if (error.contains('banned')) {
      return 'تم تعليق حسابك. تواصل مع الدعم';
    }
    if (error.contains('max_devices')) {
      return 'تم الوصول للحد الأقصى من الأجهزة';
    }
    return 'حدث خطأ. تحقق من اتصالك وحاول مجدداً';
  }
}
