import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import '../../common/sample_section_data.dart';

class CategoryCardsTitleOverlay extends StatelessWidget {
  final List<SampleTile> categories;

  const CategoryCardsTitleOverlay({
    super.key,
    this.categories = SampleSectionData.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h,
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
            width: 125.w,
            child: Stack(
              children: [

                // 🔲 Image Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    color: CupertinoColors.systemGrey3,
                    child: CustomImageContainer(
                      imagePath: tile.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12.r),
                        bottomRight: Radius.circular(12.r),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40.h,
                    padding: const EdgeInsets.only(
                      bottom: 6,
                      left: 6,
                      right: 6
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 📝 Text
                        Expanded(
                          child: Text(
                            tile.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10,),

                        Container(
                          height: 20,
                          width: 20,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                          ),
                          alignment: Alignment.center,
                          child: const Icon(TablerIcons.chevron_right, size: 15,),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
