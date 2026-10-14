import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/my_orders/model/order_detail_model.dart';
import 'package:intl/intl.dart';

enum _RefundStage { requested, approved, processing, credited, rejected, cancelled }

const Color _neutralPill = Color(0xFF9AA0A6);

class ItemRefundCard extends StatelessWidget {
  final OrderDetailData order;
  final OrderItems item;

  const ItemRefundCard({
    super.key,
    required this.order,
    required this.item,
  });

  static bool hasRefund(OrderItems item) =>
      item.returns.any((r) => (r.refundAmount ?? 0) > 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final refunds =
        item.returns.where((r) => (r.refundAmount ?? 0) > 0).toList();
    if (refunds.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange_rounded,
                  size: 16.sp,),
              SizedBox(width: 6.w),
              Text(
                l10n?.itemRefundTitle ?? 'Refund',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          for (int i = 0; i < refunds.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Divider(
                  height: 1, color: Theme.of(context).colorScheme.outline),
              )
            else
              SizedBox(height: 10.h),
            _RefundBlock(order: order, refund: refunds[i]),
          ],
        ],
      ),
    );
  }
}

class _RefundBlock extends StatelessWidget {
  final OrderDetailData order;
  final ItemReturn refund;

  const _RefundBlock({required this.order, required this.refund});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final stage = _stageOf(refund);
    final amountText = _money(order, (refund.refundAmount ?? 0).toDouble());
    final pill = _pill(context, l10n, stage);
    final note = _note(l10n, stage);
    final date = _formatDate(refund.refundProcessedAt);
    final method = _methodText(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.itemRefundAmountLabel ?? 'Refund amount',
                    style: AppTextStyles.label.copyWith(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    amountText,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: pill.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                pill.text,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: pill.color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: pill.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(pill.icon, size: 15.sp, color: pill.color),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  note,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        if ((refund.quantity ?? 0) > 0)
          _detailRow(context, l10n?.itemRefundQtyLabel ?? 'Items returned',
              '${refund.quantity}'),
        if (stage != _RefundStage.rejected && stage != _RefundStage.cancelled)
          _detailRow(context, l10n?.itemRefundMethodLabel ?? 'Refund method',
              method),
        if (stage == _RefundStage.credited && date != null)
          _detailRow(
              context, l10n?.itemRefundDateLabel ?? 'Refunded on', date),
        if ((refund.reason ?? '').trim().isNotEmpty)
          _detailRow(context, l10n?.itemRefundReasonLabel ?? 'Reason',
              refund.reason!.trim()),
        if (_showTimelineLink) ...[
          SizedBox(height: 10.h),
          _timelineLink(context, l10n),
        ],
      ],
    );
  }

  bool get _isCancelled =>
      (refund.returnItemCustomerStatus?.code ?? refund.returnStatus ?? '')
          .toLowerCase()
          .trim() ==
      'cancelled';

  bool get _showTimelineLink =>
      !_isCancelled && refund.returnTimeline.isNotEmpty;

  Widget _timelineLink(BuildContext context, AppLocalizations? l10n) {
    return InkWell(
      onTap: () => context.push(AppRoutes.returnTimeline, extra: refund),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(Icons.timeline_rounded,
                size: 15.sp, color: Theme.of(context).colorScheme.tertiary),
            SizedBox(width: 6.w),
            Text(
              l10n?.viewReturnTimeline ?? 'View return timeline',
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(Icons.chevron_right,
                size: 16.sp, color: Theme.of(context).colorScheme.tertiary),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: Colors.grey.shade600),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _RefundStage _stageOf(ItemReturn r) {
    final status =
        (r.returnStatus ?? r.returnItemCustomerStatus?.code ?? '').toLowerCase().trim();
    if (status == 'cancelled' || status == 'canceled') {
      return _RefundStage.cancelled;
    }
    if (status == 'rejected') return _RefundStage.rejected;
    if (status == 'refunded' ||
        status == 'refund_processed' ||
        (r.refundProcessedAt ?? '').isNotEmpty) {
      return _RefundStage.credited;
    }
    if (status == 'received' ||
        (r.receivedAt ?? '').isNotEmpty ||
        status == 'picked_up' ||
        (r.pickedUpAt ?? '').isNotEmpty) {
      return _RefundStage.processing;
    }
    if (status == 'approved' || (r.sellerApprovedAt ?? '').isNotEmpty) {
      return _RefundStage.approved;
    }
    return _RefundStage.requested;
  }

  _RefundPill _pill(
      BuildContext context, AppLocalizations? l10n, _RefundStage stage) {
    switch (stage) {
      case _RefundStage.credited:
        return _RefundPill(
          text: l10n?.refundStatusRefunded ?? 'Refunded',
          color: context.appColors.success,
          icon: Icons.check_circle_rounded,
        );
      case _RefundStage.processing:
        return _RefundPill(
          text: l10n?.refundStatusProcessing ?? 'Processing',
          color: context.appColors.warning,
          icon: Icons.autorenew_rounded,
        );
      case _RefundStage.approved:
        return _RefundPill(
          text: refund.returnItemCustomerStatus?.label ?? 'Approved',
          color: context.appColors.warning,
          icon: Icons.verified_outlined,
        );
      case _RefundStage.cancelled:
        return _RefundPill(
          text: refund.returnItemCustomerStatus?.label ?? 'Cancelled',
          color: _neutralPill,
          icon: Icons.do_not_disturb_on_outlined,
        );
      case _RefundStage.rejected:
        return _RefundPill(
          text: l10n?.refundStatusRejected ?? 'Rejected',
          color: Theme.of(context).colorScheme.error,
          icon: Icons.cancel_rounded,
        );
      case _RefundStage.requested:
        return _RefundPill(
          text: l10n?.refundStatusRequested ?? 'Requested',
          color: context.appColors.warning,
          icon: Icons.schedule_rounded,
        );
    }
  }

  String _note(AppLocalizations? l10n, _RefundStage stage) {
    switch (stage) {
      case _RefundStage.credited:
        return l10n?.itemRefundCreditedNote ??
            'Refund completed successfully.';
      case _RefundStage.processing:
        return l10n?.itemRefundProcessingNote ??
            'Refund is being processed and should reflect within 1–3 days.';
      case _RefundStage.approved:
        return refund.returnItemCustomerStatus?.description ??
            'Your return has been approved. The refund will be initiated once the item is picked up.';
      case _RefundStage.cancelled:
        return refund.returnItemCustomerStatus?.description ??
            'This return was cancelled, so no refund was issued.';
      case _RefundStage.rejected:
        return l10n?.itemRefundRejectedNote ??
            'This return was rejected, so no refund was issued.';
      case _RefundStage.requested:
        return l10n?.itemRefundRequestedNote ??
            'Refund will be initiated once your return is approved.';
    }
  }

  String _methodText(AppLocalizations? l10n) {
    final isCod = (order.paymentMethod ?? '').toLowerCase().contains('cod');
    if (isCod) return l10n?.refundMethodWallet ?? 'Wallet';
    return l10n?.refundMethodSource ?? 'Original payment method';
  }

  String? _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return DateFormat('d MMM yyyy').format(dt.toLocal());
  }
}

class _RefundPill {
  final String text;
  final Color color;
  final IconData icon;

  const _RefundPill({
    required this.text,
    required this.color,
    required this.icon,
  });
}

String _money(OrderDetailData order, double value) {
  final symbol = (order.currencySymbol == null || order.currencySymbol!.isEmpty)
      ? '₹'
      : order.currencySymbol!;
  return '$symbol${formatPrice(value)}';
}
