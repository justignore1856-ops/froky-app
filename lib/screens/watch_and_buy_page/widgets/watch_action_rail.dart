import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/widgets/like_burst_effect.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/settings_data_instance.dart';
import '../../../l10n/app_localizations.dart';

class WatchActionRail extends StatelessWidget {
  final int likes;
  final bool isLiked;
  final String shareTitle;
  final String shareUrl;
  final String slug;
  final VoidCallback onToggleLike;

  const WatchActionRail({
    super.key,
    required this.likes,
    required this.isLiked,
    required this.shareTitle,
    required this.shareUrl,
    required this.slug,
    required this.onToggleLike,
  });

  void _share(BuildContext context) async {
    final url = SettingsData.instance.web?.customerWebUrl ?? '';

    if (url.isNotEmpty) {
      final productLink = '${url}watch-and-buy?slug=$slug';

      final l10n = AppLocalizations.of(context)!;
      final shareText = '${l10n.checkOutThisProduct}\n$productLink';
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            title: 'Share Product',
          ),
        );
      } catch (e) {
        debugPrint('Error sharing link: $e');
      }
    } else {
      debugPrint('No URL to share');
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 100000) {
      return '${(count / 100000).toStringAsFixed(1)}L';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 14.w, bottom: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Like Button with Heart Particle Burst (No button scale distortion)
          LikeBurstEffect(
            isLiked: isLiked,
            onTap: () {
              HapticFeedback.mediumImpact();
              onToggleLike();
            },
            child: Column(
              children: [
                Icon(
                  isLiked
                      ? TablerIcons.heart_filled
                      : TablerIcons.heart,
                  color: isLiked ? Colors.red: Colors.white,
                  size: 34.r,
                  /*shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],*/
                ),
                const SizedBox(height: 4,),
                Text(
                  _formatCount(likes),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),

          // 2. Share Button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _share(context);
            },
            child: Column(
              children: [
                Transform.flip(
                  flipX: true,
                  child: Icon(
                    Icons.reply_rounded,
                    color: Colors.white,
                    size: 32.r,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Share',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
