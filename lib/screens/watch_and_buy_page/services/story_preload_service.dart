import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_story_model.dart';
import 'package:video_player/video_player.dart';

class StoryPreloadService {
  static final StoryPreloadService _instance = StoryPreloadService._internal();
  factory StoryPreloadService() => _instance;
  StoryPreloadService._internal();

  final Map<String, VideoPlayerController> _storyVideoPool = {};

  static const Map<String, String> _networkHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Connection': 'keep-alive',
  };

  /// Preload upcoming slide (image or video)
  void preloadSlide(BuildContext context, WatchStorySlide slide) {
    if (slide.mediaType == StoryMediaType.image) {
      if (slide.mediaUrl.isNotEmpty && slide.mediaUrl.startsWith('http')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          precacheImage(CachedNetworkImageProvider(slide.mediaUrl), context).catchError((_) {});
        });
      }
    } else if (slide.mediaType == StoryMediaType.video) {
      if (slide.mediaUrl.isNotEmpty && !_storyVideoPool.containsKey(slide.mediaUrl)) {
        final ctrl = VideoPlayerController.networkUrl(
          Uri.parse(slide.mediaUrl),
          httpHeaders: _networkHeaders,
        );
        _storyVideoPool[slide.mediaUrl] = ctrl;
        ctrl.initialize().then((_) {
          ctrl.setVolume(1.0);
          log('StoryPreloadService: Preloaded video slide ${slide.mediaUrl}');
        }).catchError((e) {
          log('StoryPreloadService: Failed preloading video slide ${slide.mediaUrl}: $e');
        });
      }
    }
  }

  /// Preload all slides for the next store group
  void preloadNextGroup(BuildContext context, WatchStoryGroup group) {
    for (final slide in group.slides) {
      preloadSlide(context, slide);
    }
  }

  /// Get preloaded or create new video player controller for story slide
  VideoPlayerController getOrCreateController(String videoUrl) {
    if (_storyVideoPool.containsKey(videoUrl)) {
      final existing = _storyVideoPool[videoUrl]!;
      if (existing.value.isInitialized) {
        existing.seekTo(Duration.zero);
      }
      return existing;
    }
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      httpHeaders: _networkHeaders,
    );
    _storyVideoPool[videoUrl] = ctrl;
    ctrl.initialize().catchError((_) {});
    return ctrl;
  }

  /// Dispose old controllers
  void disposeExcept(Set<String> keepUrls) {
    final toRemove = _storyVideoPool.keys.where((k) => !keepUrls.contains(k)).toList();
    for (final url in toRemove) {
      final ctrl = _storyVideoPool.remove(url);
      ctrl?.pause();
      ctrl?.dispose();
    }
  }

  void disposeAll() {
    for (final ctrl in _storyVideoPool.values) {
      ctrl.pause();
      ctrl.dispose();
    }
    _storyVideoPool.clear();
  }
}
