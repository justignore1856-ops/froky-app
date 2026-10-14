import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/utils/widgets/custom_shimmer.dart';

class ProductDetailShimmer extends StatelessWidget {
  const ProductDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget.rectangular(
                          height: 25.h,
                          isBorder: true,
                        ),
                        SizedBox(height: 6.h,),
                        ShimmerWidget.rectangular(
                          height: 25.h,
                          isBorder: true,
                          width: 150.w,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 25.w,),
                  ShimmerWidget.rectangular(
                    height: 25.h,
                    isBorder: true,
                    width: 80.w,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ShimmerWidget.rectangular(
                    height: 25.h,
                    isBorder: true,
                    width: 60.w,
                  ),
                  SizedBox(width: 5.w,),
                  ShimmerWidget.rectangular(
                    height: 25.h,
                    isBorder: true,
                    width: 60.w,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h,),
            productListShimmer(3)
          ],
        ),
      ),
    );
  }
}

Widget productListShimmer(int crossAxisCount) {
  return Padding(
    padding: EdgeInsetsGeometry.directional(
      start: 14.w,
      end: 8.w,
      top: 8.h,
      bottom: 8.h,
    ),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 70),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 6.h,
        mainAxisExtent: crossAxisCount == 2 ? 180.h : 230.h,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget.rectangular(
              isBorder: true,
              height: 130.h,
              width: 130.w,
              borderRadius: 15,
            ),
            SizedBox(height: 10.h),
            ShimmerWidget.rectangular(
              isBorder: true,
              height: 15.h,
              width: 130.w,
              borderRadius: 15,
            ),
            const SizedBox(height: 2.0),
            ShimmerWidget.rectangular(
              isBorder: true,
              height: 15.h,
              width: 130.w,
              borderRadius: 15,
            ),
            const SizedBox(height: 2.0),
            ShimmerWidget.rectangular(
              isBorder: true,
              height: 15.h,
              width: 60.w,
              borderRadius: 15,
            ),
            const SizedBox(height: 2.0),
            ShimmerWidget.rectangular(
              isBorder: true,
              height: 15.h,
              width: 100.w,
              borderRadius: 15,
            ),
            const SizedBox(height: 2.0),
            ShimmerWidget.rectangular(
              isBorder: true,
              height: 15.h,
              width: 80.w,
              borderRadius: 15,
            ),
          ],
        );
      },
    ),
  );
}