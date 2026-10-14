import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/helper.dart';

import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/product_card/product_card_style1.dart';
import '../model/wishlist_product_model.dart';

class WishlistProductsGrid extends StatelessWidget {
  final List<WishlistProductItems> items;

  const WishlistProductsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: isTablet(context)
            ? SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 10.h,
                mainAxisExtent: 222.h,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 10.h,
                mainAxisExtent: 222.h,
              ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildGridItem(context, items[index]),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, WishlistProductItems item) {
    final product = item.product;
    final variant = item.variant;
    final storeId = variant?.storeId ?? item.store?.id ?? 0;

    return ProductCardStyle1(
      productId: product?.id ?? 0,
      productImage: product?.image ?? '',
      productSlug: product?.slug ?? '',
      productName: product?.title ?? '',
      productPrice: (variant?.price ?? 0).toString(),
      specialPrice: (variant?.specialPrice ?? 0).toString(),
      currencySymbol: variant?.currencySymbol ?? '',
      format: variant?.format,
      productTags: const [],
      estimatedDeliveryTime: (product?.estimatedDeliveryTime ?? '').toString(),
      assetImage: '',
      ratings: product?.ratings ?? 0.0,
      ratingCount: product?.ratingCount ?? 0,
      onAddToCart: () {
        if (product == null) return;
        final cartItem = UserCart(
          productId: product.id.toString(),
          variantId: variant.id.toString(),
          variantName: product.title.toString(),
          vendorId: variant.storeId.toString(),
          name: product.title.toString(),
          image: product.image ?? '',
          price: (variant.specialPrice ?? 0).toDouble(),
          originalPrice: (variant.price ?? 0).toDouble(),
          quantity: product.minimumOrderQuantity ?? 1,
          serverCartItemId: null,
          syncAction: CartSyncAction.add,
          updatedAt: DateTime.now(),
          minQty: product.minimumOrderQuantity ?? 1,
          maxQty: product.totalAllowedQuantity ?? 0,
          isOutOfStock: (variant.stock ?? 0) <= 0,
          isSynced: false,
        );
        context.read<CartBloc>().add(AddToCart(item: cartItem, context: context));
      },
      isStoreOpen: true,
      isWishListed: true,
      productVariantId: variant?.id ?? 0,
      storeId: storeId,
      totalStocks: variant?.stock ?? 0,
      showWishlist: true,
      wishlistItemId: item.id ?? 0,
      imageFit: product?.imageFit ?? 'contain',
      quantityStepSize: product?.quantityStepSize ?? 1,
      minQty: product?.minimumOrderQuantity ?? 1,
      totalAllowedQuantity: product?.totalAllowedQuantity ?? 0,
      isRecommended: false,
      isInStock: variant!.isInStock!,
    );
  }
}
