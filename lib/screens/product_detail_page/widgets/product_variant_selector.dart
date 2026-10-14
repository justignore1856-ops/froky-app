import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_commerce/utils/widgets/price_utils.dart';
import '../../../utils/widgets/dominant_colors.dart';

class ProductVariantSelector extends StatelessWidget {
  final String label;
  final String attributeSlug;
  final String variantType;
  final SwatchValues? selectedValue;
  final ValueChanged<SwatchValues> onSelected;
  final List<SwatchValues> productAttributes;
  final List<ProductVariants> variants;

  const ProductVariantSelector({
    super.key,
    required this.label,
    required this.attributeSlug,
    required this.variantType,
    required this.selectedValue,
    required this.onSelected,
    required this.productAttributes,
    required this.variants,
  });

  ProductVariants? _findVariantForSwatch(SwatchValues swatch) {
    try {
      return variants.firstWhere((v) {
        final attrValue = v.attributes[attributeSlug];
        return attrValue?.toString().toLowerCase().trim() ==
            swatch.value.toString().toLowerCase().trim();
      });
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isColor = variantType == 'color';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 10.h),
        isColor ? _buildColorSwatches(context) : _buildTextVariantCards(context),
        SizedBox(height: 5.h),
      ],
    );
  }

  Widget _buildColorSwatches(BuildContext context) {
    return SizedBox(
      height: 35.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productAttributes.length,
        itemBuilder: (BuildContext context, int index) {
          final currentValue = productAttributes[index];
          final isSelected = selectedValue == currentValue;
          final color = getColorFromHex(currentValue.swatch);
          final matchedVariant = _findVariantForSwatch(currentValue);
          final isOutOfStock = matchedVariant != null && !matchedVariant.isInStock;

          return GestureDetector(
            onTap: isOutOfStock ? null : () => onSelected(currentValue),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Opacity(
                opacity: isOutOfStock ? 0.4 : 1.0,
                child: Container(
                  width: 35.w,
                  height: 35.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check,
                            size: 16.sp,
                            color: (color?.computeLuminance() ?? 1.0) < 0.5
                                ? Colors.white
                                : Colors.black87,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextVariantCards(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: productAttributes.map((currentValue) {
        final isSelected = selectedValue == currentValue;
        final matchedVariant = _findVariantForSwatch(currentValue);
        final isOutOfStock =
            matchedVariant != null && !matchedVariant.isInStock;

        final double? price = matchedVariant?.price.toDouble();
        final double? salePrice = matchedVariant?.specialPrice.toDouble();
        final bool hasDiscount =
            price != null && salePrice != null && PriceUtils.hasDiscount(price, salePrice);
        final double discountPct = hasDiscount
            ? PriceUtils.calculateDiscountPercentage(price, salePrice)
            : 0;
        // Variant-level currency follows the per-row payload from PricePresenter.
        final String variantSymbol = matchedVariant?.currencySymbol ?? '';
        final variantFormat = matchedVariant?.format;
        String fmt(double v) => variantFormat != null
            ? PriceUtils.formatWithFormat(v, variantFormat, variantSymbol)
            : PriceUtils.formatWithSymbol(v, variantSymbol);
        final String displayPrice = salePrice != null && salePrice > 0
            ? fmt(salePrice)
            : (price != null ? fmt(price) : '');


        return GestureDetector(
          onTap: isOutOfStock ? null : () => onSelected(currentValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            constraints: BoxConstraints(minWidth: 80.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isOutOfStock
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.08)
                      : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isOutOfStock
                    ? theme.colorScheme.outline.withValues(alpha: 0.3)
                    : isSelected
                        ? AppTheme.primaryColor
                        : theme.colorScheme.outline.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Opacity(
              opacity: isOutOfStock ? 0.5 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentValue.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : theme.colorScheme.tertiary,
                    ),
                  ),
                  if (displayPrice.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      displayPrice,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : theme.colorScheme.tertiary,
                      ),
                    ),
                    if (hasDiscount) ...[
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fmt(price),
                            style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.tertiary.withValues(alpha: 0.6),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: theme.colorScheme.tertiary.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${discountPct.toStringAsFixed(2)}% off',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (isOutOfStock) ...[
                    SizedBox(height: 4.h),
                    Text(
                      l10n.outOfStock,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
