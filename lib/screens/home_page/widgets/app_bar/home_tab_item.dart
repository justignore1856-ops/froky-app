import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/utils/widgets/cache_manager.dart';
import 'package:lottie/lottie.dart';

import '../../model/home_tab_model.dart';

class HomeAllTabStatic extends StatelessWidget {
  const HomeAllTabStatic({super.key});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 65,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 25,
            height: 35,
            child: Icon(HeroiconsOutline.squares2x2, size: 28),
          ),
          Text(
            AppLocalizations.of(context)!.all,
            textAlign: TextAlign.center,
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }
}

class HomeTabBarItem extends StatelessWidget {
  final TabController controller;
  final HomeTabItem item;
  final int index;
  final Color? activeColor;
  final Color? unselectedColor;

  const HomeTabBarItem({
    super.key,
    required this.controller,
    required this.item,
    required this.index,
    this.activeColor,
    this.unselectedColor,
  });

  Widget _buildSingleIcon(String url, bool isDefault) {
    if (url.isEmpty) {
      return isDefault
          ? const Icon(HeroiconsOutline.squares2x2, size: 26)
          : const Icon(Icons.category_outlined, size: 26);
    }
    final isLottie = url.toLowerCase().endsWith('.json') ||
        url.toLowerCase().contains('/lottie/');
    if (isLottie) {
      return Lottie.network(
        url,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        errorBuilder: (context, error, stackTrace) => isDefault
            ? const Icon(HeroiconsOutline.squares2x2, size: 26)
            : const Icon(Icons.category_outlined, size: 26),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: customCacheManager,
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: false,
      placeholder: (context, url) => const SizedBox.shrink(),
      errorWidget: (context, url, error) => isDefault
          ? const Icon(HeroiconsOutline.squares2x2, size: 26)
          : const Icon(Icons.category_outlined, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inactiveUrl = (item.appearance?.icon?.isNotEmpty ?? false)
        ? item.appearance!.icon!
        : (item.icon ?? '');
    final activeUrl = (item.appearance?.activeIcon?.isNotEmpty ?? false)
        ? item.appearance!.activeIcon!
        : ((item.activeIcon?.isNotEmpty ?? false)
            ? item.activeIcon!
            : inactiveUrl);
    final bool hasDistinctActiveIcon =
        activeUrl.isNotEmpty && activeUrl != inactiveUrl;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final bool isSelected = controller.index == index;
        final Color? effectiveColor = isSelected ? activeColor : unselectedColor;

        Widget iconWidget;
        if (hasDistinctActiveIcon) {
          iconWidget = Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: isSelected ? 0.0 : 1.0,
                child: _buildSingleIcon(inactiveUrl, item.isDefault),
              ),
              Opacity(
                opacity: isSelected ? 1.0 : 0.0,
                child: _buildSingleIcon(activeUrl, item.isDefault),
              ),
            ],
          );
        } else {
          iconWidget = _buildSingleIcon(inactiveUrl, item.isDefault);
        }

        final title = item.title.isNotEmpty
            ? item.title
            : (item.isDefault
                ? (AppLocalizations.of(context)?.all ?? 'All')
                : '');

        return Tab(
          height: 65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 25,
                height: 35,
                child: Center(child: iconWidget),
              ),
              SizedBox(
                height: 16,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: appFontSize(11),
                      height: 1.1,
                      letterSpacing: 0.02,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: effectiveColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

