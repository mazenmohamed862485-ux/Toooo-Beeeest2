// ============================================================
// TO Best — infrastructure/video_service_drive.dart
// Implementation لخدمة الفيديو باستخدام Google Drive عبر GAS
//
// ⚠️ ملاحظة تقنية مهمة:
// Google Drive لا يدعم HTTP Range Requests بشكل كامل.
// هذا يعني أن Seeking داخل الفيديو قد يكون محدوداً أو غير دقيق.
// للحصول على تجربة Seeking أفضل، يُنصح بالترقية إلى:
//   - Cloudflare Stream (يدعم Range Requests و Adaptive Bitrate)
//   - Bunny.net Video (أرخص مع دعم كامل)
// الترقية تتطلب فقط استبدال هذا الملف بـ CloudflareVideoService
// بدون أي تعديل على الـ UI أو الـ Domain Layer.
// ============================================================

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'video_service.dart';
import 'gas_client.dart';
import '../domain/entities/health_data.dart' show VideoMetadata;
import '../config/app_config.dart';

/// Implementation لخدمة الفيديو باستخدام Google Drive عبر GAS
///
/// التطبيق لا يتعامل مع Drive مباشرة أبداً —
/// كل الطلبات تمر عبر GAS للحفاظ على إخفاء الـ URL
class VideoServiceDrive implements VideoService {
  VideoServiceDrive({
    required this.gasClient,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(minutes: 5),
              ),
            );

  final GasClient gasClient;
  final Dio _dio;

  /// مجلد الكاش
  static const String _cacheFolder = 'video_cache';

  /// الحد الأقصى للكاش (500 MB)
  static const int _maxCacheBytes =
      AppConfig.videoCacheMaxMb * 1024 * 1024;

  @override
  Future<List<VideoMetadata>> getVideosForExercise(
      String exerciseId) async {
    final result = await gasClient.post(
      action: 'GET_EXERCISE_VIDEOS',
      data: {'exerciseId': exerciseId},
    );

    final videos = result['videos'] as List<dynamic>? ?? [];
    return videos.map((v) {
      final map = v as Map<String, dynamic>;
      return VideoMetadata(
        videoId: map['videoId']?.toString() ?? '',
        exerciseId: exerciseId,
        title: map['title']?.toString() ?? '',
        durationSeconds:
            int.tryParse(map['duration']?.toString() ?? '0') ?? 0,
        thumbnailUrl: map['thumbnail']?.toString() ?? '',
        driveFileId: map['driveFileId']?.toString() ?? '',
        orderIndex:
            int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  @override
  Future<String> getStreamUrl(String videoId) async {
    // الـ URL يُجلب من GAS ولا يُعرض للمستخدم في الواجهة
    final result = await gasClient.post(
      action: 'GET_VIDEO_STREAM_URL',
      data: {'videoId': videoId},
    );

    final url = result['url']?.toString() ?? '';
    if (url.isEmpty) {
      throw VideoServiceException(
        message: 'Failed to get stream URL for video: $videoId',
      );
    }

    return url;
  }

  @override
  Future<void> prefetchVideo(String videoId) async {
    // فحص الكاش أولاً
    if (await isVideoCached(videoId)) return;

    // فحص حجم الكاش وتنظيفه إذا لزم الأمر
    await _evictIfNeeded();

    final url = await getStreamUrl(videoId);
    final cacheFile = await _getCacheFile(videoId);

    try {
      await _dio.download(url, cacheFile.path);
    } catch (e) {
      // حذف الملف غير المكتمل
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      rethrow;
    }
  }

  @override
  Future<bool> isVideoCached(String videoId) async {
    final file = await _getCacheFile(videoId);
    return file.existsSync() && file.lengthSync() > 0;
  }

  @override
  Future<void> clearVideoCache() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  @override
  Future<int> getCacheSize() async {
    final cacheDir = await _getCacheDir();
    if (!await cacheDir.exists()) return 0;

    int total = 0;
    await for (final entity in cacheDir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// الحصول على مسار ملف الكاش للفيديو
  ///
  /// يُرجع مسار الكاش إذا كان الفيديو محفوظاً،
  /// أو null إذا لم يكن موجوداً (للاستخدام مع video_player مباشرة)
  Future<String?> getCachedVideoPath(String videoId) async {
    final file = await _getCacheFile(videoId);
    if (file.existsSync() && file.lengthSync() > 0) {
      return file.path;
    }
    return null;
  }

  // ── Private Helpers ───────────────────────────────────────

  Future<Directory> _getCacheDir() async {
    final appDir = await getTemporaryDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheFolder');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<File> _getCacheFile(String videoId) async {
    final dir = await _getCacheDir();
    // تنظيف videoId من الأحرف الخاصة
    final safeName = videoId.replaceAll(RegExp(r'[^\w\-]'), '_');
    return File('${dir.path}/$safeName.mp4');
  }

  /// تنظيف الكاش بـ LRU عند تجاوز الحد الأقصى
  Future<void> _evictIfNeeded() async {
    final currentSize = await getCacheSize();
    if (currentSize < _maxCacheBytes) return;

    final cacheDir = await _getCacheDir();
    final files = <File>[];

    await for (final entity in cacheDir.list()) {
      if (entity is File) files.add(entity);
    }

    // ترتيب من الأقدم للأحدث (LRU)
    files.sort(
      (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
    );

    // حذف الملفات القديمة حتى يتحرر 20% من الحجم
    final targetSize = _maxCacheBytes * 0.8;
    var currentBytes = currentSize;

    for (final file in files) {
      if (currentBytes <= targetSize) break;
      final fileSize = await file.length();
      await file.delete();
      currentBytes -= fileSize;
    }
  }
}

/// خطأ في خدمة الفيديو
class VideoServiceException implements Exception {
  const VideoServiceException({required this.message});
  final String message;

  @override
  String toString() => 'VideoServiceException: $message';
}
