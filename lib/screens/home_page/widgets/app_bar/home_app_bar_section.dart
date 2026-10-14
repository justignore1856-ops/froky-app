import 'package:flutter/material.dart';


class HomeAppBarSection extends StatelessWidget {
  final bool canUseTabController;
  final double appBarOpacity;
  final Color? textColor;
  final Widget title;
  final Widget flexibleSpaceBackground;
  final Widget searchField;
  final Widget? tabBar;
  final Widget? notificationsAction;
  final bool isDarkMode;
  final Color? darkBackgroundColor;

  const HomeAppBarSection({
    super.key,
    required this.canUseTabController,
    required this.appBarOpacity,
    required this.textColor,
    required this.title,
    required this.flexibleSpaceBackground,
    required this.searchField,
    required this.isDarkMode,
    this.darkBackgroundColor,
    this.tabBar,
    this.notificationsAction,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: canUseTabController ? 160.0 : 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: title,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? darkBackgroundColor : Colors.white,
        ),
        child: FlexibleSpaceBar(
          background: flexibleSpaceBackground,
        ),
      ),
      actions: [
        if (notificationsAction != null)
          Center(child: notificationsAction!)
        else
          const SizedBox(width: 48),
        const SizedBox(width: 10),
      ],
      bottom: canUseTabController
          ? PreferredSize(
              preferredSize: const Size.fromHeight(62),
              child: Column(
                children: [
                  searchField,
                  const SizedBox(height: 8),
                  tabBar ?? const SizedBox(height: 50),
                ],
              ),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: searchField,
              ),
            ),
    );
  }
}
