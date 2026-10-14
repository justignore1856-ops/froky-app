import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

import '../../common/sample_section_data.dart';

class CategoryCardsImage extends StatelessWidget {
  final List<SampleTile> categories;

  const CategoryCardsImage({
    super.key,
    this.categories = SampleSectionData.categories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125.h,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 115.w,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomImageContainer(
                      imagePath: tile.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
