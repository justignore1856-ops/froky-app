import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:lottie/lottie.dart';

import '../../config/theme.dart';
import 'cache_manager.dart';
import 'custom_shimmer.dart';

class CustomImageContainer extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool? isForCategoryTab;

  const CustomImageContainer({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.isForCategoryTab = false,
  });

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isSvgImage(String path) {
    return path.toLowerCase().endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {
    // log('IMAGE ____ $imagePath');
    final bool isSvg = _isSvgImage(imagePath);
    final bool isNetwork = _isNetworkImage(imagePath);
    final bool isLottieFile = imagePath.toLowerCase().contains('.json');

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: isLottieFile
            ? (isNetwork
            ? Lottie.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: (context, child, composition) => composition == null
              ? placeholder ??
              ShimmerWidget.rectangular(
                width: width,
                height: 200.h,
                isBorder: false,
              )
              : child,
          errorBuilder: errorWidget != null ? (_, __, ___) => errorWidget! : null,
        )
            : Lottie.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: (context, child, composition) => composition == null
              ? placeholder ??
              ShimmerWidget.rectangular(
                width: width,
                height: 200.h,
                isBorder: false,
              )
              : child,
          errorBuilder: errorWidget != null ? (_, __, ___) => errorWidget! : null,
        ))
            : isSvg
            ? (isNetwork
            ? SvgPicture.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: placeholder != null ? (_) => placeholder! : null,
        )
            : SvgPicture.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          colorMapper: const CustomColorMapper(
            targetColor: Color(0xFFFFB616), // The exact color inside the SVG
            replacementColor: AppTheme.primaryColor, // Your constant color
          ),
          placeholderBuilder: placeholder != null ? (_) => placeholder! : null,
        ))
            : (isNetwork
            ? CachedNetworkImage(
          imageUrl: imagePath,
          cacheManager: customCacheManager,
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.high,
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 300),
          useOldImageOnUrlChange: true,
          imageBuilder: (context, imageProvider) {
            return Image(image: imageProvider, fit: fit);
          },
          placeholder: (context, url) =>
          placeholder ??
              ShimmerWidget.rectangular(
                width: width,
                height: 200.h,
                isBorder: false,
              ),
          errorWidget: (context, url, error) {
            return errorWidget ??
                Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 50,
                  ),
                );
          },
        )
            : Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    TablerIcons.package,
                    color: Colors.grey,
                    size: 100,
                  ),
                );
          },
        )),
      ),
    );
  }
}

// 1. Create a ColorMapper class
class CustomColorMapper extends ColorMapper {
  final Color targetColor;
  final Color replacementColor;

  const CustomColorMapper({
    required this.targetColor,
    required this.replacementColor,
  });

  @override
  Color substitute(
      String? id,
      String elementName,
      String attributeName,
      Color color,
      ) {
    // If the SVG engine finds the old color, swap it with the new one
    if (color == targetColor) {
      return replacementColor;
    }
    // Otherwise, leave the original color alone
    return color;
  }
}


/*
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'cache_manager.dart';

class CustomImageContainer extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool? isForCategoryTab;
  final bool useOldImageOnUrlChange;
  final bool gaplessPlayback;

  const CustomImageContainer({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.isForCategoryTab = false,
    this.useOldImageOnUrlChange = false,
    this.gaplessPlayback = true,
  });

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isSvgImage(String path) {
    return path.toLowerCase().endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {

    final bool isSvg = _isSvgImage(imagePath);
    final bool isNetwork = _isNetworkImage(imagePath);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: _isNetworkImage(imagePath)
            ? CachedNetworkImage(
                imageUrl: imagePath,
                memCacheWidth: 300,
                cacheManager: customCacheManager,
                width: width,
                height: height,
                fit: fit,
                filterQuality: FilterQuality.high,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                useOldImageOnUrlChange: useOldImageOnUrlChange,
                imageBuilder: (context, imageProvider) {
                  return Image(
                    image: imageProvider,
                    width: width,
                    height: height,
                    fit: fit,
                    gaplessPlayback: gaplessPlayback,
                  );
                },
                placeholder: (context, url) => placeholder ??
                  Center(
                    child: Image.asset('assets/images/placeholder.png'),
                  ),
                errorWidget: (context, url, error) {
                  return errorWidget ??
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 50,
                      ),
                    );
                },
              )
            : isSvg ? (isNetwork
            ? SvgPicture.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: placeholder != null ? (_) => placeholder! : null,
        )
            : SvgPicture.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          colorMapper: const CustomColorMapper(
            targetColor: Color(0xFFFFB616),
            replacementColor: AppTheme.primaryColor,
          ),
          placeholderBuilder: placeholder != null ? (_) => placeholder! : null,
        ))
            : Image.asset(
                imagePath,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  return errorWidget ??
                      Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          TablerIcons.package,
                          color: Colors.grey,
                          size: 60,
                        ),
                      );
                },
              ),
      ),
    );
  }
}

class CustomColorMapper extends ColorMapper {
  final Color targetColor;
  final Color replacementColor;

  const CustomColorMapper({
    required this.targetColor,
    required this.replacementColor,
  });

  @override
  Color substitute(
      String? id,
      String elementName,
      String attributeName,
      Color color,
      ) {
    // If the SVG engine finds the old color, swap it with the new one
    if (color == targetColor) {
      return replacementColor;
    }
    // Otherwise, leave the original color alone
    return color;
  }
}*/
