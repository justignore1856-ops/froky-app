import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/helper.dart';
import '../../../model/settings_model/settings_model.dart';
import '../../../utils/widgets/cache_manager.dart';
import '../model/home_tab_model.dart';

EdgeInsets getPadding(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final horizontalPadding = screenWidth * 0.04;
  return EdgeInsets.symmetric(horizontal: horizontalPadding);
}

int getCrossAxisCount(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth >= 1200) return 6;
  if (screenWidth >= 800) return 5;
  if (screenWidth >= 600) return 4;
  if (screenWidth >= 400) return 4;
  return 3;
}

double getSpacing(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return screenWidth * 0.04;
}

bool isValidHomeGeneralSettings(HomeGeneralSettings settings) {
  return settings.title.trim().isNotEmpty ||
      settings.icon.trim().isNotEmpty ||
      settings.activeIcon.trim().isNotEmpty;
}

LinearGradient parseGradient({
  required Color start,
  required Color end,
  String? angle,
}) {
  if (angle == null || angle.isEmpty) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [start, end],
    );
  }
  double angleDeg = double.tryParse(angle.replaceAll('deg', '').trim()) ?? 90;
  if ((angleDeg - 90).abs() < 1) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [start, end],
    );
  } else if ((angleDeg - 180).abs() < 1) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [start, end],
    );
  } else if ((angleDeg - 270).abs() < 1) {
    return LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [start, end],
    );
  } else if ((angleDeg - 0).abs() < 1 || (angleDeg - 360).abs() < 1) {
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [start, end],
    );
  }
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [start, end],
  );
}

void precacheTabImages(List<HomeTabItem> tabs, BuildContext ctx) {
  if (!ctx.mounted || tabs.isEmpty) return;
  final tablet = isTablet(ctx);
  for (final tab in tabs) {
    final appearance = tab.appearance;
    final String bgUrl = tablet
        ? (appearance?.tabletBackgroundImage?.isNotEmpty ?? false
        ? appearance!.tabletBackgroundImage!
        : (appearance?.backgroundImage ?? tab.backgroundImage ?? ''))
        : (appearance?.mobileBackgroundImage?.isNotEmpty ?? false
        ? appearance!.mobileBackgroundImage!
        : (appearance?.backgroundImage ?? tab.backgroundImage ?? ''));

    if (bgUrl.isNotEmpty &&
        (bgUrl.startsWith('http://') || bgUrl.startsWith('https://'))) {
      precacheImage(
        CachedNetworkImageProvider(bgUrl, cacheManager: customCacheManager),
        ctx,
      );
    }

    final iconUrl = appearance?.icon ?? tab.icon ?? '';
    if (iconUrl.isNotEmpty &&
        (iconUrl.startsWith('http://') || iconUrl.startsWith('https://'))) {
      precacheImage(
        CachedNetworkImageProvider(iconUrl, cacheManager: customCacheManager),
        ctx,
      );
    }

    final activeIconUrl = appearance?.activeIcon ?? tab.activeIcon ?? '';
    if (activeIconUrl.isNotEmpty &&
        (activeIconUrl.startsWith('http://') ||
            activeIconUrl.startsWith('https://'))) {
      precacheImage(
        CachedNetworkImageProvider(activeIconUrl,
            cacheManager: customCacheManager),
        ctx,
      );
    }
  }
}

double? parseAspectRatio(String? ratioStr) {
  if (ratioStr == null) return null;
  final clean = ratioStr.trim().toLowerCase();
  if (clean.isEmpty || clean == 'original' || clean == 'auto') {
    return null;
  }
  // Handles '3:2', '4:3', '16:9', '1:1', '3/2', '3x2'
  final delimiter = clean.contains(':')
      ? ':'
      : clean.contains('/')
      ? '/'
      : clean.contains('x')
      ? 'x'
      : null;

  if (delimiter != null) {
    final parts = clean.split(delimiter);
    if (parts.length == 2) {
      final width = double.tryParse(parts[0].trim());
      final height = double.tryParse(parts[1].trim());
      if (width != null && height != null && height > 0) {
        return width / height;
      }
    }
  }
  final directVal = double.tryParse(clean);
  if (directVal != null && directVal > 0) {
    return directVal;
  }
  return null;
}