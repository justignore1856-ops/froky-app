import 'dart:async';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/repo/watch_and_buy_repo.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_video_preload_service.dart';
import 'package:video_player/video_player.dart';

class WatchStatusPreloadService {
  static final WatchStatusPreloadService _instance =
      WatchStatusPreloadService._internal();
  factory WatchStatusPreloadService() => _instance;
  WatchStatusPreloadService._internal();

  final WatchAndBuyRepository _repository = WatchAndBuyRepository();
  final Map<String, List<WatchStatusItem>> _cachedStatuses = {};
  final Set<String> _inFlightFetches = {};
  final Set<String> _preloadedMediaUrls = {};

  Map<String, List<WatchStatusItem>> get cachedStatuses => _cachedStatuses;

  List<WatchStatusItem>? getCached(String username) => _cachedStatuses[username];

  void setCached(String username, List<WatchStatusItem> items) {
    _cachedStatuses[username] = items;
  }

  bool hasCached(String username) =>
      _cachedStatuses.containsKey(username) &&
      (_cachedStatuses[username]?.isNotEmpty ?? false);

  void clearCache() {
    _cachedStatuses.clear();
    _inFlightFetches.clear();
    _preloadedMediaUrls.clear();
  }

  void invalidateProfile(String username) {
    _cachedStatuses.remove(username);
    _inFlightFetches.remove(username);
  }

  /// Preload statuses for the top items in the tray (e.g. first 5 items)
  Future<void> preloadStatusFeed(
    List<WatchStatusFeedItem> feedItems, {
    int count = 5,
    bool forceRefresh = false,
  }) async {
    if (feedItems.isEmpty) return;
    if (forceRefresh) {
      _cachedStatuses.clear();
      _preloadedMediaUrls.clear();
    }
    final limit = count.clamp(1, feedItems.length);
    for (int i = 0; i < limit; i++) {
      final username = feedItems[i].profile.username;
      if (username.isNotEmpty) {
        // Preload video media for the top 2 profiles to conserve hardware decoders
        preloadProfile(
          username,
          forceRefresh: forceRefresh,
          preloadVideo: i < 2,
        );
      }
    }
  }

  /// Preload statuses for a single profile
  Future<List<WatchStatusItem>?> preloadProfile(
    String username, {
    bool forceRefresh = false,
    bool preloadVideo = true,
  }) async {
    if (username.isEmpty) return null;
    if (!forceRefresh && _cachedStatuses.containsKey(username)) {
      final cached = _cachedStatuses[username]!;
      if (preloadVideo && cached.isNotEmpty) {
        _preloadSlideMedia(cached.first);
      }
      return cached;
    }
    if (_inFlightFetches.contains(username)) {
      return null;
    }

    _inFlightFetches.add(username);

    try {
      final res = await _repository.fetchProfileStatuses(
        username: username,
        perPage: 15,
      );
      _cachedStatuses[username] = res.items;

      // Preload media for first slide safely
      if (res.items.isNotEmpty) {
        if (preloadVideo) {
          _preloadSlideMedia(res.items.first);
        } else {
          _precacheImagesOnly(res.items.first);
        }
      }
      return res.items;
    } catch (e) {
      log('WatchStatusPreloadService preloadProfile error ($username): $e');
      return null;
    } finally {
      _inFlightFetches.remove(username);
    }
  }

  void _precacheImagesOnly(WatchStatusItem slide) {
    if (slide.isImage && slide.mediaUrl.isNotEmpty) {
      try {
        CachedNetworkImageProvider(slide.mediaUrl)
            .resolve(ImageConfiguration.empty);
      } catch (_) {}
    }
    if (slide.coverUrl != null && slide.coverUrl!.isNotEmpty) {
      try {
        CachedNetworkImageProvider(slide.coverUrl!)
            .resolve(ImageConfiguration.empty);
      } catch (_) {}
    }
  }

  void _preloadSlideMedia(WatchStatusItem slide) {
    if (slide.mediaUrl.isEmpty || _preloadedMediaUrls.contains(slide.mediaUrl)) {
      return;
    }
    _preloadedMediaUrls.add(slide.mediaUrl);

    if (slide.isVideo) {
      WatchVideoPreloadService().getOrCreateController(
        slide.mediaUrl,
        isMuted: true,
        isLooping: false,
      );
    } else {
      if (slide.mediaUrl.startsWith('http')) {
        try {
          CachedNetworkImageProvider(slide.mediaUrl)
              .resolve(ImageConfiguration.empty);
        } catch (_) {}
      }
    }

    if (slide.coverUrl != null && slide.coverUrl!.startsWith('http')) {
      try {
        CachedNetworkImageProvider(slide.coverUrl!)
            .resolve(ImageConfiguration.empty);
      } catch (_) {}
    }
  }

  /// Get preloaded video controller or create new one via unified WatchVideoPreloadService
  VideoPlayerController getOrCreateVideoController(String videoUrl) {
    return WatchVideoPreloadService().getOrCreateController(
      videoUrl,
      isLooping: false,
    );
  }

  bool isVideoInitialized(String videoUrl) {
    return WatchVideoPreloadService().isInitialized(videoUrl);
  }

  void invalidateVideo(String videoUrl) {
    _preloadedMediaUrls.remove(videoUrl);
    WatchVideoPreloadService().invalidate(videoUrl);
  }

  void releaseVideo(String videoUrl) {
    WatchVideoPreloadService().release(videoUrl);
  }

  void disposeAllVideos() {
    _preloadedMediaUrls.clear();
    WatchVideoPreloadService().disposeAll();
  }
}
