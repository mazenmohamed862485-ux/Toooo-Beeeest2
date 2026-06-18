// ============================================================
// TO Best — infrastructure/gas_client.dart
// عميل GAS API — يتعامل مع Google Apps Script Backend
// ============================================================

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/secrets.dart';

/// عميل الاتصال بـ Google Apps Script
///
/// كل الطلبات تذهب عبر POST بـ action field
/// المصادقة عبر secret key في كل طلب
class GasClient {
  GasClient({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _dio = dio ?? _buildDio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  // ── مفاتيح التخزين الآمن ─────────────────────────────────
  static const String _gasUrlKey = 'gas_base_url';
  static const String _gasSecretKey = 'gas_secret_key';

  /// الإجراءات العامة التي لا تحتاج Secret Key
  static const Set<String> _publicActions = {
    'PING',
    'FORGOT_PASSWORD',
    'RESET_PASSWORD',
    'GUEST_LOGIN',
    'CHECK_BAN',
  };

  // ── إنشاء Dio Instance ───────────────────────────────────
  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    )..interceptors.addAll([
        LogInterceptor(
          requestBody: false, // لا تُسجَّل البيانات الحساسة
          responseBody: false,
          logPrint: (obj) => _log(obj.toString()),
        ),
        _RetryInterceptor(),
      ]);
  }

  static void _log(String message) {
    // ignore: avoid_print
    print('[GasClient] $message');
  }

  // ── الحصول على URL الحالي ────────────────────────────────

  /// جلب GAS Base URL (من SecureStorage أو Secrets)
  Future<String> _getBaseUrl() async {
    final stored = await _secureStorage.read(key: _gasUrlKey);
    return stored?.isNotEmpty == true ? stored! : AppSecrets.gasBaseUrl;
  }

  /// جلب Secret Key (من SecureStorage أو Secrets)
  Future<String> _getSecret() async {
    final stored = await _secureStorage.read(key: _gasSecretKey);
    return stored?.isNotEmpty == true ? stored! : AppSecrets.gasSecretKey;
  }

  // ── حفظ الإعدادات (MANAGER فقط) ─────────────────────────

  /// حفظ GAS URL و Secret Key من شاشة الإعدادات
  Future<void> saveConnectionSettings({
    required String gasUrl,
    required String secretKey,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _gasUrlKey, value: gasUrl),
      _secureStorage.write(key: _gasSecretKey, value: secretKey),
    ]);
    // تحديث Base URL في Dio
    _dio.options.baseUrl = gasUrl;
  }

  // ── الدالة الرئيسية للطلبات ──────────────────────────────

  /// إرسال طلب لـ GAS Backend
  ///
  /// [action] نوع العملية (مثل LOGIN، SAVE_LOG)
  /// [data] البيانات الإضافية
  /// يُرجع Map<String, dynamic> من GAS
  Future<Map<String, dynamic>> post({
    required String action,
    Map<String, dynamic> data = const {},
  }) async {
    final baseUrl = await _getBaseUrl();
    final secret = await _getSecret();

    final payload = <String, dynamic>{
      'action': action,
      ...data,
    };

    // إضافة secret لجميع الطلبات غير العامة
    if (!_publicActions.contains(action)) {
      payload['secret'] = secret;
    }

    try {
      final response = await _dio.post<String>(
        baseUrl,
        data: 'payload=${Uri.encodeComponent(jsonEncode(payload))}',
      );

      if (response.data == null) {
        throw GasException(action: action, message: 'Empty response from GAS');
      }

      final result = jsonDecode(response.data!) as Map<String, dynamic>;

      if (result['ok'] != true) {
        final err = result['err']?.toString() ?? 'unknown_error';
        throw GasException(action: action, message: err, code: err);
      }

      return result;
    } on DioException catch (e) {
      throw GasNetworkException(
        action: action,
        message: e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// اختبار الاتصال بـ GAS
  Future<bool> ping() async {
    try {
      final result = await post(action: 'PING');
      return result['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}

// ── Exceptions ────────────────────────────────────────────────

/// خطأ من GAS API
class GasException implements Exception {
  const GasException({
    required this.action,
    required this.message,
    this.code,
  });

  final String action;
  final String message;
  final String? code;

  @override
  String toString() => 'GasException[$action]: $message (code: $code)';
}

/// خطأ شبكي
class GasNetworkException extends GasException {
  const GasNetworkException({
    required super.action,
    required super.message,
    this.statusCode,
  });

  final int? statusCode;

  @override
  String toString() =>
      'GasNetworkException[$action]: $message (HTTP: $statusCode)';
}

// ── Retry Interceptor ─────────────────────────────────────────

/// Interceptor لإعادة المحاولة تلقائياً عند الفشل
class _RetryInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    var attempt = err.requestOptions.extra['_retry_count'] as int? ?? 0;

    // إعادة المحاولة فقط لأخطاء الشبكة (لا لأخطاء 4xx)
    final shouldRetry = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (shouldRetry && attempt < _maxRetries) {
      attempt++;
      await Future.delayed(_retryDelay * attempt);

      err.requestOptions.extra['_retry_count'] = attempt;
      try {
        final response = await Dio().fetch<dynamic>(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        // تجاهل — سيصل للـ handler الأصلي
      }
    }

    handler.next(err);
  }
}
