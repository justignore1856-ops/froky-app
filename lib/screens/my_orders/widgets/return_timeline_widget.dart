import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../model/order_detail_model.dart';

Color _timelineDone = AppTheme.orderTrackMainColor;
const Color _timelinePending = Color(0xFFD9D9D9);
const Color _timelinePendingText = Color(0xFFB0B0B0);

class ReturnTimelineWidget extends StatelessWidget {
  final ItemReturn returnData;

  const ReturnTimelineWidget({super.key, required this.returnData});

  bool get _isRejected =>
      (returnData.returnStatus ?? returnData.returnItemCustomerStatus?.code ?? '')
          .toLowerCase()
          .trim() ==
      'rejected';

  int get _lastDoneIndex {
    var idx = -1;
    for (var i = 0; i < returnData.returnTimeline.length; i++) {
      if (returnData.returnTimeline[i].done == true) idx = i;
    }
    return idx;
  }

  int get _activeIndex {
    if (_isRejected) return -1;
    final next = _lastDoneIndex + 1;
    return next < returnData.returnTimeline.length ? next : -1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = returnData.returnTimeline;
    if (steps.isEmpty) return const SizedBox.shrink();
    final active = _activeIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isRejected) _rejectedBanner(context),
        for (var i = 0; i < steps.length; i++)
          _ReturnStepRow(
            step: steps[i],
            subText: _subText(l10n, steps[i]),
            isFirst: i == 0,
            isLast: i == steps.length - 1,
            reached: steps[i].done == true,
            isActive: i == active,
            incomingReached: i > 0 && steps[i - 1].done == true,
          ),
      ],
    );
  }

  String _subText(AppLocalizations? l10n, ReturnTimelineStep step) {
    if (l10n == null) return '';
    final reached = step.done == true;
    switch ((step.key ?? '').toLowerCase().trim()) {
      case 'requested':
        return reached
            ? l10n.returnStepRequestedDone
            : l10n.returnStepRequestedPending;
      case 'approved':
        return reached
            ? l10n.returnStepApprovedDone
            : l10n.returnStepApprovedPending;
      case 'picked_up':
        return reached
            ? l10n.returnStepPickedUpDone
            : l10n.returnStepPickedUpPending;
      case 'received':
        return reached
            ? l10n.returnStepReceivedDone
            : l10n.returnStepReceivedPending;
      case 'refunded':
        return reached
            ? l10n.returnStepRefundedDone
            : l10n.returnStepRefundedPending;
      default:
        return '';
    }
  }

  Widget _rejectedBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = returnData.returnItemCustomerStatus?.label ?? 'Return rejected';
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, size: 16.sp, color: scheme.error),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnStepRow extends StatelessWidget {
  final ReturnTimelineStep step;
  final String subText;
  final bool isFirst;
  final bool isLast;
  final bool reached;
  final bool isActive;
  final bool incomingReached;

  const _ReturnStepRow({
    required this.step,
    required this.subText,
    required this.isFirst,
    required this.isLast,
    required this.reached,
    required this.isActive,
    required this.incomingReached,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlighted = reached || isActive;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26.w,
            child: Column(
              children: [
                Container(
                  width: 2.w,
                  height: 3.h,
                  color: isFirst
                      ? Colors.transparent
                      : (incomingReached ? _timelineDone : _timelinePending),
                ),
                _dot(),
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: isLast
                        ? Colors.transparent
                        : (reached ? _timelineDone : _timelinePending),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
              child: _content(scheme, highlighted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    if (reached) {
      return Container(
        width: 12.w,
        height: 12.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _timelineDone, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: 8.sp, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _timelineDone, width: 2.w),
        ),
      );
    }
    return Container(
      width: 12.w,
      height: 12.w,
      alignment: Alignment.center,
      decoration:
          const BoxDecoration(color: _timelinePending, shape: BoxShape.circle),
      child: Container(
        width: 5.w,
        height: 5.w,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  Widget _content(ColorScheme scheme, bool highlighted) {
    final labelColor = highlighted ? scheme.onSurface : _timelinePendingText;
    final dateColor = highlighted
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : _timelinePendingText;
    final date = _formatStepDateTime(step.at);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.label ?? '',
          style: AppTextStyles.body.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            height: 1.3,
            color: labelColor,
          ),
        ),
        if (subText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              subText,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w300,
                height: 1.3,
                color: labelColor.withValues(alpha: highlighted ? 0.75 : 1),
              ),
            ),
          ),
        if (date.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              date,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w300,
                height: 1.3,
                color: dateColor,
              ),
            ),
          ),
      ],
    );
  }
}

String _ordinalSuffix(int day) {
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

String _formatStepDateTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final dt = DateTime.tryParse(raw.trim());
  if (dt == null) return '';
  final weekday = DateFormat('EEE').format(dt);
  final month = DateFormat('MMM').format(dt);
  final year = DateFormat('yy').format(dt);
  final time =
      DateFormat('h:mm').format(dt) + DateFormat('a').format(dt).toLowerCase();
  return "$weekday, ${dt.day}${_ordinalSuffix(dt.day)} $month '$year - $time";
}
