import 'package:flutter/material.dart';
import '../../../../config/helper.dart';
import '../../../../config/theme.dart';
import '../../../../utils/widgets/custom_image_container.dart';
import '../../model/home_tab_model.dart';
import '../home_helpers.dart';

class HomeFlexibleSpaceBackground extends StatelessWidget {
  final HomeTabItem? activeTab;
  final ScrollController scrollController;

  const HomeFlexibleSpaceBackground({
    super.key,
    required this.activeTab,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final appearance = activeTab?.appearance;

    final String bgImage = tablet
        ? (appearance?.tabletBackgroundImage?.isNotEmpty ?? false
            ? appearance!.tabletBackgroundImage!
            : (appearance?.backgroundImage ?? activeTab?.backgroundImage ?? ''))
        : (appearance?.mobileBackgroundImage?.isNotEmpty ?? false
            ? appearance!.mobileBackgroundImage!
            : (appearance?.backgroundImage ?? activeTab?.backgroundImage ?? ''));

    final String bgType = (appearance?.backgroundType.isNotEmpty ?? false)
        ? appearance!.backgroundType
        : (bgImage.isNotEmpty ? 'image' : 'gradient');

    if (bgType == 'none') {
      return Container(
        key: ValueKey('none_$bgImage'),
        width: double.infinity,
        height: double.infinity,
        color: isDarkMode(context)
            ? AppTheme.darkProductCardColor
            : Theme.of(context).scaffoldBackgroundColor,
      );
    }

    Widget buildGradient() {
      if (appearance?.gradientStart != null && appearance?.gradientEnd != null) {
        final Color? start = hexStringToColor(appearance!.gradientStart!);
        final Color? end = hexStringToColor(appearance.gradientEnd!);
        if (start != null && end != null) {
          return Container(
            decoration: BoxDecoration(
              gradient: parseGradient(
                start: start,
                end: end,
                angle: appearance.gradientAngle,
              ),
            ),
          );
        }
      }

      const Color primaryColor = AppTheme.primaryColor;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
      );
    }

    final Widget content = (bgType == 'image' && bgImage.isNotEmpty)
        ? Stack(
            fit: StackFit.expand,
            children: [
              buildGradient(),
              CustomImageContainer(
                imagePath: bgImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: const SizedBox.shrink(),
              ),
            ],
          )
        : buildGradient();

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final double offset =
            scrollController.hasClients ? scrollController.offset : 0.0;
        final double opacity = (1.0 - (offset / 60.0)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: SizedBox.expand(
          key: ValueKey(
            '$bgImage|$bgType|${appearance?.gradientStart}|${appearance?.gradientEnd}',
          ),
          child: content,
        ),
      ),
    );
  }
}
