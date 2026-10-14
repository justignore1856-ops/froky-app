import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import '../../../utils/money_format.dart';
import '../../../utils/widgets/price_utils.dart';

class PriceRowWidget extends StatelessWidget {
  final double originalPrice;
  final double? salePrice;
  final String currencySymbol;
  final MoneyFormat? format;
  final double? fontSize;
  final double? originalFontSize;
  final double? discountFontSize;
  final FontWeight? fontWeight;
  final Color? priceColor;
  final Color? originalPriceColor;
  final Color? discountBackgroundColor;
  final Color? discountTextColor;

  const PriceRowWidget({
    super.key,
    required this.originalPrice,
    this.salePrice,
    this.currencySymbol = '',
    this.format,
    this.fontSize,
    this.originalFontSize,
    this.discountFontSize,
    this.fontWeight,
    this.priceColor,
    this.originalPriceColor,
    this.discountBackgroundColor,
    this.discountTextColor,
  });

  @override
  Widget build(BuildContext context) {
    // ────────────────────────────────────────────────
    final displayPrice = salePrice != null && salePrice! > 0 ? salePrice! : originalPrice;

    // Only show discount UI if there's a meaningful discount
    final hasRealDiscount = salePrice != null &&
        salePrice! > 0 &&
        salePrice! < originalPrice &&
        (originalPrice - salePrice!).abs() > 0.01; // avoid floating-point noise

    final discountPercentage = hasRealDiscount
        ? PriceUtils.calculateDiscountPercentage(originalPrice, salePrice!)
        : 0;

    String fmt(double v) => format != null
        ? PriceUtils.formatWithFormat(v, format!, currencySymbol)
        : PriceUtils.formatWithSymbol(v, currencySymbol);

    // ────────────────────────────────────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6, // horizontal spacing
          runSpacing: 2, // vertical spacing when wrapped
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 🔹 Main Price
            Text(
              fmt(displayPrice),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: fontWeight ?? FontWeight.bold,
                color: priceColor ?? Theme.of(context).colorScheme.tertiary,
              ),
            ),

            if (hasRealDiscount) ...[
              // 🔹 Original Price
              Text(
                fmt(originalPrice),
                style: AppTextStyles.caption.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.5),
                  decorationColor: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.5),
                ),
              ),

              // 🔹 Discount Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: Text(
                  '${discountPercentage.toStringAsFixed(2)}% OFF',
                  style: TextStyle(
                    fontSize: discountFontSize ?? 10.sp,
                    fontWeight: FontWeight.w500,
                    color: discountTextColor ?? Colors.green,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}