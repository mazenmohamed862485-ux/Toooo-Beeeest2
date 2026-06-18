// ============================================================
// TO Best — infrastructure/polling_service.dart
// Adaptive Polling للشات
// ============================================================

import 'dart:async';

/// خدمة Adaptive Polling للشات
///
/// - Foreground نشط:  كل 5 ثواني
/// - Foreground خامل: يزداد تدريجياً حتى 30 ثانية
/// - عند النشاط:      يعود لـ 5 ثواني فوراً
/// - AI Chat:         لا Polling (Gemini direct)
class PollingService {
  PollingService._internal();
  static final PollingService _instance = PollingService._internal();
  factory PollingService() => _instance;

  Timer? _timer;
  int _currentIntervalSeconds = 5;
  DateTime _lastActivityTime = DateTime.now();
  bool _isPolling = false;

  // ── الحد الأدنى والأقصى ─────────────────────────────────
  static const int _minInterval = 5;
  static const int _maxInterval = 30;
  static const int _idleThresholdSeconds = 30;

  // ── Stream للرسائل الجديدة ───────────────────────────────
  final StreamController<void> _pollController =
      StreamController<void>.broadcast();

  Stream<void> get onPoll => _pollController.stream;

  // ── تشغيل وإيقاف ─────────────────────────────────────────

  /// بدء الـ Polling
  void startPolling(Future<void> Function() onPoll) {
    if (_isPolling) return;
    _isPolling = true;
    _currentIntervalSeconds = _minInterval;
    _scheduleNext(onPoll);
  }

  /// إيقاف الـ Polling
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
    _currentIntervalSeconds = _minInterval;
  }

  /// تسجيل نشاط المستخدم (يُعيد الـ Interval للحد الأدنى)
  void registerActivity() {
    _lastActivityTime = DateTime.now();
    if (_currentIntervalSeconds > _minInterval && _isPolling) {
      _currentIntervalSeconds = _minInterval;
    }
  }

  void _scheduleNext(Future<void> Function() onPoll) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: _currentIntervalSeconds), () async {
      if (!_isPolling) return;

      _pollController.add(null);
      try {
        await onPoll();
      } catch (_) {
        // تجاهل الأخطاء — استمر في الـ Polling
      }

      _updateInterval();
      _scheduleNext(onPoll);
    });
  }

  void _updateInterval() {
    final idleSeconds =
        DateTime.now().difference(_lastActivityTime).inSeconds;

    if (idleSeconds >= _idleThresholdSeconds) {
      _currentIntervalSeconds = (_currentIntervalSeconds * 2)
          .clamp(_minInterval, _maxInterval);
    } else {
      _currentIntervalSeconds = _minInterval;
    }
  }

  void dispose() {
    stopPolling();
    _pollController.close();
  }
}
