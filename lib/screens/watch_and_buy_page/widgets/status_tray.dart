import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_status_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

class StatusTray extends StatelessWidget {
  final List<WatchStatusFeedItem> items;
  final Function(int index) onStatusTap;
  final double shrinkProgress;
  final AnimationController? shuffleAnimation;

  const StatusTray({
    super.key,
    required this.items,
    required this.onStatusTap,
    this.shrinkProgress = 0.0,
    this.shuffleAnimation,
  });

  Widget _buildStatusItem(
    BuildContext context,
    int index,
    WatchStatusFeedItem feedItem, {
    required double bubbleSize,
    required double itemWidth,
    required double textOpacity,
    required double ringPadding,
    required double innerGap,
    required double progress,
    required bool isDark,
  }) {
    final profile = feedItem.profile;
    final bool isUnseen = profile.hasUnseenStatus;

    Widget itemContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onStatusTap(index),
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Status Avatar Bubble with Gradient Ring
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Outer Ring
                Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  padding: EdgeInsets.all(ringPadding),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnseen
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFF2D55),
                              Color(0xFFFF9500),
                              Color(0xFF9B51E0),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          )
                        : null,
                    color: isUnseen
                        ? null
                        : (isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(innerGap),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0F0F12) : Colors.white,
                    ),
                    child: Hero(
                      tag: 'hero_status_media_${profile.username}_$index',
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
                            final radius = lerpDouble(
                              bubbleSize / 2,
                              0.0,
                              animation.value,
                            )!.clamp(0.0, bubbleSize / 2);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(radius),
                              child: CustomImageContainer(
                                imagePath: profile.photoUrl,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        );
                      },
                      child: ClipOval(
                        child: CustomImageContainer(
                          imagePath: profile.photoUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Profile Username Underneath (Fades and collapses smoothly on scroll)
            if (textOpacity > 0.0) ...[
              SizedBox(height: lerpDouble(5.h, 0.0, progress)!),
              Opacity(
                opacity: textOpacity,
                child: SizedBox(
                  height: 14.h,
                  child: Text(
                    profile.username.isNotEmpty ? profile.username : 'Creator',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight:
                          isUnseen ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF2C2C2E),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // If shuffle animation is active, wrap in staggered domino wave animation
    if (shuffleAnimation != null) {
      return AnimatedBuilder(
        animation: shuffleAnimation!,
        builder: (context, _) {
          if (!shuffleAnimation!.isAnimating) return itemContent;

          final val = shuffleAnimation!.value;
          final double itemDelay = (index * 0.05).clamp(0.0, 0.25);
          final double adjustedVal =
              ((val - itemDelay) / (1.0 - itemDelay)).clamp(0.0, 1.0);

          double scale;
          double offsetY;
          double rotation;
          double opacity;

          if (adjustedVal <= 0.45) {
            final p = adjustedVal / 0.45;
            scale = 1.0 - (0.18 * p);
            offsetY = -12.h * sin(p * pi);
            rotation = (index.isEven ? -0.15 : 0.15) * p;
            opacity = 1.0 - (0.45 * p);
          } else {
            final p = (adjustedVal - 0.45) / 0.55;
            final bounce = Curves.elasticOut.transform(p);
            scale = 0.82 + (0.18 * bounce);
            offsetY = -12.h * (1.0 - p);
            rotation = (index.isEven ? -0.15 : 0.15) * (1.0 - p);
            opacity = 0.55 + (0.45 * p);
          }

          return Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: itemContent,
                ),
              ),
            ),
          );
        },
      );
    }

    return itemContent;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = shrinkProgress.clamp(0.0, 1.0);
    final double bubbleSize = lerpDouble(58.r, 38.r, progress)!;
    final double itemWidth = lerpDouble(66.w, 44.w, progress)!;
    final double separatorWidth = lerpDouble(14.w, 10.w, progress)!;
    final double textOpacity = (1.0 - progress * 2.5).clamp(0.0, 1.0);
    final double ringPadding = lerpDouble(2.5.r, 1.8.r, progress)!;
    final double innerGap = lerpDouble(2.0.r, 1.5.r, progress)!;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(width: separatorWidth),
      itemBuilder: (context, index) {
        return _buildStatusItem(
          context,
          index,
          items[index],
          bubbleSize: bubbleSize,
          itemWidth: itemWidth,
          textOpacity: textOpacity,
          ringPadding: ringPadding,
          innerGap: innerGap,
          progress: progress,
          isDark: isDark,
        );
      },
    );
  }
}
