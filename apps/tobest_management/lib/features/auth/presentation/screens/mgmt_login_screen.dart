// ============================================================
// TO Best Management — mgmt_login_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import '../providers/mgmt_auth_provider.dart';

class MgmtLoginScreen extends HookConsumerWidget {
  const MgmtLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final isPasswordVisible = useState(false);
    final errorMessage = useState<String?>(null);
    final authState = ref.watch(mgmtAuthStateProvider);

    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;
      errorMessage.value = null;

      try {
        await ref.read(mgmtAuthStateProvider.notifier).login(
              email: emailCtrl.text.trim(),
              password: passwordCtrl.text,
            );
      } catch (e) {
        errorMessage.value = _mapError(e.toString());
      }
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/tom_icon_light.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 64,
                        color: AppColors.accent2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TO Best Management',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تسجيل دخول الفريق الإداري',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco(
                            label: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: !isPasswordVisible.value,
                          style: const TextStyle(color: Colors.white),
                          onFieldSubmitted: (_) => handleLogin(),
                          decoration: _inputDeco(
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white54,
                              ),
                              onPressed: () => isPasswordVisible.value =
                                  !isPasswordVisible.value,
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.length < 8 ? 'كلمة المرور قصيرة' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (errorMessage.value != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Text(
                        errorMessage.value!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    onPressed: authState.isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent2,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.accent2, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      errorStyle: const TextStyle(color: AppColors.error),
    );
  }

  String _mapError(String e) {
    if (e.contains('wrong_password') || e.contains('invalid_login')) {
      return 'بيانات الدخول غير صحيحة';
    }
    if (e.contains('unauthorized_role')) {
      return 'هذا الحساب غير مصرح له بالوصول للإدارة';
    }
    if (e.contains('banned')) return 'الحساب معلّق';
    return 'حدث خطأ. تحقق من اتصالك وحاول مجدداً';
  }
}
