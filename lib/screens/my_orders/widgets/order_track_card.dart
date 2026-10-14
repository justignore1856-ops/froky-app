import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../model/order_detail_model.dart';

const Color _trackDone = AppTheme.orderTrackMainColor;
const Color _trackInactive = Color(0xFFD9D9D9);
const Color _trackHollowBorder = Color(0xFFCBD5E1);
const Color _trackMuted = Color(0xFF9AA0A6);

class OrderTrackCard extends StatelessWidget {
  final List<OrderTimelineStage> stages;

  const OrderTrackCard({super.key, required this.stages});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final nodes = _buildNodes(context, l10n);
    final progress = _progress(nodes);
    final title = _currentStage()?.label ?? '';
    final subtitle = _statusSummary(l10n);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w300,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                SizedBox(height: 20.h),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, animated, _) =>
                      _stepper(context, nodes, animated),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(8.r),
              onTap: () => context.push(AppRoutes.orderTimeline, extra: stages),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Text(
                  l10n?.orderTrackSeeAllUpdates ?? 'See all updates',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── stepper ──────────────────────────────────────────────────────────────

  Widget _stepper(BuildContext context, List<_TrackNode> nodes, double progress) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < nodes.length; i++) ...[
              _node(context, nodes[i]),
              if (i != nodes.length - 1)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: _connector(
                      (progress - i).clamp(0.0, 1.0),
                      nodes[i + 1].color,
                    ),
                  ),
                ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        _labelsRow(nodes, (n) => n.label,
            fontSize: 10.sp, colorFor: (n) => n.done ? const Color(0xFF1F2937) : _trackMuted),
        SizedBox(height: 1.h),
      ],
    );
  }

  Widget _labelsRow(
    List<_TrackNode> nodes,
    String Function(_TrackNode) textOf, {
    required double fontSize,
    required Color Function(_TrackNode) colorFor,
  }) {
    return Row(
      children: [
        for (var i = 0; i < nodes.length; i++)
          Expanded(
            child: Text(
              textOf(nodes[i]),
              textAlign: _alignFor(i, nodes.length),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w300,
                color: colorFor(nodes[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _node(BuildContext context, _TrackNode node) {
    if (node.done) {
      return Container(
        width: 16.w,
        height: 16.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: node.color, shape: BoxShape.circle),
        child: Icon(node.icon, size: 12.sp, color: Colors.white),
      );
    }
    return Container(
      width: 16.w,
      height: 16.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: node.current ? node.color : _trackHollowBorder,
          width: 1.5.w,
        ),
      ),
    );
  }

  Widget _connector(double fill, Color color) {
    final f = fill.clamp(0.0, 1.0);
    final greenFlex = (f * 1000).round();
    final greyFlex = 1000 - greenFlex;
    return SizedBox(
      height: 2
          .h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (greenFlex > 0)
              Expanded(flex: greenFlex, child: ColoredBox(color: color)),
            if (greyFlex > 0)
              Expanded(flex: greyFlex, child: const ColoredBox(color: _trackInactive)),
          ],
        ),
      ),
    );
  }

  TextAlign _alignFor(int index, int length) {
    if (index == 0) return TextAlign.start;
    if (index == length - 1) return TextAlign.end;
    return TextAlign.center;
  }

  // ── data → nodes ─────────────────────────────────────────────────────────

  List<_TrackNode> _buildNodes(BuildContext context, AppLocalizations? l10n) {
    return _templateKeys()
        .map((key) => _nodeFor(context, key, _stageByKey(key), l10n))
        .toList();
  }

  List<String> _templateKeys() {
    if (_stageReached('cancelled') || _stageReached('canceled')) {
      return const ['confirmed', 'cancelled', 'refunded'];
    }
    if (_stageReached('returned')) {
      return const ['confirmed', 'delivered', 'returned', 'refunded'];
    }
    return const ['confirmed', 'shipped', 'delivered'];
  }

  /// "Reached" = the stage is done, current, or has at least one done event.
  /// Presence alone isn't enough (returned/refunded are always in the payload).
  bool _stageReached(String key) {
    final s = _stageByKey(key);
    if (s == null) return false;
    if (s.done == true || s.current == true) return true;
    return s.events.any((e) => e.done == true);
  }

  _TrackNode _nodeFor(BuildContext context, String key,
      OrderTimelineStage? stage, AppLocalizations? l10n) {
    return _TrackNode(
      key: key,
      label: _labelFor(key, stage, l10n),
      date: _formatTrackDate(stage?.at),
      done: stage?.done == true,
      current: stage?.current == true,
      color: _colorForKey(context, key),
      icon: _iconForKey(key),
      stage: stage,
    );
  }

  String _labelFor(String key, OrderTimelineStage? stage, AppLocalizations? l10n) {
    if ((stage?.label ?? '').isNotEmpty) return stage!.label!;
    switch (key) {
      case 'confirmed':
        return l10n?.orderTrackStepConfirmed ?? 'Order Confirmed';
      case 'shipped':
        return l10n?.orderTrackStepShipped ?? 'Shipped';
      case 'delivered':
        return l10n?.orderTrackStepDelivery ?? 'Delivered';
      case 'cancelled':
      case 'canceled':
        return l10n?.orderTrackStepCancelled ?? 'Cancelled';
      case 'returned':
        return l10n?.orderTrackStepReturned ?? 'Returned';
      case 'refunded':
        return l10n?.orderTrackStepRefunded ?? 'Refunded';
      default:
        return key;
    }
  }

  Color _colorForKey(BuildContext context, String key) {
    switch (key) {
      case 'cancelled':
      case 'canceled':
        return Theme.of(context).colorScheme.error;
      case 'returned':
        return context.appColors.warning;
      default:
        return _trackDone; // confirmed / shipped / delivered / refunded
    }
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'cancelled':
      case 'canceled':
        return Icons.close_rounded;
      case 'returned':
        return Icons.keyboard_return_rounded;
      default:
        return Icons.check_rounded;
    }
  }

  /// Overall progress in "node units": leading full segments + the partial
  /// fraction of the first in-progress segment.
  double _progress(List<_TrackNode> nodes) {
    double p = 0;
    for (var i = 0; i < nodes.length - 1; i++) {
      final frac = _segmentFraction(nodes, i);
      if (frac >= 1.0) {
        p = (i + 1).toDouble();
      } else {
        return i + frac;
      }
    }
    return p;
  }

  /// Fraction (0..1) of the connector between milestone [i] and [i+1], based on
  /// the done events across every timeline stage that lies between them
  /// (e.g. the hidden `preparing` stage between Confirmed and Shipped).
  double _segmentFraction(List<_TrackNode> nodes, int i) {
    final startIdx = _indexOfStageKey(nodes[i].key);
    final endIdx = _indexOfStageKey(nodes[i + 1].key);
    if (startIdx < 0 || endIdx < 0 || endIdx <= startIdx) {
      return nodes[i + 1].done ? 1.0 : 0.0;
    }
    int done = 0, total = 0;
    for (var k = startIdx + 1; k <= endIdx; k++) {
      final st = stages[k];
      if (st.events.isEmpty) {
        total += 1;
        if (st.done == true) done += 1;
      } else {
        total += st.events.length;
        // A done stage fully advances the line (node reached); only an
        // in-progress stage contributes a partial fill from its done events.
        done += st.done == true
            ? st.events.length
            : st.events.where((e) => e.done == true).length;
      }
    }
    if (total == 0) return nodes[i + 1].done ? 1.0 : 0.0;
    return done / total;
  }

  int _indexOfStageKey(String key) {
    for (var i = 0; i < stages.length; i++) {
      if ((stages[i].key ?? '').toLowerCase() == key) return i;
    }
    return -1;
  }

  OrderTimelineStage? _stageByKey(String key) {
    for (final s in stages) {
      if ((s.key ?? '').toLowerCase() == key) return s;
    }
    return null;
  }

  OrderTimelineStage? _currentStage() {
    for (final s in stages) {
      if (s.current == true) return s;
    }
    OrderTimelineStage? lastDone;
    for (final s in stages) {
      if (s.done == true) lastDone = s;
    }
    return lastDone ?? (stages.isNotEmpty ? stages.last : null);
  }

  String _statusSummary(AppLocalizations? l10n) {
    final key = (_currentStage()?.key ?? '').toLowerCase();
    switch (key) {
      case 'placed':
        return l10n?.orderTrackSummaryPlaced ?? 'Your order has been placed';
      case 'confirmed':
        return l10n?.orderTrackSummaryConfirmed ?? 'Your order is confirmed';
      case 'preparing':
        return l10n?.orderTrackSummaryPreparing ??
            'Seller is preparing your order';
      case 'shipped':
        return l10n?.orderTrackSummaryShipped ?? 'Your order is on the way';
      case 'delivered':
        return l10n?.orderTrackSummaryDelivered ?? 'Your order has been delivered';
      case 'cancelled':
      case 'canceled':
        return l10n?.orderTrackSummaryCancelled ?? 'Your order was cancelled';
      case 'returned':
        return l10n?.orderTrackSummaryReturned ?? 'Your return is in progress';
      case 'refunded':
        return l10n?.orderTrackSummaryRefunded ?? 'Your refund has been processed';
      default:
        return '';
    }
  }
}

class _TrackNode {
  final String key;
  final String label;
  final String date;
  final bool done;
  final bool current;
  final Color color;
  final IconData icon;
  final OrderTimelineStage? stage;

  const _TrackNode({
    required this.key,
    required this.label,
    required this.date,
    required this.done,
    required this.current,
    required this.color,
    required this.icon,
    required this.stage,
  });
}

String _formatTrackDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final dt = DateTime.tryParse(raw.trim());
  if (dt == null) return '';
  return DateFormat('MMM d').format(dt);
}
