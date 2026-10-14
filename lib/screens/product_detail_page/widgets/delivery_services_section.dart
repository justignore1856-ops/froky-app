import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:hyper_commerce/config/app_text_styles.dart';
import '../../../config/helper.dart';
import '../../../config/settings_data_instance.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../model/selected_address/selected_address_model.dart';
import '../../../utils/widgets/price_utils.dart';
import '../model/product_detail_model.dart';

class DeliveryServicesSection extends StatelessWidget {
  final ProductData product;
  final ProductVariants activeVariant;
  final SelectedAddress? selectedAddress;
  final VoidCallback onChangeAddress;

  const DeliveryServicesSection({
    super.key,
    required this.product,
    required this.activeVariant,
    required this.selectedAddress,
    required this.onChangeAddress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      color: surfaceColor,
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deliveryAndServices,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.tertiary,
            ),
          ),
          SizedBox(height: 12.h),
          _AddressPickerCard(address: selectedAddress, onTap: onChangeAddress),
          SizedBox(height: 12.h),
          _StandardDeliveryCard(activeVariant: activeVariant, product: product),
          SizedBox(height: 14.h),
          if (SettingsData.instance.payment?.cod == true)
            _ServiceInfoRow(
              icon: Icons.payments_outlined,
              title: l10n.payOnDeliveryAvailable,
            ),
          if (product.isReturnable) ...[
            SizedBox(height: 12.h),
            _ServiceInfoRow(
              icon: Icons.autorenew,
              title: l10n.hassleFreeReturnAndExchange(product.returnableDays),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressPickerCard extends StatelessWidget {
  final SelectedAddress? address;
  final VoidCallback onTap;

  const _AddressPickerCard({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final displayText = address != null
        ? _formatAddress(address!)
        : l10n.selectDeliveryAddress;

    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: isTablet(context) ? 22 : 18.sp,
              color: theme.colorScheme.tertiary.withValues(alpha: 0.8),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              l10n.change,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.tertiary,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(SelectedAddress address) {
    final parts = <String>[];
    final line1 = address.addressLine1?.trim();
    final city = address.city?.trim();
    final zipcode = address.zipcode?.trim();
    if (line1 != null && line1.isNotEmpty) parts.add(line1);
    if (city != null && city.isNotEmpty) parts.add(city);
    if (zipcode != null && zipcode.isNotEmpty) parts.add(zipcode);
    return parts.join(', ');
  }

}

class _StandardDeliveryCard extends StatelessWidget {
  final ProductVariants activeVariant;
  final ProductData product;

  const _StandardDeliveryCard({
    required this.activeVariant,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final double mrp = activeVariant.price.toDouble();
    final double? sale = activeVariant.specialPrice > 0
        ? activeVariant.specialPrice.toDouble()
        : null;
    final bool hasDiscount = sale != null && PriceUtils.hasDiscount(mrp, sale);
    final double discountPct = hasDiscount
        ? PriceUtils.calculateDiscountPercentage(mrp, sale)
        : 0;

    String fmt(double v) => PriceUtils.formatWithFormat(
          v,
          activeVariant.format,
          activeVariant.currencySymbol,
        );

    final String priceText = sale != null ? fmt(sale) : fmt(mrp);
    final isDeliverable = product.deliveryEta != null;
    final Color accent = product.deliveryEta != null ? AppTheme.primaryColor : AppTheme.errorColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: isDeliverable ? 8.h : 4.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(product.deliveryEta != null)...[
            Icon(
              Icons.check_circle,
              size: isTablet(context) ? 24 : 20.sp,
              color: accent,
            ),
            SizedBox(width: 10.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.standardDelivery,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.tertiary
                          .withValues(alpha: 0.7),
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 0.h),
                  Text(
                    _deliveryLine(context),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    '${l10n.mrp} ${fmt(mrp)}',
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.tertiary
                          .withValues(alpha: 0.6),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: theme.colorScheme.tertiary
                          .withValues(alpha: 0.6),
                    ),
                  ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      priceText,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    if (hasDiscount) ...[
                      SizedBox(width: 4.w),
                      Text(
                        '(${discountPct.toStringAsFixed(2)}% ${l10n.off})',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ]
          else...[
            Icon(
              TablerIcons.circle_x,
              size: isTablet(context) ? 24 : 20.sp,
              color: accent,
            ),
            SizedBox(width: 10.w),
            Text(
              'Item not deliverable to your location',
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.tertiary
                    .withValues(alpha: 0.7),
                letterSpacing: 0.3,
              ),
            ),
          ]
        ],
      ),
    );
  }

  String _deliveryLine(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eta = product.deliveryEta;
    final now = DateTime.now();
    final date = eta != null
        ? (etaDate(now, eta.max, eta.unit) ?? etaDate(now, eta.min, eta.unit))
        : null;
    final String formatted = DateFormat('d MMM').format(date!);
    return l10n.deliveryByDate(formatted);
  }
}

class _ServiceInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _ServiceInfoRow({
    required this.icon,
    required this.title,
  }) : subtitle = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Icon(
              icon,
              size: isTablet(context) ? 28 : 18.sp,
              color: theme.colorScheme.tertiary.withValues(alpha: 0.8),
            ),
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 12,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle!,
                  style: AppTextStyles.label.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
