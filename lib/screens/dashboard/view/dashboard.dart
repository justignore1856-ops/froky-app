import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_commerce/config/global_keys.dart';
import 'package:hyper_commerce/config/notification_service.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/auth/bloc/apply_referral/apply_referral_bloc.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import '../../../config/helper.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../config/global.dart';
import '../../../config/settings_data_instance.dart';
import '../../../bloc/settings_bloc/settings_bloc.dart';
import '../../../services/location/location_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/cart_service.dart';
import '../../../services/referral_prompt_coordinator.dart';
import '../../../utils/widgets/custom_toast.dart';

class Dashboard extends StatefulWidget {
  final int index;
  final StatefulNavigationShell navigationShell;
  const Dashboard(
      {super.key, required this.index, required this.navigationShell});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late int _currentIndex;
  DateTime? _lastBackPressed;

  /// Drives the hide-on-scroll animation for the bottom nav.
  late final AnimationController _bottomNavController;

  @override
  void initState() {
    super.initState();
    _currentIndex = _calculateCurrentIndex();
    _bottomNavController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // start visible
    );
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');
    DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification response received: ${response.payload}');
        if (response.payload != null) {
          try {
            log('User navigating from foreground notification tap');
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            NotificationService.handleNotificationNavigation(data);
          } catch (e) {
            log('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Prime the cart badge with whatever is currently in local storage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartBloc>().add(LoadCart());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _maybeShowReferralPrompt();
      });
    });

    // Debug: Print stored location
    final storedLocation = LocationService.getStoredLocation();
    if (storedLocation != null) {
      log('Stored Location: ${storedLocation.fullAddress}');
      log('Area: ${storedLocation.area}');
      log('City: ${storedLocation.city}');
      log('State: ${storedLocation.state}');
    } else {
      log('No location stored in Hive');
    }
  }

  int _calculateCurrentIndex() {
    final bool isWatchEnabled =
        SettingsData.instance.watchAndBuy?.enabled == true;
    final int shellIndex = widget.navigationShell.currentIndex;

    if (isWatchEnabled) {
      if (shellIndex == 3) return 4;
      return shellIndex;
    } else {
      if (shellIndex == 3) return 3;
      if (shellIndex == 2) return 0;
      return shellIndex;
    }
  }


  void _goBranch(int index) {
    _bottomNavController.forward();

    final bool isWatchEnabled =
        SettingsData.instance.watchAndBuy?.enabled == true;

    if (isWatchEnabled) {
      // CART CLICK (Index 3) — push as a top-level route, not as a shell branch.
      if (index == 3) {
        if (Global.userData != null) {
          GoRouter.of(context).push(AppRoutes.cart);
        } else {
          GoRouter.of(context).push(AppRoutes.login);
        }
        return;
      }

      // Bottom-nav index -> shell branch index.
      // 0 (Home) -> 0, 1 (Categories) -> 1, 2 (Watch) -> 2, 4 (Account) -> 3.
      final int branchIndex = index == 4 ? 3 : index;
      widget.navigationShell.goBranch(branchIndex);

      setState(() {
        _currentIndex = index;
      });
    } else {
      // CART CLICK (Index 2) — push as a top-level route, not as a shell branch.
      if (index == 2) {
        if (Global.userData != null) {
          GoRouter.of(context).push(AppRoutes.cart);
        } else {
          GoRouter.of(context).push(AppRoutes.login);
        }
        return;
      }

      // Bottom-nav index -> shell branch index.
      // 0 (Home) -> 0, 1 (Categories) -> 1, 3 (Account) -> 3.
      final int branchIndex = index == 3 ? 3 : index;
      widget.navigationShell.goBranch(branchIndex);

      setState(() {
        _currentIndex = index;
      });
    }

    context.read<CartBloc>().add(LoadCart());
  }

  /// Reacts to any vertical scroll anywhere inside the shell body.
  bool _handleScrollNotification(UserScrollNotification notification) {
    final bool isWatchEnabled =
        SettingsData.instance.watchAndBuy?.enabled == true;
    final bool isWatchTab = isWatchEnabled && _currentIndex == 2;
    final bool isAccountTab =
        isWatchEnabled ? _currentIndex == 4 : _currentIndex == 3;

    // Ignore horizontal scrolls (carousels, TabBarViews, etc) and Watch & Buy / Account tabs.
    if (notification.metrics.axis != Axis.vertical ||
        isAccountTab ||
        isWatchTab) {
      return false;
    }

    switch (notification.direction) {
      case ScrollDirection.reverse:
        // User is scrolling DOWN → hide.
        if (_bottomNavController.status != AnimationStatus.dismissed &&
            _bottomNavController.status != AnimationStatus.reverse) {
          _bottomNavController.reverse();
        }
        break;
      case ScrollDirection.forward:
        // User is scrolling UP → show.
        if (_bottomNavController.status != AnimationStatus.completed &&
            _bottomNavController.status != AnimationStatus.forward) {
          _bottomNavController.forward();
        }
        break;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  Future<void> _handleBack(BuildContext context) async {
    if (widget.index != 0) {
      _goBranch(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)?.pressAgainToExitTheApp ??
            'Press again to exit the app',
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    _currentIndex = _calculateCurrentIndex();
    final l10n = AppLocalizations.of(context);
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartLoaded) {
          if (state.errorMessage != null) {
            ToastManager.show(
              context: context,
              message: state.errorMessage ?? 'Failed to add item to cart',
              type: ToastType.error,
            );
          }
        }
        CartService.triggerCartAnimationOnFirstAdd(context, state);
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          await _handleBack(context);
        },
        child: Scaffold(
          // Listen to scroll notifications from any descendant page and
          body: NotificationListener<UserScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.navigationShell,
          ),
          // SizeTransition both slides the nav down and shrinks its
          bottomNavigationBar: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              final bool isWatchEnabled =
                  SettingsData.instance.watchAndBuy?.enabled == true;
              final String watchTitle =
                  (SettingsData.instance.watchAndBuy?.title?.isNotEmpty == true)
                      ? SettingsData.instance.watchAndBuy!.title!
                      : 'Watch';

              final cartBadgeItem = BottomNavigationBarItem(
                icon: BlocBuilder<CartBloc, CartState>(
                  buildWhen: (prev, curr) {
                    final prevCount =
                        prev is CartLoaded ? prev.totalItems : 0;
                    final currCount =
                        curr is CartLoaded ? curr.totalItems : 0;
                    return prevCount != currCount;
                  },
                  builder: (context, state) {
                    final int count =
                        state is CartLoaded ? state.totalItems : 0;
                    const Widget bagIcon =
                        Icon(HugeIconsStroke.shoppingBasket01);
                    if (count <= 0) return bagIcon;
                    return Badge(
                      label: Text(count > 99 ? '99+' : '$count'),
                      backgroundColor: isDarkMode(context)
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.tertiary,
                      textColor: Colors.white,
                      child: bagIcon,
                    );
                  },
                ),
                label: l10n?.bag ?? 'Bag',
              );

              final accountItem = BottomNavigationBarItem(
                icon: Icon((isWatchEnabled
                        ? _currentIndex == 4
                        : _currentIndex == 3)
                    ? HugeIconsSolid.user
                    : HugeIconsStroke.user),
                label: l10n?.account ?? 'Account',
              );

              return SizeTransition(
                sizeFactor: _bottomNavController,
                // alignment: Alignment.topCenter,
                axisAlignment: -1,
                child: Container(
                  height: AppHelpers.bottomNavBarHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                  ),
                  // Stack the moving indicator on top of the BottomNavigationBar
                  child: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: _currentIndex,
                    selectedItemColor: isDarkMode(context)
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.tertiary,
                    unselectedItemColor: isDarkMode(context)
                        ? const Color(0xFF6B6B6B)
                        : Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.6),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    onTap: _goBranch,
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(
                          _currentIndex == 0
                              ? HugeIconsSolid.home03
                              : HugeIconsStroke.home03,
                        ),
                        label: l10n?.home ?? 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(_currentIndex == 1
                            ? HugeIconsSolid.deliveryBox01
                            : HugeIconsStroke.deliveryBox01),
                        label: l10n?.categories ?? 'Categories',
                      ),
                      if (isWatchEnabled)
                        BottomNavigationBarItem(
                          icon: Icon(_currentIndex == 2
                              ? HugeIconsSolid.playSquare
                              : HugeIconsStroke.playSquare),
                          label: watchTitle,
                        ),
                      cartBadgeItem,
                      accountItem,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  void _maybeShowReferralPrompt({int retriesLeft = 6}) {
    if (!ReferralPromptCoordinator.pending) return;

    final messenger = GlobalKeys.scaffoldMessengerKey.currentState;
    if (messenger == null) {
      if (retriesLeft <= 0) return;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _maybeShowReferralPrompt(retriesLeft: retriesLeft - 1);
        }
      });
      return;
    }

    if (!ReferralPromptCoordinator.consume()) return;

    final theme = Theme.of(context);
    const Duration promptDuration = Duration(seconds: 5);

    bool userResolved = false;

    // Hide any in-flight SnackBar first so ours isn't queued behind it.
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: promptDuration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.surface,
        elevation: 3,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        content: _ReferralPromptContent(
          duration: promptDuration,
          onYes: () {
            userResolved = true;
            messenger.hideCurrentSnackBar();
            _openReferralCodeSheet();
          },
          onNo: () {
            userResolved = true;
            messenger.hideCurrentSnackBar();
            _dispatchSkipReferral();
          },
        ),
      ),
    );

    controller.closed.then((reason) {
      if (!mounted) return;
      if (userResolved) return;
      if (reason == SnackBarClosedReason.timeout) {
        _dispatchSkipReferral();
      }
    });
  }

  void _dispatchSkipReferral() {
    final bloc = ApplyReferralBloc();
    late final StreamSubscription<ApplyReferralState> sub;
    sub = bloc.stream.listen((state) {
      if (state is ApplyReferralSuccess || state is ApplyReferralFailed) {
        sub.cancel();
        bloc.close();
      }
    });
    bloc.add(const ApplyReferralRequest(code: null));
  }

  void _openReferralCodeSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider<ApplyReferralBloc>(
          create: (_) => ApplyReferralBloc(),
          child: const _ReferralCodeBottomSheet(),
        );
      },
    );
  }

  @override
  void dispose() {
    _bottomNavController.dispose();
    super.dispose();
  }
}

class _ReferralPromptContent extends StatefulWidget {
  final Duration duration;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _ReferralPromptContent({
    required this.duration,
    required this.onYes,
    required this.onNo,
  });

  @override
  State<_ReferralPromptContent> createState() => _ReferralPromptContentState();
}

class _ReferralPromptContentState extends State<_ReferralPromptContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
      upperBound: 1.0,
    )..reverse();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have a referral code?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Apply it to earn rewards on your first order.',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onNo,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'No',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onYes,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Yes',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Countdown bar — drains from full to empty over `duration`.
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: AnimatedBuilder(
            animation: _countdown,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: _countdown.value,
                minHeight: 3,
                backgroundColor:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReferralCodeBottomSheet extends StatefulWidget {
  const _ReferralCodeBottomSheet();

  @override
  State<_ReferralCodeBottomSheet> createState() =>
      _ReferralCodeBottomSheetState();
}

class _ReferralCodeBottomSheetState extends State<_ReferralCodeBottomSheet> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onApply() {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _onSkip();
      return;
    }
    context
        .read<ApplyReferralBloc>()
        .add(ApplyReferralRequest(code: code));
  }

  void _onSkip() {
    FocusManager.instance.primaryFocus?.unfocus();
    context
        .read<ApplyReferralBloc>()
        .add(const ApplyReferralRequest(code: null));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<ApplyReferralBloc, ApplyReferralState>(
      listener: (context, state) {
        if (state is ApplyReferralSuccess) {
          Navigator.of(context).pop();
          final msg = state.message.isNotEmpty
              ? state.message
              : (l10n?.referralAppliedSuccess ?? 'Referral applied');
          ToastManager.show(
            context: context,
            message: msg,
            type: ToastType.success,
          );
        } else if (state is ApplyReferralFailed) {
          ToastManager.show(
            context: context,
            message: state.message.isNotEmpty
                ? state.message
                : (l10n?.referralFailedRetry ?? 'Could not apply. Try again.'),
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ApplyReferralLoading;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: AbsorbPointer(
                  absorbing: isLoading,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.referralCodeTitle ?? 'Got a referral code?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            l10n?.referralCodeSubtitle ??
                                'Apply a referral code to earn rewards on your first order.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.4,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _codeController,
                          hintText: l10n?.referralCodeHint ??
                              'Enter referral code',
                          prefixIcon: Icons.card_giftcard_outlined,
                          enabled: !isLoading,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onApply(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : _onSkip,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  side: BorderSide(
                                      color: theme.colorScheme.outline),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  l10n?.skipReferral ?? 'Skip',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: isLoading
                                  ? Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CustomCircularProgressIndicator(),
                                      ),
                                    )
                                  : CustomButton(
                                      onPressed: _onApply,
                                      child: Text(
                                        l10n?.applyReferralCode ??
                                            'Apply Referral Code',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
        },
      );
  }
}
