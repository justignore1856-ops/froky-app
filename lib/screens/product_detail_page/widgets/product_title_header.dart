import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/price_row_widget.dart';
import 'package:hyper_commerce/utils/widgets/sponsored_badge.dart';
import '../../../l10n/app_localizations.dart';

/// The top section of the product detail page: title, estimated delivery.
class ProductTitleHeader extends StatelessWidget {
  final ProductData product;
  final ProductVariants activeVariant;
  final ProductVariants currentVariant;

  const ProductTitleHeader({
    super.key,
    required this.product,
    required this.activeVariant,
    required this.currentVariant,
  });

  @override
  Widget build(BuildContext context) {
    final lowStockLimit =
        int.tryParse(SettingsData.instance.system?.lowStockLimit ?? '') ?? 5;
    product.estimatedDeliveryTime.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brandName.isNotEmpty ? capitalizeFirstLetter(product.brandName) : product.categoryName,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8)
                ),
              ),
            ),
          ],
        ),
        if (product.isSponsored)
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 2.h),
            child: const SponsoredBadge(style: SponsoredBadgeStyle.chip),
          ),
        if (currentVariant.stock != null &&
            currentVariant.stock! <= lowStockLimit &&
            currentVariant.stock! > 0) ...[
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                AppLocalizations.of(context)!.hurryOnlyLeft(currentVariant.stock!),
                style: AppTextStyles.label.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 10.h),
        PriceRowWidget(
          originalPrice: activeVariant.price.toDouble(),
          salePrice: activeVariant.specialPrice.toDouble(),
          currencySymbol: activeVariant.currencySymbol,
          format: activeVariant.format,
          fontSize: 12.sp,
          originalFontSize: 10.sp,
          discountFontSize: 8.sp,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }


}