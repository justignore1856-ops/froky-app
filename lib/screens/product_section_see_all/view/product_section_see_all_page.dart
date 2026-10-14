import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_commerce/config/dependency_injection_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';

import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/basket_button.dart';
import '../../home_page/widgets/sections/products/home_layout_product_card.dart';
import '../bloc/product_section_see_all_bloc.dart';
import '../bloc/product_section_see_all_event.dart';
import '../bloc/product_section_see_all_state.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class ProductSectionSeeAllPage extends StatefulWidget {
  final int sectionId;
  final String title;

  const ProductSectionSeeAllPage({
    super.key,
    required this.sectionId,
    this.title = '',
  });

  @override
  State<ProductSectionSeeAllPage> createState() =>
      _ProductSectionSeeAllPageState();
}

class _ProductSectionSeeAllPageState extends State<ProductSectionSeeAllPage> {
  final ScrollController _scrollController = ScrollController();
  late final ProductSectionSeeAllBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductSectionSeeAllBloc>()
      ..add(FetchProductSectionItems(sectionId: widget.sectionId));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _bloc.add(const FetchMoreProductSectionItems());
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (isTablet(context) ? 4 : 3 );
    return CustomScaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(HeroiconsOutline.magnifyingGlass),
            onPressed: () {
              GoRouter.of(context).push(AppRoutes.search);
            },
          ),
          const BasketButton(),
        ],
      ),
      showViewCart: true,
      showAppBar: true,
      body: TabletConstrainedBody(
        child: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<ProductSectionSeeAllBloc, ProductSectionSeeAllState>(
          builder: (context, state) {
            if (state is ProductSectionSeeAllLoading ||
                state is ProductSectionSeeAllInitial) {
              return const Center(child: CustomCircularProgressIndicator());
            }
            if (state is ProductSectionSeeAllFailed) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(state.error, textAlign: TextAlign.center),
                ),
              );
            }
            if (state is ProductSectionSeeAllLoaded) {
              if (state.items.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)?.noData ?? 'No data',
                  ),
                );
              }
              return CustomRefreshIndicator(
                onRefresh: () async {
                  context.read<ProductSectionSeeAllBloc>().add(FetchProductSectionItems(sectionId: widget.sectionId));
                },
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.items.length,
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
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, i) =>
                            HomeLayoutProductCard(data: state.items[i]),
                      ),
                    ),
                    if (state.isLoadingMore)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      ),
    );
  }
}
