import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart'
    show ProductData;

import '../../../../../config/helper.dart';
import '../common/section_background.dart';
import 'home_layout_product_card.dart';

class DynamicProductSection extends StatelessWidget {
  final String title;
  final List<ProductData> products;
  final String orientation;
  final String? style;
  final SectionBackground background;
  final VoidCallback? onSeeAll;

  const DynamicProductSection({
    super.key,
    required this.title,
    required this.products,
    this.orientation = 'horizontal',
    this.style,
    this.background = const SectionBackground.none(),
    this.onSeeAll,
  });

  bool get _isGrid => orientation == 'vertical';
  bool get _isCatalog => style == 'catalog' || style == 'compact';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveBackground =
        (_isGrid && background.type == SectionBackgroundType.image)
            ? const SectionBackground.none()
            : background;
    return Container(
      decoration: effectiveBackground.toDecoration(),
      padding: effectiveBackground.hasBackground
          ? EdgeInsets.symmetric(vertical: 16.h)
          : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || onSeeAll != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.w, 16.w, 14.h),
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
                    GestureDetector(
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
          _body(context),
        ],
      ),
    );
  }

  Widget _body(BuildContext ctx) {
    if (products.isEmpty) return const SizedBox.shrink();
    if (_isGrid) {
      final maxExtent = _isCatalog ? 180.w : 140.w;
      final mainExtent = _isCatalog
          ? (isTablet(ctx) ? 245.h : 290.h)
          : 220.h;

      final visibleProducts = products.take(12).toList();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleProducts.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            mainAxisExtent: mainExtent,
          ),
          padding: EdgeInsets.zero,
          itemBuilder: (context, i) => HomeLayoutProductCard(
            data: products[i],
            style: style,
          ),
        ),
      );
    }

    final listHeight = _isCatalog
        ? (isTablet(ctx) ? 245.h : 290.h)
        : (isTablet(ctx) ? 212.h : 220.h);
    final cardWidth = _isCatalog ? 160.w : 110.w;

    return SizedBox(
      height: listHeight,
      child: RepaintBoundary(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: products.length,
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemBuilder: (context, i) => SizedBox(
            width: cardWidth,
            child: HomeLayoutProductCard(
              data: products[i],
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
