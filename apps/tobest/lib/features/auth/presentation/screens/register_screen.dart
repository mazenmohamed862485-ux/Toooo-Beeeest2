// ============================================================
// TO Best — register_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/utils/validators.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final step = useState(0); // 0=بيانات الحساب، 1=بيانات الجسم
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);

    // Step 0 controllers
    final nameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final phoneCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final referralCtrl = useTextEditingController();
    final isPassVisible = useState(false);

    // Step 1 controllers
    final weightCtrl = useTextEditingController();
    final heightCtrl = useTextEditingController();
    final ageCtrl = useTextEditingController();
    final gender = useState(Gender.male);
    final activityLevel = useState(ActivityLevel.moderate);
    final goal = useState('maintain');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> submitRegistration() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      errorMsg.value = null;

      try {
        await ref.read(authStateProvider.notifier).register(
              email: emailCtrl.text.trim(),
              password: passwordCtrl.text,
              name: nameCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              gender: gender.value.name,
              weight: double.tryParse(weightCtrl.text) ?? 70,
              height: double.tryParse(heightCtrl.text) ?? 170,
              age: int.tryParse(ageCtrl.text) ?? 25,
              activityLevel: activityLevel.value.key,
              goal: goal.value,
              referralCode: referralCtrl.text.trim(),
            );
      } catch (e) {
        errorMsg.value = _mapError(e.toString());
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(step.value == 0 ? 'إنشاء حساب' : 'بياناتك الجسدية'),
        leading: step.value == 0
            ? null
            : BackButton(onPressed: () => step.value = 0),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: step.value == 0 ? 0.5 : 1.0,
                backgroundColor: AppColors.lightBorder,
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (step.value == 0) ...[
                // ── Step 0: Account Info ────────────────────
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: AppValidators.fullName,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: AppValidators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '05xxxxxxxx',
                  ),
                  validator: AppValidators.saudiPhone,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: !isPassVisible.value,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(isPassVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          isPassVisible.value = !isPassVisible.value,
                    ),
                  ),
                  validator: AppValidators.password,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: AppValidators.confirmPassword(passwordCtrl.text),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: referralCtrl,
                  decoration: const InputDecoration(
                    labelText: 'كود الإحالة (اختياري)',
                    prefixIcon: Icon(Icons.card_giftcard_rounded),
                  ),
                  validator: AppValidators.optional,
                ),
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) step.value = 1;
                  },
                  child: const Text('التالي'),
                ),
              ] else ...[
                // ── Step 1: Body Info ───────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الوزن (كيلو)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                        ),
                        validator: AppValidators.weight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: TextFormField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الطول (سم)',
                          prefixIcon: Icon(Icons.height_rounded),
                        ),
                        validator: AppValidators.height,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'العمر',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: AppValidators.age,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Gender
                Text('الجنس',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: Gender.values.map((g) {
                    final selected = gender.value == g;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: g == Gender.female ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => gender.value = g,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : AppColors.lightBorder,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(g.arabicLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : null)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Activity Level
                Text('مستوى النشاط',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<ActivityLevel>(
                  value: activityLevel.value,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.directions_run_rounded),
                  ),
                  items: ActivityLevel.values
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.arabicLabel),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) activityLevel.value = v;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Goal
                Text('هدفك',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: goal.value,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'loseWeight', child: Text('خسارة الوزن')),
                    DropdownMenuItem(value: 'maintain', child: Text('الحفاظ على الوزن')),
                    DropdownMenuItem(value: 'gainMuscle', child: Text('بناء العضلات')),
                  ],
                  onChanged: (v) {
                    if (v != null) goal.value = v;
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),

                if (errorMsg.value != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(errorMsg.value!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                ElevatedButton(
                  onPressed: isLoading.value ? null : submitRegistration,
                  child: isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('إنشاء الحساب'),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لديك حساب؟'),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('تسجيل الدخول'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mapError(String e) {
    if (e.contains('email_exists') || e.contains('already_exists')) {
      return 'البريد الإلكتروني مسجّل مسبقاً';
    }
    if (e.contains('phone_exists')) return 'رقم الهاتف مسجّل مسبقاً';
    if (e.contains('invalid_referral')) return 'كود الإحالة غير صالح';
    return 'حدث خطأ. تحقق من اتصالك وحاول مجدداً';
  }
}
