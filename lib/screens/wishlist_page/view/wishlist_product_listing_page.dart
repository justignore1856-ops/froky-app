import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_shimmer.dart';
import 'package:hyper_commerce/utils/widgets/empty_states_page.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../bloc/wishlist_product_bloc/wishlist_product_bloc.dart';
import '../model/wishlist_product_model.dart';
import '../widgets/wishlist_products_grid.dart';

class WishlistProductListingPage extends StatefulWidget {
  final int wishlistId;
  const WishlistProductListingPage({
    super.key,
    required this.wishlistId
  });

  @override
  State<WishlistProductListingPage> createState() => _WishlistProductListingPageState();
}

class _WishlistProductListingPageState extends State<WishlistProductListingPage> {
  @override
  void initState() {
    super.initState();

    context.read<WishlistProductBloc>().add(
      FetchWishlistProductData(
        wishlistId: widget.wishlistId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: true,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: false,
        title: BlocBuilder<WishlistProductBloc, WishlistProductState>(
          builder: (BuildContext context, WishlistProductState state) {

            if (state is WishlistProductLoaded) {
              return Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.wishlistName,
                        style: TextStyle(
                          fontSize: isTablet(context) ? 24 : 20.sp,
                          fontFamily: AppTheme.fontFamily,
                         ),
                      ),
                      Text(
                        '${state.totalProducts} items',
                        style: TextStyle(
                          fontSize: isTablet(context) ? 14 : 10.sp,
                          color: Colors.grey,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      )
                    ],
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          context.read<WishlistProductBloc>().add(
            FetchWishlistProductData(
              wishlistId: widget.wishlistId,
            ),
          );
        },
        child: BlocConsumer<WishlistProductBloc, WishlistProductState>(
          listener: (BuildContext context, WishlistProductState state) {},
          builder: (BuildContext context, WishlistProductState state) {
            if (state is WishlistProductLoaded) {
              return NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo is ScrollUpdateNotification &&
                      !state.hasReachedMax &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 50) {}
                  return false;
                },
                child: Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: Column(
                    children: [
                      Container(
                        height: 1,
                        color: Colors.grey.shade200,
                        width: double.infinity,
                      ),
                      productList(
                        productData: state.wishlistProductItems,
                        hasReachedMax: state.hasReachedMax,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is WishlistProductLoading) {
              return const CustomCircularProgressIndicator();
            }
            return NoProductPage(
              onRetry: (){
                context.read<WishlistProductBloc>().add(
                  FetchWishlistProductData(
                    wishlistId: widget.wishlistId,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget productList({
    required List<WishlistProductItems> productData,
    required bool hasReachedMax,
  }) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(productData, hasReachedMax),
      ),
    );
  }

  Widget _buildContent(
      List<WishlistProductItems> productData,
      bool hasReachedMax,
      ) {

    if (productData.isEmpty) {
      return NoProductPage(
        onRetry: (){
          context.read<WishlistProductBloc>().add(
            FetchWishlistProductData(
              wishlistId: widget.wishlistId,
            ),
          );
        },
      );
    }

    return WishlistProductsGrid(items: productData);
  }

  Widget productShimmer() {
    return Column(
      children: [
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 130,
          width: 130,
          borderRadius: 15,
        ),
        const SizedBox(height: 10.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15,
          width: 130,
          borderRadius: 15,
        ),
      ],
    );
  }

}