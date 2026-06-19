// ============================================================
// TO Best — ai_coach/presentation/screens/ai_coach_screen.dart
// شاشة AI Coach: Gemini + Context الكامل للمستخدم
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/config/secrets.dart';
import 'package:shared/domain/entities/user.dart';
import 'package:shared/domain/entities/chat_message.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/data/models/chat_model.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:isar/isar.dart';

/// شاشة AI Coach
///
/// يستخدم Gemini API مباشرة (بدون Backend)
/// يحتفظ بسياق المحادثة كاملاً
/// يعرف كل بيانات المستخدم (برنامج، وزن، هدف...)
class AiCoachScreen extends HookConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final messageCtrl = useTextEditingController();
    final scrollCtrl = useScrollController();
    final messages = useState<List<AiMessage>>([]);
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    // تحميل السجل المحلي
    useEffect(() {
      _loadHistory(ref, user?.uid ?? '').then((history) {
        messages.value = history;
        _scrollToBottom(scrollCtrl);
      });
      return null;
    }, []);

    // بناء Gemini Model
    final model = useMemoized(() {
      return GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: AppSecrets.geminiApiKey,
        systemInstruction: Content.system(_buildSystemPrompt(user)),
      );
    }, [user?.uid]);

    // محادثة Gemini (تحتفظ بالسياق)
    final chat = useMemoized(() {
      // بناء تاريخ المحادثة لـ Gemini
      final history = messages.value
          .where((m) => m.role == 'user' || m.role == 'model')
          .map((m) => Content(m.role, [TextPart(m.content)]))
          .toList();

      return model.startChat(history: history);
    }, [model]);

    Future<void> sendMessage({String? text, List<String>? imagePaths}) async {
      final msgText = text ?? messageCtrl.text.trim();
      if (msgText.isEmpty && (imagePaths == null || imagePaths.isEmpty)) {
        return;
      }

      messageCtrl.clear();
      isLoading.value = true;

      // رسالة المستخدم
      final userMsg = AiMessage(
        id: const Uuid().v4(),
        userId: user?.uid ?? '',
        role: 'user',
        content: msgText,
        timestamp: DateTime.now(),
        imageUrls: imagePaths ?? [],
      );

      messages.value = [...messages.value, userMsg];
      _scrollToBottom(scrollCtrl);

      // حفظ في Isar
      await _saveMessage(ref, userMsg);

      try {
        Content content;
        if (imagePaths != null && imagePaths.isNotEmpty) {
          // إرسال مع صور
          final parts = <Part>[TextPart(msgText)];
          for (final path in imagePaths) {
            // (في الـ production: تحويل لـ base64 وإرسال كـ DataPart)
            parts.add(TextPart('[صورة مرفقة]'));
          }
          content = Content('user', parts);
        } else {
          content = Content.text(msgText);
        }

        final response = await chat.sendMessage(content);
        final responseText =
            response.text ?? 'لم أتمكن من الإجابة. جرّب مرة أخرى.';

        // رسالة Gemini
        final aiMsg = AiMessage(
          id: const Uuid().v4(),
          userId: user?.uid ?? '',
          role: 'model',
          content: responseText,
          timestamp: DateTime.now(),
        );

        messages.value = [...messages.value, aiMsg];
        await _saveMessage(ref, aiMsg);
      } catch (e) {
        final errMsg = AiMessage(
          id: const Uuid().v4(),
          userId: user?.uid ?? '',
          role: 'model',
          content: 'عذراً، حدث خطأ. تحقق من اتصالك وحاول مجدداً.',
          timestamp: DateTime.now(),
        );
        messages.value = [...messages.value, errMsg];
      } finally {
        isLoading.value = false;
        _scrollToBottom(scrollCtrl);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: accent, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Coach'),
                Text(
                  'Gemini 2.0 Flash',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          // مسح السجل
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'مسح المحادثة',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('مسح المحادثة؟'),
                  content:
                      const Text('سيتم حذف كل سجل المحادثة مع AI Coach'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _clearHistory(ref, user?.uid ?? '');
                messages.value = [];
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ───────────────────────────────────────
          Expanded(
            child: messages.value.isEmpty
                ? _EmptyState(accent: accent, onSuggestion: sendMessage)
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: messages.value.length +
                        (isLoading.value ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == messages.value.length) {
                        return _TypingIndicator(isDark: isDark);
                      }
                      final msg = messages.value[i];
                      return _AiMessageBubble(
                        message: msg,
                        isDark: isDark,
                        accent: accent,
                      );
                    },
                  ),
          ),

          // ── Input ──────────────────────────────────────────
          _AiInputBar(
            controller: messageCtrl,
            isDark: isDark,
            accent: accent,
            isLoading: isLoading.value,
            onSend: () => sendMessage(text: messageCtrl.text.trim()),
            onPickImage: () async {
              final picker = ImagePicker();
              final imgs = await picker.pickMultiImage(imageQuality: 75);
              if (imgs.isEmpty) return;
              sendMessage(
                text: messageCtrl.text.trim(),
                imagePaths: imgs.map((i) => i.path).toList(),
              );
              messageCtrl.clear();
            },
          ),
        ],
      ),
    );
  }

  // ── System Prompt ───────────────────────────────────────────

  String _buildSystemPrompt(UserEntity? user) {
    if (user == null) {
      return 'أنت مدرب لياقة بدنية ذكي. أجب بالعربية الفصحى البسيطة.';
    }

    return '''
أنت AI Coach في تطبيق TO Best — مدرب لياقة بدنية وتغذية ذكي ومتخصص.

معلومات المستخدم:
- الاسم: ${user.name}
- الجنس: ${user.gender.arabicLabel}
- العمر: ${user.age} سنة
- الوزن: ${user.weight} كيلوغرام
- الطول: ${user.height} سنتيمتر
- الهدف: ${_goalArabic(user.goal)}
- مستوى النشاط: ${user.activityLevel.arabicLabel}
- البرنامج التدريبي: ${user.program.isNotEmpty ? user.program : 'غير محدد'}
- السعرات اليومية المستهدفة: ${user.dailyCalories} سعرة

مهامك:
1. الإجابة عن أسئلة التمرين والتغذية بدقة علمية
2. تقديم اقتراحات مخصصة بناءً على بيانات المستخدم
3. تحليل صور الطعام وتقدير السعرات (إذا أُرسلت)
4. تحليل تقنية التمرين من الصور (إذا أُرسلت)
5. دعم المستخدم نفسياً وتحفيزه

قواعد:
- أجب دائماً بالعربية الفصحى البسيطة
- كن دقيقاً وعلمياً
- لا تقدم معلومات طبية — أحل للطبيب عند الحاجة
- اجعل إجاباتك مختصرة وعملية
- استخدم أرقاماً دقيقة بناءً على بيانات المستخدم
''';
  }

  String _goalArabic(String goal) => switch (goal) {
        'loseWeight' => 'خسارة الوزن',
        'gainMuscle' => 'بناء العضلات',
        'maintain' => 'الحفاظ على الوزن',
        _ => goal,
      };

  // ── Helpers ─────────────────────────────────────────────────

  Future<List<AiMessage>> _loadHistory(WidgetRef ref, String userId) async {
    if (userId.isEmpty) return [];
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    final models = await db.aiMessageIsarModels
        .filter()
        .userIdEqualTo(userId)
        .sortByTimestampMs()
        .limit(100)
        .findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> _saveMessage(WidgetRef ref, AiMessage message) async {
    if (message.userId.isEmpty) return;
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    await db.writeTxn(() async {
      await db.aiMessageIsarModels
          .put(AiMessageIsarModel.fromEntity(message));
    });
  }

  Future<void> _clearHistory(WidgetRef ref, String userId) async {
    if (userId.isEmpty) return;
    final isar = ref.read(isarServiceProvider);
    final db = await isar.db;
    await db.writeTxn(() async {
      await db.aiMessageIsarModels
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  void _scrollToBottom(ScrollController ctrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctrl.hasClients) {
        ctrl.animateTo(
          ctrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ── Sub-Widgets ───────────────────────────────────────────────

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({
    required this.message,
    required this.isDark,
    required this.accent,
  });

  final AiMessage message;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
        left: isUser ? 40 : 0,
        right: isUser ? 0 : 40,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: accent, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? accent
                        : (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: !isUser
                        ? Border.all(color: AppColors.lightBorder)
                        : null,
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.lightOnSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.accent, required this.onSuggestion});
  final Color accent;
  final void Function({String? text}) onSuggestion;

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'كيف أحسّن أدائي في Squat؟',
      'ما هي أفضل الأطعمة للبناء العضلي؟',
      'كيف أحسب السعرات التي أحتاجها؟',
      'ما هو أفضل وقت للتمرين؟',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 64, color: accent),
            const SizedBox(height: 16),
            Text(
              'AI Coach جاهز لمساعدتك',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => onSuggestion(text: s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: accent.withOpacity(0.2)),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 13,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _AiInputBar extends StatelessWidget {
  const _AiInputBar({
    required this.controller,
    required this.isDark,
    required this.accent,
    required this.isLoading,
    required this.onSend,
    required this.onPickImage,
  });

  final TextEditingController controller;
  final bool isDark;
  final Color accent;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: isLoading ? null : onPickImage,
              color: accent,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: 'اسأل مدربك...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: accent),
                      )
                    : Icon(Icons.send_rounded, color: accent),
                onPressed: isLoading ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
