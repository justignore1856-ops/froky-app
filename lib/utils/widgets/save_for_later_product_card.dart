import 'package:animations/animations.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_event.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart' show Badge;
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/product_detail_page/view/product_detail_page.dart';
import 'package:hyper_commerce/services/auth_guard.dart';
import 'package:hyper_commerce/utils/widgets/animated_button.dart';
import 'package:hyper_commerce/utils/money_format.dart';
import 'package:hyper_commerce/utils/widgets/price_utils.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/product_indicator.dart';
import 'package:hyper_commerce/utils/widgets/hero_tags.dart';
import 'package:hyper_commerce/utils/widgets/sponsored_badge.dart';
import '../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../config/global.dart';
import '../../config/helper.dart';
import '../../l10n/app_localizations.dart';
import '../../model/user_cart_model/user_cart.dart';
import '../../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import '../../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_state.dart';
import 'package:flutter/services.dart';
import '../../services/user_cart/cart_validation.dart';
import 'custom_toast.dart';

class SaveForLaterProductCard extends StatelessWidget {
  final int productId;
  final String productImage;
  final String productName;
  final String productSlug;
  final String productPrice;
  final List<String> productTags;
  final String specialPrice;
  final String currencySymbol;
  final MoneyFormat? format;
  final String estimatedDeliveryTime;
  final String? assetImage;
  final double ratings;
  final int ratingCount;
  final VoidCallback onMoveToCart;
  final bool isStoreOpen;
  final bool isWishListed;
  final int productVariantId;
  final int storeId;
  final int wishlistItemId;
  final int? totalStocks;
  final String imageFit;
  final bool showWishlist;
  final int? variantCount;
  final VoidCallback? onVariantSelectorRequested;
  final int quantityStepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final String? indicator;
  final bool isRecommended;
  final bool isSponsored;
  final VoidCallback? onCardTap;
  final Badge? badge;
  final bool isInStock;
  final int cartItemId;

  const SaveForLaterProductCard({
    super.key,
    required this.productId,
    required this.productImage,
    required this.productName,
    required this.productSlug,
    required this.productPrice,
    required this.productTags,
    this.assetImage,
    required this.specialPrice,
    this.currencySymbol = '',
    this.format,
    required this.estimatedDeliveryTime,
    required this.ratings,
    required this.ratingCount,
    required this.onMoveToCart,
    required this.isStoreOpen,
    required this.isWishListed,
    required this.productVariantId,
    required this.storeId,
    required this.wishlistItemId,
    required this.totalStocks,
    required this.imageFit,
    this.showWishlist = true,
    this.variantCount,
    this.onVariantSelectorRequested,
    required this.quantityStepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    this.indicator,
    this.isRecommended = false,
    this.isSponsored = false,
    this.onCardTap,
    this.badge,
    required this.isInStock,
    required this.cartItemId
  });

  BoxFit get _boxFit {
    switch (imageFit.toLowerCase()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stocks = totalStocks;
    late final bool isDim;
    if(isInStock == false && stocks! <= 0) {
      isDim = true;
    } else {
      isDim = false;
    }
    final discountPct = PriceUtils.calculateDiscountPercentage(
      double.tryParse(productPrice) ?? 0,
      double.tryParse(specialPrice) ?? 0,
    );
    final hasDiscount = discountPct > 0;

    return OpenContainer(
      clipBehavior: Clip.antiAlias,
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fade,
      closedElevation: 0,
      openElevation: 0,
      closedShape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      openShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      tappable: false,
      useRootNavigator: true,
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: () {
            onCardTap?.call();
            openContainer();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ColorFiltered(
              colorFilter: isDim
                  ? ColorFilter.mode(
                Colors.black.withValues(alpha: 0.1),
                BlendMode.srcATop,
              )
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imageSection(
                    context: context,
                    isDim: isDim,
                    discountPct: discountPct,
                    hasDiscount: hasDiscount,
                  ),
                  _infoSection(
                    context: context,
                    isDim: isDim,
                    discountPct: discountPct,
                    hasDiscount: hasDiscount,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        return ProductDetailPage(
          productSlug: productSlug,
          initialData: ProductInitialData(
            title: productName,
            mainImage: productImage,
          ),
          closeContainer: closeContainer,
        );
      },
    );
  }

  // ── Image section ──────────────────────────────────────────────────────────
  Widget _imageSection({
    required BuildContext context,
    required bool isDim,
    required double discountPct,
    required bool hasDiscount,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Base image container
          Container(
            margin: EdgeInsetsDirectional.only(end: 0.w, bottom: 4.h),
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: _boxFit == BoxFit.contain
                ? const EdgeInsets.all(8.0)
                : EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: productImage.isNotEmpty
                  ? Hero(
                tag: productHeroTag(productSlug),
                child: ColorFiltered(
                  colorFilter: isDim
                      ? const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ])
                      : const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply),
                  child: CustomImageContainer(
                      imagePath: productImage, fit: _boxFit),
                ),
              )
                  : _buildAssetImageOrPlaceholder(),
            ),
          ),

          // ── top-left: status › API badge › discount badge ──
          if (isDim)
            PositionedDirectional(
              top: 0,
              start: 0,
              child: _statusBadge(context),
            )
          else if (badge?.label?.isNotEmpty == true)
            PositionedDirectional(
              top: 0,
              start: 0,
              child: _apiBadgeWidget(context),
            ),

          // ── top-right: wishlist ──
          if (!isDim && showWishlist)
            PositionedDirectional(
              top: -2.h,
              end: 0.w,
              child: _wishlistButton(context),
            ),

          // ── bottom-left: Ad / Sponsored chip ──
          if (!isDim && isSponsored)
            PositionedDirectional(
              bottom: 6.h,
              start: 6.w,
              child: const SponsoredBadge(style: SponsoredBadgeStyle.chip),
            ),

          // ── bottom-right (upper): veg / non-veg indicator ──
          if (!isDim &&
              indicator != null &&
              (indicator == 'veg' || indicator == 'non_veg'))
            PositionedDirectional(
              // sits just above the ADD pill (26.h tall + 8.h offset + 4.h gap)
              bottom: 35.h,
              end: 12.w,
              child: productIndicator(indicator!),
            ),

          // ── bottom-right: pill ADD / stepper ──
          /*if (!isDim)
            PositionedDirectional(
              bottom: 10,
              end: 5,
              child: _cartButton(context),
            ),*/
        ],
      ),
    );
  }

  // ── Info section (order: price → dashed divider → name → rating → delivery) ──

  Widget _infoSection({
    required BuildContext context,
    required bool isDim,
    required double discountPct,
    required bool hasDiscount,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 5.h),

          // 1. Product name (bold) — directly under image
          _productNameWidget(context, isDim),

          SizedBox(height: 6.h),

          // 2. Price row
          _priceRow(context, isDim),

          // 3. Rating pill + review count (only when both are non-zero)
          if (ratings > 0 && ratingCount > 0) ...[
            SizedBox(height: 6.h),
            _ratingWidget(context),
          ],

          SizedBox(height: 4.h),

          _cartButton(context)
        ],
      ),
    );
  }

  // ── Image overlay helpers ──────────────────────────────────────────────────

  Widget _statusBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(8.r),
          bottomEnd: Radius.circular(4.r),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)?.outOfStock ?? 'Out of stock',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _apiBadgeWidget(BuildContext context) {
    final bgColor = _hexToColor(badge!.bgColor) ?? AppTheme.discountCardColor;
    final textColor = _hexToColor(badge!.textColor) ?? Colors.white;
    final borderColor = _hexToColor(badge!.borderColor);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 80.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(8.r),
            bottomEnd: Radius.circular(4.r),
          ),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
        ),
        child: Text(
          capitalizeFirstLetter(badge!.label!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _wishlistButton(BuildContext context) {
    return BlocBuilder<UserWishlistBloc, UserWishlistState>(
      builder: (context, wishlistState) {
        final bloc = context.read<UserWishlistBloc>();
        final isWishListedFromBloc =
        bloc.isProductWishlisted(productId, productVariantId, storeId);
        final hasBlocData =
        bloc.hasProductData(productId, productVariantId, storeId);

        final finalIsWishListed =
        hasBlocData ? isWishListedFromBloc : isWishListed;

        return AnimatedButton(
            onTap: () async {
              if (Global.userData == null) {
                await AuthGuard.ensureLoggedIn(context);
                return;
              }
              // One-tap toggle on the default "Favorite" wishlist via the
              // dedicated toggle endpoint — no list selection, no bottom sheet,
              // no client-held item id required.
              bloc.add(ToggleFavorite(
                productId: productId,
                productVariantId: productVariantId,
                storeId: storeId,
                currentlyFavorited: finalIsWishListed,
              ));
            },
            child: Container(
              height: 32.r,
              width: 32.r,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // 🎨 Fill
                  if (finalIsWishListed)
                    Icon(
                      AppHelpers.wishListedIcon,
                      color: AppTheme.primaryColor,
                      size: 14.r,
                    )
                  else
                    Icon(
                      AppHelpers.wishListedIcon,
                      color: Colors.white,
                      size: 14.r,
                    ),

                  Icon(
                    finalIsWishListed
                        ? AppHelpers.notWishListedIcon
                        : AppHelpers.notWishListedIcon,
                    color: Colors.black.withValues(alpha: 0.6),
                    size: 14.r,
                  ),
                ],
              ),
            )
        );
      },
    );
  }

  Widget _cartButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final stocks = totalStocks;
        final isStockAvailable = isInStock;
        _getCartItem(state);
        _getTotalQuantityAcrossVariants(state);
        final Set<int> currentStoreIds = {};
        int currentTotalItems = 0;

        if (state is CartLoaded) {
          currentStoreIds.addAll(
            state.items
                .map((item) => int.tryParse(item.vendorId))
                .where((id) => id != null)
                .cast<int>(),
          );
          currentTotalItems = state.items.length;
        }

        return Row(
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: GestureDetector(
                  onTap: (){
                    context.read<RemoveItemFromCartBloc>().add(RemoveItemFromCartRequest(
                      cartItemId: cartItemId
                    ));
                  },
                  child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppTheme.primaryColor
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                          child: Icon(
                            TablerIcons.trash, size: 18,)
                      )
                  )
              ),
            ),
            const SizedBox(width: 10,),
            Expanded(
              child: SizedBox(
                height: 40,
                child: GestureDetector(
                    onTap: (isInStock == true || stocks! > 0)
                        ? () async {
                      if (!context.mounted) return;
                      final error =
                      CartValidation.validateProductAddToCart(
                          context: context,
                          requestedQuantity: minQty,
                          minQty: minQty,
                          maxQty: totalAllowedQuantity,
                          stock: totalStocks,
                          stepSize: quantityStepSize,
                          isStoreOpen: isStoreOpen,
                          isInStock: isStockAvailable
                      );
                      final cartError =
                      CartValidation.validateBeforeAddToCart(
                        context: context,
                        currentCartItemCount: currentTotalItems,
                        requestedAddQuantity: 1,
                        currentStoreIdsInCart: currentStoreIds,
                        thisProductStoreId: storeId,
                      );

                      if (error != null || cartError != null) {
                        ToastManager.show(
                          context: context,
                          message: cartError ?? error!,
                          type: ToastType.error,
                        );
                      } else {
                        HapticFeedback.selectionClick();
                        onMoveToCart();
                      }
                    }
                        : null,
                    child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                            child: Text(
                              'Move to cart',
                              style: AppTextStyles.body,
                            )
                        )
                    )
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Info section helpers ───────────────────────────────────────────────────

  Widget _priceRow(BuildContext context, bool isDim) {
    final double regular = double.tryParse(productPrice) ?? 0.0;
    final double special = double.tryParse(specialPrice) ?? 0.0;
    final bool hasDiscount = special > 0 && special < regular;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Special (or regular) price — prominent
        Text(
          format != null
              ? PriceUtils.formatWithFormat(hasDiscount ? special : regular, format!, currencySymbol)
              : PriceUtils.formatWithSymbol(hasDiscount ? special : regular, currencySymbol),
          style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.bold,
              color: isDim
                  ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
                  : null
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (hasDiscount) ...[
          SizedBox(width: 5.w),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              format != null
                  ? PriceUtils.formatWithFormat(regular, format!, currencySymbol)
                  : PriceUtils.formatWithSymbol(regular, currencySymbol),
              style: AppTextStyles.caption.copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor:
                Theme.of(context).colorScheme.onSecondaryContainer,
                decorationThickness: 1.5,
                color: isDim
                    ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _productNameWidget(BuildContext context, bool isDim) {
    return Text(
      '$productName$productName',
      style: AppTextStyles.label.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: isDim
            ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
            : null,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _ratingWidget(BuildContext context) {
    // Whole numbers show without a decimal (5), fractional show one place (4.5).
    final ratingLabel = ratings == ratings.roundToDouble()
        ? ratings.toStringAsFixed(0)
        : ratings.toStringAsFixed(1);
    return Row(
      children: [
        // Compact rating pill — "5★" on a dark green chip.
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ratingLabel,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                AppTheme.ratingStarIconFilled,
                size: 10.r,
                color: Colors.black,
              ),
            ],
          ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            '(${_formatCount(ratingCount)})',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  int _getTotalQuantityAcrossVariants(CartState state) {
    if (state is! CartLoaded) return 0;
    return state.items
        .where((item) =>
    int.tryParse(item.productId) == productId &&
        int.tryParse(item.vendorId) == storeId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  UserCart? _getCartItem(CartState state) {
    if (state is CartLoaded) {
      try {
        return state.items.firstWhere(
              (item) =>
          int.parse(item.productId) == productId &&
              int.parse(item.vendorId) == storeId,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildAssetImageOrPlaceholder() {
    if (assetImage != null && assetImage!.isNotEmpty) {
      return CustomImageContainer(imagePath: assetImage!, fit: BoxFit.cover);
    }
    return Builder(
      builder: (context) => Container(
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 24.sp,
        ),
      ),
    );
  }
}


/// Inserts thousands separators into an integer count (e.g. 15090 → "15,090").
String _formatCount(int n) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return negative ? '-$buf' : buf.toString();
}

/// Parses a CSS-style hex color string (`#RGB`, `#RRGGBB`, `#AARRGGBB`) to [Color].
Color? _hexToColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.replaceAll('#', '');
  final expanded = cleaned.length == 3
      ? cleaned.split('').map((c) => '$c$c').join()
      : cleaned;
  final withAlpha = expanded.length == 6 ? 'FF$expanded' : expanded;
  final value = int.tryParse(withAlpha, radix: 16);
  return value != null ? Color(value) : null;
}
