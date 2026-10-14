import 'dart:typed_data';

class WatchThumbnailService {
  static final WatchThumbnailService _instance =
      WatchThumbnailService._internal();
  factory WatchThumbnailService() => _instance;
  WatchThumbnailService._internal();

  /// Synchronously get from in-memory cache (no-op)
  Uint8List? getCachedThumbnail(String videoUrl) => null;

  /// Disabled video frame extraction
  Future<Uint8List?> getThumbnail(
    String videoUrl, {
    int timeMs = 200,
    int maxWidth = 360,
    int quality = 75,
  }) async => null;

  /// Preload thumbnails (no-op)
  void preloadThumbnails(List<String> videoUrls) {}

  /// Clear cache (no-op)
  void clearCache() {}
}
