// ============================================================
// google_signin_completion_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/data/models/user_model.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/utils/validators.dart';
import '../providers/auth_provider.dart';

/// إكمال بيانات حساب Google الجديد
class GoogleSignInCompletionScreen extends HookConsumerWidget {
  const GoogleSignInCompletionScreen({
    super.key,
    required this.googleData,
  });

  final Map<String, dynamic> googleData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final phoneCtrl = useTextEditingController();
    final weightCtrl = useTextEditingController();
    final heightCtrl = useTextEditingController();
    final ageCtrl = useTextEditingController();
    final referralCtrl = useTextEditingController();
    final gender = useState(Gender.male);
    final activityLevel = useState(ActivityLevel.moderate);
    final goal = useState('maintain');
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> complete() async {
      if (!formKey.currentState!.validate()) return;
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
            if (referralCtrl.text.trim().isNotEmpty)
              'referralCode': referralCtrl.text.trim(),
          },
        );

        final userData = result['user'] as Map<String, dynamic>?;
        if (userData == null) throw Exception('invalid_response');

        final userModel = UserIsarModel.fromJson(userData);

        // فحص الدور
        if (!AppConfig.tobest_allowedRoles.contains(userModel.role)) {
          throw Exception('unauthorized_role');
        }

        final isar = ref.read(isarServiceProvider);
        final db = await isar.db;
        await db.writeTxn(() async {
          await db.userIsarModels.put(userModel);
        });

        // GoRouter يتولى التوجيه تلقائياً
      } catch (e) {
        errorMsg.value = e.toString().contains('email_exists')
            ? 'البريد الإلكتروني مسجّل مسبقاً'
            : 'حدث خطأ، حاول مجدداً';
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('أكمل بياناتك')),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // مرحبا
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.waving_hand_rounded,
                        color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'مرحباً ${googleData['name'] ?? ''}!\nنحتاج بعض المعلومات لإكمال تسجيلك',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // رقم الهاتف
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

              // الوزن والطول
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الوزن (كيلو)',
                        prefixIcon:
                            Icon(Icons.monitor_weight_outlined),
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

              // العمر
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

              // الجنس
              Text('الجنس',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: Gender.values.map((g) {
                  final selected = gender.value == g;
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: g == Gender.female ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => gender.value = g,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            g.arabicLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight:
                                  selected ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // مستوى النشاط
              DropdownButtonFormField<ActivityLevel>(
                value: activityLevel.value,
                decoration: const InputDecoration(
                  labelText: 'مستوى النشاط',
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

              // الهدف
              DropdownButtonFormField<String>(
                value: goal.value,
                decoration: const InputDecoration(
                  labelText: 'هدفك',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'loseWeight', child: Text('خسارة الوزن')),
                  DropdownMenuItem(
                      value: 'maintain', child: Text('الحفاظ على الوزن')),
                  DropdownMenuItem(
                      value: 'gainMuscle',
                      child: Text('بناء العضلات')),
                ],
                onChanged: (v) {
                  if (v != null) goal.value = v;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // كود الإحالة
              TextFormField(
                controller: referralCtrl,
                decoration: const InputDecoration(
                  labelText: 'كود الإحالة (اختياري)',
                  prefixIcon: Icon(Icons.card_giftcard_rounded),
                ),
                validator: AppValidators.optional,
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
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              ElevatedButton(
                onPressed: isLoading.value ? null : complete,
                child: isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('إنهاء التسجيل'),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// guest_screen.dart
// ============================================================

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text('وضع الضيف')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(

                child: Container(

                width: 96,

                height: 96,

                decoration: BoxDecoration(

                  color: accent.withOpacity(0.1),

                  shape: BoxShape.circle,

                ),

                child: Icon(Icons.person_outline_rounded,

                    size: 52, color: accent),

                ),

              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'أنت في وضع الضيف',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'يمكنك تصفح بعض المحتوى المحدود.\nسجّل دخولك للاستفادة من جميع الميزات:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ميزات مقفلة
              ...[
                '🏋️ برامج التمرين الشخصية',
                '🥗 تتبع التغذية والسعرات',
                '📊 تقارير التقدم',
                '💬 الشات مع المدرب',
                '🤖 AI Coach',
              ].map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 16,
                            color: AppColors.lightOnSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(feature,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  )),

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

extension _WidgetCenterExt on Widget {
  Widget get also => this;
}
