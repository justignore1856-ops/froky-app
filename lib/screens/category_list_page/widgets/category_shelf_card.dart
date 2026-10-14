import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/utils/widgets/cache_manager.dart';
import '../../../router/app_routes.dart';
import '../../home_page/model/category_model.dart';
import '../../product_listing_page/model/product_listing_type.dart';

class CategoryShelfCard extends StatelessWidget {
  final CategoryData category;

  const CategoryShelfCard({super.key, required this.category});

  void _openCategory(BuildContext context) {
    GoRouter.of(context).push(AppRoutes.productListing, extra: {
      'isTheirMoreCategory': (category.subcategoryCount ?? 0) > 0,
      'title': category.title,
      'logo': category.image,
      'totalProduct': category.productCount,
      'type': ProductListingType.category,
      'identifier': category.slug,
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    final isDark = isDarkMode(context);
    final cardBgColor =
        isDark ? AppTheme.darkProductCardColor : const Color(0xFFECEEF1);
    final titleColor =
        isDark ? AppTheme.darkFontColor : const Color(0xFF111827);

    return Material(
      color: cardBgColor,
      borderRadius: radius,
      child: InkWell(
        onTap: () => _openCategory(context),
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bottom-Right Category Image
              if (category.image != null && category.image!.isNotEmpty)
                Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  width: 90.w,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: CachedNetworkImage(
                      imageUrl: category.image!,
                      cacheManager: customCacheManager,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      fadeInDuration: const Duration(milliseconds: 150),
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

              // Top-Left Category Title
              Positioned(
                left: 12.w,
                top: 12.h,
                right: 75.w,
                child: Text(
                  category.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.fontFamily,
                    color: titleColor,
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


