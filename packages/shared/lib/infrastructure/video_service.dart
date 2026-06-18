// ============================================================
// TO Best — infrastructure/video_service.dart
// واجهة خدمة الفيديو المجردة
// قابلة للاستبدال: Drive → Cloudflare → Bunny بدون تغيير UI
// ============================================================

import '../domain/entities/health_data.dart' show VideoMetadata;

/// واجهة مجردة لخدمة الفيديو
///
/// يمكن استبدال الـ Implementation بدون أي تغيير في الـ UI أو Domain
abstract class VideoService {
  /// جلب metadata الفيديوهات لتمرين معين
  Future<List<VideoMetadata>> getVideosForExercise(String exerciseId);

  /// الحصول على Streaming URL (لا يظهر للمستخدم)
  Future<String> getStreamUrl(String videoId);

  /// Pre-fetch فيديو في الكاش للاستخدام Offline
  Future<void> prefetchVideo(String videoId);

  /// هل الفيديو موجود في الكاش
  Future<bool> isVideoCached(String videoId);

  /// مسح كاش الفيديو بالكامل
  Future<void> clearVideoCache();

  /// حجم الكاش الحالي بالـ Bytes
  Future<int> getCacheSize();
}
