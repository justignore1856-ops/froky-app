import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';

import '../../../../../config/helper.dart';
import '../common/sample_section_data.dart';
import '../common/section_background.dart';
import 'styles/category_cards_title_overlay.dart';
import 'styles/category_cards_grid.dart';
import 'styles/category_cards_image.dart';

/// Selectable card layout for the category section.
enum CategoryCardStyle { overlayTitle, grid, imageCards }


class CategorySection extends StatelessWidget {
  final String title;
  final List<SampleTile> categories;
  final CategoryCardStyle style;
  final SectionBackground background;
  final VoidCallback? onSeeAll;

  const CategorySection({
    super.key,
    this.title = 'Shop by category',
    this.categories = SampleSectionData.categories,
    this.style = CategoryCardStyle.overlayTitle,
    this.background = const SectionBackground.none(),
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: background.toDecoration(),
      padding: EdgeInsets.only(
        top: 10.h,
        bottom: 10.h
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared header — same in all styles.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  InkWell(
                    onTap: onSeeAll,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet(context) ? 10.w : 6.w,
                        vertical: isTablet(context) ? 4.h : 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode(context)
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.seeAll,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    switch (style) {
      case CategoryCardStyle.overlayTitle:
        return CategoryCardsTitleOverlay(categories: categories);
      case CategoryCardStyle.grid:
        return CategoryCardsGrid(categories: categories);
      case CategoryCardStyle.imageCards:
        return CategoryCardsImage(categories: categories);
    }
  }
}
