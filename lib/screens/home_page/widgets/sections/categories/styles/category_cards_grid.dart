import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

import '../../common/sample_section_data.dart';

class CategoryCardsGrid extends StatelessWidget {
  final List<SampleTile> categories;
  final int crossAxisCount;

  const CategoryCardsGrid({
    super.key,
    this.categories = SampleSectionData.categories,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    int getCrossAxisCount(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth >= 1200) return 6;
      if (screenWidth >= 800) return 5;
      if (screenWidth >= 600) return 4;
      return 3; // 👈 3 per row for mobile
    }

    // Calculate responsive spacing
    double getSpacing(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      return screenWidth * 0.025;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getCrossAxisCount(context),
          crossAxisSpacing: getSpacing(context),
          mainAxisSpacing: getSpacing(context),
          childAspectRatio: 0.62,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (context, i) {
          final tile = categories[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;
                final cardHeight = constraints.maxHeight;
                final borderRadius = cardWidth * 0.12;

                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 65,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: SizedBox.expand(
                              child: CustomImageContainer(
                                imagePath: tile.imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        flex: 35,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: cardWidth * 0.05),
                          child: Text(
                            tile.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: _responsiveFontSize(cardWidth),
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  double _responsiveFontSize(double cardWidth) {
    if (cardWidth >= 100) return 14;
    if (cardWidth >= 80) return 13;
    if (cardWidth >= 60) return 12;
    return 12;
  }
}
