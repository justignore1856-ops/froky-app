import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../config/theme.dart';
import '../../model/home_tab_model.dart';
import 'home_tab_item.dart';

class HomeTabBarWidget extends StatelessWidget {
  final TabController controller;
  final List<HomeTabItem> tabs;
  final Color? activeColor;
  final Color? unselectedColor;

  const HomeTabBarWidget({
    super.key,
    required this.controller,
    required this.tabs,
    this.activeColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveActiveColor =
        activeColor ?? Theme.of(context).primaryColor;
    final Color effectiveUnselectedColor =
        unselectedColor ?? AppTheme.lightFontColor;

    final List<Widget> tabWidgets = tabs.isNotEmpty
        ? tabs.asMap().entries.map((entry) {
            return HomeTabBarItem(
              controller: controller,
              item: entry.value,
              index: entry.key,
              activeColor: effectiveActiveColor,
              unselectedColor: effectiveUnselectedColor,
            );
          }).toList()
        : const [HomeAllTabStatic()];

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      enableFeedback: true,
      labelColor: effectiveActiveColor,
      automaticIndicatorColorAdjustment: true,
      unselectedLabelColor: effectiveUnselectedColor,
      labelStyle: TextStyle(
        fontSize: appFontSize(11),
        height: 1.1,
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: appFontSize(11),
        height: 1.1,
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w500,
      ),
      dividerColor: Colors.transparent,
      dividerHeight: 0.0,
      indicatorColor: effectiveActiveColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: effectiveActiveColor,
          width: 3,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        insets: EdgeInsets.zero,
      ),
      padding: EdgeInsets.zero,
      tabs: tabWidgets,
    );
  }
}
