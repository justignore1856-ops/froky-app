import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/home_page/model/category_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

/// Fluid, TabBar-style vertical sliding subcategory sidebar
class SideSubcategoryBar extends StatefulWidget {
  final List<CategoryData> subcategories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SideSubcategoryBar({
    super.key,
    required this.subcategories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<SideSubcategoryBar> createState() => _SideSubcategoryBarState();
}

class _SideSubcategoryBarState extends State<SideSubcategoryBar> {
  final ScrollController _scrollController = ScrollController();
  static final double _itemHeight = 86.h;
  static final double _highlightMargin = 5.h;
  static final double _highlightHeight = 86.h - 10.h;

  @override
  void didUpdateWidget(covariant SideSubcategoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = (widget.selectedIndex * _itemHeight) -
        (viewportHeight / 2) +
        (_itemHeight / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = widget.subcategories.length + 1; // 0 = "All"
    final int safeSelectedIndex = widget.selectedIndex.clamp(0, totalCount - 1);
    final double highlightTop = safeSelectedIndex * _itemHeight + _highlightMargin;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppTheme.primaryColor;

    return Container(
      width: 75.w,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(top: 0, bottom: 70.h),
        child: Stack(
          children: [
            // 🔹 1. Animated Sliding Active Background Highlight
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubicEmphasized,
              top: highlightTop,
              height: _highlightHeight,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.26 : 0.18),
                      primaryColor.withValues(alpha: isDark ? 0.14 : 0.09),
                      primaryColor.withValues(alpha: isDark ? 0.04 : 0.025),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.75, 1.0],
                  ),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(0.r),
                  ),
                ),
              ),
            ),

            // 🔹 2. Animated Sliding TabBar Right Edge Indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubicEmphasized,
              top: highlightTop,
              height: _highlightHeight,
              right: 0,
              width: 3.5.w,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(8.r),
                  ),
                ),
              ),
            ),

            // 🔹 3. Subcategory Items List Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: List.generate(totalCount, (index) {
                final bool isSelected = safeSelectedIndex == index;
                final bool isAll = index == 0;
                final CategoryData? subcategory =
                    isAll ? null : widget.subcategories[index - 1];

                final String title = isAll ? "All" : (subcategory?.title ?? '');
                final String imagePath = isAll
                    ? 'assets/images/icons/shopping-basket.png'
                    : (subcategory?.image ?? '');

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onSelected(index),
                  child: SizedBox(
                    height: _itemHeight,
                    width: 75.w,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.06 : 0.94,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              height: 42.h,
                              width: 42.w,
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: CustomImageContainer(
                                imagePath: imagePath,
                                height: isSelected ? 40.h : 35.h,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: isSelected ? 11.5.sp : 11.sp,
                              color: isSelected
                                  ? (isDark ? Colors.white : primaryColor)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.75),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}