import 'dart:async';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/notification_service.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/deep_link.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_commerce/screens/notification_page/bloc/notification_bloc.dart';
import 'package:hyper_commerce/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_commerce/services/market/market_service.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/empty_states_page.dart';
import '../bloc/home_layout/home_layout_bloc.dart';
import '../bloc/home_layout/home_layout_event.dart';
import '../bloc/home_layout/home_layout_state.dart';
import '../bloc/home_tab/home_tab_bloc.dart';
import '../bloc/home_tab/home_tab_event.dart';
import '../bloc/home_tab/home_tab_state.dart';
import '../model/home_tab_model.dart';
import '../widgets/app_bar/animated_text_field.dart';
import '../widgets/app_bar/home_app_bar_section.dart';
import '../widgets/app_bar/home_flexible_space_background.dart';
import '../widgets/app_bar/home_notification_button.dart';
import '../widgets/app_bar/home_tab_bar_widget.dart';
import '../widgets/app_bar/home_top_address_section.dart';
import '../widgets/body/home_tab_content.dart';
import '../widgets/floating/back_to_top_button.dart';
import '../widgets/home_helpers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final AppLinksDeepLink _appLinksDeepLink = AppLinksDeepLink.instance;
  TabController? _tabController;
  late final ValueNotifier<TabController?> _tabControllerNotifier;
  final ScrollController nestedScrollController = ScrollController();

  final ValueNotifier<int> _activeTabIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _showScrollToTopNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isScrollingToTopNotifier =
      ValueNotifier<bool>(false);

  List<HomeTabItem> _homeTabs = [];
  bool _isTabControllerInitialized = false;
  final bool _isRecreatingTabController = false;
  String? _lastMarketCode;
  StreamSubscription<String?>? _marketSub;

  int? _lastFetchedTabIndex;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabControllerNotifier = ValueNotifier<TabController?>(null);
    _initAppServices();
    _initMarketListener();

    final homeTabState = context.read<HomeTabBloc>().state;
    if (homeTabState is HomeTabLoaded && homeTabState.homeTabs.isNotEmpty) {
      _applyLoadedTabs(homeTabState.homeTabs, isInitial: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onInitialPostFrame();
      }
    });
  }

  void _initAppServices() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        NotificationService.handleNotificationNavigation(message.data);
      }
    });
    _appLinksDeepLink.initDeepLinks(context);
  }

  void _applyLoadedTabs(List<HomeTabItem> tabs, {bool isInitial = false}) {
    if (tabs.isEmpty) return;

    final bool isFirstInit = _tabController == null;
    final int previousIndex = _tabController?.index ?? 0;
    final int targetIndex =
        (previousIndex < tabs.length) ? previousIndex : 0;

    if (isFirstInit || _tabController!.length != tabs.length) {
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();

      _tabController = TabController(
        length: tabs.length,
        initialIndex: targetIndex,
        vsync: this,
      );
      _tabController!.addListener(_onTabChanged);
      _isTabControllerInitialized = true;
    }

    _homeTabs = tabs;
    _activeTabIndexNotifier.value = targetIndex;
    _tabControllerNotifier.value = _tabController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheTabImages(tabs, context);
      }
    });

    if (isFirstInit || isInitial) {
      _lastFetchedTabIndex = targetIndex;
      apiCalls(tabs[targetIndex].layoutQuery);
    }
  }

  void _initMarketListener() {
    _lastMarketCode = MarketService.currentCode();
    _marketSub = MarketService.changes.listen((code) {
      if (!mounted || _lastMarketCode == code) return;
      _lastMarketCode = code;
      context.read<HomeTabBloc>().add(FetchHomeTabs(context: context));
      _refreshDataForCurrentTab();
    });
  }

  void _onInitialPostFrame() {
    if (AppLinksDeepLink.instance.hasPendingLink) {
      log('HomePage: Deep link pending, skipping initial API calls');
      return;
    }
    context.read<UserProfileBloc>().add(FetchUserProfile());
    final homeTabState = context.read<HomeTabBloc>().state;
    if (homeTabState is HomeTabLoaded && homeTabState.homeTabs.isNotEmpty) {
      if (_tabController == null || _homeTabs.isEmpty) {
        _applyLoadedTabs(homeTabState.homeTabs, isInitial: true);
      }
    } else {
      context.read<HomeTabBloc>().add(FetchHomeTabs(context: context));
    }
  }

  void _onTabChanged() {
    if (!_canUseTabController) return;
    final int index = _tabController!.index;
    if (_activeTabIndexNotifier.value != index) {
      _activeTabIndexNotifier.value = index;
    }
    if (_lastFetchedTabIndex == index) return;
    _lastFetchedTabIndex = index;

    if (index >= 0 && index < _homeTabs.length) {
      apiCalls(_homeTabs[index].layoutQuery);
    } else {
      apiCalls();
    }
    scrollToTop();
  }

  bool get _canUseTabController =>
      _tabController != null &&
      _isTabControllerInitialized &&
      !_isRecreatingTabController &&
      mounted;

  void apiCalls([Map<String, dynamic>? layoutQuery]) {
    if (!_canUseTabController) {
      return;
    }

    log('Layout Query $layoutQuery');
    final int index = _tabController!.index;

    final Map<String, dynamic>? updatedLayoutQuery =
        index != 0 ? layoutQuery : null;

    context.read<HomeLayoutBloc>().add(
          FetchHomeLayout(
            layoutQuery: updatedLayoutQuery,
          ),
        );

    if (Global.userData != null) {
      context.read<GetUserCartBloc>().add(
            FetchUserCart(),
          );

      context.read<NotificationBloc>().add(
            FetchNotifications(),
          );
    }
  }

  void _refreshDataForCurrentTab() {
    if (_tabController != null &&
        _tabController!.index >= 0 &&
        _tabController!.index < _homeTabs.length) {
      apiCalls(_homeTabs[_tabController!.index].layoutQuery);
    } else {
      apiCalls();
    }
  }

  void _loadMoreForCurrentTab() {
    final state = context.read<HomeLayoutBloc>().state;
    if (state is HomeLayoutLoaded &&
        !state.hasReachedMax &&
        !state.isLoadingMore) {
      context.read<HomeLayoutBloc>().add(const FetchMoreHomeLayout());
    }
  }

  void scrollToTop() {
    _showScrollToTopNotifier.value = false;
    _isScrollingToTopNotifier.value = true;

    if (nestedScrollController.hasClients) {
      nestedScrollController
          .animateTo(
            0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
        if (mounted) {
          _isScrollingToTopNotifier.value = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _showScrollToTopNotifier.dispose();
    _isScrollingToTopNotifier.dispose();
    _activeTabIndexNotifier.dispose();
    _tabControllerNotifier.dispose();
    nestedScrollController.dispose();
    if (_isTabControllerInitialized) {
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();
    }
    _marketSub?.cancel();
    super.dispose();
  }

  Widget _buildHomeTabContent(
      {int tabIndex = 0, Map<String, dynamic>? layoutQuery}) {
    final effectiveQuery = tabIndex == 0 ? null : layoutQuery;
    return HomeTabContent(
      tabIndex: tabIndex,
      layoutQuery: effectiveQuery,
      onRefresh: () async => apiCalls(effectiveQuery),
      onRetry: () => apiCalls(effectiveQuery),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<GetUserCartBloc, GetUserCartState>(
          listener: (context, state) {},
        ),
        BlocListener<HomeTabBloc, HomeTabState>(
          listener: (context, state) {
            if (state is HomeTabLoaded) {
              _applyLoadedTabs(state.homeTabs);
            }
          },
        ),
      ],
      child: BlocBuilder<HomeTabBloc, HomeTabState>(
        builder: (context, tabState) {
          if (_tabController == null || _homeTabs.isEmpty) {
            if (tabState is HomeTabFailed) {
              return CustomScaffold(
                showViewCart: false,
                body: NoProductPage(
                  onRetry: () {
                    context
                        .read<HomeTabBloc>()
                        .add(FetchHomeTabs(context: context));
                  },
                ),
              );
            }
            return const CustomScaffold(
              showViewCart: false,
              body: Center(
                child: CustomCircularProgressIndicator(),
              ),
            );
          }

          return CustomScaffold(
            showViewCart: true,
            onConnectivityRestored: (context) async {
              context.read<CartBloc>().add(SyncLocalCart(context: context));
              _refreshDataForCurrentTab();
            },
            body: Stack(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _isScrollingToTopNotifier,
                  builder: (context, isScrolling, child) {
                    return AbsorbPointer(
                      absorbing: isScrolling,
                      child: child!,
                    );
                  },
                  child: NestedScrollView(
                    controller: nestedScrollController,
                    physics: _canUseTabController
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return [
                        ValueListenableBuilder<TabController?>(
                          valueListenable: _tabControllerNotifier,
                          builder: (context, tabController, _) {
                            if (tabController == null) {
                              return const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              );
                            }
                            return ValueListenableBuilder<int>(
                              valueListenable: _activeTabIndexNotifier,
                              builder: (context, activeIndex, _) {
                                final HomeTabItem? activeTab =
                                    (activeIndex >= 0 &&
                                            activeIndex < _homeTabs.length)
                                        ? _homeTabs[activeIndex]
                                        : null;

                                final String? fontColorHex =
                                    activeTab?.appearance?.fontColor;
                                final Color? parsedFontColor =
                                    (fontColorHex?.isNotEmpty ?? false)
                                        ? hexStringToColor(fontColorHex!)
                                        : null;
                                final Color textColor = parsedFontColor ??
                                    (isDarkMode(context)
                                        ? AppTheme.darkFontColor
                                        : AppTheme.lightFontColor);

                                final String? activeFontColorHex =
                                    activeTab?.appearance?.activeFontColor;
                                final Color? activeFontColor =
                                    (activeFontColorHex?.isNotEmpty ?? false)
                                        ? hexStringToColor(activeFontColorHex!)
                                        : textColor;

                                final List<String> searchHints =
                                    removeUnderscoresFromStringList(
                                        activeTab?.searchLabels ?? []);

                                final List<HomeTabItem> visibleTabs = _homeTabs
                                    .take(tabController.length)
                                    .toList();

                                return HomeAppBarSection(
                                  canUseTabController: _canUseTabController,
                                  appBarOpacity: 1.0,
                                  textColor: textColor,
                                  title: HomeTopAddressSection(
                                      textColor: textColor),
                                  flexibleSpaceBackground:
                                      HomeFlexibleSpaceBackground(
                                    activeTab: activeTab,
                                    scrollController: nestedScrollController,
                                  ),
                                  searchField: CustomAnimatedTextField(
                                    key: ValueKey(searchHints.join('|')),
                                    searchHintTextList: searchHints,
                                  ),
                                  tabBar: HomeTabBarWidget(
                                    controller: tabController,
                                    tabs: visibleTabs,
                                    activeColor: activeFontColor,
                                    unselectedColor: textColor,
                                  ),
                                  notificationsAction: Global.userData != null
                                      ? HomeNotificationButton(
                                          iconColor: textColor)
                                      : null,
                                  isDarkMode: isDarkMode(context),
                                  darkBackgroundColor:
                                      AppTheme.darkProductCardColor,
                                );
                              },
                            );
                          },
                        ),
                      ];
                    },
                    body: _canUseTabController
                        ? NotificationListener<ScrollNotification>(
                            onNotification:
                                (ScrollNotification notification) {
                              if (notification
                                  is ScrollUpdateNotification) {
                                final metrics = notification.metrics;
                                if (metrics.axis == Axis.vertical) {
                                  final delta =
                                      notification.scrollDelta ?? 0.0;
                                  bool shouldShow =
                                      _showScrollToTopNotifier.value;

                                  if (metrics.pixels <= 300) {
                                    shouldShow = false;
                                  } else if (delta < 0) {
                                    shouldShow = true;
                                  } else if (delta > 0) {
                                    shouldShow = false;
                                  }

                                  if (_showScrollToTopNotifier.value !=
                                          shouldShow &&
                                      !_isScrollingToTopNotifier.value) {
                                    _showScrollToTopNotifier.value =
                                        shouldShow;
                                  }

                                  if (metrics.pixels >=
                                      metrics.maxScrollExtent * 0.85) {
                                    _loadMoreForCurrentTab();
                                  }
                                }
                              }
                              return false;
                            },
                            child: ValueListenableBuilder<TabController?>(
                              valueListenable: _tabControllerNotifier,
                              builder: (context, tabController, _) {
                                if (tabController == null) {
                                  return const SizedBox.shrink();
                                }
                                final int count = tabController.length;
                                final List<Widget> children =
                                    (_homeTabs.length >= count && count > 1)
                                        ? _homeTabs
                                            .take(count)
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map((entry) =>
                                                _buildHomeTabContent(
                                                  tabIndex: entry.key,
                                                  layoutQuery: entry
                                                      .value.layoutQuery,
                                                ))
                                            .toList()
                                        : [
                                            _buildHomeTabContent(
                                                tabIndex: 0)
                                          ];

                                return TabBarView(
                                  key: ValueKey(
                                      'tab_view_${tabController.length}'),
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  controller: tabController,
                                  children: children,
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                BackToTopButton(
                  isVisibleListenable: _showScrollToTopNotifier,
                  onTap: scrollToTop,
                  topOffset: 130.h,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}