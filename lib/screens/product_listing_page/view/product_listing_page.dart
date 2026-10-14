import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/screens/ad_campaign/bloc/ad_click_bloc/ad_click_bloc.dart';
import 'package:hyper_commerce/screens/ad_campaign/widgets/ad_visibility_observer.dart';
import 'package:hyper_commerce/utils/widgets/bottom_variant_selector_with_addons.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/product_card/product_card_style1.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_shimmer.dart';
import 'package:hyper_commerce/utils/widgets/empty_states_page.dart';
import 'package:remixicon/remixicon.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../model/sorting_model/sorting_model.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../../utils/widgets/custom_filter_bottom_sheet.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../../utils/widgets/basket_button.dart';
import '../../../utils/widgets/custom_sorting_bottom_sheet.dart';
import '../../sub_category_page/bloc/sub_category_bloc.dart';
import '../../sub_category_page/bloc/sub_category_state.dart';
import '../../home_page/model/category_model.dart';
import '../../product_detail_page/model/product_detail_model.dart';
import '../bloc/filter/filter_bloc.dart';
import '../bloc/filter/filter_event.dart';
import '../bloc/nested_category/nested_category_bloc.dart';
import '../bloc/product_listing/product_listing_bloc.dart';
import '../model/product_listing_type.dart';
import '../widgets/custom_filter_sort_btn_widget.dart';
import '../widgets/side_subcategory_bar.dart';

class ProductListingPage extends StatefulWidget {
  final bool isTheirMoreCategory;
  final String title;
  final String totalProduct;
  final String logo;

  final ProductListingType type;
  final String identifier;
  const ProductListingPage({
    super.key,
    required this.isTheirMoreCategory,
    required this.title,
    required this.totalProduct,
    required this.logo,
    this.type = ProductListingType.category,
    required this.identifier,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProductListingBloc(),),
        BlocProvider(create: (context) => NestedCategoryBloc(),),
        BlocProvider(create: (context) => FilterBloc(),),
        BlocProvider(create: (context) => SubCategoryBloc(),),
      ],
      child: _ProductListingView(
        isTheirMoreCategory: widget.isTheirMoreCategory,
        title: widget.title,
        totalProduct: widget.totalProduct,
        logo: widget.logo,
        type: widget.type,
        identifier: widget.identifier,
      ),
    );
  }
}


class _ProductListingView extends StatefulWidget {
  final bool isTheirMoreCategory;
  final String title;
  final String totalProduct;
  final String logo;

  // New generic listing inputs
  final ProductListingType type;
  final String identifier;
  const _ProductListingView({
    required this.isTheirMoreCategory,
    required this.title,
    required this.totalProduct,
    required this.logo,
    this.type = ProductListingType.category,
    required this.identifier,
  });

  @override
  State<_ProductListingView> createState() => _ProductListingViewState();
}

class _ProductListingViewState extends State<_ProductListingView> {
  bool isDataFirstTime = false;
  CategoryData selectedSubcategory = CategoryData();
  Map<String, bool> selectedFilters = {};
  int selectedCategoryIndex = 0;
  int _currentSelectedIndex = 0;
  int totalProductsCount = 0;
  int? parentCategoryTotalCount;

  @override
  void initState() {
    super.initState();
    isDataFirstTime = false;

    final currentState = context.read<ProductListingBloc>().state;
    if (currentState is ProductListingInitial || widget.type != ProductListingType.search) {
      context.read<ProductListingBloc>().add(
        FetchListingProducts(
          type: widget.type,
          identifier: widget.identifier,
          sortType: 'default'),
      );
    }

    if (widget.isTheirMoreCategory &&
        widget.type == ProductListingType.category) {
      context
          .read<NestedCategoryBloc>()
          .add(FetchNestedCategory(slug: widget.identifier));
    }
    _currentSelectedIndex = 0;

    context.read<FilterBloc>().add(ClearAllFilters());
  }

  int get selectedFilterCount {
    return selectedFilters.values.where((selected) => selected).length;
  }

  void _showSortBottomSheet() {
    final currentState = context.read<ProductListingBloc>().state;
    final currentSortType = currentState is ProductListingLoaded
        ? currentState.currentSortType
        : SortType.relevance;

    CustomSortBottomSheet.show(
      context: context,
      currentSortType: currentSortType,
      onSortSelected: (SortOption selectedSort) {
        _applySorting(selectedSort);
      },
    );
  }

  void _applySorting(SortOption sortOption) {
    context.read<ProductListingBloc>().add(
      FetchSortedListingProducts(
        type: widget.type,
        identifier: widget.isTheirMoreCategory &&
            widget.type == ProductListingType.category &&
            selectedSubcategory.slug != null
            ? selectedSubcategory.slug!
            : widget.identifier,
        sortType: sortOption.apiValue,
      ),
    );
  }

  void _showFilterBottomSheet({
    required List<int> categoryIds,
    required List<int> brandsIds
  }) {

    CustomFilterBottomSheet.show(
      context: context,
      listingType: widget.type,
      categoryIds: categoryIds,
      brandsIds: brandsIds,
      value: widget.identifier,
      onApplyFilters: (category, brands, attribute) {
        final categorySlugs = category.map((e) => e.slug ?? '').toList();
        final brandSlugs = brands.map((e) => e.slug ?? '').toList();
        final attributeIds = attribute.map((e) => e.id!).toList();
        context.read<ProductListingBloc>().add(FetchFilteredListingProducts(
          type: widget.type,
          identifier: widget.isTheirMoreCategory &&
              widget.type == ProductListingType.category &&
              selectedSubcategory.slug != null
              ? selectedSubcategory.slug!
              : widget.identifier,
          categorySlugs: categorySlugs,
          brandSlugs: brandSlugs,
          attributeIds: attributeIds,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: false,
        title: BlocListener<SubCategoryBloc, SubCategoryState>(
          listener: (BuildContext context, SubCategoryState state) {
            if (state is SubCategoryLoaded) {
              selectedSubcategory = state.subCategoryData.first;
            }
          },
          child: Row(
            children: [
              if (widget.type != ProductListingType.store &&
                  widget.type != ProductListingType.search &&
                  widget.type != ProductListingType.featuredSection)
                Container(
                  height: 45.h,
                  width: 45.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: CustomImageContainer(
                    imagePath: widget.logo,
                    height: 35.h,
                    fit: BoxFit.contain,
                  ),
                ),

              if (widget.type != ProductListingType.store &&
                  widget.type != ProductListingType.search)
                SizedBox(width: 10.w),

              /// 🔹 Title + Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        widget.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    BlocSelector<ProductListingBloc, ProductListingState, int>(
                      selector: (state) {
                        if (state is ProductListingLoaded &&
                            !state.isFilterLoading) {
                          totalProductsCount = state.totalProducts;
                        }
                        return totalProductsCount;
                      },
                      builder: (context, count) {
                        return Text(
                          '$count items',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        titleSpacing: 0,
        actions: <Widget>[
          SizedBox(width: 10.w,),
          if (widget.type != ProductListingType.search)
            IconButton(
              icon: const Icon(HeroiconsOutline.magnifyingGlass),
              onPressed: () {
                GoRouter.of(context).push(AppRoutes.search);
              },
            ),
          const BasketButton(),
        ],
      ),
      body: BlocConsumer<ProductListingBloc, ProductListingState>(
        listener: (BuildContext context, ProductListingState state) {
          if (state is ProductListingLoading) {
            setState(() {
              isDataFirstTime = true;
            });
          }
        },
        builder: (BuildContext context, ProductListingState state) {
          if (state is ProductListingLoaded) {
            final bool showSubcategorySidebar = widget.isTheirMoreCategory &&
                context.read<NestedCategoryBloc>().state
                is NestedCategoryLoaded &&
                (context.read<NestedCategoryBloc>().state
                as NestedCategoryLoaded)
                    .subCategoryData
                    .isNotEmpty;

            return CustomRefreshIndicator(
              onRefresh: () async {
                context.read<ProductListingBloc>().add(
                  FetchListingProducts(
                      type: widget.type,
                      identifier: widget.identifier,
                      sortType: 'default'),
                );
                setState(() {
                  _currentSelectedIndex = 0;
                });
              },
              child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo is ScrollUpdateNotification &&
                        !state.hasReachedMax &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      context.read<ProductListingBloc>().add(
                        FetchMoreListingProducts(
                          type: widget.type,
                          identifier: widget.identifier,
                        ),
                      );
                    }
                    return false;
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT: Subcategory Sidebar (Conditional)
                      if (showSubcategorySidebar) ...[
                        categoryList(),
                        SizedBox(width: 3.w),
                      ],

                        // RIGHT: Product Grid (Always present)
                        Expanded(
                          child: Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Column(
                              children: [
                                SizedBox(height: 10.h),

                                // Sort Button
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: MediaQuery.of(context).size.width,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        CustomFilterSortBtnWidget(
                                          onTap: () => _showFilterBottomSheet(
                                              categoryIds: state.categoryIds ?? [],
                                              brandsIds: state.brandIds ?? []
                                          ),
                                          buttonName: 'Filter',
                                          iconData: RemixIcons.equalizer_3_line,
                                        ),
                                        SizedBox(width: 10.w),
                                        CustomFilterSortBtnWidget(
                                          onTap: _showSortBottomSheet,
                                          buttonName: 'Sort',
                                          iconData:
                                          HeroiconsOutline.arrowsUpDown,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 10.h),
                                const Divider(height: 1, thickness: 1),

                                // Product List with dynamic grid columns
                                productList(
                                  productData: state.productList,
                                  isFilterLoading: state.isFilterLoading,
                                  hasReachedMax: state.hasReachedMax,
                                  isLoading: state.isLoading,
                                  crossAxisCount: showSubcategorySidebar
                                      ? (isTablet(context) ? 3 : 2)
                                      : (isTablet(context)
                                      ? 4
                                      : 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ));

          }
          if (state is ProductListingLoading) {
            return const CustomCircularProgressIndicator();
          } else if (state is ProductListingFailed) {
            if (widget.type == ProductListingType.search) {
              return const NoSearchPage();
            } else {
              return NoProductPage(
                onRetry: () {},
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget productList({
    required List<ProductData> productData,
    required bool isFilterLoading,
    required bool hasReachedMax,
    required bool isLoading,
    required int crossAxisCount,
  }) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(
            productData, isFilterLoading, hasReachedMax, crossAxisCount),
      ),
    );
  }

  Widget _buildContent(
      List<ProductData> productData,
      bool isFilterLoading,
      bool hasReachedMax,
      int crossAxisCount,
      ) {
    if (isFilterLoading) {
      return productListShimmer(
        crossAxisCount,
        key: const ValueKey('shimmer'),
      );
    }

    if (productData.isEmpty) {
      return const NoProductPage(
        key: ValueKey('no_product'),
      );
    }

    return _buildProductGrid(
      productData,
      hasReachedMax,
      crossAxisCount,
      key: widget.type == ProductListingType.search
          ? const ValueKey('product_grid_search')
          : const ValueKey('product_grid_normal'),
    );
  }

  Widget _buildProductGrid(
      List<ProductData> productData,
      bool hasReachedMax,
      int crossAxisCount, {
        Key? key,
      }) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsetsGeometry.directional(
              start: 14.w,
              end: 6.w,
              top: 8.h,
              bottom: 8.h,
            ),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 70),
              gridDelegate: isTablet(context)
                  ? SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 6.h,
                      mainAxisExtent: 232.h,
                    )
                  : SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 6.h,
                      mainAxisExtent: crossAxisCount == 2 ? 228.h : 232.h,
                    ),
              itemCount:
              hasReachedMax ? productData.length : productData.length + 3,
              itemBuilder: (context, index) =>
                  _buildGridItem(productData, index, crossAxisCount),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(
      List<ProductData> productData,
      int index,
      int crossAxisCount,
      ) {
    if (index >= productData.length) {
      return productShimmer();
    }

    final product = productData[index];
    final card = ProductCardStyle1(
      productId: product.id,
      productImage: product.mainImage,
      productName: product.title,
      productSlug: product.slug,
      productPrice: product.variants.first.price.toString(),
      specialPrice: product.variants.first.specialPrice.toString(),
      // Currency follows the variant payload — converted to the caller's
      // market by App\Support\PricePresenter on the backend.
      currencySymbol: product.variants.first.currencySymbol,
      format: product.variants.first.format,
      estimatedDeliveryTime: product.estimatedDeliveryTime.toString(),
      assetImage: '',
      productTags: product.tags,
      ratings: double.parse(product.ratings.toString()),
      ratingCount: product.ratingCount,
      isSponsored: product.isSponsored,
      badge: product.badge,
      onCardTap: product.isSponsored
          ? () => context.read<AdClickBloc>().add(RecordClick(
                campaignId: product.campaignId,
                visitorKey: product.visitorKey,
              ))
          : null,
      onAddToCart: () {
        if (product.variants.length > 1 || product.variants.any((v) => v.addonGroups.isNotEmpty == true)) {
          showVariantBottomSheetWithAddons(
            variantsList: product.variants,
            productData: product,
            productImage: product.mainImage,
            quantityStepSize: product.quantityStepSize,
            context: context,
          );
        } else {
          final item = UserCart(
              productId: product.id.toString(),
              variantId: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .id
                  .toString(),
              variantName: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .title
                  .toString(),
              vendorId: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .storeId
                  .toString(),
              name: product.title,
              image: product.mainImage,
              price: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .specialPrice
                  .toDouble(),
              originalPrice: product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .price
                  .toDouble(),
              quantity: product.minimumOrderQuantity,
              serverCartItemId: null,
              syncAction: CartSyncAction.add,
              updatedAt: DateTime.now(),
              minQty: product.minimumOrderQuantity,
              maxQty: product.totalAllowedQuantity,
              isOutOfStock: !product.variants
                  .firstWhere((variant) => variant.isDefault)
                  .isInStock,
              isSynced: false);
          context.read<CartBloc>().add(AddToCart(item: item, context:  context));
        }
      },
      variantCount: product.variants.length,
      onVariantSelectorRequested: product.variants.length > 1
          ? () => showVariantBottomSheetWithAddons(
        variantsList: product.variants,
        productData: product,
        productImage: product.mainImage,
        quantityStepSize: product.quantityStepSize,
        context: context,
      )
          : null,
      isStoreOpen: true,
      isWishListed: product.favorite.isNotEmpty,
      productVariantId:
      product.variants.firstWhere((variant) => variant.isDefault).id,
      storeId:
      product.variants.firstWhere((variant) => variant.isDefault).storeId,
      wishlistItemId: product.favorite.isNotEmpty ? product.favorite.first.id ?? 0 : 0,
      totalStocks:
      product.variants.firstWhere((variant) => variant.isDefault).stock,
      imageFit: product.imageFit,
      quantityStepSize: product.quantityStepSize,
      minQty: product.minimumOrderQuantity,
      totalAllowedQuantity: product.totalAllowedQuantity,
      indicator: product.indicator,
      isInStock: product.variants.firstWhere((variant) => variant.isDefault).isInStock,
      brandName: product.brandName,
    );

    if (product.isSponsored && product.campaignId > 0) {
      return AdVisibilityObserver(
        campaignId: product.campaignId,
        visitorKey: product.visitorKey,
        child: card,
      );
    }

    return card;
  }

  Widget productListShimmer(int crossAxisCount, {Key? key}) {
    return Padding(
      key: key,
      padding: EdgeInsetsGeometry.directional(
        start: 14.w,
        end: 8.w,
        top: 8.h,
        bottom: 8.h,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 70),
        gridDelegate: isTablet(context)
            ? SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 6.h,
                mainAxisExtent: 222.h,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 6.h,
                // +22.h to keep the shimmer skeleton in step with the real cards
                // (which now reserve room for the "Recommended" chip).
                mainAxisExtent: crossAxisCount == 2 ? 202.h : 222.h,
              ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 130.h,
                width: 130.w,
                borderRadius: 15,
              ),
              SizedBox(height: 10.h),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 15.h,
                width: 130.w,
                borderRadius: 15,
              ),
              const SizedBox(height: 2.0),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 15.h,
                width: 130.w,
                borderRadius: 15,
              ),
              const SizedBox(height: 2.0),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 15.h,
                width: 80.w,
                borderRadius: 15,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget productShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 130.h,
          width: 130.w,
          borderRadius: 15,
        ),
        SizedBox(height: 10.h),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15.h,
          width: 130.w,
          borderRadius: 15,
        ),
        const SizedBox(height: 2.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15.h,
          width: 130.w,
          borderRadius: 15,
        ),
        const SizedBox(height: 2.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15.h,
          width: 80.w,
          borderRadius: 15,
        ),
      ],
    );
  }

  Widget categoryList() {
    return BlocBuilder<NestedCategoryBloc, NestedCategoryState>(
      builder: (context, state) {
        if (state is NestedCategoryLoaded && state.subCategoryData.isNotEmpty) {
          return SideSubcategoryBar(
            subcategories: state.subCategoryData,
            selectedIndex: _currentSelectedIndex,
            onSelected: (int index) {
              if (index == 0) {
                // "All" tab selected
                setState(() {
                  _currentSelectedIndex = 0;
                  selectedSubcategory = CategoryData();
                });

                context.read<ProductListingBloc>().add(
                  FetchSortedListingProducts(
                    type: ProductListingType.category,
                    identifier: widget.identifier,
                    sortType: 'default',
                  ),
                );
              } else {
                final subcategory = state.subCategoryData[index - 1];
                if ((subcategory.subcategoryCount ?? 0) > 0) {
                  GoRouter.of(context).push(AppRoutes.productListing, extra: {
                    'isTheirMoreCategory': true,
                    'title': subcategory.title,
                    'logo': subcategory.image,
                    'totalProduct': subcategory.productCount,
                    'type': ProductListingType.category,
                    'identifier': subcategory.slug,
                  });
                } else {
                  setState(() {
                    selectedSubcategory = subcategory;
                    _currentSelectedIndex = index;
                  });

                  context.read<ProductListingBloc>().add(
                    FetchSortedListingProducts(
                      type: ProductListingType.category,
                      identifier: subcategory.slug ?? '',
                      sortType: 'default',
                    ),
                  );
                }
              }
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class FilterCategory {
  final String title;
  final List<String> options;

  FilterCategory({
    required this.title,
    required this.options,
  });
}