import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../connectivity_wrapper.dart';
import 'custom_scaffold_default_app_bar.dart';

class CustomScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? showAppBar;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final PreferredSizeWidget? appBar;
  final int itemCount;
  final String? itemText;
  final bool showViewCart;
  final FutureOr<void> Function(BuildContext context)? onConnectivityRestored;
  final FutureOr<void> Function(BuildContext context)? onConnectivityLost;
  final FutureOr<void> Function(bool isConnected, BuildContext context)?
      onConnectivityChanged;
  final bool notifyConnectivityStatusOnInit;

  const CustomScaffold({
    super.key,
    required this.body,
    this.title,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.showAppBar,
    this.appBarActions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBar,
    this.itemCount = 3,
    this.itemText,
    this.showViewCart = true,
    this.onConnectivityRestored,
    this.onConnectivityLost,
    this.onConnectivityChanged,
    this.notifyConnectivityStatusOnInit = false,
  });

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _expandController;

  bool _isCartVisible = false;
  bool _isCurrentlyConnected = true;
  static bool _hasAnimatedGlobally = false;
  static bool _hasShownFullCartAnimation = false;
  int _previousItemCount = 0;
  bool _hasInitializedCart = false;

  @override
  void initState() {
    super.initState();

    // Controller for slide up/down animation - made faster
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Controller for expand/collapse animation - made faster
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

  }

  @override
  void didUpdateWidget(CustomScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget update logic removed - handled in build method
  }

  Future<void> _animateIn() async {
    if (_slideController.isAnimating || _expandController.isAnimating) {
      return;
    }

    await _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _expandController.forward();
    _hasShownFullCartAnimation = true;
  }

  Future<void> _animateOut() async {
    if (_slideController.isAnimating || _expandController.isAnimating) {
      return;
    }

    await _expandController.reverse();
    await Future.delayed(const Duration(milliseconds: 80));
    await _slideController.reverse();
    setState(() {
      _isCartVisible = false;
    });
    _hasShownFullCartAnimation = false;
  }

  void _showCartWithoutAnimation() {
    _slideController.value = 1.0;
    _expandController.value = 1.0;
    setState(() {
      _isCartVisible = true;
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      onStatusChange: _handleConnectivityStatus,
      notifyStatusChangeOnInit: widget.notifyConnectivityStatusOnInit,
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartBlocState) {
          final hasCartItems =
              cartBlocState is CartLoaded && cartBlocState.items.isNotEmpty;

          int currentItemCount = 0;


          // Only process animation logic when cart data is actually loaded
          final isCartDataLoaded = cartBlocState is CartLoaded;

          // Animation logic
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Skip processing if cart data hasn't loaded yet
            if (!isCartDataLoaded) {
              log('Cart data not loaded yet, skipping animation logic');
              return;
            }

            // Initialize cart state on first load
            if (!_hasInitializedCart) {
              _hasInitializedCart = true;
              _previousItemCount = currentItemCount;

              if (hasCartItems) {
                setState(() {
                  _isCartVisible = true;
                });

                // Show animation only on app startup with existing items
                if (!_hasAnimatedGlobally &&
                    !_hasShownFullCartAnimation &&
                    currentItemCount > 0) {
                  log('Initial load: Animating app startup with existing cart');
                  _hasAnimatedGlobally = true;
                  _animateIn();
                } else {
                  log('Initial load: Showing cart without animation');
                  _showCartWithoutAnimation();
                }
              }
              return;
            }
            if (hasCartItems && !_isCartVisible) {
              // Cart has items and is not visible
              setState(() {
                _isCartVisible = true;
              });

              // Check if we should show full cart animation
              bool shouldShowFullAnimation = false;

              // Condition 1: First product added (cart was empty, now has 1 item)
              if (_previousItemCount == 0 && currentItemCount == 1) {
                log('Animating: First product added to cart (full animation)');
                shouldShowFullAnimation = true;
              }

              // Show full animation or just display cart
              if (shouldShowFullAnimation) {
                _animateIn();
              } else if ((_slideController.value != 1.0 ||
                      _expandController.value != 1.0) &&
                  !_slideController.isAnimating &&
                  !_expandController.isAnimating) {
                log('Showing cart without full animation (page navigation or additional product)');
                _showCartWithoutAnimation();
              }
            } else if (!hasCartItems && _isCartVisible && _hasInitializedCart) {
              log('Animating out: Cart is now empty');
              _animateOut();
              _hasInitializedCart = false;
            }

            // Update previous count
            _previousItemCount = currentItemCount;
          });

          return Scaffold(
            backgroundColor:
                widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
            appBar: widget.appBar ??
                (widget.showAppBar == true
                    ? CustomScaffoldDefaultAppBar(
                        title: widget.title,
                        actions: widget.appBarActions,
                      )
                    : null),
            body: Stack(
              children: [
                widget.body,

              ],
            ),
            bottomNavigationBar: widget.bottomNavigationBar,
            floatingActionButton: widget.floatingActionButton,
            floatingActionButtonLocation: widget.floatingActionButtonLocation,
          );
        },
      ),
    );
  }

  void _handleConnectivityStatus(bool isConnected) {
    log('Handle Connectivity Status $isConnected');
    if (_isCurrentlyConnected == isConnected) {
      _invokeConnectivityChangedCallback(isConnected);
      return;
    }

    _isCurrentlyConnected = isConnected;
    _invokeConnectivityChangedCallback(isConnected);

    if (isConnected) {
      _invokeFutureOr(widget.onConnectivityRestored);
    } else {
      _invokeFutureOr(widget.onConnectivityLost);
    }
  }

  void _invokeConnectivityChangedCallback(bool isConnected) {
    final callback = widget.onConnectivityChanged;
    if (callback == null) return;

    final result = callback(isConnected, context);
    if (result is Future<void>) {
      unawaited(result);
    }
  }

  void _invokeFutureOr(
      FutureOr<void> Function(BuildContext context)? callback) {
    if (callback == null) return;

    final result = callback(context);
    if (result is Future<void>) {
      unawaited(result);
    }
  }
}
