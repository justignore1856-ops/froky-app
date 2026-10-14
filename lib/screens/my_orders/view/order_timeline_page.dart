import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../model/order_detail_model.dart';
import '../widgets/order_timeline_widget.dart';

class OrderTimelinePage extends StatelessWidget {
  final List<OrderTimelineStage> timeline;

  const OrderTimelinePage({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    log('Order Time line  ${timeline.first}');
    return CustomScaffold(
      showAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          child: OrderTimelineWidget(stages: timeline),
        ),
      ),
    );
  }
}
