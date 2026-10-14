import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/bloc/seller_profile_bloc/seller_profile_bloc.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/watch_grid_card.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_shimmer.dart';

class SellerProfilePage extends StatefulWidget {
  final String username;

  const SellerProfilePage({
    super.key,
    required this.username,
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context
        .read<SellerProfileBloc>()
        .add(FetchSellerProfile(username: widget.username));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      context
          .read<SellerProfileBloc>()
          .add(FetchMoreSellerProfileReels(username: widget.username));
    }
  }

  Future<void> _onRefresh() async {
    context.read<SellerProfileBloc>().add(
          FetchSellerProfile(username: widget.username, isRefresh: true),
        );
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _openPlayer(List<WatchAndBuyItem> reels, int index) {
    final item = reels[index];

    GoRouter.of(context).push(
      AppRoutes.watchAndBuyPlayer,
      extra: {
        'initialIndex': index,
        'shortsSlug': item.slug.isNotEmpty ? item.slug : item.id.toString(),
        'initialItem': item,
      },
    );
  }

  void _openStatusViewer(WatchProfile profile) {
    if (!profile.hasActiveStatus) return;

    final feedItem = WatchStatusFeedItem(
      profile: profile,
      statusCount: 1,
    );

    GoRouter.of(context).push(
      AppRoutes.statusViewer,
      extra: {
        'statusProfiles': [feedItem],
        'initialProfileIndex': 0,
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WatchProfile profile,
    List<WatchAndBuyItem> reels,
    int totalReels,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveStatus = profile.hasActiveStatus;
    final hasUnseenStatus = profile.hasUnseenStatus;
    final reelCount = totalReels > 0 ? totalReels : reels.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Avatar on Left & Info / Badges on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Status Gradient Ring
              GestureDetector(
                onTap: () => _openStatusViewer(profile),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72.r,
                      height: 72.r,
                      padding: EdgeInsets.all(hasActiveStatus ? 2.5.r : 0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasActiveStatus
                            ? LinearGradient(
                                colors: hasUnseenStatus
                                    ? [
                                        const Color(0xFFFF2D55),
                                        const Color(0xFFFF9500),
                                        const Color(0xFF9B51E0),
                                      ]
                                    : [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              )
                            : null,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(hasActiveStatus ? 2.r : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? const Color(0xFF0F0F12) : Colors.white,
                        ),
                        child: ClipOval(
                          child: CustomImageContainer(
                            imagePath: profile.photoUrl,
                            height: 64.r,
                            width: 64.r,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14.w),

              // Seller Name & Badges on Right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Username & Verified Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.username.isNotEmpty
                                ? profile.username
                                : 'Seller',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Icon(
                          Icons.verified_rounded,
                          color: const Color(0xFF1DA1F2),
                          size: 17.r,
                        ),
                      ],
                    ),
                    SizedBox(height: 7.h),

                    // Badges Row: Type & Reels Count
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (profile.type.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              profile.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF555555),
                              ),
                            ),
                          ),
                        // Reels count badge pill
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 3.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                TablerIcons.video,
                                size: 13.r,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF4A4A4A),
                              ),
                              SizedBox(width: 4.5.w),
                              Text(
                                '${_formatNumber(reelCount)} Reels',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Bio Description
          if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              profile.bio!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReelsGrid(List<WatchAndBuyItem> reels) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 9 / 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = reels[index];
            return WatchGridCard(
              key: ValueKey(
                  'seller_reel_${item.id}_${item.likeCount}_${item.likedByMe}'),
              item: item,
              showSellerInfo: false,
              onTap: () => _openPlayer(reels, index),
            );
          },
          childCount: reels.length,
        ),
      ),
    );
  }

  Widget _buildSellerProfileShimmer(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // 1. Profile Header Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar on Left & Info / Badges on Right
                Row(
                  children: [
                    ShimmerWidget.circular(
                      width: 72.r,
                      height: 72.r,
                      isBorder: false,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerWidget.rectangular(
                            width: 130.w,
                            height: 18.h,
                            borderRadius: 4.r,
                            isBorder: true,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              ShimmerWidget.rectangular(
                                width: 48.w,
                                height: 18.h,
                                borderRadius: 6.r,
                                isBorder: true,
                              ),
                              SizedBox(width: 8.w),
                              ShimmerWidget.rectangular(
                                width: 72.w,
                                height: 18.h,
                                borderRadius: 12.r,
                                isBorder: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Bio Lines Shimmer
                ShimmerWidget.rectangular(
                  width: 240.w,
                  height: 12.h,
                  borderRadius: 4.r,
                  isBorder: true,
                ),
                SizedBox(height: 5.h),
                ShimmerWidget.rectangular(
                  width: 160.w,
                  height: 12.h,
                  borderRadius: 4.r,
                  isBorder: true,
                ),
              ],
            ),
          ),
        ),

        // 2. 2-Column Grid Shimmer
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ShimmerWidget.rectangular(
                  height: double.infinity,
                  width: double.infinity,
                  borderRadius: 12.r,
                  isBorder: true,
                );
              },
              childCount: 6,
            ),
          ),
        ),
      ],
    );
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19.r,
          ),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          widget.username.isNotEmpty ? widget.username : 'Seller Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: BlocBuilder<SellerProfileBloc, SellerProfileState>(
        builder: (context, state) {
          if (state is SellerProfileLoading || state is SellerProfileInitial) {
            return _buildSellerProfileShimmer(context);
          }

          if (state is SellerProfileError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TablerIcons.alert_circle,
                    size: 40.r,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SellerProfileBloc>().add(
                            FetchSellerProfile(username: widget.username),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is! SellerProfileLoaded) {
            return const SizedBox.shrink();
          }

          final profile = state.profile;
          final reels = state.reels;
          final totalReels = state.pagination.total;
          final isLoadingMore = state.isLoadingMore;

          return CustomRefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Profile Header
                SliverToBoxAdapter(
                  child: _buildProfileHeader(
                    context,
                    profile,
                    reels,
                    totalReels,
                  ),
                ),

                // 2. 2-Column Uniform Grid of Reels
                if (reels.isNotEmpty)
                  _buildReelsGrid(reels)
                else if (state is! SellerProfileLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TablerIcons.video_off,
                            size: 44.r,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'No reels posted yet',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Pagination Loader
                if (isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: const Center(
                        child: CustomCircularProgressIndicator(),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: SizedBox(height: 30.h),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
