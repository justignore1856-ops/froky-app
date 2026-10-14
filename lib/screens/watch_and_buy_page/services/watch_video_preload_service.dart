import 'dart:async';
import 'dart:developer';
import 'package:video_player/video_player.dart';

class WatchVideoPreloadService {
  static final WatchVideoPreloadService _instance =
      WatchVideoPreloadService._internal();
  factory WatchVideoPreloadService() => _instance;
  WatchVideoPreloadService._internal();

  final Map<String, VideoPlayerController> _pool = {};
  final Set<String> _initializingUrls = {};
  final Map<String, int> _activeReferences = {};
  final Map<String, bool> _mutedStates = {};

  static const Map<String, String> _networkHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Connection': 'keep-alive',
  };

  static Uri _safeUri(String url) {
    final trimmed = url.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme && !trimmed.contains(' ')) {
      return parsed;
    }
    try {
      return Uri.parse(Uri.encodeFull(trimmed));
    } catch (_) {
      return Uri.parse(trimmed);
    }
  }

  /// Increment active widget reference count for this URL
  void retain(String videoUrl) {
    if (videoUrl.isEmpty) return;
    _activeReferences[videoUrl] = (_activeReferences[videoUrl] ?? 0) + 1;
  }

  /// Decrement active widget reference count for this URL
  void release(String videoUrl) {
    if (videoUrl.isEmpty) return;
    final current = _activeReferences[videoUrl] ?? 0;
    if (current <= 1) {
      _activeReferences.remove(videoUrl);
    } else {
      _activeReferences[videoUrl] = current - 1;
    }
  }

  /// Check if a URL is currently attached to an active player widget
  bool isActivelyUsed(String videoUrl) {
    return (_activeReferences[videoUrl] ?? 0) > 0;
  }

  /// Get preloaded controller or create a new one synchronously
  VideoPlayerController getOrCreateController(
    String videoUrl, {
    bool isMuted = false,
    bool isLooping = true,
  }) {
    if (videoUrl.isEmpty) {
      throw ArgumentError('videoUrl cannot be empty');
    }
    _mutedStates[videoUrl] = isMuted;

    if (_pool.containsKey(videoUrl)) {
      final ctrl = _pool[videoUrl]!;
      try {
        if (!ctrl.value.hasError) {
          ctrl.setVolume(isMuted ? 0.0 : 1.0);
          ctrl.setLooping(isLooping);
          return ctrl;
        }
      } catch (_) {
        _pool.remove(videoUrl);
      }
    }

    final controller = VideoPlayerController.networkUrl(
      _safeUri(videoUrl),
      httpHeaders: _networkHeaders,
    );

    _pool[videoUrl] = controller;
    _initializeController(
      videoUrl,
      controller,
      isMuted: isMuted,
      isLooping: isLooping,
    );
    return controller;
  }

  /// Check if a controller is ready to play immediately
  bool isInitialized(String videoUrl) {
    final ctrl = _pool[videoUrl];
    if (ctrl == null) return false;
    try {
      return ctrl.value.isInitialized && !ctrl.value.hasError;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initializeController(
    String videoUrl,
    VideoPlayerController controller, {
    bool isMuted = false,
    bool isLooping = true,
  }) async {
    if (_initializingUrls.contains(videoUrl)) return;
    _initializingUrls.add(videoUrl);

    try {
      await controller.initialize();
      await controller.setLooping(isLooping);
      final targetMuted = _mutedStates[videoUrl] ?? isMuted;
      await controller.setVolume(targetMuted ? 0.0 : 1.0);
      log('WatchVideoPreloadService: Preloaded & buffered $videoUrl');
    } catch (e) {
      log('WatchVideoPreloadService: Failed to initialize $videoUrl: $e');
      if (_pool[videoUrl] == controller && !isActivelyUsed(videoUrl)) {
        _pool.remove(videoUrl);
        try {
          controller.dispose();
        } catch (_) {}
      }
    } finally {
      _initializingUrls.remove(videoUrl);
    }
  }

  /// Preload surrounding videos in a sliding window around currentIndex
  void preloadSurroundingVideos(
    List<String> videoUrls,
    int currentIndex, {
    int bufferAhead = 2,
    int bufferBehind = 1,
    bool isLooping = true,
  }) {
    if (videoUrls.isEmpty) return;

    final keepUrls = <String>{};
    final minIndex = (currentIndex - bufferBehind).clamp(0, videoUrls.length - 1);
    final maxIndex = (currentIndex + bufferAhead).clamp(0, videoUrls.length - 1);

    // 1. Mark and preload window URLs (keep volume 0 while preloading)
    for (int i = minIndex; i <= maxIndex; i++) {
      final url = videoUrls[i];
      if (url.isNotEmpty) {
        keepUrls.add(url);
        if (!_pool.containsKey(url)) {
          _mutedStates[url] = true;
          final ctrl = VideoPlayerController.networkUrl(
            _safeUri(url),
            httpHeaders: _networkHeaders,
          );
          _pool[url] = ctrl;
          _initializeController(
            url,
            ctrl,
            isMuted: true,
            isLooping: isLooping,
          );
        }
      }
    }

    // 2. Dispose distant controllers only if NOT currently used by an active widget
    final urlsToDispose = _pool.keys
        .where((u) => !keepUrls.contains(u) && !isActivelyUsed(u))
        .toList();
    for (final url in urlsToDispose) {
      final ctrl = _pool.remove(url);
      _mutedStates.remove(url);
      if (ctrl != null) {
        try {
          ctrl.setVolume(0.0);
          ctrl.pause();
          ctrl.dispose();
          log('WatchVideoPreloadService: Disposed distant controller for $url');
        } catch (_) {}
      }
    }
  }

  /// Preload a list of top videos (e.g. from the feed grid)
  void preloadTopVideos(
    List<String> videoUrls, {
    int count = 2,
    bool isLooping = true,
  }) {
    final topCount = count.clamp(1, videoUrls.length);
    for (int i = 0; i < topCount; i++) {
      final url = videoUrls[i];
      if (url.isNotEmpty && !_pool.containsKey(url)) {
        _mutedStates[url] = true;
        final ctrl = VideoPlayerController.networkUrl(
          _safeUri(url),
          httpHeaders: _networkHeaders,
        );
        _pool[url] = ctrl;
        _initializeController(
          url,
          ctrl,
          isMuted: true,
          isLooping: isLooping,
        );
      }
    }
  }

  /// Invalidate and dispose a specific video URL controller
  void invalidate(String videoUrl) {
    if (videoUrl.isEmpty) return;
    _initializingUrls.remove(videoUrl);
    _activeReferences.remove(videoUrl);
    _mutedStates.remove(videoUrl);
    final ctrl = _pool.remove(videoUrl);
    if (ctrl != null) {
      try {
        ctrl.setVolume(0.0);
        ctrl.pause();
        ctrl.dispose();
        log('WatchVideoPreloadService: Invalidated controller for $videoUrl');
      } catch (_) {}
    }
  }

  /// Stop & pause all active controllers and mute audio completely
  void pauseAll() {
    for (final ctrl in _pool.values) {
      try {
        ctrl.setVolume(0.0);
        if (ctrl.value.isInitialized) {
          ctrl.pause();
        }
      } catch (_) {}
    }
  }

  /// Dispose inactive controllers on teardown
  void disposeAll() {
    final urlsToDispose = _pool.keys.where((u) => !isActivelyUsed(u)).toList();
    for (final url in urlsToDispose) {
      final ctrl = _pool.remove(url);
      _mutedStates.remove(url);
      if (ctrl != null) {
        try {
          ctrl.setVolume(0.0);
          ctrl.pause();
          ctrl.dispose();
        } catch (_) {}
      }
    }
    _initializingUrls.clear();
  }
}
