import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

class WatchGridCard extends StatelessWidget {
  final WatchAndBuyItem item;
  final VoidCallback onTap;
  final VoidCallback? onProfileTap;
  final double? thumbnailHeight;
  final bool showSellerInfo;

  const WatchGridCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onProfileTap,
    this.thumbnailHeight,
    this.showSellerInfo = true,
  });

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildCoverImage() {
    // 1. If backend provided a cover image
    if (item.coverUrl != null && item.coverUrl!.trim().isNotEmpty) {
      return CustomImageContainer(
        imagePath: item.coverUrl!,
        fit: BoxFit.cover,
      );
    }

    // 2. If cover image is not available, show the profile image as cover image
    if (item.profile.photoUrl.trim().isNotEmpty) {
      return CustomImageContainer(
        imagePath: item.profile.photoUrl,
        fit: BoxFit.cover,
      );
    }

    // 3. Fallback placeholder if neither is available
    return Container(
      color: const Color(0xFF181820),
      child: Center(
        child: Icon(
          TablerIcons.player_play,
          size: 28.r,
          color: Colors.white24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget thumbnailWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A. Thumbnail Image with Optimized Hero Transition
          Hero(
            tag: 'hero_watch_video_${item.id}',
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
                    child: _buildCoverImage(),
                  );
                },
              );
            },
            child: _buildCoverImage(),
          ),

          // B. Bottom Vignette Gradient
          if (item.title.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 70.h,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

          // C. Caption upon the Video Card
          if (item.title.isNotEmpty)
            Positioned(
              left: 8.w,
              right: 8.w,
              bottom: 8.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),

                  if(!showSellerInfo)...[
                    SizedBox(width: 6.w),

                    // Right: Like Count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(TablerIcons.heart_filled,
                          size: 12.r,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _formatNumber(item.likeCount),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ]

                ],
              ),
            ),

        ],
      ),
    );

    final Widget sizedThumbnail = thumbnailHeight != null
        ? SizedBox(
            height: thumbnailHeight,
            width: double.infinity,
            child: thumbnailWidget,
          )
        : AspectRatio(
            aspectRatio: 9 / 16,
            child: thumbnailWidget,
          );

    if (!showSellerInfo) {
      return GestureDetector(
        onTap: onTap,
        child: sizedThumbnail,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Video Thumbnail Card (Aspect Ratio ~9:16)
          sizedThumbnail,

          // 2. Seller Profile and Likes below the Video Card
          if (item.storeName.isNotEmpty || item.likeCount > 0) ...[
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Row(
                children: [
                  // Left: Seller Profile (Avatar & Store Name)
                  if (item.storeName.isNotEmpty)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onProfileTap ??
                            () {
                              if (item.storeName.isNotEmpty) {
                                GoRouter.of(context).push(
                                  AppRoutes.sellerProfile,
                                  extra: {
                                    'username': item.storeName,
                                  },
                                );
                              }
                            },
                        child: Row(
                          children: [
                            if (item.storeLogo.isNotEmpty)
                              ClipOval(
                                child: CustomImageContainer(
                                  imagePath: item.storeLogo,
                                  height: 18.r,
                                  width: 18.r,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (item.storeLogo.isNotEmpty) SizedBox(width: 5.w),
                            Expanded(
                              child: Text(
                                item.storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  SizedBox(width: 6.w),

                  // Right: Like Count
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(TablerIcons.heart_filled,
                        size: 13.r,
                        color: (isDark ? Colors.white60 : Colors.black87),
                      ),
                      SizedBox(width: 3.5.w),
                      Text(
                        _formatNumber(item.likeCount),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
