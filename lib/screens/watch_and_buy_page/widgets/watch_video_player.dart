import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_video_preload_service.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/like_burst_effect.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:video_player/video_player.dart';

class WatchVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final Uint8List? frameThumbnail;
  final bool isActive;
  final ValueNotifier<bool>? isMutedNotifier;
  final String? heroTag;
  final VoidCallback? onToggleMute;
  final VoidCallback? onDoubleTapLike;

  const WatchVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.frameThumbnail,
    required this.isActive,
    this.isMutedNotifier,
    this.heroTag,
    this.onToggleMute,
    this.onDoubleTapLike,
  });

  @override
  State<WatchVideoPlayer> createState() => _WatchVideoPlayerState();
}

class _WatchVideoPlayerState extends State<WatchVideoPlayer> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;

  // Granular Notifiers to prevent rebuilding the video player widget tree
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _showPlayPauseNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showHeartNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _is2xSpeedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WatchVideoPreloadService().retain(widget.videoUrl);
    widget.isMutedNotifier?.addListener(_onMuteChanged);
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant WatchVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isMutedNotifier != widget.isMutedNotifier) {
      oldWidget.isMutedNotifier?.removeListener(_onMuteChanged);
      widget.isMutedNotifier?.addListener(_onMuteChanged);
      _applyMute();
    }

    if (oldWidget.videoUrl != widget.videoUrl) {
      WatchVideoPreloadService().release(oldWidget.videoUrl);
      WatchVideoPreloadService().retain(widget.videoUrl);
      _detachController();
      _initializePlayer();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _play(restart: true);
      } else {
        _onHoldEnd();
        _pause();
      }
    }
  }

  void _onMuteChanged() {
    _applyMute();
  }

  void _applyMute() {
    final isMuted = widget.isMutedNotifier?.value ?? false;
    try {
      _videoController?.setVolume(isMuted ? 0.0 : 1.0);
    } catch (_) {}
  }

  void _initializePlayer() {
    _hasError = false;
    final isMuted = widget.isMutedNotifier?.value ?? false;
    _videoController = WatchVideoPreloadService().getOrCreateController(
      widget.videoUrl,
      isMuted: isMuted,
    );

    try {
      if (_videoController!.value.isInitialized) {
        _isInitialized = true;
        _hasError = false;
        if (widget.isActive) {
          _videoController!.seekTo(Duration.zero);
          _videoController!.play();
          _isPlayingNotifier.value = true;
        } else {
          _videoController!.pause();
          _isPlayingNotifier.value = false;
        }
      } else {
        _videoController!.addListener(_onControllerUpdate);
      }
    } catch (_) {
      _hasError = true;
    }
  }

  void _onControllerUpdate() {
    if (_videoController == null) return;
    try {
      if (_videoController!.value.isInitialized && !_isInitialized) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        if (widget.isActive) {
          _videoController!.seekTo(Duration.zero);
          _videoController!.play();
          _isPlayingNotifier.value = true;
        }
      }
    } catch (_) {}
  }

  void _play({bool restart = false}) {
    if (mounted) {
      _isPlayingNotifier.value = true;
    }
    _applyMute();
    try {
      if (restart && _videoController != null && _videoController!.value.isInitialized) {
        _videoController!.seekTo(Duration.zero);
      }
      _videoController?.play();
    } catch (_) {}
  }

  void _pause() {
    if (mounted) {
      _isPlayingNotifier.value = false;
    }
    try {
      _videoController?.setVolume(0.0);
      _videoController?.pause();
    } catch (_) {}
  }

  void _togglePlayPause() {
    if (_isPlayingNotifier.value) {
      _pause();
    } else {
      _play(restart: false);
    }

    _showPlayPauseNotifier.value = true;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _showPlayPauseNotifier.value = false;
      }
    });
  }

  void _triggerDoubleTapHeart() {
    final bool isLoggedIn =
        Global.userData != null && Global.userData!.token.isNotEmpty;

    if (isLoggedIn) {
      // If heart animation is already actively running, do not re-trigger or stack
      if (!_showHeartNotifier.value) {
        _showHeartNotifier.value = true;
      }
    }
    widget.onDoubleTapLike?.call();
  }

  void _onHoldStart() {
    if (_videoController == null) return;
    try {
      if (!_videoController!.value.isInitialized) return;
      if (!_isPlayingNotifier.value) {
        _play(restart: false);
      }
      _videoController?.setPlaybackSpeed(2.0);
      _is2xSpeedNotifier.value = true;
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _onHoldEnd() {
    if (_videoController == null) return;
    try {
      if (!_videoController!.value.isInitialized) return;
      _videoController?.setPlaybackSpeed(1.0);
      _is2xSpeedNotifier.value = false;
    } catch (_) {}
  }

  void _detachController() {
    if (_videoController != null) {
      try {
        _videoController?.setPlaybackSpeed(1.0);
        _videoController?.setVolume(0.0);
        _videoController?.pause();
        _videoController?.removeListener(_onControllerUpdate);
      } catch (_) {}
      _videoController = null;
    }
  }

  @override
  void dispose() {
    widget.isMutedNotifier?.removeListener(_onMuteChanged);
    _onHoldEnd();
    _detachController();
    WatchVideoPreloadService().release(widget.videoUrl);
    _isPlayingNotifier.dispose();
    _showPlayPauseNotifier.dispose();
    _showHeartNotifier.dispose();
    _is2xSpeedNotifier.dispose();
    super.dispose();
  }

  Widget _buildThumbnail() {
    if (widget.thumbnailUrl.isNotEmpty) {
      return CustomImageContainer(
        imagePath: widget.thumbnailUrl,
        fit: BoxFit.cover,
      );
    }

    if (widget.frameThumbnail != null) {
      return Image.memory(
        widget.frameThumbnail!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return Container(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      onDoubleTap: _triggerDoubleTapHeart,
      onLongPressStart: (_) => _onHoldStart(),
      onLongPressEnd: (_) => _onHoldEnd(),
      onLongPressCancel: _onHoldEnd,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // 1. Background Thumbnail (Shown immediately at 0ms as Hero destination)
          widget.heroTag != null
              ? Hero(
                  tag: widget.heroTag!,
                  flightShuttleBuilder: (
                    flightContext,
                    animation,
                    flightDirection,
                    fromHeroContext,
                    toHeroContext,
                  ) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        final radius =
                            (12.r * (1.0 - animation.value)).clamp(0.0, 12.r);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: _buildThumbnail(),
                        );
                      },
                    );
                  },
                  child: _buildThumbnail(),
                )
              : _buildThumbnail(),

          // 2. Pre-Buffered Video Player with Zero-Flicker Crossfade
          if (_videoController != null &&
              !_hasError &&
              _videoController!.value.isInitialized)
            AnimatedOpacity(
              opacity: _isInitialized ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeIn,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            ),

          // 3. Error Fallback (Only shown if video genuinely failed to load)
          if (_hasError)
            Container(
              color: Colors.black45,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _detachController();
                    _initializePlayer();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Tap to retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 4. Play / Pause Overlay Indicator with ValueListenableBuilder
          ValueListenableBuilder<bool>(
            valueListenable: _showPlayPauseNotifier,
            builder: (context, showIcon, _) {
              if (!showIcon) return const SizedBox.shrink();
              return Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isPlayingNotifier,
                  builder: (context, isPlaying, _) {
                    return Container(
                      width: 68.r,
                      height: 68.r,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1.2),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 40.r,
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 5. Double-Tap Heart Burst Shower (No enlarging heart effect)
          ValueListenableBuilder<bool>(
            valueListenable: _showHeartNotifier,
            builder: (context, showHeart, _) {
              if (!showHeart) return const SizedBox.shrink();
              return Center(
                child: HeartBurstShower(
                  particleCount: 24,
                  baseDistance: 70.0,
                  sizeMultiplier: 1.3,
                  onComplete: () {
                    if (mounted) {
                      _showHeartNotifier.value = false;
                    }
                  },
                ),
              );
            },
          ),

          // 6. 2X Speed Hold Indicator Pill with ValueListenableBuilder
          ValueListenableBuilder<bool>(
            valueListenable: _is2xSpeedNotifier,
            builder: (context, is2x, _) {
              if (!is2x) return const SizedBox.shrink();
              return Positioned(
                top: 75.h,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6.w),
                      const Text(
                        '2X Speed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
