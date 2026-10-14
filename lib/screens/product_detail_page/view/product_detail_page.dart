import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_state.dart';
import 'package:hyper_commerce/model/recent_product_model/recent_product_model.dart';
import 'package:hyper_commerce/screens/address_list_page/model/get_address_list_model.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/add_to_cart/add_to_cart_state.dart';
import 'package:hyper_commerce/screens/cart_page/widgets/address_selection_bottom_sheet.dart';
import 'package:hyper_commerce/model/selected_address/selected_address_model.dart';
import 'package:hyper_commerce/services/address/selected_address_hive.dart';
import 'package:hyper_commerce/services/market/market_service.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_detail_bloc/product_detail_bloc.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_detail_bloc/product_detail_event.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_detail_bloc/product_detail_state.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_review_bloc/product_review_bloc.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/app_bar_widget.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/custom_product_feature_section_widget.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/delivery_services_section.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_bottom_cart_bar.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_description_section.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_detail_shimmer.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_faq_section.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_image_slider.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_reviews_section.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_title_header.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_variant_selector.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/seller_store_name_card.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/similar_product_widget.dart';
import 'package:hyper_commerce/services/recent_product/recent_product_service.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/empty_states_page.dart';
import '../model/product_initial_data.dart';
export 'package:hyper_commerce/screens/product_detail_page/model/product_initial_data.dart';
export 'package:hyper_commerce/screens/product_detail_page/widgets/rating_bar_widget.dart';

class ProductDetailPage extends StatefulWidget {
  final String productSlug;
  final ProductInitialData? initialData;
  final VoidCallback? closeContainer;

  const ProductDetailPage({
    super.key,
    required this.productSlug,
    this.initialData,
    this.closeContainer,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsKey = GlobalKey();
  final ProductDetailBloc _productDetailBloc = ProductDetailBloc();
  Map<String, SwatchValues> selectedVariants = {};
  bool _showTitle = false;
  bool _hasLoggedView = false;

  // Address picked for this page only — never written back to the Hive default.
  SelectedAddress? _selectedAddress;

  void _scrollToReviews() {
    final ctx = _reviewsKey.currentContext;
    if (ctx == null) return;
    final renderObject = ctx.findRenderObject();
    if (renderObject == null) return;

    final position = Scrollable.of(ctx).position;
    final viewport = RenderAbstractViewport.of(renderObject);
    final double reveal = viewport.getOffsetToReveal(renderObject, 0.0).offset;
    final double target = (reveal - 100.h)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    position.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  ProductVariants? _currentVariant;


  ProductVariants _getActiveVariant(ProductData product) {
    if (selectedVariants.isEmpty) {
      return product.variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => product.variants.first,
      );
    }

    return product.variants.firstWhere(
      (v) {
        for (var attr in product.attributes) {
          final selected = selectedVariants[attr.name];
          if (selected != null) {
            final variantValue = v.attributes[attr.slug];
            if (variantValue?.toString().toLowerCase().trim() !=
                selected.value.toString().toLowerCase().trim()) {
              return false;
            }
          }
        }
        return true;
      },
      orElse: () => product.variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => product.variants.first,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _selectedAddress = HiveSelectedAddressHelper.getSelectedAddress();
    _fetchProductDetail();
  }

  Future<void> _fetchProductDetail({bool silent = false}) async {
    final countryCode = _selectedAddress?.countryCode;
    final marketCode = countryCode != null
        ? await MarketService.marketCodeForCountry(countryCode)
        : null;
    if (!mounted) return;

    _productDetailBloc.add(
      FetchProductDetail(
        productSlug: widget.productSlug,
        addressId: countryCode ?? 'IN',
        marketCode: marketCode,
        silent: silent,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach once when the tree is built
    PrimaryScrollController.of(context).addListener(_onScroll);
  }

  void _onScroll() {
    final offset = PrimaryScrollController.of(context).offset;
    final show = offset > 200;
    if (_showTitle != show) {
      setState(() => _showTitle = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _productDetailBloc.close();
    super.dispose();
  }

  Future<void> _onProductViewed(
    String id,
    String name,
    String imageUrl,
    String slug,
  ) async {
    final product = RecentProduct(
      id: id,
      name: name,
      imageUrl: imageUrl,
      productSlug: slug,
    );
    await RecentlyViewedService.addProduct(product);
  }

  void _openAddressBottomSheet(BuildContext context) {
    final selected = _selectedAddress;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AddressSelectionBottomSheet(
        selectedAddress:
            selected != null ? AddressListData(id: selected.id) : null,
        onAddressSelected: _onAddressChanged,
      ),
    );
  }

  void _onAddressChanged(AddressListData address) {
    if (_selectedAddress?.id == address.id) return;

    setState(() {
      _selectedAddress = SelectedAddress.fromAddressListData(address);
    });
    _fetchProductDetail(silent: true);
  }

  void _hydrateSelectedVariantsIfEmpty(ProductData product) {
    if (selectedVariants.isNotEmpty || _currentVariant == null) return;
    for (var attr in product.attributes) {
      final variantAttrValue = _currentVariant!.attributes[attr.slug];
      if (variantAttrValue == null) continue;
      try {
        final sw = attr.swatchValues.firstWhere(
          (s) =>
              s.value.toString().toLowerCase().trim() ==
              variantAttrValue.toString().toLowerCase().trim(),
        );
        selectedVariants[attr.name] = sw;
      } catch (_) {
        selectedVariants[attr.name] =
            SwatchValues(value: variantAttrValue.toString(), swatch: '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AddToCartBloc()),
        BlocProvider.value(value: _productDetailBloc),
        BlocProvider(
          create: (_) => ProductReviewBloc()
            ..add(FetchProductReview(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => ProductFAQBloc()
            ..add(FetchProductFAQ(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => SimilarProductBloc()
            ..add(FetchSimilarProduct(
              excludeProductSlug: [widget.productSlug],
            )),
        ),
      ],
      child: CustomScaffold(
        showViewCart: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: MultiBlocListener(
          listeners: [
            // Pre-existing (kept as a no-op slot — some downstream code
            BlocListener<AddToCartBloc, AddToCartState>(
              listener: (_, __) {},
            ),
            // Catches server-side cart errors (e.g.
            BlocListener<CartBloc, CartState>(
              listenWhen: (prev, next) =>
                  next is CartLoaded && next.errorMessage != null,
              listener: (context, state) {
                if (state is CartLoaded && state.errorMessage != null) {
                  ToastManager.show(
                    context: context,
                    message: state.errorMessage!,
                    type: ToastType.error,
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (BuildContext context, ProductDetailState state) {
              if (state is ProductDetailLoading || state is ProductDetailInitial) {
                return NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      const AppBarWidget(
                        showTitle: true,
                      ),
                    ];
                  },
                  body: const ProductDetailShimmer(),
                );
              }
              else if (state is ProductDetailLoaded) {
                final product = state.productData[0];

                if (product.variants.isEmpty) {
                  return const NoProductPage();
                }

                _currentVariant ??= product.variants.firstWhere(
                  (v) => v.isDefault,
                  orElse: () => product.variants.first,
                );

                _hydrateSelectedVariantsIfEmpty(product);

                final activeVariant = _getActiveVariant(product);
                _currentVariant = activeVariant;

                if (!_hasLoggedView) {
                  _hasLoggedView = true;
                  _onProductViewed(
                    product.id.toString(),
                    product.title,
                    product.mainImage,
                    product.slug,
                  );
                }

                final surfaceColor = Theme.of(context).colorScheme.surface;

                final scrollView = NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      const AppBarWidget(
                        showTitle: true,
                      ),
                    ];
                  },
                  body: CustomScrollView(
                    clipBehavior: Clip.antiAlias,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // Image slider at the top of the body
                            ProductImageSlider(
                              productSlug: widget.productSlug,
                              initialData: widget.initialData,
                              loadedProduct: product,
                              selectedVariant: activeVariant,
                              onRatingTap: _scrollToReviews,
                            ),
                            SizedBox(height: 10.h),

                            // Card 1 — Title + rating + pricing
                            Container(
                              width: double.infinity,
                              color: surfaceColor,
                              padding: EdgeInsets.fromLTRB(
                                12.w,
                                15.h,
                                12.w,
                                12.h,
                              ),
                              child: ProductTitleHeader(
                                product: product,
                                activeVariant: activeVariant,
                                currentVariant:
                                    _currentVariant ?? activeVariant,
                              ),
                            ),

                            // Card 2 — Variant selector
                            if (product.attributes.isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              Container(
                                width: double.infinity,
                                color: surfaceColor,
                                padding: EdgeInsets.fromLTRB(
                                  12.w,
                                  12.h,
                                  12.w,
                                  12.h,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: product.attributes.length,
                                  itemBuilder: (context, index) {
                                    final attribute =
                                        product.attributes[index];
                                    return ProductVariantSelector(
                                      label: attribute.name,
                                      attributeSlug: attribute.slug,
                                      variantType: attribute.swatcheType,
                                      selectedValue:
                                          selectedVariants[attribute.name],
                                      onSelected: (SwatchValues value) {
                                        setState(() {
                                          selectedVariants[attribute.name] =
                                              value;
                                        });
                                      },
                                      productAttributes:
                                          attribute.swatchValues,
                                      variants: product.variants,
                                    );
                                  },
                                ),
                              ),
                            ],

                            // Card 3 — Delivery & Services
                            SizedBox(height: 10.h),
                            DeliveryServicesSection(
                              product: product,
                              activeVariant: activeVariant,
                              selectedAddress: _selectedAddress,
                              onChangeAddress: () =>
                                  _openAddressBottomSheet(context),
                            ),


                            // Card 4 — Product description / details
                            SizedBox(height: 10.h),
                            Container(
                              width: double.infinity,
                              color: surfaceColor,
                              padding: EdgeInsets.fromLTRB(
                                12.w,
                                0.h,
                                12.w,
                                0.h,
                              ),
                              child: ProductDescriptionSection(product: product),
                            ),

                            SizedBox(height: 10.h),
                            if (product.variants.first.storeName.isNotEmpty &&
                                product.variants.first.storeSlug.isNotEmpty) ...[
                              SellerStoreNameCard(
                                storeName: product.variants.first.storeName,
                                storeSlug: product.variants.first.storeSlug,
                                sellerName: product.seller,
                              ),

                            ],
                            if (product.customProductFeaturedSections
                                .isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              CustomProductFeatureSectionWidget(
                                sections:
                                    product.customProductFeaturedSections,
                              ),
                            ],
                            ProductReviewsSection(
                                key: _reviewsKey, product: product),
                            ProductFaqSection(product: product),
                            BlocBuilder<SimilarProductBloc,
                                SimilarProductState>(
                              builder: (context, state) {
                                if (state is SimilarProductLoaded) {
                                  return SimilarProductWidget(
                                    product: state.similarProduct,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                return Stack(
                  children: [
                    scrollView,
                    if (state.isRefreshing)
                      Positioned.fill(
                        child: AbsorbPointer(
                          child: ColoredBox(
                            color: Theme.of(context)
                                .colorScheme
                                .scrim
                                .withValues(alpha: 0.06),
                            child: const CustomCircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                );
              }
              if (state is ProductDetailFailed) {
                return const NoProductPage();
              }
              return const CustomCircularProgressIndicator();
            },
          ),
        ),
        bottomNavigationBar: ProductBottomCartBar(
          selectedVariants: selectedVariants,
          countryCode: _selectedAddress?.countryCode ?? MarketService.currentCountryIso2(),
        ),
      ),
    );
  }
}
