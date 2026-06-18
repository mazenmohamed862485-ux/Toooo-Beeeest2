// ============================================================
// TO Best Management — connection_settings_screen.dart
// إعدادات الاتصال بـ GAS — MANAGER فقط
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';

class ConnectionSettingsScreen extends HookConsumerWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gasUrlCtrl = useTextEditingController();
    final secretCtrl = useTextEditingController();
    final geminiKeyCtrl = useTextEditingController();
    final isTesting = useState(false);
    final testResult = useState<bool?>(null);
    final isSaving = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> testConnection() async {
      if (gasUrlCtrl.text.trim().isEmpty) return;
      isTesting.value = true;
      testResult.value = null;

      try {
        final tempClient = GasClient();
        await tempClient.saveConnectionSettings(
          gasUrl: gasUrlCtrl.text.trim(),
          secretKey: secretCtrl.text.trim(),
        );
        final ok = await tempClient.ping();
        testResult.value = ok;
      } catch (_) {
        testResult.value = false;
      } finally {
        isTesting.value = false;
      }
    }

    Future<void> saveSettings() async {
      if (gasUrlCtrl.text.trim().isEmpty) return;
      isSaving.value = true;

      try {
        final gasClient = ref.read(gasClientProvider);
        await gasClient.saveConnectionSettings(
          gasUrl: gasUrlCtrl.text.trim(),
          secretKey: secretCtrl.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ الإعدادات بنجاح ✓'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحفظ: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الاتصال')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── تحذير ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هذه الإعدادات حساسة. تغييرها يؤثر على كل مستخدمي التطبيق.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── GAS URL ───────────────────────────────────────
            Text(
              'GAS Backend URL',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gasUrlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://script.google.com/macros/s/.../exec',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Secret Key ────────────────────────────────────
            Text(
              'Secret Key',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: secretCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'المفتاح السري',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Gemini API Key ────────────────────────────────
            Text(
              'Gemini API Key',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: geminiKeyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'مفتاح Gemini API',
                prefixIcon: Icon(Icons.auto_awesome_rounded),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Test Connection ───────────────────────────────
            OutlinedButton.icon(
              onPressed: isTesting.value ? null : testConnection,
              icon: isTesting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_protected_setup_rounded),
              label:
                  Text(isTesting.value ? 'جاري الاختبار...' : 'اختبار الاتصال'),
            ),

            // Test Result
            if (testResult.value != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (testResult.value!
                              ? AppColors.success
                              : AppColors.error)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      testResult.value!
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: testResult.value!
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      testResult.value!
                          ? 'الاتصال ناجح ✓'
                          : 'فشل الاتصال — تحقق من الـ URL والمفتاح',
                      style: TextStyle(
                        color: testResult.value!
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // ── Save ──────────────────────────────────────────
            ElevatedButton(
              onPressed: isSaving.value ? null : saveSettings,
              child: isSaving.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}
