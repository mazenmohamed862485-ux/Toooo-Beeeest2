// ============================================================
// TO Best — design/widgets/breathing_animation.dart
// Breathing Animation — تُستخدم في:
//   • Splash Screen
//   • Rest Timer بين السيتات
//   • Subscription Pending Screen
//   • Loading/Sync Indicator في كل أنحاء التطبيق
// ============================================================

import 'package:flutter/material.dart';
import '../tokens.dart';

/// نوع الـ Breathing Animation
enum BreathingAnimationType {
  /// للـ Splash وحالات الانتظار الرئيسية
  full,

  /// كـ Loading indicator مدمج في الشاشات
  compact,

  /// للـ Rest Timer — مع عداد وقت
  restTimer,
}

/// Breathing Animation
///
/// دائرة تكبر 4 ثواني (شهيق) وتصغر 4 ثواني (زفير)
/// مع نص "شهيق..." / "زفير..." يتغير مع الحركة
///
/// تُستخدم في جميع أنحاء التطبيق كـ:
/// - تمرين تنفسي
/// - Rest Timer بعد كل ست
/// - Loading/Sync indicator
/// - Splash Screen animation
class BreathingAnimation extends StatefulWidget {
  const BreathingAnimation({
    super.key,
    this.type = BreathingAnimationType.full,
    this.size = 200,
    this.color,
    this.showText = true,
    this.remainingSeconds,
    this.onTimerComplete,
    this.onSkip,
  });

  /// نوع الـ Animation
  final BreathingAnimationType type;

  /// حجم الدائرة الخارجية
  final double size;

  /// لون الدائرة (افتراضي: brandGreen)
  final Color? color;

  /// إظهار نص الشهيق/الزفير
  final bool showText;

  /// الثواني المتبقية (للـ Rest Timer)
  final int? remainingSeconds;

  /// عند انتهاء المؤقت
  final VoidCallback? onTimerComplete;

  /// زر "تخطي"
  final VoidCallback? onSkip;

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _timerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isInhale = true;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _initBreathAnimation();

    if (widget.remainingSeconds != null) {
      _secondsLeft = widget.remainingSeconds!;
      _initTimerAnimation();
    }
  }

  void _initBreathAnimation() {
    // دورة كاملة = 8 ثواني (4 شهيق + 4 زفير)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50, // 4 ثواني شهيق
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50, // 4 ثواني زفير
      ),
    ]).animate(_breathController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 0.9),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 0.5),
        weight: 50,
      ),
    ]).animate(_breathController);

    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathController.repeat();
      }
    });

    _breathController.addListener(() {
      final newIsInhale = _breathController.value < 0.5;
      if (newIsInhale != _isInhale) {
        setState(() => _isInhale = newIsInhale);
      }
    });

    _breathController.forward();
  }

  void _initTimerAnimation() {
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.remainingSeconds!),
    );

    _timerController.addListener(() {
      final elapsed = (widget.remainingSeconds! * _timerController.value).round();
      final remaining = widget.remainingSeconds! - elapsed;
      if (remaining != _secondsLeft) {
        setState(() => _secondsLeft = remaining);
      }
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTimerComplete?.call();
      }
    });

    _timerController.forward();
  }

  @override
  void dispose() {
    _breathController.dispose();
    if (widget.remainingSeconds != null) {
      _timerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.brandGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (widget.type) {
      BreathingAnimationType.full => _buildFull(color, isDark),
      BreathingAnimationType.compact => _buildCompact(color),
      BreathingAnimationType.restTimer => _buildRestTimer(color, isDark),
    };
  }

  // ── Full Animation ────────────────────────────────────────

  Widget _buildFull(Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // الدائرة الخارجية (Ripple)
                  Transform.scale(
                    scale: _scaleAnimation.value * 1.2,
                    child: Opacity(
                      opacity: _opacityAnimation.value * 0.3,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  // الدائرة الرئيسية
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: widget.size * 0.75,
                        height: widget.size * 0.75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(
                            color: color,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.showText) ...[
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _isInhale ? 'شهيق...' : 'زفير...',
              key: ValueKey(_isInhale),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Compact Animation (Loading Indicator) ─────────────────

  Widget _buildCompact(Color color) {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Rest Timer Animation ──────────────────────────────────

  Widget _buildRestTimer(Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الدائرة مع العداد
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Ripple خلفي
                Transform.scale(
                  scale: _scaleAnimation.value * 1.15,
                  child: Opacity(
                    opacity: _opacityAnimation.value * 0.2,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  ),
                ),
                // الدائرة الرئيسية
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      border: Border.all(color: color, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_secondsLeft',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'راحة',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // نص الشهيق/الزفير
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _isInhale ? 'شهيق...' : 'زفير...',
            key: ValueKey(_isInhale),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        // زر التخطي
        if (widget.onSkip != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onSkip,
            child: const Text('تخطي'),
          ),
        ],
      ],
    );
  }
}
