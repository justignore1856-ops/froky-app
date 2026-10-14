import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_commerce/utils/widgets/bottom_variant_selector_with_addons.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/product_card/product_card_style2.dart';
import '../../ad_campaign/bloc/ad_click_bloc/ad_click_bloc.dart';
import '../../ad_campaign/widgets/ad_visibility_observer.dart';
import '../bloc/similar_product_bloc/similar_product_bloc.dart';

class SimilarProductsBottomSheet extends StatelessWidget {
  const SimilarProductsBottomSheet({super.key});

  static const double _rowHeight = 240;

  static void show(BuildContext context) {
    final bloc = context.read<SimilarProductBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const SimilarProductsBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(theme),
            _buildHeader(context, theme),
            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline),
            BlocBuilder<SimilarProductBloc, SimilarProductState>(
              builder: (context, state) {
                if (state is SimilarProductLoaded) {
                  if (state.similarProduct.isEmpty) {
                    return _buildMessage(
                      context,
                      theme,
                      AppLocalizations.of(context)?.noData ??
                          'No similar products found',
                    );
                  }
                  return _buildList(context, state.similarProduct);
                } else if (state is SimilarProductFailure) {
                  return _buildMessage(
                    context,
                    theme,
                    AppLocalizations.of(context)?.somethingWentWrong ??
                        'Something went wrong',
                  );
                }
                return _buildLoading();
              },
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.similarProducts ?? 'Similar Products',
              style: AppTextStyles.titleLarge.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                TablerIcons.x,
                color: theme.colorScheme.onSecondaryContainer,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: _rowHeight.h,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessage(BuildContext context, ThemeData theme, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ProductData> products) {
    final count = products.length > 15 ? 15 : products.length;

    return SizedBox(
      height: _rowHeight.h,
      child: ListView.separated(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) => SizedBox(
          width: 155.w,
          child: _buildCard(context, products[index]),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ProductData productData) {
    final defaultVariant = productData.variants.firstWhere(
      (v) => v.isDefault,
      orElse: () {
        if (productData.variants.isNotEmpty) return productData.variants.first;
        throw Exception('No variants available for product ${productData.id}');
      },
    );

    final card = ProductCardStyle2(
      productId: productData.id,
      productImage: productData.mainImage,
      productSlug: productData.slug,
      productName: productData.title,
      productPrice: defaultVariant.price.toString(),
      specialPrice: defaultVariant.specialPrice.toString(),
      currencySymbol: defaultVariant.currencySymbol,
      format: defaultVariant.format,
      productTags: const [],
      estimatedDeliveryTime: productData.estimatedDeliveryTime.toString(),
      ratings: double.parse(productData.ratings.toString()),
      ratingCount: productData.ratingCount,
      isSponsored: productData.isSponsored,
      onCardTap: productData.isSponsored
          ? () => context.read<AdClickBloc>().add(RecordClick(
                campaignId: productData.campaignId,
                visitorKey: productData.visitorKey,
              ))
          : null,
      onAddToCart: () {
        if (productData.variants.length > 1 ||
            productData.variants.any((v) => v.addonGroups.isNotEmpty == true)) {
          showVariantBottomSheetWithAddons(
            variantsList: productData.variants,
            productData: productData,
            productImage: productData.mainImage,
            quantityStepSize: productData.quantityStepSize,
            context: context,
          );
        } else {
          final item = UserCart(
            productId: productData.id.toString(),
            variantId: defaultVariant.id.toString(),
            variantName: defaultVariant.title.toString(),
            vendorId: defaultVariant.storeId.toString(),
            name: productData.title,
            image: productData.mainImage,
            price: defaultVariant.specialPrice.toDouble(),
            originalPrice: defaultVariant.price.toDouble(),
            quantity: productData.minimumOrderQuantity,
            serverCartItemId: null,
            syncAction: CartSyncAction.add,
            updatedAt: DateTime.now(),
            minQty: productData.minimumOrderQuantity,
            maxQty: productData.totalAllowedQuantity,
            isOutOfStock: !defaultVariant.isInStock,
            isSynced: false,
          );
          context.read<CartBloc>().add(AddToCart(item: item, context: context));
        }
      },
      variantCount: productData.variants.length,
      onVariantSelectorRequested: productData.variants.length > 1
          ? () => showVariantBottomSheetWithAddons(
                variantsList: productData.variants,
                productData: productData,
                productImage: productData.mainImage,
                quantityStepSize: productData.quantityStepSize,
                context: context,
              )
          : null,
      isStoreOpen: productData.storeStatus?.isOpen ?? true,
      isWishListed: productData.favorite.isNotEmpty,
      productVariantId: defaultVariant.id,
      storeId: defaultVariant.storeId,
      wishlistItemId:
          productData.favorite.isNotEmpty ? productData.favorite.first.id ?? 0 : 0,
      totalStocks: defaultVariant.stock,
      imageFit: productData.imageFit,
      quantityStepSize: productData.quantityStepSize,
      minQty: productData.minimumOrderQuantity,
      totalAllowedQuantity: productData.totalAllowedQuantity,
      indicator: productData.indicator,
      isInStock: defaultVariant.isInStock,
    );

    if (productData.isSponsored && productData.campaignId > 0) {
      return AdVisibilityObserver(
        campaignId: productData.campaignId,
        visitorKey: productData.visitorKey,
        child: card,
      );
    }

    return card;
  }
}

class SimilarProductsButton extends StatelessWidget {
  final VoidCallback onTap;
  const SimilarProductsButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/icons/similar-product-icon.png',
          height: 20,
        ),
      ),
    );
  }
}
