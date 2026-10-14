import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../model/order_detail_model.dart';
import '../widgets/return_timeline_widget.dart';

class ReturnTimelinePage extends StatelessWidget {
  final ItemReturn returnData;

  const ReturnTimelinePage({super.key, required this.returnData});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          child: ReturnTimelineWidget(returnData: returnData),
        ),
      ),
    );
  }
}
