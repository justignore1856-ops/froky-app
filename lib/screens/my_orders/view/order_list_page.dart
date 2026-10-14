import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/get_my_order/get_my_order_event.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/get_my_order/get_my_order_state.dart';
import 'package:hyper_commerce/screens/my_orders/model/order_list_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/empty_states_page.dart';
import '../../../l10n/app_localizations.dart';
import '../model/order_filter_model.dart';
import '../widgets/order_filter_bottom_sheet.dart';
import '../widgets/order_list_card.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  OrderFilter _filter = const OrderFilter();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<GetMyOrderBloc>().add(FetchMyOrder());
    _searchController.addListener(() {
      final value = _searchController.text.trim();
      if (value != _query) {
        setState(() => _query = value);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    OrderFilterSheet.show(
      context: context,
      dateOptions: SettingsData.instance.system!.dataFilterEnum!,
      sortOptions: SettingsData.instance.system!.orderStatusEnum!,
      currentFilter: _filter,
      onApply: (newFilter) {
        setState(() => _filter = newFilter);
        context.read<GetMyOrderBloc>().add(FetchMyOrder(
              dateFilter: _filter.selectedDateFilter,
              statusSort: _filter.selectedStatusSort,
            ));
      },
    );
  }

  List<OrderListItem> _applySearch(List<OrderListItem> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((item) {
      final haystack = [
        item.title,
        item.variantTitle,
        item.product?.name,
        item.store?.name,
        item.sellerName,
        item.sku,
        item.customerStatus?.label,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _openDetail(OrderListItem item) {
    final slug = item.order?.slug ?? item.slug;
    if (slug == null) return;
    GoRouter.of(context).push(
      AppRoutes.orderItemDetail,
      extra: {'order-slug': slug, 'order-item-id': item.id},
    );
  }

  void _rateItem(OrderListItem item) async {
    if (item.id == null) return;
    final reviewed = item.isUserReviewGiven == true;
    final image = (item.variant?.image?.isNotEmpty ?? false)
        ? item.variant!.image
        : item.product?.image;
    await GoRouter.of(context).push<bool>(
      AppRoutes.productRating,
      extra: {
        'orderItemId': item.id,
        'productName': item.title ?? item.product?.name,
        'variantTitle': item.variantTitle,
        'image': image,
        'initialRating': reviewed ? (item.userReview?.rating ?? 0) : 0,
        'initialTitle': item.userReview?.title,
        'initialComment': item.userReview?.comment,
        'feedbackId': reviewed ? item.userReview?.id : null,
      },
    );
    if (mounted) context.read<GetMyOrderBloc>().add(RefreshMyOrders());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      showViewCart: false,
      showAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(l10n?.myOrders ?? 'My Orders'),
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: Theme.of(context).colorScheme.tertiary,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shadowColor:
        Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildSectionRow(context, l10n),
        ),
      ),
      body: TabletConstrainedBody(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildList(context, l10n)),
        ],
      ),
      ),
    );
  }


  Widget _buildSectionRow(BuildContext context, AppLocalizations? l10n) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 6.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.allOrders ?? 'All orders',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            InkWell(
              onTap: _openFilterSheet,
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 15.sp),
                    SizedBox(width: 6.w),
                    Text(
                      l10n?.filters ?? 'Filter',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_filter.hasFilters) ...[
                      SizedBox(width: 6.w),
                      Container(
                        width: 16.w,
                        height: 16.w,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_filter.activeCount}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations? l10n) {
    return BlocBuilder<GetMyOrderBloc, GetMyOrderState>(
      builder: (context, state) {
        if (state is GetMyOrderLoading) {
          return const Center(child: CustomCircularProgressIndicator());
        } else if (state is GetMyOrderLoaded) {
          final items = _applySearch(state.myOrderData);
          if (items.isEmpty) {
            return _buildEmpty(context, l10n);
          }
          return CustomRefreshIndicator(
            onRefresh: () async {
              context.read<GetMyOrderBloc>().add(FetchMyOrder(
                    dateFilter: _filter.selectedDateFilter,
                    statusSort: _filter.selectedStatusSort,
                  ));
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (_query.isEmpty &&
                    scrollInfo is ScrollUpdateNotification &&
                    !state.hasReachedMax &&
                    !state.isLoadingMore &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200) {
                  context.read<GetMyOrderBloc>().add(
                        FetchMoreMyOrder(
                          dateFilter: _filter.selectedDateFilter,
                          statusSort: _filter.selectedStatusSort,
                        ),
                      );
                }
                return false;
              },
              child: TabletPairedListView(
                padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
                itemCount: (_query.isEmpty && !state.hasReachedMax)
                    ? items.length + 1
                    : items.length,
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return state.isLoadingMore
                        ? SizedBox(
                            height: 70.h,
                            child: const CustomCircularProgressIndicator(),
                          )
                        : const SizedBox.shrink();
                  }
                  final item = items[index];
                  return OrderListCard(
                    item: item,
                    onTap: () => _openDetail(item),
                    onRate: (_) => _rateItem(item),
                  );
                },
              ),
            ),
          );
        } else if (state is GetMyOrderFailed) {
          return NoOrderPage(
            onRetry: () {
              context.read<GetMyOrderBloc>().add(FetchMyOrder());
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 72.sp, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          Text(
            l10n?.noOrdersYet ?? 'No orders yet',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
