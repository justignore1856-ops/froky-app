import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/get_my_order/get_my_order_event.dart';
import '../../../router/app_routes.dart';
import '../../cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/get_my_order/get_my_order_bloc.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class OrderSuccessPage extends StatefulWidget {
  final String address;
  final String addressType;
  final String orderSlug;
  final int orderItemId;

  const OrderSuccessPage({
    super.key,
    required this.address,
    required this.addressType,
    required this.orderSlug,
    required this.orderItemId,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  static const int _countdownFrom = 4;
  Timer? _timer;
  int _secondsLeft = _countdownFrom;

  @override
  void initState() {
    super.initState();
    context.read<GetMyOrderBloc>().add(FetchMyOrder());
    context.read<CartBloc>().add(ClearCart(context: context));
    context.read<GetUserCartBloc>().add(RefreshUserCart());
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        _openOrderDetail();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }


  void _openOrderDetail() {
    _timer?.cancel();
    if (!mounted) return;
    GoRouter.of(context).pushReplacement(
      AppRoutes.orderItemDetail,
      extra: {'order-slug': widget.orderSlug,  'order-item-id': widget.orderItemId},
    );
  }

  void _continueShopping() {
    _timer?.cancel();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _continueShopping();
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: TabletConstrainedBody(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1.0),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.elasticOut,
                        builder: (_, s, child) =>
                            Transform.scale(scale: s, child: child),
                        child: Icon(
                          TablerIcons.circle_check_filled,
                          color: AppTheme.primaryColor,
                          size: 104.r,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        l10n?.orderPlacedTitle ?? 'Order placed!',
                        style: AppTextStyles.headline.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n?.orderPlacedThanks ??
                            'Thank you — your order is confirmed.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _addressCard(scheme, l10n),

                    ],
                  ),
                ),
              ),
        ),
      ),
      ),
    );
  }

  Widget _addressCard(ColorScheme scheme, AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16.sp, color: scheme.primary),
              SizedBox(width: 6.w),
              Text(
                '${l10n?.deliveringTo ?? 'Delivering to'} ${widget.addressType.toUpperCase()}',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            widget.address,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
