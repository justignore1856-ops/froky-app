import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';

import '../common/sample_section_data.dart';
import 'brand_style_one.dart';
import 'brand_style_two.dart';

/// Selectable card layout for the brand section.
enum BrandCardStyle { cards, grid, }

class BrandSection extends StatelessWidget {
  final String title;
  final List<SampleTile> brands;
  final BrandCardStyle style;
  final Color? backgroundColor;
  final VoidCallback? onSeeAll;

  const BrandSection({
    super.key,
    this.title = 'Shop by brand',
    this.brands = SampleSectionData.brands,
    this.style = BrandCardStyle.cards,
    this.backgroundColor,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared header — same in all styles.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
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
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: onSeeAll,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      child: Text(
                        AppLocalizations.of(context)?.seeAll ?? 'See All',
                        style: AppTextStyles.body.copyWith(
                            color: Theme.of(context).colorScheme.tertiary,
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
      case BrandCardStyle.cards:
        return BrandStyleOne(brands: brands);
      case BrandCardStyle.grid:
        return BrandStyleTwo(brands: brands);
    }
  }
}
