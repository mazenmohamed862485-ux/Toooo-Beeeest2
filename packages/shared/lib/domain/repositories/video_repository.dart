// TO Best — domain/repositories/video_repository.dart

import '../entities/health_data.dart' show VideoMetadata;

abstract class VideoRepository {
  Future<List<VideoMetadata>> getVideosForExercise(String exerciseId);
  Future<String> getStreamUrl(String videoId);
  Future<void> prefetchVideo(String videoId);
  Future<bool> isVideoCached(String videoId);
  Future<void> clearVideoCache();
  Future<int> getCacheSize();
}
