import 'package:flutter/material.dart';

/// Centers page content at a maximum width on tablets.
///
/// On phones (shortestSide < 600) this is a no-op and returns [child]
/// unchanged. On tablets it top-centers the content and constrains it to
/// [maxWidth], so phone-designed layouts stop stretching edge-to-edge.
class TabletConstrainedBody extends StatelessWidget {
  const TabletConstrainedBody({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.shortestSide < 600) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A drop-in replacement for `ListView.builder` that lays items out in two
/// columns on tablets (shortestSide >= 600) and a single column on phones.
///
/// Items are paired into rows, so variable-height cards are supported; the
/// two cells of a row are top-aligned. Scroll-based load-more listeners keep
/// working unchanged.
class TabletPairedListView extends StatelessWidget {
  const TabletPairedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.spacing = 12,
    this.controller,
    this.physics,
    this.clipBehavior = Clip.hardEdge,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final twoColumn = MediaQuery.of(context).size.shortestSide >= 600;
    if (!twoColumn) {
      return ListView.builder(
        padding: padding,
        controller: controller,
        physics: physics,
        clipBehavior: clipBehavior,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }
    final rowCount = (itemCount + 1) ~/ 2;
    return ListView.builder(
      padding: padding,
      controller: controller,
      physics: physics,
      clipBehavior: clipBehavior,
      itemCount: rowCount,
      itemBuilder: (context, row) {
        final left = row * 2;
        final right = left + 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: itemBuilder(context, left)),
            SizedBox(width: spacing),
            Expanded(
              child: right < itemCount
                  ? itemBuilder(context, right)
                  : const SizedBox(),
            ),
          ],
        );
      },
    );
  }
}
