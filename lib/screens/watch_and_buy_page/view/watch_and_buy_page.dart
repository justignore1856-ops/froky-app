import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/seller_profile_bloc/seller_profile_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_and_buy_feed_bloc/watch_and_buy_feed_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_and_buy_reel_bloc/watch_and_buy_reel_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_video_preload_service.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/watch_action_rail.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/watch_product_overlay.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/watch_video_player.dart';
import 'package:hyper_commerce/services/auth_guard.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:visibility_detector/visibility_detector.dart';

class WatchAndBuyPage extends StatelessWidget {
  final int initialIndex;
  final String shortsSlug;
  final WatchAndBuyItem? initialItem;
  final Uint8List? frameThumbnail;
  final bool onShortsTap;

  const WatchAndBuyPage({
    super.key,
    this.initialIndex = 0,
    this.shortsSlug = '',
    this.initialItem,
    this.frameThumbnail,
    this.onShortsTap = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WatchAndBuyReelBloc>(
      create: (context) => WatchAndBuyReelBloc(
        onLikeChanged: (reelId, isLiked, likeCount) {
          try {
            context.read<WatchAndBuyFeedBloc>().add(
                  UpdateFeedReelLike(
                    reelId: reelId,
                    isLiked: isLiked,
                    likeCount: likeCount,
                  ),
                );
          } catch (_) {}
          try {
            context.read<SellerProfileBloc>().add(
                  UpdateSellerProfileReelLike(
                    reelId: reelId,
                    isLiked: isLiked,
                    likeCount: likeCount,
                  ),
                );
          } catch (_) {}
        },
      )..add(FetchPlayerReels(
          slug: shortsSlug,
          initialItem: initialItem,
        )),
      child: _WatchAndBuyPlayerView(
        initialIndex: initialIndex,
        shortsSlug: shortsSlug,
        initialItem: initialItem,
        frameThumbnail: frameThumbnail,
      ),
    );
  }
}

class _WatchAndBuyPlayerView extends StatefulWidget {
  final int initialIndex;
  final String shortsSlug;
  final WatchAndBuyItem? initialItem;
  final Uint8List? frameThumbnail;

  const _WatchAndBuyPlayerView({
    required this.initialIndex,
    required this.shortsSlug,
    this.initialItem,
    this.frameThumbnail,
  });

  @override
  State<_WatchAndBuyPlayerView> createState() => _WatchAndBuyPlayerViewState();
}

class _WatchAndBuyPlayerViewState extends State<_WatchAndBuyPlayerView>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  final ValueNotifier<bool> _isMutedNotifier = ValueNotifier<bool>(false);
  bool _isPageVisible = true;
  bool _isAppInForeground = true;
  DateTime? _lastLikeActionTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isAppInForeground) {
        setState(() {
          _isAppInForeground = true;
        });
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isAppInForeground) {
        setState(() {
          _isAppInForeground = false;
        });
        WatchVideoPreloadService().pauseAll();
      }
    }
  }

  Future<void> _refreshList() async {
    context
        .read<WatchAndBuyReelBloc>()
        .add(FetchPlayerReels(slug: widget.shortsSlug));
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _currentIndex = 0;
  }

  Future<void> _toggleLike(WatchAndBuyItem item, {bool forceLike = false}) async {
    final isLoggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!isLoggedIn || !mounted) return;

    final blocState = context.read<WatchAndBuyReelBloc>().state;
    final bool isCurrentlyLiked = (blocState is WatchAndBuyReelLoaded)
        ? blocState.likedIds.contains(item.id)
        : item.likedByMe;

    // Only apply the cooldown block when liking; do not block after dislike/unlike
    if (!isCurrentlyLiked || forceLike) {
      final now = DateTime.now();
      if (_lastLikeActionTime != null &&
          now.difference(_lastLikeActionTime!) <
              const Duration(milliseconds: 1500)) {
        return;
      }
      _lastLikeActionTime = now;
    } else {
      // Reset cooldown on dislike so user can immediately re-like without delay
      _lastLikeActionTime = null;
    }

    if (!mounted) return;
    context.read<WatchAndBuyReelBloc>().add(
          TogglePlayerReelLike(
            reelId: item.id,
            forceLike: forceLike,
          ),
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isMutedNotifier.dispose();
    _pageController.dispose();
    WatchVideoPreloadService().pauseAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('widget frame thumbnail ${widget.frameThumbnail}');
    return VisibilityDetector(
      key: const Key('watch_and_buy_player_view_key'),
      onVisibilityChanged: (info) {
        if(!mounted) return;
        final bool visible = info.visibleFraction > 0.5;
        if (_isPageVisible != visible) {
          setState(() {
            _isPageVisible = visible;
          });
          if (!visible) {
            WatchVideoPreloadService().pauseAll();
          }
        }
      },
      child: CustomScaffold(
        body: BlocConsumer<WatchAndBuyReelBloc, WatchAndBuyReelState>(
          listener: (context, state) {
            if (state is WatchAndBuyReelLoaded && state.items.isNotEmpty) {
              WatchVideoPreloadService().preloadSurroundingVideos(
                state.items.map((e) => e.videoUrl).toList(),
                _currentIndex,
              );
            }
          },
          builder: (context, state) {
            final items = state is WatchAndBuyReelLoaded
                ? state.items
                : (widget.initialItem != null
                    ? [widget.initialItem!]
                    : <WatchAndBuyItem>[]);

            if (state is WatchAndBuyReelLoading && items.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor,
                ),
              );
            }

            if (state is WatchAndBuyReelError && items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ElevatedButton(
                      onPressed: _refreshList,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final likedIds =
                state is WatchAndBuyReelLoaded ? state.likedIds : <int>{};
            final likeCounts = state is WatchAndBuyReelLoaded
                ? state.likeCounts
                : <int, int>{};

            if (items.isEmpty) {
              return _buildEmptyState();
            }

            return Stack(
              children: [
                // 1. Vertical Snap Feed
                CustomRefreshIndicator(
                  onRefresh: _refreshList,
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });

                      // Preload sliding window
                      WatchVideoPreloadService().preloadSurroundingVideos(
                        items.map((e) => e.videoUrl).toList(),
                        index,
                      );

                      // Cursor-based infinite scroll
                      if (index >= items.length - 2 &&
                          state is WatchAndBuyReelLoaded &&
                          state.hasMore &&
                          !state.isLoadingMore) {
                        context
                            .read<WatchAndBuyReelBloc>()
                            .add(const FetchMorePlayerReels());
                      }
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isLiked = likedIds.contains(item.id);
                      final likes = likeCounts[item.id] ?? item.likeCount;
                      final bool isVideoActive = (_currentIndex == index) &&
                          _isPageVisible &&
                          _isAppInForeground;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // A. Video Engine
                          WatchVideoPlayer(
                            videoUrl: item.videoUrl,
                            thumbnailUrl: item.thumbnailUrl,
                            frameThumbnail:
                                (index == 0) ? widget.frameThumbnail : null,
                            heroTag: (index == 0)
                                ? 'hero_watch_video_${item.id}'
                                : null,
                            isActive: isVideoActive,
                            isMutedNotifier: _isMutedNotifier,
                            onDoubleTapLike: () =>
                                _toggleLike(item, forceLike: true),
                          ),

                          // B. Top and Bottom Black Vignette Gradients
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 160.h,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.75),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 380.h,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.95),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // C. Right Action Rail (Like & Share)
                          Positioned(
                            right: 0,
                            bottom: item.products.isNotEmpty ? 135.h : 50.h,
                            child: WatchActionRail(
                              likes: likes,
                              isLiked: isLiked,
                              shareTitle: item.title,
                              shareUrl: item.videoUrl,
                              onToggleLike: () => _toggleLike(item),
                              slug: item.slug,
                            ),
                          ),

                          // D. Bottom Overlay: Creator, Title & Product Cards
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 16.h,
                            child: WatchProductOverlay(
                              products: item.products,
                              title: item.title,
                              description: item.caption ?? '',
                              storeName: item.storeName,
                              storeLogo: item.storeLogo,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 2. Top Navigation Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Directionality.of(context) == TextDirection.ltr
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 28.r,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            onPressed: () {
                              WatchVideoPreloadService().pauseAll();
                              GoRouter.of(context).pop();
                            },
                          ),

                          // Mute / Unmute Button in Top Navigation Bar
                          ValueListenableBuilder<bool>(
                            valueListenable: _isMutedNotifier,
                            builder: (context, isMuted, _) {
                              return GestureDetector(
                                onTap: () {
                                  _isMutedNotifier.value =
                                      !_isMutedNotifier.value;
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Icon(
                                    isMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 18.r,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 64.r,
            color: Colors.white54,
          ),
          SizedBox(height: 16.h),
          Text(
            'No videos available right now',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _refreshList,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}