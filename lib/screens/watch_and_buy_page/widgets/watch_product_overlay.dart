import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';

class WatchProductOverlay extends StatefulWidget {
  final List<WatchProductItem> products;
  final String title;
  final String description;
  final String storeName;
  final String storeLogo;

  const WatchProductOverlay({
    super.key,
    required this.products,
    required this.title,
    required this.description,
    required this.storeName,
    required this.storeLogo,
  });

  @override
  State<WatchProductOverlay> createState() => _WatchProductOverlayState();
}

class _WatchProductOverlayState extends State<WatchProductOverlay> {
  Widget _buildSingleProductCard(BuildContext context, WatchProductItem product,
      {double? width}) {
    final price = product.displayPrice;
    final originalPrice = product.price;
    final hasDiscount = product.hasDiscount;
    final discountPercent = hasDiscount
        ? (((originalPrice - price) / originalPrice) * 100).round()
        : 0;

    final currency =
        product.currencySymbol.isNotEmpty ? product.currencySymbol : '₹';

    final ratingDisplay = product.ratings != null
        ? product.ratings!.toStringAsFixed(1)
        : (product.ratingCount?.toString());

    return GestureDetector(
      onTap: () {
        if (product.productSlug.isNotEmpty) {
          GoRouter.of(context).push(
            AppRoutes.productDetailPage,
            extra: {'productSlug': product.productSlug},
          );
        }
      },
      child: Container(
        width: width,
        height: 100,
        padding: EdgeInsets.all(7.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Thumbnail Image
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CustomImageContainer(
                      imagePath: product.image,
                      height: 52.r,
                      width: 40.r,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (ratingDisplay != null)
                  PositionedDirectional(
                    bottom: 3,
                    start: 3,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            ratingDisplay,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            TablerIcons.star_filled,
                            size: 10,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8.w),

            // Product Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Price and Discount row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.w,
                    runSpacing: 2.h,
                    children: [
                      Text(
                        '$currency${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (hasDiscount)
                        Text(
                          '$currency${originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black38,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (hasDiscount)
                        Text(
                          '$discountPercent% OFF',
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProducts = widget.products.isNotEmpty;
    final captionText = widget.description.isNotEmpty ? widget.description : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Creator Profile Row
        Padding(
          padding: EdgeInsets.only(left: 16.w, right: 80.w),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.storeName.isNotEmpty) {
                GoRouter.of(context).push(
                  AppRoutes.sellerProfile,
                  extra: {
                    'username': widget.storeName,
                  },
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.storeLogo.isNotEmpty)
                  ClipOval(
                    child: CustomImageContainer(
                      imagePath: widget.storeLogo,
                      height: 28.r,
                      width: 28.r,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (widget.storeLogo.isNotEmpty) SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    widget.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),

        // 2. Expandable Video Caption / Description
        if (captionText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 80.w),
            child: _ExpandableCaption(text: captionText),
          ),
        SizedBox(height: 10.h),

        // 3. Bottom Product Card(s)
        if (hasProducts)
          widget.products.length == 1
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: SizedBox(
                    height: 90,
                    child: _buildSingleProductCard(
                      context,
                      widget.products.first,
                    ),
                  ),
                )
              : SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: widget.products.length,
                    separatorBuilder: (_, __) => SizedBox(width: 10.w),
                    itemBuilder: (context, idx) {
                      return _buildSingleProductCard(
                        context,
                        widget.products[idx],
                        width: 220.w,
                      );
                    },
                  ),
                ),
      ],
    );
  }
}

/// Expandable Caption Widget (2 lines collapsed by default, expands on tap with smooth animation)
class _ExpandableCaption extends StatefulWidget {
  final String text;

  const _ExpandableCaption({required this.text});

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant _ExpandableCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.3,
      shadows: [
        Shadow(color: Colors.black87, blurRadius: 6),
      ],
    );

    // If text is short (<= 75 chars), show without toggle
    if (widget.text.trim().length <= 75) {
      return Text(
        widget.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.topLeft,
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _isExpanded ? 130.h : 42.h,
          ),
          child: SingleChildScrollView(
            physics: _isExpanded
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: RichText(
              text: TextSpan(
                style: textStyle,
                children: [
                  TextSpan(
                    text: _isExpanded
                        ? widget.text
                        : '${widget.text.substring(0, 70).trim()}... ',
                  ),
                  TextSpan(
                    text: _isExpanded ? ' less' : 'more',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
