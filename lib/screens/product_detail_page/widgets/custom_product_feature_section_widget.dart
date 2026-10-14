import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';

class CustomProductFeatureSectionWidget extends StatelessWidget {
  final List<CustomProductFeaturedSections> sections;

  const CustomProductFeatureSectionWidget({
    super.key,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;

        final fields = section.fields ?? [];

        if (fields.isEmpty) return const SizedBox.shrink();

        final bool isLast = index == sections.length - 1;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.r),
          ),
          margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: isLast ? 0.h : 20.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title (e.g. "Say Yes to fresh!", "Why Choose Us", etc.)
                if (section.title?.isNotEmpty == true)
                  Text(
                    section.title!,
                    style: AppTextStyles.titleSmall,
                  ),

                // Optional section description/subtitle
                if (section.description?.isNotEmpty == true) ...[
                  SizedBox(height: 4.h),
                  Text(
                    section.description!,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],

                SizedBox(height: section.title != null || section.description != null ? 10.h : 0.h),

                // All feature items (fields) of this section
                ...fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildFeatureItem(
                      image: field.image ?? '',
                      icon: _mapIcon(field.title ?? ''),
                      color: _mapColor(field.title ?? ''),
                      title: field.title ?? 'Feature',
                      description: field.description ?? '',
                      isLast: isLast
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String image,
    required Color color,
    required String title,
    required String description,
    required bool isLast,
  }) {
    return Container(
      // margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image.isNotEmpty == true) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: image,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: 46, height: 46, color: Colors.white),
                errorWidget: (_, __, ___) =>
                    Container(width: 46, height: 46, color: Colors.white),
              ),
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1117),
                  ),
                ),
                if (description.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: const Color(0xFF5B5454),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple heuristic-based icon & color mapping
  IconData _mapIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('fresh') || t.contains('sourced') || t.contains('daily')) {
      return Icons.eco_outlined;
    }
    if (t.contains('expert') || t.contains('team')) {
      return Icons.people_alt_outlined;
    }
    if (t.contains('quality') || t.contains('check') || t.contains('audit')) {
      return Icons.verified_outlined;
    }
    if (t.contains('pack') || t.contains('hygiene')) {
      return Icons.inventory_2_outlined;
    }
    if (t.contains('store') || t.contains('assurance') || t.contains('shop')) {
      return Icons.storefront_outlined;
    }
    return Icons.check_circle_outline_rounded;
  }

  Color _mapColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('fresh') || t.contains('sourced')) return Colors.green.shade600;
    if (t.contains('expert')) return Colors.teal.shade600;
    if (t.contains('quality') || t.contains('check')) return Colors.blue.shade600;
    if (t.contains('pack') || t.contains('hygiene')) return Colors.green.shade700;
    if (t.contains('store') || t.contains('assurance')) return Colors.orange.shade700;
    return AppTheme.primaryColor;
  }
}