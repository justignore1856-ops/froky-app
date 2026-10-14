import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import '../../../config/helper.dart';
import '../../../utils/widgets/custom_image_container.dart';
import '../../../config/theme.dart';

class ReviewRatingDetailedCard extends StatelessWidget {
  final double rating;
  final String date;
  final String reviewText;
  final List<String>? images;
  final int? maxLines;
  final int index;
  final String userName;

  const ReviewRatingDetailedCard({
    super.key,
    required this.rating,
    required this.date,
    required this.reviewText,
    required this.index,
    required this.userName,
    this.maxLines,
    this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 4.h, bottom: 4.h, left: 0.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        /*border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),*/
      ),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating and date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                // Star rating
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.black26,
                      child: Icon(HeroiconsSolid.user),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w400
                          ),
                        ),
                        Text(
                          formatIsoDateToCustomFormat(date),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    /*Text(
                      rating.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
                      ),
                    ),*/
                  ],
                ),
                // Date

              ],
            ),
            const SizedBox(height: 10,),
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 18,
              itemPadding: const EdgeInsetsGeometry.directional(start: 2),
              itemBuilder: (context, _) => const Icon(
                AppTheme.ratingStarIconFilled,
                color: AppTheme.ratingStarColor,
              ),
              ignoreGestures: true,
              onRatingUpdate: (rating) {},
            ),

            // Horizontal Image List (if images are provided)
            if (images != null && images!.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 50.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: CustomImageContainer(
                          imagePath:  images![index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 10),
            // Review text
            Expanded(
              child: Padding(
                padding: const EdgeInsetsGeometry.directional(start: 4.0, end: 4.0),
                child: Text(
                  reviewText,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                  maxLines: maxLines ?? 100,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
