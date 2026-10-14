import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../model/order_detail_model.dart';

Color _timelineDone = AppTheme.orderTrackMainColor;
const Color _timelineException = Color(0xFFF59F00);
const Color _timelinePending = Color(0xFFd9d9d9);
const Color _timelinePendingText = Color(0xFFB0B0B0);

class OrderTimelineWidget extends StatelessWidget {
  final List<OrderTimelineStage> stages;

  const OrderTimelineWidget({super.key, required this.stages});

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stages.length; i++)
          _TimelineStageRow(
            stage: stages[i],
            isLast: i == stages.length - 1,
            incomingColor: i == 0 ? null : _incomingColor(i),
            dotColor: _dotColor(stages[i]),
          ),
      ],
    );
  }

  Color _incomingColor(int i) {
    final prev = stages[i - 1];
    final passed = prev.done == true && prev.current != true;
    return passed ? _timelineDone : _timelinePending;
  }

  Color _dotColor(OrderTimelineStage s) {
    if (_isException(s)) return _timelineException;
    final reached = s.done == true || s.current == true;
    return reached ? _timelineDone : _timelinePending;
  }

  static bool _isException(OrderTimelineStage s) {
    if ((s.marker ?? '').toLowerCase() == 'exception') return true;
    return s.events.any((e) => e.isException == true);
  }
}

class _TimelineStageRow extends StatelessWidget {
  final OrderTimelineStage stage;
  final bool isLast;
  final Color? incomingColor;
  final Color dotColor;

  const _TimelineStageRow({
    required this.stage,
    required this.isLast,
    required this.incomingColor,
    required this.dotColor,
  });

  bool get _isPassed => stage.done == true && stage.current != true;
  bool get _isActiveDone => stage.current == true && stage.done == true;
  bool get _isStageReached => stage.done == true || stage.current == true;

  Color get _belowDotColor {
    if (isLast) return Colors.transparent;
    return (_isPassed || _isActiveDone) ? _timelineDone : _timelinePending;
  }

  bool _isEventReached(int j) {
    if (_isPassed) return true;
    if (_isActiveDone) return stage.events[j].done == true;
    return false;
  }

  Color _railColor(bool reached) => reached ? _timelineDone : _timelinePending;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerRow(scheme),
        for (var j = 0; j < stage.events.length; j++) _eventRow(scheme, l10n, j),
      ],
    );
  }

  Widget _headerRow(ColorScheme scheme) {
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
                  color: incomingColor ?? Colors.transparent,
                ),
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: !_isStageReached ? Container(
                    width: 5.w,
                    height: 5.h,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ) : const SizedBox.shrink(),
                ),
                Expanded(child: Container(width: 2.w, color: _belowDotColor)),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: stage.events.isEmpty ? 10.h : 8.h),
              child: _headerContent(scheme, _isStageReached),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(ColorScheme scheme, AppLocalizations? l10n, int j) {
    final isLastEvent = j == stage.events.length - 1;
    final contentColor =
        isLast ? Colors.transparent : _railColor(_isEventReached(j));
    final gapColor = isLast
        ? Colors.transparent
        : _railColor(isLastEvent ? _isPassed : _isEventReached(j + 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 26.w,
                child: Column(
                  children: [
                    Expanded(child: Container(width: 2.w, color: contentColor)),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(child: _eventContent(scheme, l10n, stage.events[j], _isEventReached(j))),
            ],
          ),
        ),
        if (!(isLast && isLastEvent))
          SizedBox(
            height: 12.h,
            child: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Container(width: 2.w, color: gapColor),
            ),
          ),
      ],
    );
  }

  Widget _headerContent(ColorScheme scheme, bool reached) {
    final date = _formatHeaderDate(stage.at);
    final labelColor = reached ? scheme.onSurface : _timelinePendingText;
    final dateColor = reached ? scheme.onSurfaceVariant.withValues(alpha: 0.5) : _timelinePendingText;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: stage.label ?? '',
            style: AppTextStyles.body.copyWith(
              height: 1.3,
              color: labelColor,
            ),
          ),
          if (date.isNotEmpty)
            TextSpan(
              text: '  $date',
              style: AppTextStyles.label.copyWith(
                height: 1.0,
                color: dateColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _eventContent(
    ColorScheme scheme,
    AppLocalizations? l10n,
    OrderTimelineEvent e,
    bool reached,
  ) {
    _metaLine(e);
    final time = _formatEventDateTime(e.at);
    final label = _eventLabel(l10n, e, reached);
    final mainColor = reached ? scheme.onSurface : _timelinePendingText;
    final subColor = reached ? scheme.onSurfaceVariant.withValues(alpha: 0.5) : _timelinePendingText;
    /*return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final url = Uri.parse(meta); // meta should be your link

              if (await canLaunchUrl(url)) {
                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              } else {
              debugPrint('Could not launch $meta');
              }
            },
            child: Text(
              meta,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.35,
                color: mainColor,
              ),
            ),
          ),
        if (label.isNotEmpty)
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w300,
              height: 1.35,
              color: mainColor,
            ),
          ),
        if (time.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Text(
              time,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w300,
                height: 1.3,
                color: subColor,
              ),
            ),
          ),
      ],
    );*/

    return Builder(
      builder: (context) {
        final courier = (e.meta?['courier'] ?? '').toString().trim();
        final tracking = (e.meta?['tracking_id'] ?? '').toString().trim();
        final trackingUrl = (e.meta?['tracking_url'] ?? '').toString().trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (courier.isNotEmpty || tracking.isNotEmpty)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (courier.isNotEmpty)
                    Text(
                      '$courier - ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: mainColor,
                        height: 1.35,
                      ),
                    ),

                  if (tracking.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(trackingUrl);

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Text(
                        tracking,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            if (label.isNotEmpty)
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w300,
                  height: 1.35,
                  color: mainColor,
                ),
              ),
            if (time.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Text(
                  time,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                    color: subColor,
                  ),
                ),
              ),
          ],
        );
      }
    );
  }



  String _metaLine(OrderTimelineEvent e) {
    final meta = e.meta;
    if (meta == null) return '';
    final courier = (meta['courier'] ?? '').toString().trim();
    final tracking = (meta['tracking_id'] ?? '').toString().trim();

    return [courier, tracking].where((s) => s.isNotEmpty).join(' - ');
  }

  // Localized event text by status code: the reached form when the event has
  // happened, the "yet to…" form otherwise. Falls back to the backend label.
  String _eventLabel(AppLocalizations? l10n, OrderTimelineEvent e, bool reached) {
    final fallback = e.label ?? '';
    if (l10n == null) return fallback;
    switch (e.code) {
      case 'order_placed':
        return reached ? l10n.timelineOrderPlacedDone : l10n.timelineOrderPlacedPending;
      case 'payment_received':
        return reached ? l10n.timelinePaymentReceivedDone : l10n.timelinePaymentReceivedPending;
      case 'preparing':
        return reached ? l10n.timelinePreparingDone : l10n.timelinePreparingPending;
      case 'shipped':
        return reached ? l10n.timelineShippedDone : l10n.timelineShippedPending;
      case 'out_for_delivery':
        return reached ? l10n.timelineOutForDeliveryDone : l10n.timelineOutForDeliveryPending;
      case 'delivered':
        return reached ? l10n.timelineDeliveredDone : l10n.timelineDeliveredPending;
      case 'return_requested':
        return reached ? l10n.timelineReturnRequestedDone : l10n.timelineReturnRequestedPending;
      case 'return_received':
        return reached ? l10n.timelineReturnReceivedDone : l10n.timelineReturnReceivedPending;
      case 'refund_issued':
        return reached ? l10n.timelineRefundIssuedDone : l10n.timelineRefundIssuedPending;
      default:
        return fallback;
    }
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

DateTime? _tryParseDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim());
}

String _formatHeaderDate(String? raw) {
  final dt = _tryParseDate(raw);
  if (dt == null) return '';
  final weekday = DateFormat('EEE').format(dt);
  final month = DateFormat('MMM').format(dt);
  final year = DateFormat('yy').format(dt);
  return "$weekday, ${dt.day}${_ordinalSuffix(dt.day)} $month '$year";
}

String _formatEventDateTime(String? raw) {
  final dt = _tryParseDate(raw);
  if (dt == null) return '';
  final time = DateFormat('h:mm').format(dt) + DateFormat('a').format(dt).toLowerCase();
  return '${_formatHeaderDate(raw)} - $time';
}
