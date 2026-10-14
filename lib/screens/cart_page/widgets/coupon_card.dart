import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';
import '../model/promo_code_model.dart';

class CouponCard extends StatefulWidget {
  final PromoCodeData coupon;
  final double cartAmount;
  final bool isApplied;
  final bool isLoading;
  final VoidCallback? onApply;

  const CouponCard({
    super.key,
    required this.coupon,
    this.cartAmount = 0,
    this.isApplied = false,
    this.isLoading = false,
    this.onApply,
  });

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool get _isCashback =>
      (widget.coupon.promoMode ?? '').toLowerCase() == 'cashback';

  bool get _isPercent =>
      (widget.coupon.discountType ?? widget.coupon.promoMode ?? '')
          .toLowerCase()
          .contains('percent');

  double? _num(String? raw) => double.tryParse(raw ?? '');

  String _plain(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();


  String _stubLabel(AppLocalizations? l10n) {
    if (_isCashback) return l10n?.cashbackLabel ?? 'CASHBACK';
    final amt = _num(widget.coupon.discountAmount);
    final amtStr = amt == null ? '' : _plain(amt);
    if (_isPercent) return '$amtStr% ${l10n?.off ?? 'OFF'}';
    return '${AppHelpers.baseCurrencySymbol}$amtStr ${l10n?.off ?? 'OFF'}';
  }


  void _showDescriptionSheet(BuildContext context, String description) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 5.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (widget.coupon.code ?? '').toUpperCase(),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Icon(
                        TablerIcons.x,
                        size: 20.r,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Html(
                    data: description,
                    shrinkWrap: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {


    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final Color stubColor =
    isDarkMode(context) ? Colors.grey.shade700 : Colors.grey.shade500;
    final Color notchColor = theme.colorScheme.surfaceContainer;
    final Color mutedColor = theme.colorScheme.onSecondaryContainer;

    final double minOrder = _num(widget.coupon.minOrderTotal) ?? 0;
    final double remaining = minOrder - widget.cartAmount;
    final String? description = widget.coupon.description;

    // A coupon is unavailable (not yet unlocked) when the cart total hasn't
    // reached the minimum order requirement and it isn't already applied.
    final bool isUnavailable = remaining > 0 && !widget.isApplied;

    final Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 60.w,
            color: stubColor,
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                _stubLabel(l10n),
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(l10n, theme, remaining),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 1,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                        theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    widget.coupon.shortDescription ?? '',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: mutedColor,
                      height: 1.35,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          _showDescriptionSheet(context, description),
                      child: Text(
                        '+ ${l10n?.moreLabel ?? 'MORE'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isUnavailable ? 0.45 : 1.0,
        child: IgnorePointer(
          // Prevent taps on the "MORE" link / apply text while the card
          // is dimmed out and not yet unlocked.
          ignoring: isUnavailable,
          child: IntrinsicHeight(
            child: Stack(
              children: [
                cardContent,
                Positioned(
                  left: -6,
                  top: 0,
                  bottom: 0,
                  width: 12,
                  child: CustomPaint(
                    painter: _NotchPainter(notchColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      AppLocalizations? l10n, ThemeData theme, double remaining) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          TablerIcons.rosette_discount,
          size: isTablet(context) ? 26 : 22.r,
          color: AppTheme.primaryColor,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            (widget.coupon.code ?? '').toUpperCase(),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.tertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        _buildApplyAction(l10n, theme, remaining),
      ],
    );
  }

  Widget _buildApplyAction(
      AppLocalizations? l10n, ThemeData theme, double remaining) {
    if (widget.isLoading) {
      return SizedBox(
        width: 16.r,
        height: 16.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (widget.isApplied) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n?.applied ?? 'Applied',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.success,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(TablerIcons.circle_check,
              size: 16, color: context.appColors.success),
        ],
      );
    }
    // Card-level dimming now communicates unavailability, so the apply
    // text always uses the active/primary color here.
    return Semantics(
      button: true,
      label: l10n?.apply ?? 'Apply',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onApply,
        child: Text(
          (l10n?.apply ?? 'Apply').toUpperCase(),
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

}

class _NotchPainter extends CustomPainter {
  final Color color;

  _NotchPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const int count = 4;
    const double r = 7;
    const double gap = 8;
    const double step = (2 * r) + gap;
    const double totalHeight = (count * 2 * r) + ((count - 1) * gap);
    double y = ((size.height - totalHeight) / 2) + r;
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(Offset(size.width / 2, y), r, paint);
      y += step;
    }
  }

  @override
  bool shouldRepaint(covariant _NotchPainter old) => old.color != color;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const double dash = 3;
    const double gap = 3;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}