import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/sample_section_data.dart';

/// Brand cards — Style 1 (body only, no section title).
/// Card design replicated from `custom_brands_card.dart`: a bordered surface
/// card with a subtle shadow and the logo shown with BoxFit.contain, in a
/// horizontal scroll. Card width adapts for tablets (65.w) vs phones (100.w).
class BrandStyleOne extends StatelessWidget {
  final List<SampleTile> brands;

  const BrandStyleOne({
    super.key,
    this.brands = SampleSectionData.brands,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return SizedBox(
      height: 90.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: brands.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, i) {
          final tile = brands[i];
          return GestureDetector(
            onTap: tile.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
            width: isTablet ? 65.w : 100.w,
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: scheme.tertiary.withValues(alpha: 0.1),
                  blurRadius: 0.5,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: CachedNetworkImage(
              imageUrl: tile.imageUrl,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) =>
                  Icon(Icons.storefront_rounded, color: scheme.primary),
            ),
          ),
          );
        },
      ),
    );
  }
}
