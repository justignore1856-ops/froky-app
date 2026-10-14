import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_state.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import '../../config/global.dart';
import 'animated_button.dart';

class BasketButton extends StatelessWidget {
  final IconData? icon;
  final String? route;
  final VoidCallback? onTap;
  final Color? iconColor;

  const BasketButton({
    super.key,
    this.icon,
    this.route,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (prev, curr) {
        final prevCount = prev is CartLoaded ? prev.totalItems : 0;
        final currCount = curr is CartLoaded ? curr.totalItems : 0;
        return prevCount != currCount;
      },
      builder: (context, state) {
        final int count = state is CartLoaded ? state.totalItems : 0;
        final Widget iconWidget = Icon(
          icon ?? HugeIconsStroke.shoppingBasket01,
          color: iconColor,
        );
        final Widget child = count <= 0
            ? iconWidget
            : Badge(
                label: Text(count > 99 ? '99+' : '$count'),
                backgroundColor: isDarkMode(context)
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.tertiary,
                textColor: Colors.white,
                child: iconWidget,
              );
        return AnimatedButton(
          onTap: (){
            if (Global.userData != null) {
              GoRouter.of(context).push(AppRoutes.cart);
            } else {
              GoRouter.of(context).push(AppRoutes.login);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: child
          ),
        );
      },
    );
  }
}
