import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/utils/widgets/price_utils.dart';
import '../../../config/helper.dart';
import '../../../utils/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../model/get_cart_model.dart';
import '../model/promo_code_model.dart';

class BillSummaryWidget extends StatelessWidget {
  final double itemsOriginalPrice;
  final double itemsDiscountedPrice;
  final double itemsSavings;
  final double deliveryChargeOriginal;
  final double platformFee;
  final double? codFee;
  final double grandTotal;
  final double totalSavings;
  final bool? isFromOrderDetail;
  final VoidCallback? downloadInvoice;
  final String? promoCode;
  final double? promoDiscount;
  final String? promoError;
  final VoidCallback? removeCoupon;
  final String? promoMode;
  final String? discountAmount;
  final PromoCodeData? promoApplied;
  final List<SellerShippingCost> sellerShippingCosts;
  final List<TaxBreakdownItem> taxBreakdown;
  final double? taxTotal;
  final List<PendingCharge> pendingCharges;
  final double? pendingChargesTotal;
  final String? currencySymbol;
  final MoneyFormat? format;
  final double? totalPayable;
  final String? paymentMethod;


  const BillSummaryWidget({
    super.key,
    required this.itemsOriginalPrice,
    required this.itemsDiscountedPrice,
    required this.itemsSavings,
    required this.deliveryChargeOriginal,
    required this.platformFee,
    this.codFee,
    required this.grandTotal,
    required this.totalSavings,
    this.isFromOrderDetail = false,
    this.downloadInvoice,
    this.promoCode,
    this.promoDiscount,
    this.promoError,
    this.removeCoupon,
    this.promoMode,
    this.discountAmount,
    this.promoApplied,
    this.totalPayable,
    this.sellerShippingCosts = const [],
    this.taxBreakdown = const [],
    this.taxTotal,
    this.pendingCharges = const [],
    this.pendingChargesTotal,
    this.currencySymbol,
    this.format,
    this.paymentMethod
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = currencySymbol ?? AppHelpers.currency;

    String formatPriceVal(double amount) {
      if (format != null) {
        return PriceUtils.formatWithFormat(amount, format!, currency);
      }
      return PriceUtils.formatWithSymbol(amount, currency);
    }

    final promoCode = this.promoCode;
    final promoDiscount = this.promoDiscount;
    final promoError = this.promoError;
    final totalPayable = this.totalPayable;
    final sellerShippingCosts = this.sellerShippingCosts;
    final taxBreakdown = this.taxBreakdown;
    final pendingCharges = this.pendingCharges;
    // If any store in the shipping breakdown can't fulfil, the whole order
    // is treated as not deliverable — surface that in the charge row/popup.
    final hasUndeliverable =
        sellerShippingCosts.any((s) => s.isFulfillable == false);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        // borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isFromOrderDetail == false ? 12.0.w : 12.w,
          right: 12.0.w,
          top: 12.h,
          bottom: 12.h
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.billDetails ?? 'Bill details',
              style: AppTextStyles.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(height: 20.h),

            _buildItemRow(
              context: context,
              icon: Icons.receipt_long,
              label: l10n?.itemsTotal ?? 'Items total',
              originalPrice: itemsOriginalPrice > itemsDiscountedPrice ? formatPriceVal(itemsOriginalPrice) : null,
              finalPrice: formatPriceVal(itemsDiscountedPrice),
              hasDiscount: itemsOriginalPrice > itemsDiscountedPrice,
              // Always enabled — popup falls back to a note-only view when
              // the API returns no tax breakdown.
              onLabelTap: () => _showBillInfoPopup(
                context: context,
                title: l10n?.itemsTotal ?? 'Items total',
                note:
                    'Taxes shown here are inclusive in the item prices and '
                    'are calculated based on government regulations and '
                    'product types.',
                entries: taxBreakdown
                    .map((t) => _BillInfoEntry(
                          label: t.title ?? 'Tax',
                          priceText:
                              formatPriceVal(t.amount?.toDouble() ?? 0.0),
                        ))
                    .toList(),
                totalLabel: 'Total taxes',
                totalPriceText:
                    taxTotal != null ? formatPriceVal(taxTotal!) : null,
              ),
            ),
            SizedBox(height: 16.h),

            _buildItemRow(
              context: context,
              icon: Icons.delivery_dining,
              label: l10n?.deliveryCharge ?? 'Delivery charge',
              originalPrice: null,
              finalPrice: hasUndeliverable
                  ? 'Not deliverable'
                  : (deliveryChargeOriginal <= 0 ? (l10n?.free ?? 'FREE') : formatPriceVal(deliveryChargeOriginal)),
              finalPriceColor: hasUndeliverable
                  ? Theme.of(context).colorScheme.error
                  : (deliveryChargeOriginal <= 0 ? context.appColors.success : null),
              onLabelTap: () => _showBillInfoPopup(
                context: context,
                title: l10n?.deliveryCharge ?? 'Delivery charge',
                note:
                    'Delivery charges may vary based on your address, '
                    'the store fulfilling each item, and order value.',
                entries: sellerShippingCosts.map((s) {
                  final priceText = s.isFulfillable == false
                      ? 'Not deliverable'
                      : (s.shippingCost == 0.0
                          ? (l10n?.free ?? 'FREE')
                          : formatPriceVal(s.shippingCost?.toDouble() ?? 0.0));
                  return _BillInfoEntry(
                    label: s.storeName ?? 'Store',
                    priceText: priceText,
                    priceColor: s.isFulfillable == false
                        ? Theme.of(context).colorScheme.error
                        : (s.shippingCost == 0.0
                            ? context.appColors.success
                            : null),
                  );
                }).toList(),
                totalLabel: l10n?.deliveryCharge ?? 'Delivery charge',
                totalPriceText: hasUndeliverable
                    ? 'Not deliverable'
                    : (deliveryChargeOriginal <= 0
                        ? (l10n?.free ?? 'FREE')
                        : formatPriceVal(deliveryChargeOriginal)),
              ),
            ),
            SizedBox(height: 16.h),

            // Platform fee row
            if(platformFee != 0.0)...[
              _buildItemRow(
                context: context,
                icon: Icons.shopping_bag,
                label: l10n?.platformFee ?? 'Platform fee',
                finalPrice: platformFee <= 0 ? (l10n?.free ?? 'FREE') : '$currency${platformFee.toStringAsFixed(2)}',
                onLabelTap: () => _showBillInfoPopup(
                  context: context,
                  title: l10n?.platformFee ?? 'Platform fee',
                  note:
                      'A small fee that helps us run and improve the platform, '
                      'including customer support, security, and technology costs.',
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // COD Fee row
            if(codFee != null && codFee != 0.0)...[
              _buildItemRow(
                context: context,
                icon: Icons.shopping_bag,
                label: l10n?.codFee ?? 'COD fee',
                finalPrice: codFee! <= 0 ? (l10n?.free ?? 'FREE') : '$currency${codFee!.toStringAsFixed(2)}',
                onLabelTap: () => _showBillInfoPopup(
                  context: context,
                  title: l10n?.codFee ?? 'Cash on Delivery fee',
                  note:
                      'An additional charge applied to Cash on Delivery orders '
                      'to cover the handling and processing of cash payments. '
                      'Choose an online payment method to avoid this fee.',
                ),
              ),
              SizedBox(height: 16.h),
            ],

            if (promoCode != null && promoCode.isNotEmpty) ...[
              _buildItemRow(
                context: context,
                icon: TablerIcons.rosette_discount_filled,
                label: l10n?.promo ?? 'Promo',
                originalPrice: null,
                finalPrice: (promoDiscount ?? 0) <= 0
                    ? (l10n?.free ?? 'FREE')
                    : '-${formatPriceVal(promoDiscount ?? 0)}',
                finalPriceColor: context.appColors.success,
                onLabelTap: () => _showPromoDetailPopup(
                  context: context,
                  promoCode: promoCode,
                  l10n: l10n,
                ),
              ),
              SizedBox(height: 16.h),
            ],

            /// For Cart Bill Promo Preview
            if(isFromOrderDetail == false) ...[
              // Promo error message (if present)
              if (promoError != null && promoError.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          promoError,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ],

            if (pendingCharges.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 18,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Outstanding Charges',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...pendingCharges.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${c.reason ?? "Pending Charge"}${c.reasonNote != null ? " (${c.reasonNote})" : ""}',
                                style: AppTextStyles.label.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            Text(
                              formatPriceVal(c.amount?.toDouble() ?? 0.0),
                              style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.error
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const Divider(),
            SizedBox(height: 8.h),
            // Grand total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.grandTotal ?? 'Grand total',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                Text(
                  formatPriceVal(grandTotal),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),


            // Savings highlight — reinforces value at the decision point.
            if (isFromOrderDetail == false && totalSavings > 0) ...[
              _buildSavingsBanner(
                context: context,
                amountText: formatPriceVal(totalSavings),
                l10n: l10n,
              ),
            ],


            // Total payable row (order detail page only)
            if (isFromOrderDetail == true && totalPayable != null) ...[
              SizedBox(height: 5.h),
              Container(
                height: 40.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 1.0
                  )
                ),
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.paidBy ?? 'Paid By',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(filterPaymentMethodIcon(paymentMethod ?? 'cod'), color: Colors.black54, size: 15,),
                        SizedBox(width: 8.w,),
                        Text(
                          filterPaymentMethodLabel(paymentMethod ?? 'cod'),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],

          ],
        ),
      ),
    );
  }


  IconData _getPromoIcon(String? promoMode) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return Icons.account_balance_wallet;
      case 'instant':
        return Icons.check;
      default:
        return Icons.local_offer;
    }
  }

  String _getPromoTitle(String? promoMode, AppLocalizations? l10n) {
    final mode = promoMode?.toLowerCase() ?? 'instant';
    switch (mode) {
      case 'cashback':
        return l10n?.cashbackApplied ?? 'Cashback Applied';
      case 'instant':
        return l10n?.instantDiscountApplied ?? 'Instant Discount Applied';
      default:
        return l10n?.promoApplied ?? 'Promo Applied';
    }
  }

  Widget _buildSavingsBanner({
    required BuildContext context,
    required String amountText,
    required AppLocalizations? l10n,
  }) {
    final Color badgeColor =
        Color.lerp(context.appColors.success, Colors.black, 0.28) ?? context.appColors.success;

    const marker = '';
    final template =
        l10n?.youreSavingOnOrder(marker) ?? "You're saving $marker on this order";
    final parts = template.split(marker);
    final prefix = parts.isNotEmpty ? parts[0] : '';
    final suffix = parts.length > 1 ? parts[1] : '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.appColors.success.withValues(alpha: 0.25),
            context.appColors.success.withValues(alpha: 0.15),
          ],
        ),
        // border: Border.all(
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.rosette_discount_check_filled, color: Colors.green.shade900,),
          SizedBox(width: 10.w),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
                children: [
                  TextSpan(text: prefix),
                  TextSpan(
                    text: amountText,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      decorationColor: badgeColor,
                      decorationThickness: 2,
                    ),
                  ),
                  TextSpan(text: suffix),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required IconData icon,
    required String label,
    required BuildContext context,
    String? additionalInfo,
    String? originalPrice,
    required String finalPrice,
    bool hasDiscount = false,
    Color? finalPriceColor,
    VoidCallback? onLabelTap,
  }) {
    final bool isTappable = onLabelTap != null;

    final TextStyle labelStyle = AppTextStyles.body.copyWith(
      color: Theme.of(context).colorScheme.tertiary,
    );

    final Widget labelText = isTappable
        ? _DashedUnderlinedText(
            text: label,
            style: labelStyle,
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
          )
        : Text(label, style: labelStyle);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTappable)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InkWell(
                    onTap: onLabelTap,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 0),
                      child: Column(
                          children: [
                            labelText,
                          ]
                      ),
                    ),
                  ),
                )
              else
                labelText,
              if (additionalInfo != null)
                Text(
                  additionalInfo,
                  style: AppTextStyles.body.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            if (hasDiscount && originalPrice != null) ...[
              Text(
                originalPrice,
                style: AppTextStyles.label.copyWith(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              finalPrice,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: finalPriceColor ?? Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBillInfoPopup({
    required BuildContext context,
    required String title,
    required String note,
    List<_BillInfoEntry> entries = const [],
    String? totalLabel,
    String? totalPriceText,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "BillInfoDialog",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),

      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final theme = Theme.of(dialogContext);

        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                backgroundColor: theme.colorScheme.surface,
                titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                title: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entries.isNotEmpty) ...[
                        ...entries.map(
                              (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.label,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  e.priceText,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: e.priceColor ?? theme.colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (totalPriceText != null) ...[
                          Divider(height: 20.h),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  totalLabel ?? 'Total',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                              ),
                              Text(
                                totalPriceText,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 12.h),
                      ],
                      Text(
                        note,
                        style: AppTextStyles.label.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      AppLocalizations.of(context)!.gotIt,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showPromoDetailPopup({
    required BuildContext context,
    required String promoCode,
    required AppLocalizations? l10n,
  }) {
    final String? description = promoApplied?.description;
    final bool canRemove = isFromOrderDetail == false && removeCoupon != null;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "PromoDialog",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),

      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final theme = Theme.of(dialogContext);

        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                backgroundColor: theme.colorScheme.surface,
                titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                title: Row(
                  children: [
                    Icon(
                      _getPromoIcon(promoMode),
                      size: 20,
                      color: context.appColors.success,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _getPromoTitle(promoMode, l10n),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          promoCode.toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      if (description != null && description.isNotEmpty) ...[
                        Text(
                          description,
                          style: AppTextStyles.label.copyWith(
                            height: 1.4,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                l10n?.promoNote ??
                                    'This promo has been applied to your order. The discount is reflected in your total amount.',
                                style: AppTextStyles.label.copyWith(
                                  height: 1.4,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (canRemove)
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        removeCoupon?.call();
                      },
                      child: Text(
                        l10n?.removeCoupon ?? 'Remove Coupon',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      AppLocalizations.of(context)!.gotIt,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _BillInfoEntry {
  final String label;
  final String priceText;
  final Color? priceColor;

  const _BillInfoEntry({
    required this.label,
    required this.priceText,
    this.priceColor,
  });
}

class _DashedUnderlinedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color color;

  const _DashedUnderlinedText({
    required this.text,
    required this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(text, style: style),
          CustomPaint(
            painter: _DashedLinePainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  static const double _dashWidth = 1.0;
  static const double _dashSpace = 3.0;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.square;
    double startX = 0;
    final double y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + _dashWidth, y),
        paint,
      );
      startX += _dashWidth + _dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}