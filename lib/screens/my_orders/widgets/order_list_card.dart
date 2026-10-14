import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:intl/intl.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/my_orders/model/order_list_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:remixicon/remixicon.dart';

class OrderListCard extends StatelessWidget {
  final OrderListItem item;
  final VoidCallback onTap;
  final ValueChanged<int>? onRate;

  const OrderListCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final visual = _StatusVisual.resolve(_statusCode);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(0.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusHeader(item: item, visual: visual, l10n: l10n),
              SizedBox(height: 12.h),
              if (visual.kind == _StatusKind.delivered)
                _RateSection(
                  item: item,
                  l10n: l10n,
                  onRate: onRate,
                  child: _ProductRow(item: item, l10n: l10n, onTap: onTap,),
                )
              else
                _ProductRow(item: item, l10n: l10n, onTap: onTap,),
              ..._buildFooter(context, theme, l10n, visual),
            ],
          ),
        ),
      ),
    );
  }

  String get _statusCode =>
      (item.customerStatus?.code ?? item.status ?? '').toLowerCase().trim();

  List<Widget> _buildFooter(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    _StatusVisual visual,
  ) {
    final money = _formatMoney(
      item.order?.currency?.symbol,
      item.subtotal,
    );

    if (visual.kind == _StatusKind.refunded) {
      return [
        SizedBox(height: 12.h),
        _RefundBanner(
          title: l10n?.refundOfCredited(money) ?? 'Refund of $money credited',
          note: l10n?.refundCreditedProcessedNote ??
              'Processed to your original payment method. It may take 2-3 days to reflect.',
          accent: visual.color,
        ),
      ];
    }

    if (visual.kind == _StatusKind.returned) {
      return [
        SizedBox(height: 10.h),
        _FooterNote(
          text: l10n?.refundInitiatedToSource(money) ??
              'Refund of $money initiated to source',
        ),
      ];
    }

    if (visual.kind == _StatusKind.cancelled) {
      return [
        SizedBox(height: 10.h),
        _FooterNote(
          text: l10n?.cancelledAsPerRequest ?? 'Cancelled as per your request',
        ),
      ];
    }

    if (visual.kind == _StatusKind.exchange) {
      final date = _formatDate(item.returnDeadline);
      if (date == null) return const [];
      return [
        SizedBox(height: 10.h),
        _FooterNote(
          text: l10n?.pickupScheduledFor(date) ?? 'Pickup scheduled for $date',
        ),
      ];
    }

    return const [];
  }
}

class _StatusHeader extends StatelessWidget {
  final OrderListItem item;
  final _StatusVisual visual;
  final AppLocalizations? l10n;

  const _StatusHeader({
    required this.item,
    required this.visual,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final label = item.customerStatus?.label ??
        capitalizeFirstLetter(
            removeUnderscores(item.status ?? item.status ?? ''));
    final date = _formatDate(item.customerStatus?.at ?? item.createdAt);
    final dateLine = date == null
        ? label
        : (l10n?.orderStatusDate('On', date) ?? 'On · $date');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 34.w,
                height: 34.w,
                child: Image.asset(
                  visual.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Container(
                    decoration: BoxDecoration(
                      color: visual.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(visual.icon, size: 16.sp, color: visual.color),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: visual.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.h),
                    Text(
                      dateLine,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if(SettingsData.instance.system!.isDev == true)
          Text(
            '#${item.id}',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w300,
            ),
          )
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final OrderListItem item;
  final AppLocalizations? l10n;
  final VoidCallback onTap;

  const _ProductRow({required this.item, required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = _imageUrl;
    final title = item.title ?? item.product?.name ?? '';
    final category = item.product?.category ?? '';
    final brand = item.product!.brand;
    final variant = _variantLabel;
    final deadline = _formatDate(item.returnDeadline);
    final isDelivered = _StatusVisual.resolve(
          (item.customerStatus?.code ?? item.status ?? '')
              .toLowerCase()
              .trim(),
        ).kind ==
        _StatusKind.delivered;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.15),
              width: 0.8
          ),
          left: BorderSide(
              color: Colors.grey.withValues(alpha: 0.15),
              width: 0.8
          ),
            right: BorderSide(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 0.8
            ),
          bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.15),
              width: 0.8
          )
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            spreadRadius: 0.2,
            offset: const Offset(0, 0),
          ),
        ],
        borderRadius: BorderRadius.circular(12.r)
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: image.isNotEmpty
                          ? CustomImageContainer(
                              imagePath: image,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.image_outlined,
                              size: 24.sp,
                              color: Colors.grey.shade400,
                            ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            brand ?? category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w300,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (variant != null && variant.isNotEmpty) ...[
                            SizedBox(height: 0.h),
                            Text(
                              variant,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w300,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.chevron_right,
                      size: 22.sp,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                if (isDelivered &&
                    item.returnEligible == true &&
                    deadline != null) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(RemixIcons.close_circle_fill, color: Colors.grey.shade500, size: 18,),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          l10n?.returnWindowCloses(deadline) ??
                              'Return window closes $deadline',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w300,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _imageUrl {
    final v = item.variant?.image ?? '';
    if (v.isNotEmpty) return v;
    return item.product?.image ?? '';
  }

  String? get _variantLabel {
    final title = item.title ?? '';
    final variantTitle = item.variantTitle ?? '';
    if (variantTitle.isEmpty || variantTitle == title) return null;
    if (title.isNotEmpty && variantTitle.startsWith(title)) {
      final suffix = variantTitle
          .substring(title.length)
          .replaceFirst(RegExp(r'^[\s\-–—:]+'), '')
          .trim();
      return suffix.isEmpty ? null : suffix;
    }
    return variantTitle;
  }
}

class _RateRow extends StatelessWidget {
  final ValueChanged<int>? onRate;
  final int rating;
  final Color starColor;
  final Color labelColor;

  const _RateRow({
    required this.onRate,
    this.rating = 0,
    this.starColor = const Color(0xFFBDBDBD),
    this.labelColor = const Color(0xFF424242),
  });

  @override
  Widget build(BuildContext context) {
    log('Hello  $onRate');
    return Row(
      children: [
        Image.asset(
            'assets/images/icons/rating.png',
          height: 40,
        ),
        const SizedBox(width: 10,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: onRate == null ? null : () => onRate!(index + 1),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: Icon(
                      index < rating
                          ? TablerIcons.star_filled
                          : TablerIcons.star,
                      size: 16.sp,
                      color: AppTheme.ratingStarColor,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsetsGeometry.directional(start: 5.0),
              child: Text(
                'Rate this product',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RateSection extends StatelessWidget {
  final OrderListItem item;
  final Widget child;
  final AppLocalizations? l10n;
  final ValueChanged<int>? onRate;

  const _RateSection({
    required this.item,
    required this.child,
    required this.l10n,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final rating = item.userReview?.rating ?? 0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 1.0),
            AppTheme.primaryColor.withValues(alpha: 0.2),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 0.8
        ),
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 6.h),
            child: _RateRow(
              onRate: onRate,
              rating: rating,
              starColor: Colors.black.withValues(alpha: 0.55),
              labelColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundBanner extends StatelessWidget {
  final String title;
  final String note;
  final Color accent;

  const _RefundBanner({
    required this.title,
    required this.note,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            note,
            style: AppTextStyles.label.copyWith(
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  final String text;

  const _FooterNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: Colors.grey.shade600,
      ),
    );
  }
}

enum _StatusKind {
  delivered,
  outForDelivery,
  processing,
  exchange,
  cancelled,
  refunded,
  returned,
  unknown,
}

const String _statusIconBase = 'assets/images/order-status-icons/';

class _StatusVisual {
  final _StatusKind kind;
  final Color color;
  final IconData icon;
  final String asset;

  const _StatusVisual(this.kind, this.color, this.icon, this.asset);

  static _StatusVisual resolve(String code) {
    switch (code) {
      case 'delivered':
      case 'fulfilled':
      case 'completed':
        return const _StatusVisual(_StatusKind.delivered, Color(0xFF1BA672),
            Icons.check_circle_rounded, '${_statusIconBase}delivered.png');
      case 'out_for_delivery':
      case 'shipped':
      case 'on_the_way':
      case 'dispatched':
        return const _StatusVisual(_StatusKind.outForDelivery,
            Color(0xFF2F80ED), Icons.local_shipping_rounded,
            '${_statusIconBase}shipped.png');
      case 'exchange':
      case 'exchange_in_progress':
      case 'exchange_requested':
        return const _StatusVisual(_StatusKind.exchange, Colors.black,
            Icons.sync_rounded, '${_statusIconBase}on-hold.png');
      case 'cancelled':
      case 'canceled':
        return const _StatusVisual(_StatusKind.cancelled, Color(0xFFEB5757),
            Icons.cancel_rounded, '${_statusIconBase}cancelled.png');
      case 'refunded':
      case 'refund_credited':
      case 'refund_initiated':
        return const _StatusVisual(_StatusKind.refunded, Colors.black,
            Icons.replay_rounded, '${_statusIconBase}refunded.png');
      case 'returned':
      case 'return_received':
      case 'return_completed':
        return const _StatusVisual(_StatusKind.returned, Colors.black,
            Icons.keyboard_return_rounded, '${_statusIconBase}return.png');
      case 'processing':
      case 'active':
      case 'confirmed':
      case 'open':
      case 'pending':
        return const _StatusVisual(_StatusKind.processing, Colors.black,
            Icons.autorenew_rounded, '${_statusIconBase}processing.png');
      case 'on_hold':
      default:
        return const _StatusVisual(_StatusKind.unknown, Color(0xFF6B7280),
            Icons.info_rounded, '${_statusIconBase}on-hold.png');
    }
  }
}

String? _formatDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateFormat('EEE, d MMM yyyy').format(parsed.toLocal());
}

String _formatMoney(String? symbol, String? amount) {
  final value = parseDouble(amount);
  final sym = (symbol == null || symbol.isEmpty) ? '' : symbol;
  return '$sym${formatPrice(value)}';
}
