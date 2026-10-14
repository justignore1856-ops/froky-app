import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

/// Compact "Rate this product" card. Tapping a star opens the product rating
/// page (via [onRate] with the tapped star); once a review exists it shows the
/// given rating read-only.
class InlineRateProductCard extends StatelessWidget {
  final OrderItems item;
  final ValueChanged<int>? onRate;

  const InlineRateProductCard({super.key, required this.item, this.onRate});

  /// Only rate a product once its timeline shows a completed `delivered` stage.
  static bool shouldShow(OrderItems item) {
    for (final stage in item.timeline) {
      if ((stage.key ?? '').toLowerCase().trim() == 'delivered' &&
          stage.done == true) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(item)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final reviewed = item.isUserReviewGiven == true;
    final displayRating = reviewed ? (item.userReview?.rating ?? 0) : 0;
    final image = (item.variant?.image?.isNotEmpty ?? false)
        ? item.variant!.image!
        : (item.product?.image ?? '');

    return GestureDetector(
      onTap: () => onRate?.call(displayRating),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: image.isNotEmpty
                  ? CustomImageContainer(imagePath: image, fit: BoxFit.cover)
                  : Icon(Icons.image_outlined,
                      size: 20.sp, color: Colors.grey.shade400),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsGeometry.directional(start: 2.0),
                  child: Text(
                    reviewed
                        ? (l10n?.yourRating ?? 'Your rating')
                        : (l10n?.rateThisProduct ?? 'Rate this product'),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2,),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final filled = index < displayRating;
                    return Padding(
                      padding: EdgeInsetsGeometry.directional(start: 2.w),
                      child: Icon(
                        filled ? AppTheme.ratingStarIconFilled : AppTheme.ratingStarIcon,
                        size: 18.sp,
                        color:
                            filled ? AppTheme.ratingStarColor : Colors.grey.shade400,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
