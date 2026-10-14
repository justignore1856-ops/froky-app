import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_and_buy_feed_bloc/watch_and_buy_feed_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/watch_status_bloc/watch_status_feed_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_status_preload_service.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/services/watch_video_preload_service.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/status_tray.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/watch_grid_card.dart';
import 'package:hyper_commerce/utils/widgets/basket_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_shimmer.dart';

class WatchAndBuyFeedPage extends StatefulWidget {
  const WatchAndBuyFeedPage({super.key});

  @override
  State<WatchAndBuyFeedPage> createState() => _WatchAndBuyFeedPageState();
}

class _WatchAndBuyFeedPageState extends State<WatchAndBuyFeedPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late AnimationController _shuffleController;

  final List<double> _staggeredHeights = [
    250.h,
    195.h,
    275.h,
    210.h,
    240.h,
    190.h,
  ];

  @override
  void initState() {
    super.initState();
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scrollController.addListener(_onScroll);

    // Initial API fetch for video feed & status feed
    context.read<WatchAndBuyFeedBloc>().add(const FetchWatchAndBuyFeed());
    context.read<WatchStatusFeedBloc>().add(const FetchStatusFeed());
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 400.h) {
        context.read<WatchAndBuyFeedBloc>().add(const FetchMoreWatchAndBuyFeed());
      }
    }
  }

  Future<void> _refreshFeed() async {
    // 1. Invalidate preloaded status cache
    WatchStatusPreloadService().clearCache();

    // 2. Trigger API refreshes
    context.read<WatchAndBuyFeedBloc>().add(const FetchWatchAndBuyFeed(isRefresh: true));
    context.read<WatchStatusFeedBloc>().add(const FetchStatusFeed(isRefresh: true));

    // 2. Start Shuffle Animation
    _shuffleController.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 280));
    if (mounted) {
      HapticFeedback.mediumImpact();
    }

    await Future.delayed(const Duration(milliseconds: 370));
  }

  void _openStatus(List<WatchStatusFeedItem> items, int index) {
    GoRouter.of(context).push(
      AppRoutes.statusViewer,
      extra: {
        'statusProfiles': items,
        'initialProfileIndex': index,
      },
    );
  }

  void _openPlayer(WatchAndBuyItem item, int index) {
    GoRouter.of(context).push(
      AppRoutes.watchAndBuyPlayer,
      extra: {
        'initialIndex': index,
        'shortsSlug': item.slug.isNotEmpty ? item.slug : item.id.toString(),
        'initialItem': item,
      },
    );
  }

  Widget _buildAnimatedCardItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _shuffleController,
      builder: (context, _) {
        if (!_shuffleController.isAnimating) return child;

        final value = _shuffleController.value;
        final bool isLeft = index % 2 == 0;
        final double tiltDirection = isLeft ? -1.0 : 1.0;

        double scale;
        double opacity;
        double offsetX;
        double rotation;

        if (value <= 0.5) {
          final progress = value / 0.5;
          final easedProgress = Curves.easeInOutCubic.transform(progress);

          scale = 1.0 - (0.08 * easedProgress);
          opacity = 1.0 - (0.4 * easedProgress);
          offsetX = (tiltDirection * 24.w) * easedProgress;
          rotation = (tiltDirection * 0.05) * easedProgress;
        } else {
          final progress = (value - 0.5) / 0.5;
          final easedProgress = Curves.elasticOut.transform(progress);

          scale = 0.92 + (0.08 * easedProgress);
          opacity = 0.6 + (0.4 * (progress.clamp(0.0, 1.0)));
          offsetX = (tiltDirection * 24.w) * (1.0 - progress.clamp(0.0, 1.0));
          rotation = (tiltDirection * 0.05) * (1.0 - progress.clamp(0.0, 1.0));
        }

        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildStaggeredSliver(List<WatchAndBuyItem> items) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 12.w,
        itemBuilder: (context, index) {
          final h = _staggeredHeights[index % _staggeredHeights.length];
          return _buildAnimatedCardItem(
            index,
            WatchGridCard(
              key: ValueKey(
                  'feed_reel_${items[index].id}_${items[index].likeCount}_${items[index].likedByMe}'),
              item: items[index],
              thumbnailHeight: h,
              onTap: () => _openPlayer(items[index], index),
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildFeedShimmer(BuildContext context) {
    final heights = [240.h, 195.h, 270.h, 210.h, 230.h, 190.h];

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // 1. Status Tray Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: SizedBox(
              height: 90.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                itemCount: 6,
                separatorBuilder: (_, __) => SizedBox(width: 14.w),
                itemBuilder: (_, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerWidget.circular(
                      width: 58.r,
                      height: 58.r,
                      isBorder: false,
                    ),
                    SizedBox(height: 6.h),
                    ShimmerWidget.rectangular(
                      width: 46.w,
                      height: 9.h,
                      borderRadius: 4.r,
                      isBorder: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Staggered Grid Shimmer
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 12.w,
            childCount: 6,
            itemBuilder: (context, index) {
              final h = heights[index % heights.length];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerWidget.rectangular(
                    height: h,
                    width: double.infinity,
                    borderRadius: 12.r,
                    isBorder: true,
                  ),
                  SizedBox(height: 8.h),
                  ShimmerWidget.rectangular(
                    height: 12.h,
                    width: (index % 2 == 0) ? 120.w : 90.w,
                    borderRadius: 4.r,
                    isBorder: true,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shuffleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: isDark
            ? const Color(0xFF0A0A0E)
            : Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final String watchTitle =
                (SettingsData.instance.watchAndBuy?.title?.isNotEmpty == true)
                    ? SettingsData.instance.watchAndBuy!.title!
                    : 'Watch & Buy';
            return Text(
              watchTitle,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            );
          },
        ),
        actions: [
          const BasketButton(),
          SizedBox(width: 8.w),
        ],
      ),
      body: BlocConsumer<WatchAndBuyFeedBloc, WatchAndBuyFeedState>(
        listener: (context, state) {
          if (state is WatchAndBuyFeedLoaded && state.items.isNotEmpty) {
            // Background preload surrounding discovery video chunks
            WatchVideoPreloadService().preloadSurroundingVideos(
              state.items.map((e) => e.videoUrl).toList(),
              0,
            );
          }
        },
        builder: (context, state) {
          if (state is WatchAndBuyFeedLoading &&
              state is! WatchAndBuyFeedLoaded) {
            return _buildFeedShimmer(context);
          }

          if (state is WatchAndBuyFeedError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<WatchAndBuyFeedBloc>()
                          .add(const FetchWatchAndBuyFeed());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items =
              state is WatchAndBuyFeedLoaded ? state.items : <WatchAndBuyItem>[];
          final isLoadingMore =
              state is WatchAndBuyFeedLoaded && state.isLoadingMore;

          return CustomRefreshIndicator(
            onRefresh: _refreshFeed,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Pinned Shrinking Status Tray Header from WatchStatusFeedBloc
                BlocBuilder<WatchStatusFeedBloc, WatchStatusFeedState>(
                  builder: (context, statusState) {
                    final statusItems = statusState is WatchStatusFeedLoaded
                        ? statusState.items
                        : <WatchStatusFeedItem>[];

                    if (statusItems.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverPersistentHeader(
                      pinned: true,
                      delegate: _CollapsibleStatusHeaderDelegate(
                        items: statusItems,
                        onStatusTap: (index) => _openStatus(statusItems, index),
                        shuffleAnimation: _shuffleController,
                        minHeight: 52.h,
                        maxHeight: 96.h,
                      ),
                    );
                  },
                ),

                // 2. Video Feed Discovery (Staggered or Uniform Grid)
                if (items.isNotEmpty)
                  _buildStaggeredSliver(items)
                else if (state is! WatchAndBuyFeedLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No videos available right now',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // 3. Bottom Loading Spinner for Cursor Pagination
                if (isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CollapsibleStatusHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<WatchStatusFeedItem> items;
  final Function(int index) onStatusTap;
  final AnimationController? shuffleAnimation;
  final double minHeight;
  final double maxHeight;

  _CollapsibleStatusHeaderDelegate({
    required this.items,
    required this.onStatusTap,
    this.shuffleAnimation,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double maxScroll =
        (maxExtent - minExtent).clamp(0.001, double.infinity);
    final double progress = (shrinkOffset / maxScroll).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F0F12)
            : Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08 + 0.08 * progress)
                : Colors.black.withValues(alpha: 0.06 + 0.06 * progress),
            width: 0.5,
          ),
        ),
      ),
      child: StatusTray(
        items: items,
        onStatusTap: onStatusTap,
        shrinkProgress: progress,
        shuffleAnimation: shuffleAnimation,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsibleStatusHeaderDelegate oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.shuffleAnimation != shuffleAnimation;
  }
}
