import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_status_bloc/watch_status_feed_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/repo/watch_and_buy_repo.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_status_preload_service.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_video_preload_service.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:video_player/video_player.dart';

import '../../../router/app_routes.dart';

class StatusViewerPage extends StatefulWidget {
  final List<WatchStatusFeedItem> statusProfiles;
  final int initialProfileIndex;

  const StatusViewerPage({
    super.key,
    required this.statusProfiles,
    this.initialProfileIndex = 0,
  });

  @override
  State<StatusViewerPage> createState() => _StatusViewerPageState();
}

class _StatusViewerPageState extends State<StatusViewerPage>
    with TickerProviderStateMixin {
  late PageController _profilePageController;
  late int _currentProfileIndex;
  int _currentSlideIndex = 0;
  int? _targetSlideIndex;

  final WatchAndBuyRepository _repository = WatchAndBuyRepository();
  final Map<String, List<WatchStatusItem>> _profileStatusesCache = {};
  final Map<String, bool> _profileLoadingState = {};
  final Set<int> _syncedSeenIds = {};
  final Set<int> _pendingSeenStatusIds = {};
  Timer? _seenSyncDebounceTimer;

  AnimationController? _animController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isVideoLoading = false;
  bool _videoHasError = false;
  String? _activeVideoUrl;

  // Instagram-style Heavyweight Drag Down to Dismiss state
  double _dragOffsetY = 0.0;
  AnimationController? _springBackController;
  Animation<double>? _springBackAnimation;

  int _calculateInitialSlideIndex(List<WatchStatusItem> slides) {
    if (slides.isEmpty) return 0;

    // Instagram style: Find the first unseen status slide
    final firstUnseenIndex = slides.indexWhere(
      (slide) => !slide.seenByMe && !_syncedSeenIds.contains(slide.id),
    );

    // If there is an unseen slide, jump directly to it
    if (firstUnseenIndex != -1) {
      return firstUnseenIndex;
    }

    // If all slides are seen, start from the first status (index 0)
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _springBackController!.addListener(() {
      if (_springBackAnimation != null) {
        setState(() {
          _dragOffsetY = _springBackAnimation!.value;
        });
      }
    });
    _springBackController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _resume();
      }
    });

    _currentProfileIndex = widget.initialProfileIndex.clamp(
      0,
      widget.statusProfiles.length - 1,
    );
    _profilePageController =
        PageController(initialPage: _currentProfileIndex);

    // Sync preloaded cache synchronously for 0ms initial open
    _profileStatusesCache.addAll(WatchStatusPreloadService().cachedStatuses);

    final initialUsername =
        widget.statusProfiles[_currentProfileIndex].profile.username;
    if (_profileStatusesCache.containsKey(initialUsername) &&
        _profileStatusesCache[initialUsername]!.isNotEmpty) {
      _currentSlideIndex =
          _calculateInitialSlideIndex(_profileStatusesCache[initialUsername]!);
      _loadCurrentSlide();
    }

    _fetchStatusesForProfile(_currentProfileIndex);
  }

  Future<void> _fetchStatusesForProfile(int profileIndex) async {
    if (profileIndex < 0 || profileIndex >= widget.statusProfiles.length) {
      return;
    }

    final profileItem = widget.statusProfiles[profileIndex];
    final username = profileItem.profile.username;

    // Check if available in preload service
    if (!_profileStatusesCache.containsKey(username)) {
      final preloaded = WatchStatusPreloadService().getCached(username);
      if (preloaded != null && preloaded.isNotEmpty) {
        _profileStatusesCache[username] = preloaded;
      }
    }

    final bool hasCachedSlides = _profileStatusesCache.containsKey(username) &&
        _profileStatusesCache[username]!.isNotEmpty;

    if (hasCachedSlides) {
      if (profileIndex == _currentProfileIndex && _animController == null) {
        _currentSlideIndex =
            _calculateInitialSlideIndex(_profileStatusesCache[username]!);
        _loadCurrentSlide();
      }
      _preloadAdjacentProfiles(profileIndex);
    } else {
      setState(() {
        _profileLoadingState[username] = true;
      });
    }

    try {
      final response = await _repository.fetchProfileStatuses(
        username: username,
        perPage: 15,
      );

      _profileStatusesCache[username] = response.items;
      WatchStatusPreloadService().setCached(username, response.items);
      _profileLoadingState[username] = false;

      if (mounted && profileIndex == _currentProfileIndex) {
        if (!hasCachedSlides || _animController == null) {
          _currentSlideIndex =
              _calculateInitialSlideIndex(response.items);
          _loadCurrentSlide();
        }
        setState(() {});
      }

      _preloadAdjacentProfiles(profileIndex);
      _preloadSurroundingStatusVideos();
    } catch (e) {
      log('StatusViewerPage _fetchStatusesForProfile error: $e');
      if (mounted) {
        setState(() {
          _profileLoadingState[username] = false;
        });
      }
    }
  }

  void _preloadAdjacentProfiles(int currentIndex) {
    if (currentIndex + 1 < widget.statusProfiles.length) {
      final nextUsername =
          widget.statusProfiles[currentIndex + 1].profile.username;
      WatchStatusPreloadService()
          .preloadProfile(nextUsername)
          .then((items) {
        if (items != null && items.isNotEmpty) {
          _profileStatusesCache[nextUsername] = items;
          if (mounted) _preloadSurroundingStatusVideos();
        }
      });
    }
    if (currentIndex - 1 >= 0) {
      final prevUsername =
          widget.statusProfiles[currentIndex - 1].profile.username;
      WatchStatusPreloadService()
          .preloadProfile(prevUsername)
          .then((items) {
        if (items != null && items.isNotEmpty) {
          _profileStatusesCache[prevUsername] = items;
          if (mounted) _preloadSurroundingStatusVideos();
        }
      });
    }
  }

  void _onVideoControllerUpdate() {
    if (_videoController == null || !mounted) return;
    try {
      final value = _videoController!.value;
      if (value.hasError && !_videoHasError) {
        setState(() {
          _videoHasError = true;
          _isVideoLoading = false;
        });
        return;
      }

      if (value.isInitialized && _isVideoLoading && !_videoHasError) {
        final currentProfile = widget.statusProfiles[_currentProfileIndex];
        final slides =
            _profileStatusesCache[currentProfile.profile.username] ?? [];
        final slide = slides.isNotEmpty && _currentSlideIndex < slides.length
            ? slides[_currentSlideIndex]
            : null;
        final fallbackDuration =
            slide?.slideDuration ?? const Duration(seconds: 5);

        setState(() {
          _isVideoLoading = false;
          _videoHasError = false;
        });

        final duration = value.duration;
        _startAnimation(
          duration > Duration.zero ? duration : fallbackDuration,
        );
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      }
    } catch (_) {}
  }

  void _preloadSurroundingStatusVideos() {
    final orderedVideoUrls = <String>[];
    int currentUrlIndex = -1;

    final startProfile =
        (_currentProfileIndex - 1).clamp(0, widget.statusProfiles.length - 1);
    final endProfile =
        (_currentProfileIndex + 2).clamp(0, widget.statusProfiles.length - 1);

    for (int p = startProfile; p <= endProfile; p++) {
      final username = widget.statusProfiles[p].profile.username;
      final slides = _profileStatusesCache[username] ?? [];
      for (int s = 0; s < slides.length; s++) {
        final slide = slides[s];
        if (slide.isVideo && slide.mediaUrl.isNotEmpty) {
          final url = slide.mediaUrl;
          if (p == _currentProfileIndex && s == _currentSlideIndex) {
            currentUrlIndex = orderedVideoUrls.length;
          }
          orderedVideoUrls.add(url);
        }
      }
    }

    if (orderedVideoUrls.isNotEmpty && currentUrlIndex != -1) {
      WatchVideoPreloadService().preloadSurroundingVideos(
        orderedVideoUrls,
        currentUrlIndex,
        bufferAhead: 2,
        bufferBehind: 1,
        isLooping: false,
      );
    } else if (orderedVideoUrls.isNotEmpty) {
      WatchVideoPreloadService().preloadTopVideos(
        orderedVideoUrls,
        count: 2,
        isLooping: false,
      );
    }
  }

  void _loadCurrentSlide() {
    _animController?.dispose();
    _animController = null;
    if (_videoController != null) {
      _videoController?.removeListener(_onVideoControllerUpdate);
      _videoController?.pause();
      if (_activeVideoUrl != null) {
        WatchVideoPreloadService().release(_activeVideoUrl!);
      }
      _videoController = null;
    }
    _isVideoLoading = false;
    _videoHasError = false;
    _activeVideoUrl = null;

    final currentProfile = widget.statusProfiles[_currentProfileIndex];
    final slides = _profileStatusesCache[currentProfile.profile.username] ?? [];

    if (slides.isEmpty) return;

    if (_currentSlideIndex >= slides.length) {
      _currentSlideIndex = 0;
    }

    final slide = slides[_currentSlideIndex];

    // Mark as seen
    _markSlideSeen(slide, slides);

    if (slide.isVideo) {
      _activeVideoUrl = slide.mediaUrl;
      WatchVideoPreloadService().retain(slide.mediaUrl);
      _videoController = WatchVideoPreloadService().getOrCreateController(
        slide.mediaUrl,
        isMuted: false,
        isLooping: false,
      );
      _videoController!.addListener(_onVideoControllerUpdate);

      if (_videoController!.value.isInitialized &&
          !_videoController!.value.hasError) {
        _isVideoLoading = false;
        _videoHasError = false;
        final duration = _videoController!.value.duration;
        _startAnimation(
          duration > Duration.zero ? duration : slide.slideDuration,
        );
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      } else {
        _isVideoLoading = true;
        _videoHasError = false;
      }
    } else {
      _startAnimation(slide.slideDuration);
    }

    _preloadSurroundingStatusVideos();
    setState(() {});
  }

  void _retryCurrentVideo() {
    final currentProfile = widget.statusProfiles[_currentProfileIndex];
    final slides = _profileStatusesCache[currentProfile.profile.username] ?? [];
    if (slides.isEmpty || _currentSlideIndex >= slides.length) return;
    final slide = slides[_currentSlideIndex];
    if (!slide.isVideo) return;

    setState(() {
      _videoHasError = false;
      _isVideoLoading = true;
    });

    if (_activeVideoUrl != null) {
      WatchVideoPreloadService().invalidate(_activeVideoUrl!);
    }
    if (_videoController != null) {
      _videoController?.removeListener(_onVideoControllerUpdate);
      _videoController?.pause();
      _videoController = null;
    }

    _activeVideoUrl = slide.mediaUrl;
    WatchVideoPreloadService().retain(slide.mediaUrl);
    _videoController = WatchVideoPreloadService().getOrCreateController(
      slide.mediaUrl,
      isMuted: false,
      isLooping: false,
    );
    _videoController!.addListener(_onVideoControllerUpdate);

    if (_videoController!.value.isInitialized &&
        !_videoController!.value.hasError) {
      setState(() {
        _isVideoLoading = false;
        _videoHasError = false;
      });
      final duration = _videoController!.value.duration;
      _startAnimation(
        duration > Duration.zero ? duration : slide.slideDuration,
      );
      _videoController!.seekTo(Duration.zero);
      _videoController!.play();
    }
  }

  void _startAnimation(Duration duration) {
    _animController = AnimationController(vsync: this, duration: duration);
    _animController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onNextSlide();
      }
    });
    _animController!.forward();
    setState(() {});
  }

  void _markSlideSeen(WatchStatusItem slide, List<WatchStatusItem> slides) {
    final bool isLoggedIn =
        Global.userData != null && (Global.token?.isNotEmpty ?? false);
    if (!isLoggedIn) {
      // Unauthenticated users can watch stories freely, but seen tracking is disabled
      return;
    }

    if (!_syncedSeenIds.contains(slide.id)) {
      _syncedSeenIds.add(slide.id);
      _pendingSeenStatusIds.add(slide.id);

      // Instantly mark the slide as seen in our local in-memory cache
      final username =
          widget.statusProfiles[_currentProfileIndex].profile.username;
      final cachedList = _profileStatusesCache[username];
      if (cachedList != null) {
        final slideIdx = cachedList.indexWhere((s) => s.id == slide.id);
        if (slideIdx != -1) {
          cachedList[slideIdx] = cachedList[slideIdx].copyWith(seenByMe: true);
        }
      }

      // If all statuses of this seller are seen, instantly update the tray ring locally
      final allSeen = slides.every((s) => s.seenByMe || _syncedSeenIds.contains(s.id));
      if (allSeen && mounted) {
        context
            .read<WatchStatusFeedBloc>()
            .add(MarkProfileStatusAsSeenLocally(username: username));
      }

      // Debounce and batch API requests to prevent race conditions and duplicate API calls
      _seenSyncDebounceTimer?.cancel();
      _seenSyncDebounceTimer = Timer(const Duration(milliseconds: 400), () {
        _flushPendingSeenStatuses();
      });
    }
  }

  void _flushPendingSeenStatuses() {
    if (_pendingSeenStatusIds.isEmpty) return;
    final idsToSync = _pendingSeenStatusIds.toList();
    _pendingSeenStatusIds.clear();
    _repository.markStatusesSeen(statusIds: idsToSync);
  }

  void _onNextSlide() {
    final currentProfile = widget.statusProfiles[_currentProfileIndex];
    final slides = _profileStatusesCache[currentProfile.profile.username] ?? [];

    if (_currentSlideIndex < slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _loadCurrentSlide();
    } else {
      // Move to next creator profile
      if (_currentProfileIndex < widget.statusProfiles.length - 1) {
        final nextProfile = widget.statusProfiles[_currentProfileIndex + 1];
        final nextSlides =
            _profileStatusesCache[nextProfile.profile.username] ?? [];
        _currentSlideIndex = _calculateInitialSlideIndex(nextSlides);
        _profilePageController.nextPage(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      } else {
        if (mounted) {
          GoRouter.of(context).pop();
        }
      }
    }
  }

  void _onPrevSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _loadCurrentSlide();
    } else {
      if (_currentProfileIndex > 0) {
        final prevProfile =
            widget.statusProfiles[_currentProfileIndex - 1];
        final prevSlides =
            _profileStatusesCache[prevProfile.profile.username] ?? [];
        _targetSlideIndex =
            prevSlides.isNotEmpty ? prevSlides.length - 1 : 0;
        _profilePageController.previousPage(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _pause() {
    if (_isPaused) return;
    _isPaused = true;
    _animController?.stop();
    try {
      _videoController?.pause();
    } catch (_) {}
  }

  void _resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _animController?.forward();
    try {
      if (_videoController != null &&
          _videoController!.value.isInitialized &&
          !_videoHasError) {
        _videoController?.play();
      }
    } catch (_) {}
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _springBackController?.stop();
    _pause();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta == null) return;
    final newOffset = _dragOffsetY + (details.primaryDelta! * 0.30);
    if (newOffset >= 0) {
      setState(() {
        _dragOffsetY = newOffset.clamp(0.0, 320.0);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffsetY > 130.0 || velocity > 650.0) {
      GoRouter.of(context).pop();
    } else {
      _springBackAnimation = Tween<double>(
        begin: _dragOffsetY,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _springBackController!,
          curve: Curves.easeOutCubic,
        ),
      );
      _springBackController!.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _seenSyncDebounceTimer?.cancel();
    _flushPendingSeenStatuses();
    _springBackController?.dispose();
    _animController?.dispose();
    if (_videoController != null) {
      _videoController?.removeListener(_onVideoControllerUpdate);
      _videoController?.pause();
      if (_activeVideoUrl != null) {
        WatchVideoPreloadService().release(_activeVideoUrl!);
      }
      _videoController = null;
    }
    _profilePageController.dispose();
    super.dispose();
  }

  Widget _buildProgressBar(int totalSlides) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: List.generate(totalSlides, (idx) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              height: 3.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: AnimatedBuilder(
                animation: _animController ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, _) {
                  double value = 0.0;
                  if (idx < _currentSlideIndex) {
                    value = 1.0;
                  } else if (idx == _currentSlideIndex) {
                    value = _animController?.value ?? 0.0;
                  }

                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductList(List<WatchProductItem> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    if (products.length == 1) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: SizedBox(
          height: 90,
          child: _buildSingleProductCard(
            products.first,
          ),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, idx) {
          return _buildSingleProductCard(
            products[idx],
            width: 220.w,
          );
        },
      ),
    );
  }

  Widget _buildSingleProductCard(WatchProductItem product, {double? width}) {
    final price = product.displayPrice;
    final originalPrice = product.price;
    final hasDiscount = product.hasDiscount;
    final discountPercent = hasDiscount
        ? (((originalPrice - price) / originalPrice) * 100).round()
        : 0;

    final currency =
        product.currencySymbol.isNotEmpty ? product.currencySymbol : '₹';

    final ratingDisplay = product.ratings != null
        ? product.ratings!.toStringAsFixed(1)
        : (product.ratingCount?.toString());

    return GestureDetector(
      onTap: () {
        if (product.productSlug.isNotEmpty) {
          _pause();
          GoRouter.of(context).push(
            AppRoutes.productDetailPage,
            extra: {'productSlug': product.productSlug},
          ).then((_) {
            if (mounted) _resume();
          });
        }
      },
      child: Container(
        width: width,
        height: 100,
        padding: EdgeInsets.all(7.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Thumbnail Image
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CustomImageContainer(
                      imagePath: product.image,
                      height: 52.r,
                      width: 40.r,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (ratingDisplay != null)
                  PositionedDirectional(
                    bottom: 3,
                    start: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          Text(
                            ratingDisplay,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            TablerIcons.star_filled,
                            size: 10,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8.w),

            // Product Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Price and Discount row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.w,
                    runSpacing: 2.h,
                    children: [
                      Text(
                        '$currency${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (hasDiscount)
                        Text(
                          '$currency${originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black38,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (hasDiscount)
                        Text(
                          '$discountPercent% OFF',
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoStatusSlide(
    WatchStatusItem slide,
    WatchProfile profile,
    int groupIndex,
  ) {
    final bool isCurrentProfile = groupIndex == _currentProfileIndex;
    final bool isInitialized = isCurrentProfile &&
        _videoController != null &&
        _videoController!.value.isInitialized &&
        !_videoHasError;

    Widget placeholderBackground;
    if (slide.coverUrl != null && slide.coverUrl!.isNotEmpty) {
      placeholderBackground = CustomImageContainer(
        imagePath: slide.coverUrl!,
        fit: BoxFit.cover,
      );
    } else {
      placeholderBackground = Stack(
        fit: StackFit.expand,
        children: [
          CustomImageContainer(
            imagePath: profile.photoUrl,
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ],
      );
    }

    if (groupIndex == widget.initialProfileIndex && _currentSlideIndex == 0) {
      placeholderBackground = Hero(
        tag: 'hero_status_media_${profile.username}_$groupIndex',
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
              final radius = (29.r * (1.0 - animation.value)).clamp(0.0, 29.r);
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: placeholderBackground,
              );
            },
          );
        },
        child: placeholderBackground,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Placeholder Background (Cover / Blurred Profile Avatar)
        placeholderBackground,

        // 2. Video Player with FittedBox(fit: BoxFit.cover)
        if (isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width > 0
                    ? _videoController!.value.size.width
                    : (slide.width > 0 ? slide.width.toDouble() : 720.0),
                height: _videoController!.value.size.height > 0
                    ? _videoController!.value.size.height
                    : (slide.height > 0 ? slide.height.toDouble() : 1280.0),
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),

        // 3. Subtle Circular Loader while video is buffering / initializing
        if (isCurrentProfile && _isVideoLoading && !isInitialized && !_videoHasError)
          const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ),

        // 4. Retry UI if video fails to load
        if (isCurrentProfile && _videoHasError)
          Center(
            child: GestureDetector(
              onTap: _retryCurrentVideo,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Video unavailable. Tap to retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageStatusSlide(
    WatchStatusItem slide,
    WatchProfile profile,
    int groupIndex,
  ) {
    final bool isInitialFirstSlide =
        groupIndex == widget.initialProfileIndex && _currentSlideIndex == 0;

    if (isInitialFirstSlide) {
      return Hero(
        tag: 'hero_status_media_${profile.username}_$groupIndex',
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
              final radius = (29.r * (1.0 - animation.value)).clamp(0.0, 29.r);
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CustomImageContainer(
                  imagePath: slide.mediaUrl,
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
        child: CustomImageContainer(
          imagePath: slide.mediaUrl,
          fit: BoxFit.cover,
        ),
      );
    }

    return CustomImageContainer(
      imagePath: slide.mediaUrl,
      fit: BoxFit.cover,
    );
  }

  Widget _buildTextStatusSlide(
    WatchStatusItem slide,
    WatchProfile profile,
    int groupIndex,
  ) {
    final Widget textContent = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF833AB4),
            Color(0xFFFD1D1D),
            Color(0xFFFCB045),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      alignment: Alignment.center,
      child: Text(
        slide.text ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );

    if (groupIndex == widget.initialProfileIndex && _currentSlideIndex == 0) {
      return Hero(
        tag: 'hero_status_media_${profile.username}_$groupIndex',
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
              final radius = (29.r * (1.0 - animation.value)).clamp(0.0, 29.r);
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: textContent,
              );
            },
          );
        },
        child: textContent,
      );
    }

    return textContent;
  }

  Widget _buildProfilePlaceholder(WatchProfile profile, int groupIndex) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Ambient Background Image (Creator photo) with Blur & Hero tag
        (groupIndex == widget.initialProfileIndex)
            ? Hero(
                tag: 'hero_status_media_${profile.username}_$groupIndex',
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
                      final radius = (29.r *
                              (1.0 - animation.value))
                          .clamp(0.0, 29.r);
                      return ClipRRect(
                        borderRadius:
                            BorderRadius.circular(radius),
                        child: CustomImageContainer(
                          imagePath: profile.photoUrl,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  );
                },
                child: CustomImageContainer(
                  imagePath: profile.photoUrl,
                  fit: BoxFit.cover,
                ),
              )
            : CustomImageContainer(
                imagePath: profile.photoUrl,
                fit: BoxFit.cover,
              ),

        // Frosted ambient blur overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),

        // 2. Top and Bottom Ambient Gradients
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 140.h,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        // 3. Header Skeleton with Profile Avatar, Username, and Close Button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton Progress Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  child: Container(
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 4.h,
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: CustomImageContainer(
                          imagePath: profile.photoUrl,
                          height: 32.r,
                          width: 32.r,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          profile.username.isNotEmpty
                              ? profile.username
                              : 'Creator',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 26.r,
                        ),
                        onPressed: () => GoRouter.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double dragProgress = (_dragOffsetY / 320.0).clamp(0.0, 1.0);
    final double curvedProgress = Curves.easeOutQuad.transform(dragProgress);
    final double scale = 1.0 - (0.30 * curvedProgress);
    final double cornerRadius = 32.r * curvedProgress;

    return CustomScaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffsetY),
          child: Transform.scale(
            scale: scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: PageView.builder(
                controller: _profilePageController,
                physics: _dragOffsetY > 0
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: widget.statusProfiles.length,
                onPageChanged: (groupIndex) {
                  final username =
                      widget.statusProfiles[groupIndex].profile.username;
                  if (!_profileStatusesCache.containsKey(username)) {
                    final preloaded =
                        WatchStatusPreloadService().getCached(username);
                    if (preloaded != null && preloaded.isNotEmpty) {
                      _profileStatusesCache[username] = preloaded;
                    }
                  }
                  final slides = _profileStatusesCache[username] ?? [];
                  final targetSlide = _targetSlideIndex;
                  _targetSlideIndex = null;
                  setState(() {
                    _currentProfileIndex = groupIndex;
                    _currentSlideIndex = targetSlide ??
                        _calculateInitialSlideIndex(slides);
                  });
                  _loadCurrentSlide();
                  _fetchStatusesForProfile(groupIndex);
                },
                itemBuilder: (context, groupIndex) {
                  final feedItem = widget.statusProfiles[groupIndex];
                  final profile = feedItem.profile;
                  final slides =
                      _profileStatusesCache[profile.username] ?? [];
                  if (slides.isEmpty) {
                    return _buildProfilePlaceholder(profile, groupIndex);
                  }

                  final slide = slides[
                      _currentSlideIndex.clamp(0, slides.length - 1)];

                  return GestureDetector(
                    onLongPressStart: (_) => _pause(),
                    onLongPressEnd: (_) => _resume(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Media Content (Image / Video / Centered Caption with Gradient)
                        if (slide.isVideo)
                          _buildVideoStatusSlide(slide, profile, groupIndex)
                        else if (slide.isImage)
                          _buildImageStatusSlide(slide, profile, groupIndex)
                        else
                          _buildTextStatusSlide(slide, profile, groupIndex),

                        // 2. Tap Touch Zones (Left 50% Prev, Right 50% Next)
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _onPrevSlide,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _onNextSlide,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. Top Gradient Shadow
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 140.h,
                          child: const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black87,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 4. Bottom Gradient Shadow
                        if (slide.hasMedia || slide.products.isNotEmpty)
                          Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 220.h,
                          child: const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black87,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 5. Header Overlay: Progress Bars + Creator Info + Close Button
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProgressBar(slides.length),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 4.h,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                if (profile.username.isNotEmpty) {
                                                  _pause();
                                                  GoRouter.of(context).push(
                                                    AppRoutes.sellerProfile,
                                                    extra: {
                                                      'username': profile.username,
                                                    },
                                                  ).then((_) {
                                                    if (mounted) _resume();
                                                  });
                                                }
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipOval(
                                                    child: CustomImageContainer(
                                                      imagePath: profile.photoUrl,
                                                      height: 32.r,
                                                      width: 32.r,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Flexible(
                                                    child: Text(
                                                      profile.username.isNotEmpty
                                                          ? profile.username
                                                          : 'Creator',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13.sp,
                                                        fontWeight: FontWeight.bold,
                                                        shadows: const [
                                                          Shadow(
                                                            color: Colors.black87,
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (slide.formattedCreatedAt.isNotEmpty) ...[
                                              SizedBox(width: 6.w),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: const [
                                                    Shadow(
                                                      color: Colors.black87,
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                slide.formattedCreatedAt,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11.5.sp,
                                                  fontWeight: FontWeight.w500,
                                                  shadows: const [
                                                    Shadow(
                                                      color: Colors.black87,
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 26.r,
                                        ),
                                        onPressed: () =>
                                            GoRouter.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 6. Bottom Shoppable Overlay (Caption + Tagged Product Card / Carousel)
                        Positioned(
                          bottom: 24.h,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (slide.hasMedia &&
                                  slide.text != null &&
                                  slide.text!.trim().isNotEmpty) ...[
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  child: _StatusExpandableCaption(
                                    text: slide.text!,
                                    onExpandChanged: (expanded) {
                                      if (expanded) {
                                        _pause();
                                      } else {
                                        _resume();
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: 10.h),
                              ],
                              if (slide.products.isNotEmpty)
                                _buildProductList(slide.products),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Expandable Caption Widget for Status Viewer (2 lines collapsed by default, expands on tap with smooth animation & pauses slide timer)
class _StatusExpandableCaption extends StatefulWidget {
  final String text;
  final ValueChanged<bool>? onExpandChanged;

  const _StatusExpandableCaption({
    required this.text,
    this.onExpandChanged,
  });

  @override
  State<_StatusExpandableCaption> createState() =>
      _StatusExpandableCaptionState();
}

class _StatusExpandableCaptionState extends State<_StatusExpandableCaption> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant _StatusExpandableCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_isExpanded) {
        _isExpanded = false;
        widget.onExpandChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      height: 1.35,
      shadows: const [
        Shadow(color: Colors.black87, blurRadius: 6),
      ],
    );

    // If text is short (<= 75 chars), show without toggle
    if (widget.text.trim().length <= 75) {
      return Text(
        widget.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        widget.onExpandChanged?.call(_isExpanded);
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.topLeft,
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _isExpanded ? 140.h : 42.h,
          ),
          child: SingleChildScrollView(
            physics: _isExpanded
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: RichText(
              text: TextSpan(
                style: textStyle,
                children: [
                  TextSpan(
                    text: _isExpanded
                        ? widget.text
                        : '${widget.text.substring(0, 70).trim()}... ',
                  ),
                  TextSpan(
                    text: _isExpanded ? ' less' : 'more',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

