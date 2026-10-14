import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/utils/widgets/animated_button.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../services/auth_guard.dart';
import '../../../utils/widgets/basket_button.dart';
import '../../wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import '../../wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_state.dart';
import '../bloc/product_detail_bloc/product_detail_bloc.dart';
import '../bloc/product_detail_bloc/product_detail_state.dart';

class AppBarWidget extends StatelessWidget {
  final bool showTitle;

  const AppBarWidget({
    super.key,
    required this.showTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          GoRouter.of(context).push(AppRoutes.search);
        },
        child: Container(
          height: 30.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            children: [
              Icon(
                TablerIcons.zoom,
                size: 20.sp,
                color:
                    Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.searchForProducts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: showTitle ? 1 : 0,
      shadowColor: Colors.grey.withValues(alpha: 0.3),
      actions: [
        const SizedBox(
          width: 10,
        ),
        BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is! ProductDetailLoaded) {
              return AnimatedButton(
                onTap: () {},
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Icon(AppHelpers.notWishListedIcon,
                        color: Theme.of(context).colorScheme.tertiary)),
              );
            }

            final product = state.productData[0];
            // Server truth from the product API — used until the bloc has its
            // own record of this product (after a toggle or a wishlist load).
            final bool isWishlisted = product.favorite.isNotEmpty;

            return BlocBuilder<UserWishlistBloc, UserWishlistState>(
              builder: (context, wishlistState) {
                final bloc = context.read<UserWishlistBloc>();
                final productId = product.id;
                final productVariantId = product.variants
                    .firstWhere((variant) => variant.isDefault)
                    .id;
                final storeId = product.variants
                    .firstWhere((variant) => variant.isDefault)
                    .storeId;

                final isWishListedFromBloc = bloc.isProductWishlisted(
                    productId, productVariantId, storeId);
                final hasBlocData =
                    bloc.hasProductData(productId, productVariantId, storeId);
                final finalIsWishListed =
                    hasBlocData ? isWishListedFromBloc : isWishlisted;

                return AnimatedButton(
                  onTap: () async {
                    if (Global.userData == null) {
                      await AuthGuard.ensureLoggedIn(context);
                      return;
                    }
                    bloc.add(ToggleFavorite(
                      productId: productId,
                      productVariantId: productVariantId,
                      storeId: storeId,
                      currentlyFavorited: finalIsWishListed,
                    ));
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        // 🎨 Fill
                        if (finalIsWishListed)
                          Icon(
                            AppHelpers.wishListedIcon,
                            color: AppTheme.primaryColor,
                          )
                        else
                          Icon(
                            AppHelpers.wishListedIcon,
                            color: Colors.white,
                          ),

                        Icon(
                          finalIsWishListed
                              ? AppHelpers.notWishListedIcon
                              : AppHelpers.notWishListedIcon,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(
          width: 10,
        ),
        const BasketButton(),
        const SizedBox(
          width: 15,
        ),
      ],
    );
  }
}
