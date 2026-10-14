import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/cart_page/widgets/bill_summary_widget.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/get_my_order/get_my_order_event.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/re_order/re_order_bloc.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/return_order_item/return_order_item_bloc.dart';
import 'package:hyper_commerce/screens/my_orders/bloc/download_invoice/download_invoice_bloc.dart';
import 'package:hyper_commerce/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_commerce/screens/my_orders/model/order_status.dart';
import 'package:hyper_commerce/screens/my_orders/widgets/order_action_bar.dart';
import 'package:hyper_commerce/screens/my_orders/widgets/order_address_card.dart';
import 'package:hyper_commerce/screens/my_orders/widgets/order_meta_card.dart';
import 'package:hyper_commerce/screens/my_orders/widgets/order_track_card.dart';
import 'package:hyper_commerce/screens/my_orders/widgets/inline_rate_product_card.dart';
import 'package:hyper_commerce/screens/my_orders/widgets/item_refund_card.dart';
import 'package:hyper_commerce/screens/my_orders/widgets/return_item_bottom_sheet.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/whole_page_progress.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/order_detail/order_detail_bloc.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class OrderItemDetailPage extends StatefulWidget {
  final String orderSlug;
  final int? orderItemId;

  const OrderItemDetailPage({
    super.key,
    required this.orderSlug,
    this.orderItemId,
  });

  @override
  State<OrderItemDetailPage> createState() => _OrderItemDetailPageState();
}

class _OrderItemDetailPageState extends State<OrderItemDetailPage> {
  final GlobalKey _otherItemsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  int? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _selectedItemId = widget.orderItemId;
    _fetchOrder();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectItem(OrderItems item) {
    if (item.id == _selectedItemId) return;
    setState(() => _selectedItemId = item.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchOrder() async {
    if (!mounted) return;
    context
        .read<OrderDetailBloc>()
        .add(FetchOrderDetail(orderSlug: widget.orderSlug));
  }

  Future<void> _launchInvoice(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _rateProduct(
      OrderDetailData order, OrderItems item, int initialRating) async {
    if (item.id == null) return;
    final reviewed = item.isUserReviewGiven == true;
    final image = (item.variant?.image?.isNotEmpty ?? false)
        ? item.variant!.image
        : item.product?.image;
    final result = await GoRouter.of(context).push<bool>(
      AppRoutes.productRating,
      extra: {
        'orderItemId': item.id,
        'productName': item.title ?? item.product?.name,
        'variantTitle': item.variantTitle,
        'image': image,
        'initialRating':
            reviewed ? (item.userReview?.rating ?? initialRating) : initialRating,
        'initialTitle': item.userReview?.title,
        'initialComment': item.userReview?.comment,
        'feedbackId': reviewed ? item.userReview?.id : null,
      },
    );
    if (result == true && mounted) _fetchOrder();
  }

  void _startReturnItem(OrderDetailData order, OrderItems item) {
    ReturnItemBottomSheet.show(
      context,
      item: item,
      orderSlug: order.slug ?? widget.orderSlug,
    );
  }

  Future<void> _rateSeller(OrderDetailData order, OrderItems item) async {
    final sellerId = item.sellerId;
    if (sellerId == null || item.id == null) return;
    SellerFeedbackData? existing;
    for (final sf in order.sellerFeedbacks) {
      if (sf.sellerId == sellerId &&
          sf.isFeedbackGiven == true &&
          sf.feedback != null) {
        existing = sf.feedback;
        break;
      }
    }
    final result = await GoRouter.of(context).push<bool>(
      AppRoutes.sellerRating,
      extra: {
        'sellerId': sellerId,
        'orderItemId': item.id,
        'storeName': item.store?.name ?? item.sellerName ?? '',
        'initialRating': existing?.rating ?? 0,
        'initialTitle': existing?.title,
        'initialComment': existing?.description,
        'feedbackId': existing?.id,
      },
    );
    if (result == true && mounted) _fetchOrder();
  }

  Future<void> _startCancelItem(OrderItems item) async {
    if (item.id == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.cancelItem ?? 'Cancel item'),
        content: Text(l10n?.areYouSureYouWantToCancelThisItem ??
            'Are you sure you want to cancel this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.yes ?? 'Yes'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ReturnOrderItemBloc>().add(CancelOrderItem(orderItemId: item.id!));
    }
  }

  Future<void> _startCancelReturn(OrderDetailData order, OrderItems item) async {
    if (item.id == null) return;
    final l10n = AppLocalizations.of(context);
    final request = _pendingReturn(item);
    final reqQty = request?.quantity ?? 0;
    final totalQty = item.quantity ?? 0;
    final refund = request?.refundAmount;

    final details = <String>[
      if (reqQty > 0)
        '${l10n?.qty ?? 'Qty'}: '
            '${totalQty > 0 ? '$reqQty / $totalQty' : '$reqQty'}',
      if (refund != null && refund > 0)
        '${l10n?.refundLabel ?? 'Refund'}: ${_money(order, refund.toDouble())}',
    ].join('\n');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.cancelReturnRequest ?? 'Cancel return request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.areYouSureYouWantToCancelThisReturnRequest ??
                'Are you sure you want to cancel this return request?'),
            if (details.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                details,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.yes ?? 'Yes'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context
          .read<ReturnOrderItemBloc>()
          .add(CancelReturnRequest(orderItemId: item.id!));
    }
  }

  void _scrollToOtherItems() {
    final ctx = _otherItemsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onReturnState(BuildContext context, ReturnOrderItemState state) {
    if (state is ReturnOrderItemSuccess) {
      ToastManager.show(context: context, message: state.message);
      _fetchOrder();
      context.read<GetMyOrderBloc>().add(RefreshMyOrders());
    } else if (state is ReturnOrderItemFailed) {
      ToastManager.show(
        context: context,
        message: state.error,
        type: ToastType.error,
      );
    }
  }

  void _onReOrderState(BuildContext context, ReOrderState state) {
    if (state is ReOrderedSuccess) {
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push(AppRoutes.cart);
      });
    } else if (state is ReOrderedFailed) {
      ToastManager.show(
        context: context,
        message: state.errorList.join('\n\n'),
        type: ToastType.error,
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<ReturnOrderItemBloc, ReturnOrderItemState>(
          listener: _onReturnState,
        ),
        BlocListener<ReOrderBloc, ReOrderState>(listener: _onReOrderState),
      ],
      child: Stack(
        children: [
          BlocBuilder<OrderDetailBloc, OrderDetailState>(
            builder: (context, state) {
              final order = _orderOf(state);
              final status = order == null
                  ? OrderStatus.unknown
                  : OrderStatusX.fromString(order.fulfillmentStatus);
              return CustomScaffold(
                showViewCart: false,
                showAppBar: true,
                title: l10n?.orderDetails ?? 'Order Details',
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                appBarActions: [
                  TextButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.supportPage,
                      extra: {'order-id': order?.id},
                    ),
                    icon: Icon(Icons.headset_mic_outlined, size: 16.sp),
                    label: Text(l10n?.help ?? 'Help'),
                  ),
                ],
                body: TabletConstrainedBody(
        child: CustomRefreshIndicator(
                  onRefresh: _fetchOrder,
                  child: _buildBody(context, state, l10n),
                ),
      ),
                bottomNavigationBar: order == null
                    ? null
                    : OrderActionBar(
                        order: order,
                        status: status,
                      ),
              );
            },
          ),
          BlocSelector<DownloadInvoiceBloc, DownloadInvoiceState, bool>(
            selector: (s) => s is DownloadInvoiceLoading,
            builder: (context, downloading) {
              return BlocSelector<ReOrderBloc, ReOrderState, bool>(
                selector: (s) => s is ReOrderInProgress,
                builder: (context, reOrdering) {
                  final show = downloading || reOrdering;
                  return AnimatedOpacity(
                    opacity: show ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child:
                        show ? const WholePageProgress() : const SizedBox.shrink(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  OrderDetailData? _orderOf(OrderDetailState state) {
    if (state is OrderDetailLoaded && state.cartData.isNotEmpty) {
      return state.cartData.first.data;
    }
    return null;
  }

  Widget _buildBody(
      BuildContext context, OrderDetailState state, AppLocalizations? l10n) {
    if (state is OrderDetailLoading || state is OrderDetailInitial) {
      return const CustomCircularProgressIndicator();
    }
    final order = _orderOf(state);
    if (order == null || order.items.isEmpty) {
      return _ErrorView(
        message: l10n?.failedToLoadOrderDetails ?? "Couldn't load order details",
        onRetry: _fetchOrder,
      );
    }

    final featured = order.items.firstWhere(
      (e) => e.id == _selectedItemId,
      orElse: () => order.items.first,
    );
    final others = order.items.where((e) => e.id != featured.id).toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedFeatured(
            itemId: featured.id,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeaturedItemCard(
                  order: order,
                  item: featured,
                  onCancel: () => _startCancelItem(featured),
                  onReturn: () => _startReturnItem(order, featured),
                  onCancelReturn: () => _startCancelReturn(order, featured),
                ),
                if (featured.timeline.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  OrderTrackCard(stages: featured.timeline),
                ],
                if (ItemRefundCard.hasRefund(featured)) ...[
                  SizedBox(height: 10.h),
                  ItemRefundCard(order: order, item: featured),
                ],
                if (others.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  _MoreItemsRow(
                    others: others,
                    onTap: _scrollToOtherItems,
                    label: l10n?.moreItemsInThisOrder(others.length) ??
                        '${others.length} more items in this order',
                  ),
                ],
                if (InlineRateProductCard.shouldShow(featured)) ...[
                  SizedBox(height: 10.h),
                  InlineRateProductCard(
                    item: featured,
                    onRate: (initial) => _rateProduct(order, featured, initial),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          OrderAddressCard(
            address: order.shippingAddress1 ?? '',
            mobile: order.shippingPhone ?? '',
          ),
          SizedBox(height: 10.h),
          if (others.isEmpty)
            _BillDetailsCard(
              order: order,
              item: featured,
              onGetInvoice: () => _launchInvoice(order.invoice),
              onRateSeller: () => _rateSeller(order, featured),
            )
          else
            _ItemPriceCard(
              key: ValueKey('price-${featured.id}'),
              order: order,
              item: featured,
              onGetInvoice: () => _launchInvoice(order.invoice),
              onRateSeller: () => _rateSeller(order, featured),
            ),
          if (others.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _OtherItemsCard(
              key: _otherItemsKey,
              order: order,
              others: others,
              onViewBreakup: () => _showBillBreakup(order),
              onItemTap: _selectItem,
            ),
          ],
          SizedBox(height: 10.h),
          _OrderSavingsBanner(order: order),
          SizedBox(height: 10.h),
          OrderMetaCard(
            orderId: order.id?.toString() ?? '',
            paymentMethod: order.paymentMethod ?? '',
            createdAt: order.createdAt,
            invoiceUrl: order.invoice,
            onDownloadInvoice: () => _launchInvoice(order.invoice),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  void _showBillBreakup(OrderDetailData order) {
    final totalPayable = double.tryParse(order.totalPayable ?? '');
    final subtotal = double.tryParse(order.subtotal ?? '');
    final deliveryCharge = double.tryParse(order.deliveryCharge ?? '');
    final finalTotal = double.tryParse(order.finalTotal ?? '');
    final promoDiscount = double.tryParse(order.promoDiscount ?? '0.0') ?? 0.0;
    final platformFee = double.tryParse(order.platformFee ?? '0.0') ?? 0.0;
    if (totalPayable == null ||
        subtotal == null ||
        deliveryCharge == null ||
        finalTotal == null) {
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: BillSummaryWidget(
          itemsOriginalPrice: 0,
          itemsDiscountedPrice: subtotal,
          itemsSavings: 0,
          deliveryChargeOriginal: deliveryCharge,
          grandTotal: finalTotal,
          totalSavings: 0,
          isFromOrderDetail: true,
          downloadInvoice: () => _launchInvoice(order.invoice),
          promoCode: order.promoCode?.toString(),
          promoDiscount: promoDiscount,
          totalPayable: totalPayable,
          currencySymbol: order.currencySymbol,
          format: order.format,
          platformFee: platformFee,
          paymentMethod: order.paymentMethod,
        ),
      ),
    );
  }
}

String _money(OrderDetailData order, double value) {
  final symbol = (order.currencySymbol == null || order.currencySymbol!.isEmpty)
      ? '₹'
      : order.currencySymbol!;
  return '$symbol${formatPrice(value)}';
}

Color _statusColor(BuildContext context, String? code) {
  switch ((code ?? '').toLowerCase()) {
    case 'delivered':
    case 'fulfilled':
    case 'completed':
      return context.appColors.success;
    case 'cancelled':
    case 'canceled':
      return Theme.of(context).colorScheme.error;
    case 'refunded':
    case 'returned':
      return const Color(0xFF7C5CFC);
    default:
      return context.appColors.info;
  }
}

/*String? _timelineDate(OrderItems item) {
  OrderTimelineStage? picked;
  for (final s in item.timeline) {
    if (s.current == true && (s.at ?? '').isNotEmpty) picked = s;
  }
  picked ??= item.timeline.lastWhere(
    (s) => s.done == true && (s.at ?? '').isNotEmpty,
    orElse: () => OrderTimelineStage(),
  );
  final at = picked.at;
  if (at == null || at.isEmpty) return null;
  return formatDateTime(DateTime.tryParse(at));
}*/

bool _returnDeadlineCrossed(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final deadline = DateTime.tryParse(raw);
  if (deadline == null) return false;
  return DateTime.now().isAfter(deadline);
}

String? _formatReturnDeadline(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateFormat('EEE, d MMM yyyy').format(parsed.toLocal());
}

bool _isItemDelivered(OrderItems item) => _itemStatusCode(item) == 'delivered';

/// Statuses past which a delivery estimate is meaningless or misleading.
const Set<String> _noDeliveryEstimateStatuses = {
  'delivered',
  'fulfilled',
  'completed',
  'cancelled',
  'canceled',
  'returned',
  'refunded',
  'rejected',
  'return_requested',
};

String _itemStatusCode(OrderItems item) =>
    (item.orderItemCustomerStatus?.code ?? item.status ?? '').toLowerCase().trim();

bool _isSameCalendarDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

String? _etaRangeText(int? min, int? max, String? rawUnit) {
  if (min == null && max == null) return null;
  final unit = rawUnit?.trim() ?? '';
  final range = (min != null && max != null && min != max)
      ? '$min-$max'
      : '${min ?? max}';
  return unit.isEmpty ? range : '$range $unit';
}

/// Renders the server window as dates, or as a numeric range if it sends offsets.
String? _deliveryWindowText(DeliveryEst? est) {
  if (est == null || est.isEmpty) return null;

  final fromRaw = est.from?.trim() ?? '';
  final toRaw = est.to?.trim() ?? '';
  final from = DateTime.tryParse(fromRaw);
  final to = DateTime.tryParse(toRaw);

  if (from != null || to != null) {
    final start = from ?? to!;
    final end = to ?? from!;
    if (_isSameCalendarDay(start, end)) {
      return DateFormat('EEE, d MMM yyyy').format(start.toLocal());
    }
    return '${DateFormat('d MMM').format(start.toLocal())} - '
        '${DateFormat('d MMM yyyy').format(end.toLocal())}';
  }

  return _etaRangeText(int.tryParse(fromRaw), int.tryParse(toRaw), est.unit);
}

/// Prefers the server delivery window; falls back to the structured eta range.
String? _deliveryEstimateText(OrderItems item) =>
    _deliveryWindowText(item.deliveryEstimate) ??
    _etaRangeText(item.etaMin, item.etaMax, item.etaUnit);

bool _showsDeliveryEstimate(OrderItems item) =>
    !_noDeliveryEstimateStatuses.contains(_itemStatusCode(item)) &&
    _deliveryEstimateText(item) != null;

int _returnableQty(OrderItems item) =>
    item.returnableQuantity ?? item.quantity ?? 0;

bool _isPendingReturnStatus(String? s) {
  final v = (s ?? '').toLowerCase().trim();
  return v == 'return_requested' ||
      v == 'requested' ||
      v == 'return_pending' ||
      v == 'pending' ||
      v == 'return_initiated' ||
      v == 'initiated';
}

/// The return the seller hasn't acted on yet — still cancelable by the customer.
ItemReturn? _pendingReturn(OrderItems item) {
  for (final r in item.returns) {
    if (_isPendingReturnStatus(r.returnStatus) ||
        _isPendingReturnStatus(r.returnItemCustomerStatus?.code)) {
      return r;
    }
  }
  return null;
}

bool _hasPendingReturn(OrderItems item) => _pendingReturn(item) != null;

bool _canReturnItem(OrderItems item) =>
    _isItemDelivered(item) &&
    item.returnEligible == true &&
    _returnableQty(item) > 0 &&
    !_returnDeadlineCrossed(item.returnDeadline) &&
    !_hasPendingReturn(item);

bool _canCancelReturn(OrderItems item) => _hasPendingReturn(item);

bool _canCancelItem(OrderItems item) => item.canCancel == true;

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _CardShell({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: child,
    );
  }
}

class _AnimatedFeatured extends StatelessWidget {
  final int? itemId;
  final Widget child;

  const _AnimatedFeatured({required this.itemId, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: KeyedSubtree(key: ValueKey(itemId), child: child),
    );
  }
}

class _FeaturedItemCard extends StatelessWidget {
  final OrderDetailData order;
  final OrderItems item;
  final VoidCallback onCancel;
  final VoidCallback onReturn;
  final VoidCallback onCancelReturn;

  const _FeaturedItemCard({
    required this.order,
    required this.item,
    required this.onCancel,
    required this.onReturn,
    required this.onCancelReturn,
  });

  @override
  Widget build(BuildContext context) {
    final image = (item.variant?.image?.isNotEmpty ?? false)
        ? item.variant!.image!
        : (item.product?.image ?? '');
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(context, item.orderItemCustomerStatus?.code ?? item.status);
    final statusAt = DateTime.tryParse(item.orderItemCustomerStatus?.at ?? '');
    final date = statusAt == null ? '' : formatDateTime(statusAt);
    final deliveryEstimate =
        _showsDeliveryEstimate(item) ? _deliveryEstimateText(item) : null;
    final estimateLabel = l10n?.estimatedDelivery ?? 'Estimated delivery';

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: (){
                  GoRouter.of(context).push(
                      AppRoutes.productDetailPage,
                      extra: {
                        'productSlug': item.product?.slug ?? '',
                      }
                  );
                },
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: image.isNotEmpty
                      ? CustomImageContainer(imagePath: image, fit: BoxFit.cover)
                      : Icon(Icons.image_outlined,
                          size: 28.sp, color: Colors.grey.shade400),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.product?.brand ?? item.product?.category ?? '',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C5CFC).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              item.product!.category ?? '',
                              maxLines: 1,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C5CFC),
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: (){
                        GoRouter.of(context).push(
                            AppRoutes.productDetailPage,
                            extra: {
                              'productSlug': item.product?.slug ?? '',
                            }
                        );
                      },
                      child: Text(
                        item.title ?? item.product?.name ?? 'Unknown',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 3,
                      ),
                    ),
                    if ((item.addons).isNotEmpty) ...[
                      SizedBox(height: 0.h),
                      Text(
                        item.addons
                            .map((e) => capitalizeFirstLetter(e.item?.title ?? ''))
                            .where((e) => e.isNotEmpty)
                            .join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        if ((item.variantTitle ?? '').isNotEmpty)
                          _MiniChip(text: item.variantTitle!),
                        _MiniChip(text: 'Qty: ${item.quantity ?? 1}'),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Order ID #${order.id ?? ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.attachments.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _buildAttachmentsSection(item, context),
          ],
          SizedBox(height: 12.h),
          const Divider(height: 1),
          SizedBox(height: 10.h),
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                item.orderItemCustomerStatus?.label ?? item.statusLabel ?? '',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              if (date.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    date,
                    style: AppTextStyles.label.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (deliveryEstimate != null) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  TablerIcons.truck_delivery,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  '$estimateLabel: ',
                  style: AppTextStyles.label.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    deliveryEstimate,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_isItemDelivered(item) && item.returnEligible == true) ...[
            SizedBox(height: 8.h),
            _ReturnWindowNote(
              closed: _returnDeadlineCrossed(item.returnDeadline),
              deadlineText: _formatReturnDeadline(item.returnDeadline),
            ),
          ],
          if (_pendingReturn(item) != null) ...[
            SizedBox(height: 8.h),
            _PendingReturnInfo(
              order: order,
              item: item,
              request: _pendingReturn(item)!,
            ),
          ],
          if (_canCancelItem(item) ||
              _canReturnItem(item) ||
              _canCancelReturn(item)) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                if (_canCancelItem(item))
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.cancelItem ??
                            'Cancel item',
                      ),
                    ),
                  ),
                if (_canCancelItem(item) &&
                    (_canReturnItem(item) || _canCancelReturn(item)))
                  SizedBox(width: 10.w),
                if (_canReturnItem(item))
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReturn,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.returnButton ?? 'Return',
                      ),
                    ),
                  ),
                if (_canCancelReturn(item))
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancelReturn,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.cancelReturnRequest ??
                            'Cancel return request',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const Set<String> _imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif',
  };

  String _extensionOf(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  bool _isImageUrl(String url) => _imageExtensions.contains(_extensionOf(url));

  String _getFileNameFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    if (segments.isEmpty) return url;
    return segments.last.isEmpty ? url : segments.last;
  }

  String _getFileTypeFromUrl(String url) {
    final ext = _extensionOf(url);
    return ext.isEmpty ? 'File' : ext.toUpperCase();
  }

  Widget _buildFileIcon(String url) {
    final ext = _extensionOf(url);
    IconData icon;
    Color color;
    switch (ext) {
      case 'pdf':
        icon = Icons.picture_as_pdf_rounded;
        color = Colors.redAccent;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description_rounded;
        color = Colors.blueAccent;
        break;
      case 'xls':
      case 'xlsx':
      case 'csv':
        icon = Icons.table_chart_rounded;
        color = Colors.green;
        break;
      case 'zip':
      case 'rar':
      case '7z':
        icon = Icons.folder_zip_rounded;
        color = Colors.orange;
        break;
      case 'mp4':
      case 'mov':
      case 'avi':
        icon = Icons.videocam_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.insert_drive_file_rounded;
        color = Colors.grey.shade600;
    }
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Icon(icon, color: color, size: 26.sp),
    );
  }

  Future<void> _openAttachment(String url, BuildContext context) async {
    if (url.isEmpty) return;
    if (_isImageUrl(url)) {
      _showImagePreview(url, context);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      ToastManager.show(
        context: context,
        message: 'Invalid attachment link',
        type: ToastType.error,
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ToastManager.show(
        context: context,
        message: 'Could not open attachment',
        type: ToastType.error,
      );
    }
  }

  void _showImagePreview(String url, BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(12.w),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: CustomImageContainer(
                  imagePath: url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(OrderItems item, BuildContext context) {
    // Safety check: no attachments or empty
    if (item.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Flatten all URLs from nested list
    final allUrls = item.attachments.where((url) => url.isNotEmpty && url.trim().isNotEmpty).toList();

    if (allUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDarkMode(context) ? Colors.grey.shade800.withValues(alpha: 0.4) : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heade
          Row(
            children: [
              Icon(
                TablerIcons.paperclip,
                size: 14.sp,
                color: Colors.grey.shade500,
              ),
              SizedBox(width: 6.w),
              Text(
                'Attachments (${allUrls.length})',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode(context) ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // List of attachments
          ...allUrls.map((url) {
            final isImage = _isImageUrl(url);
            final fileName = _getFileNameFromUrl(url);

            return GestureDetector(
              onTap: () => _openAttachment(url, context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Preview / Icon
                    if (isImage)
                      CustomImageContainer(
                        imagePath: url,
                        width: 32.w,
                        height: 32.w,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(6.r),
                        errorWidget: _buildFileIcon(url),
                      )
                    else
                      _buildFileIcon(url),

                    SizedBox(width: 12.w),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isImage ? 'Image' : _getFileTypeFromUrl(url),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Open icon
                    Icon(
                      TablerIcons.external_link,
                      size: 18.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }


}

/// Summary of a pending (still-cancelable) return request — shows the user
/// exactly what they'd be canceling: status, quantity and refund amount.
class _PendingReturnInfo extends StatelessWidget {
  final OrderDetailData order;
  final OrderItems item;
  final ItemReturn request;

  const _PendingReturnInfo({
    required this.order,
    required this.item,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final statusText =
        request.returnItemCustomerStatus?.label ?? 'Return requested';
    final reqQty = request.quantity ?? 0;
    final totalQty = item.quantity ?? 0;
    final qtyText = totalQty > 0 ? '$reqQty / $totalQty' : '$reqQty';
    final refund = request.refundAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: scheme.outlineVariant),
        SizedBox(height: 8.h),
        Text(
          statusText,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4.h),
        _row(l10n?.qty ?? 'Qty', qtyText, scheme),
        if (refund != null && refund > 0) ...[
          SizedBox(height: 2.h),
          _row(l10n?.refundLabel ?? 'Refund',
              _money(order, refund.toDouble()), scheme),
        ],
      ],
    );
  }

  Widget _row(String label, String value, ColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.label.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReturnWindowNote extends StatelessWidget {
  final bool closed;
  final String? deadlineText;

  const _ReturnWindowNote({required this.closed, this.deadlineText});

  @override
  Widget build(BuildContext context) {
    if (!closed && (deadlineText == null || deadlineText!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final color =
        closed ? Theme.of(context).colorScheme.error : Colors.grey.shade600;
    final text = closed
        ? (l10n?.returnWindowClosed ?? 'Return window closed')
        : (l10n?.returnWindowCloses(deadlineText!) ??
            'Return window closes ${deadlineText!}');
    return Row(
      children: [
        Icon(
          closed ? Icons.cancel_outlined : Icons.schedule_outlined,
          size: 16.sp,
          color: color,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  const _MiniChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _MoreItemsRow extends StatelessWidget {
  final List<OrderItems> others;
  final VoidCallback onTap;
  final String label;

  const _MoreItemsRow({
    required this.others,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final thumbs = others.take(3).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: _CardShell(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            SizedBox(
              width: (thumbs.length * 20 + 16).w,
              height: 36.w,
              child: Stack(
                children: [
                  for (int i = 0; i < thumbs.length; i++)
                    Positioned(
                      left: (i * 20).w,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _thumb(thumbs[i]),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20.sp, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _thumb(OrderItems item) {
    final url = (item.variant?.image?.isNotEmpty ?? false)
        ? item.variant!.image!
        : (item.product?.image ?? '');
    if (url.isEmpty) {
      return Icon(Icons.image_outlined, size: 16.sp, color: Colors.grey.shade400);
    }
    return CustomImageContainer(imagePath: url, fit: BoxFit.cover);
  }
}

class _OrderSavingsBanner extends StatelessWidget {
  final OrderDetailData order;

  const _OrderSavingsBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final promo = double.tryParse(order.promoDiscount ?? '') ?? 0;
    final giftCard = double.tryParse(order.giftCardDiscount ?? '') ?? 0;
    final savings = promo + giftCard;
    if (savings <= 0) return const SizedBox.shrink();
    final amount = _money(order, savings);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF7C5CFC).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded,
              size: 16.sp, color: const Color(0xFF7C5CFC)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              l10n?.youSavedOnThisOrder(amount) ??
                  'You saved $amount on this order',
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5E3BD6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemPriceCard extends StatefulWidget {
  final OrderDetailData order;
  final OrderItems item;
  final VoidCallback onGetInvoice;
  final VoidCallback onRateSeller;

  const _ItemPriceCard({
    super.key,
    required this.order,
    required this.item,
    required this.onGetInvoice,
    required this.onRateSeller,
  });

  @override
  State<_ItemPriceCard> createState() => _ItemPriceCardState();
}

class _ItemPriceCardState extends State<_ItemPriceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final order = widget.order;
    final item = widget.item;
    final price = double.tryParse(item.price ?? '') ?? 0;
    final qty = (item.quantity ?? 1);
    final sub = double.tryParse(item.subtotal ?? '') ?? 0;
    final tax = double.tryParse(item.taxAmount ?? '') ?? 0;
    final discount = double.tryParse(item.discount ?? '') ?? 0;
    final soldBy = item.sellerName ?? item.store?.name ?? '';
    final sellerRated = order.sellerFeedbacks.any(
        (sf) => sf.sellerId == item.sellerId && sf.isFeedbackGiven == true);

    return _CardShell(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Text(
                    l10n?.totalItemPrice ?? 'Total Item Price',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _money(order, sub),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20.sp,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              child: Column(
                children: [
                  _priceLine('${item.title ?? ''} x $qty', _money(order, sub > 0 ? sub : price * qty)),
                  if (discount > 0)
                    _priceLine(l10n?.discount ?? 'Discount',
                        '-${_money(order, discount)}'),
                  if (tax > 0)
                    _priceLine(l10n?.tax ?? 'Tax', _money(order, tax)),
                ],
              ),
            ),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C5CFC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    (order.paymentMethod ?? '').toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C5CFC),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${l10n?.paidBy ?? 'Paid By'} ${order.paymentMethod ?? ''}',
                  style: AppTextStyles.label.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (soldBy.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n?.soldBy ?? 'Sold by'}: $soldBy',
                      style: AppTextStyles.label.copyWith(
                          color: Colors.grey.shade600),
                    ),
                  ),
                  if (item.sellerId != null)
                    GestureDetector(
                      onTap: widget.onRateSeller,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        sellerRated
                            ? (l10n?.editRating ?? 'Edit rating')
                            : (l10n?.rateSeller ?? 'Rate seller'),
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onGetInvoice,
                icon: Icon(Icons.receipt_long_outlined, size: 16.sp),
                label: Text(l10n?.getInvoice ?? 'Get Invoice'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceLine(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: Colors.grey.shade700),
            ),
          ),
          Text(value,
              style: AppTextStyles.label.copyWith(color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class _BillDetailsCard extends StatelessWidget {
  final OrderDetailData order;
  final OrderItems item;
  final VoidCallback onGetInvoice;
  final VoidCallback onRateSeller;

  const _BillDetailsCard({
    required this.order,
    required this.item,
    required this.onGetInvoice,
    required this.onRateSeller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final qty = item.quantity ?? 1;
    final price = double.tryParse(item.price ?? '') ?? 0;
    final sub = double.tryParse(item.subtotal ?? '') ?? 0;
    final itemOriginal = price * qty;
    final delivery = double.tryParse(order.deliveryCharge ?? '') ?? 0;
    final platformFee = double.tryParse(order.platformFee ?? '') ?? 0;
    final promo = double.tryParse(order.promoDiscount ?? '') ?? 0;
    final giftCard = double.tryParse(order.giftCardDiscount ?? '') ?? 0;
    final grand = double.tryParse(order.finalTotal ?? '') ?? 0;
    final discount = (itemOriginal - sub) + promo + giftCard;
    final soldBy = item.sellerName ?? item.store?.name ?? '';
    final sellerRated = order.sellerFeedbacks.any(
        (sf) => sf.sellerId == item.sellerId && sf.isFeedbackGiven == true);

    return _CardShell(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 6.h),
            child: Text(
              l10n?.billDetails ?? 'Bill details',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 8.h),
            child: Column(
              children: [
                _line('${item.title ?? ''} x $qty', _money(order, itemOriginal)),
                if (delivery > 0)
                  _line(l10n?.deliveryCharge ?? 'Delivery charge',
                      _money(order, delivery)),
                if (platformFee > 0)
                  _line(l10n?.platformFee ?? 'Platform fee',
                      _money(order, platformFee)),
                if (discount > 0.009)
                  _line(l10n?.discount ?? 'Discount',
                      '-${_money(order, discount)}',
                      valueColor: context.appColors.success),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Divider(height: 1, color: scheme.outline),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.grandTotal ?? 'Grand total',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      _money(order, grand),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outline),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C5CFC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    (order.paymentMethod ?? '').toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C5CFC),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${l10n?.paidBy ?? 'Paid By'} ${order.paymentMethod ?? ''}',
                  style: AppTextStyles.label.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (soldBy.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n?.soldBy ?? 'Sold by'}: $soldBy',
                      style: AppTextStyles.label.copyWith(
                          color: Colors.grey.shade600),
                    ),
                  ),
                  if (item.sellerId != null)
                    GestureDetector(
                      onTap: onRateSeller,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        sellerRated
                            ? (l10n?.editRating ?? 'Edit rating')
                            : (l10n?.rateSeller ?? 'Rate seller'),
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onGetInvoice,
                icon: Icon(Icons.receipt_long_outlined, size: 16.sp),
                label: Text(l10n?.getInvoice ?? 'Get Invoice'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: Colors.grey.shade700),
            ),
          ),
          Text(value,
              style: AppTextStyles.label.copyWith(
                  color: valueColor ?? Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class _OtherItemsCard extends StatelessWidget {
  final OrderDetailData order;
  final List<OrderItems> others;
  final VoidCallback onViewBreakup;
  final ValueChanged<OrderItems> onItemTap;

  const _OtherItemsCard({
    super.key,
    required this.order,
    required this.others,
    required this.onViewBreakup,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = double.tryParse(order.finalTotal ?? '') ?? 0;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.otherItemsInThisDelivery ?? 'Other items in this delivery',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Order ID #${order.id ?? ''}',
            style: AppTextStyles.caption.copyWith(color: Colors.grey.shade500),
          ),
          SizedBox(height: 10.h),
          if (others.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Text(
                '—',
                style: AppTextStyles.label.copyWith(color: Colors.grey.shade500),
              ),
            )
          else
            for (final o in others)
              _OtherItemRow(item: o, onTap: () => onItemTap(o)),
          Divider(height: 18.h, color: Theme.of(context).colorScheme.outline),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.totalAmount ?? 'Total amount',
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.grey.shade500),
                  ),
                  Text(
                    _money(order, total),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewBreakup,
                child: Text(l10n?.viewBreakup ?? 'View Breakup'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtherItemRow extends StatelessWidget {
  final OrderItems item;
  final VoidCallback onTap;
  const _OtherItemRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = (item.variant?.image?.isNotEmpty ?? false)
        ? item.variant!.image!
        : (item.product?.image ?? '');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: url.isEmpty
                ? Icon(Icons.image_outlined,
                    size: 18.sp, color: Colors.grey.shade400)
                : CustomImageContainer(imagePath: url, fit: BoxFit.cover),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? item.product?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if ((item.variantTitle ?? '').isNotEmpty)
                  Text(
                    item.variantTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.label.copyWith(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18.sp, color: Colors.grey.shade400),
        ],
      ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 36.sp, color: scheme.onSurfaceVariant),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n?.retryLabel ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
