import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/payment_config.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/price_utils.dart';
import 'package:hyper_commerce/utils/widgets/whole_page_progress.dart';
import '../../../services/address/selected_address_hive.dart';
import '../../../services/market/market_service.dart';
import '../../address_list_page/model/get_address_list_model.dart';
import '../../my_orders/bloc/create_order/create_order_bloc.dart';
import '../bloc/attachment/attachment_bloc.dart';
import '../bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/promo_code/promo_code_bloc.dart';
import '../bloc/promo_code/promo_code_event.dart';
import '../model/get_cart_model.dart';
import '../widgets/address_selection_bottom_sheet.dart';
import '../widgets/bill_summary_widget.dart';
import '../widgets/cart_product_item.dart';
import '../widgets/delivery_address_widget.dart';
import '../widgets/wallet_usage_widget.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class OrderConfirmationPage extends StatefulWidget {
  final AddressListData? selectedAddress;
  final String? promoCode;
  final bool useWallet;

  const OrderConfirmationPage({
    super.key,
    this.selectedAddress,
    this.promoCode,
    this.useWallet = false,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  AddressListData? _selectedAddress;
  String? _promoCode;
  bool _userWantsWallet = false;

  String? _selectedPaymentMethodId;
  final String _orderNote = '';

  /// One key per Place-Order press; guards a timed-out create call from
  /// duplicating the order if the request is retried.
  String? _idempotencyKey;

  bool _busy = false;
  bool _deliveryExpanded = true;
  bool _amountExpanded = true;
  bool _paymentExpanded = true;

  /// Last successfully-loaded cart so the body keeps showing prices and data
  /// while a refetch (address change / wallet toggle) is in flight.
  List<CartModel>? _lastCartData;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.selectedAddress;
    _promoCode = widget.promoCode;
    _userWantsWallet = widget.useWallet;
  }

  void _refetchCart() {
    context.read<GetUserCartBloc>().add(FetchUserCart(
          addressId: _selectedAddress?.id,
          useWallet: _userWantsWallet,
          promoCode: _promoCode ?? '',
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.orderConfirmation,
          style: AppTextStyles.titleLarge.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
      ),
      body: TabletConstrainedBody(
        child: BlocListener<CreateOrderBloc, CreateOrderState>(
        listener: _onCreateOrderState,
        child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
          builder: (context, state) {
            // Keep the most recent cart so the body stays intact during a
            // refetch; only swap in fresh data once it actually loads.
            if (state is GetUserCartLoaded && state.cartData.isNotEmpty) {
              _lastCartData = state.cartData;
            } else if (state is GetUserCartUpdating &&
                state.cartData.isNotEmpty) {
              _lastCartData = state.cartData;
            }

            final cartData = _lastCartData;
            final bool cartLoading = state is GetUserCartLoading ||
                state is UserCartInitialLoading ||
                state is GetUserCartInitial;

            return Stack(
              children: [
                if (cartData != null && cartData.isNotEmpty)
                  _buildContent(
                    l10n,
                    theme,
                    cartData.first.data?.paymentSummary,
                    cartData.first.data?.items ?? [],
                    cartLoading,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                if ((cartLoading && cartData != null) || _busy)
                  const WholePageProgress(),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, ThemeData theme,
      PaymentSummary? summary, List<CartItem> items, bool loading) {
    final String formattedPayable =
        _fmt(summary?.payableAmount?.toDouble() ?? 0.0, summary);

    return ListView(
      padding: EdgeInsets.only(bottom: 24.h),
      children: [
        _buildAddressSection(l10n, theme),
        // const TrustSectionWidget(),
        SizedBox(height: 8.h),
        _buildExpectedDeliverySection(l10n, theme, items),
        SizedBox(height: 8.h),
        _buildPromoButton(l10n, theme, summary),
        SizedBox(height: 8.h),
        _buildAmountPayableSection(l10n, theme, summary, formattedPayable),
        SizedBox(height: 8.h),
        _buildPaymentSection(l10n, theme, summary, loading),
      ],
    );
  }

  Widget _buildAddressSection(AppLocalizations l10n, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: DeliveryAddressWidget(
        selectedAddress: _selectedAddress,
        onTap: _changeAddress,
      ),
    );
  }

  void _changeAddress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AddressSelectionBottomSheet(
        selectedAddress: _selectedAddress,
        deliveryZoneId: _deliveryZoneId(),
        onAddressSelected: (address) async {
          if (_selectedAddress == null || address.id != _selectedAddress!.id) {
            setState(() => _selectedAddress = address);
            HiveSelectedAddressHelper.setSelectedAddress(address);
            // Align the active market/country with the chosen address before refetching.
            await MarketService.switchAndCacheForCountry(
              iso2: address.countryCode ?? '',
              fallbackName: address.country,
            );
            if (!mounted) return;
            _refetchCart();
          }
        },
      ),
    );
  }

  int? _deliveryZoneId() {
    final state = context.read<GetUserCartBloc>().state;
    if (state is GetUserCartLoaded && state.cartData.isNotEmpty) {
      final String raw = state.cartData.first.data?.addressId ?? '';
      return raw.isNotEmpty ? int.tryParse(raw) : null;
    }
    return null;
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: child,
    );
  }

  Widget _collapsibleHeader({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
          if (trailing != null) ...[trailing, SizedBox(width: 8.w)],
          Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: theme.colorScheme.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedDeliverySection(
      AppLocalizations l10n, ThemeData theme, List<CartItem> items) {
    final List<_DeliveryGroup> groups = _groupItemsByDelivery(items);
    final bool multipleShipments = groups.length > 1;
    final String? earliest = _earliestDeliveryText(items);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _collapsibleHeader(
            title: l10n.expectedDelivery,
            expanded: _deliveryExpanded,
            onTap: () =>
                setState(() => _deliveryExpanded = !_deliveryExpanded),
            trailing: multipleShipments
                ? Text(
                    l10n.shipmentCount(groups.length),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.tertiary,
                    ),
                  )
                : (earliest == null
                    ? null
                    : Text(
                        earliest,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.tertiary,
                        ),
                      )),
          ),
          if (_deliveryExpanded) ...[
            SizedBox(height: 14.h),
            Divider(height: 1, color: theme.colorScheme.outline),
            SizedBox(height: 14.h),
            for (int i = 0; i < groups.length; i++) ...[
              if (i > 0) ...[
                SizedBox(height: 14.h),
                Divider(height: 1, color: theme.colorScheme.outline),
                SizedBox(height: 14.h),
              ],
              _buildDeliveryGroup(l10n, theme, groups[i], multipleShipments),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryGroup(AppLocalizations l10n, ThemeData theme,
      _DeliveryGroup group, bool showItemCount) {
    final String headerText = group.date != null
        ? l10n.heroArrivingBy(DateFormat('EEE, d MMM').format(group.date!))
        : l10n.checkingDelivery;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: isTablet(context) ? 20 : 18.r,
              color: context.appColors.success,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                headerText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appColors.success,
                ),
              ),
            ),
            if (showItemCount) ...[
              SizedBox(width: 6.w),
              Text(
                '· ${l10n.shipmentItemCount(group.items.length)}',
                style: AppTextStyles.label.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12.h),
        ...group.items
            .map((item) => _buildCompactDeliveryRow(theme, l10n, item)),
      ],
    );
  }

  Widget _buildCompactDeliveryRow(
      ThemeData theme, AppLocalizations l10n, CartItem item) {
    final String brand = item.product?.brand ?? '';
    final String size = item.variant?.title ?? '';
    final List<String> meta = [
      if (brand.isNotEmpty) brand.toUpperCase(),
      if (size.isNotEmpty) l10n.sizeLabel(size),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: theme.colorScheme.surfaceContainer,
              border: Border.all(color: theme.colorScheme.outline, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CustomImageContainer(
                imagePath: item.product?.image ?? '',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                if (meta.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      meta.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoButton(
      AppLocalizations l10n, ThemeData theme, PaymentSummary? summary) {
    return InkWell(
      onTap: () => _openPromoCode(summary),
      child: Container(
        color: theme.colorScheme.surface,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(TablerIcons.rosette_discount_filled,
                color: const Color(0xFF149400), size: isTablet(context) ? 22 : 24.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                l10n.viewCouponOffers,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _openPromoCode(PaymentSummary? summary) async {
    final result = await GoRouter.of(context).push(
      AppRoutes.promoCode,
      extra: {
        'cartAmount': summary?.itemsTotal?.toDouble() ?? 0.0,
        'deliveryCharges': summary?.deliveryCharges?.toDouble() ?? 0.0,
      },
    );
    if (result is String && result.isNotEmpty && mounted) {
      setState(() => _promoCode = result);
      _refetchCart();
    }
  }

  Widget _buildAmountPayableSection(AppLocalizations l10n, ThemeData theme,
      PaymentSummary? summary, String formattedPayable) {
    return _sectionCard(
      child: Column(
        children: [
          _collapsibleHeader(
            title: l10n.amountPayable,
            expanded: _amountExpanded,
            onTap: () => setState(() => _amountExpanded = !_amountExpanded),
            trailing: Text(
              formattedPayable,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
          if (_amountExpanded && summary != null) ...[
            SizedBox(height: 12.h),
            BillSummaryWidget(
              itemsOriginalPrice: 0,
              itemsDiscountedPrice: summary.itemsTotal?.toDouble() ?? 0,
              itemsSavings: 0,
              deliveryChargeOriginal: summary.deliveryCharges?.toDouble() ?? 0,
              platformFee: summary.platformFee?.toDouble() ?? 0,
              codFee: summary.codFee?.toDouble() ?? 0,
              grandTotal: summary.orderTotal?.toDouble() ?? 0,
              totalSavings: summary.totalSavings?.toDouble() ?? 0,
              promoCode: summary.promoCode,
              promoDiscount:
                  double.tryParse(summary.promoDiscount ?? '0') ?? 0.0,
              promoError: summary.promoError,
              removeCoupon: () {
                setState(() => _promoCode = '');
                context.read<PromoCodeBloc>().add(RemovePromoCode());
                _refetchCart();
              },
              promoMode: summary.promoApplied?.promoMode ?? '',
              discountAmount: summary.promoApplied?.discountAmount ?? '',
              promoApplied: summary.promoApplied,
              sellerShippingCosts: summary.sellerShippingCosts,
              taxBreakdown: summary.taxBreakdown,
              taxTotal: summary.taxTotal,
              pendingCharges: summary.pendingCharges,
              pendingChargesTotal: summary.pendingChargesTotal,
              currencySymbol: summary.currencySymbol,
              format: summary.format,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection(AppLocalizations l10n, ThemeData theme,
      PaymentSummary? summary, bool loading) {
    final double payable = summary?.payableAmount?.toDouble() ?? 0.0;
    final bool codAvailable = summary?.codAvailable ?? false;

    final methods = PaymentConfig.getEnabledPaymentMethods().toList();

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _collapsibleHeader(
            title: l10n.payment,
            expanded: _paymentExpanded,
            onTap: () => setState(() => _paymentExpanded = !_paymentExpanded),
          ),
          if (_paymentExpanded) ...[
            SizedBox(height: 8.h),
            WalletUsageWidget(
              isWalletEnabled: _userWantsWallet,
              onWalletToggle: (v) {
                setState(() => _userWantsWallet = v);
                _refetchCart();
              },
              currencySymbol: summary?.currencySymbol,
              format: summary?.format,
            ),
            SizedBox(height: 8.h),
            // Keep gateways visible but disable them when the wallet covers
            // the full amount (nothing left to pay through a gateway).
            ...methods.map(
              (m) => _buildPaymentOption(theme, m, payable <= 0, codAvailable),
            ),
          ],
          SizedBox(height: 16.h),
          _buildPlaceOrderButton(l10n, theme, loading),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      ThemeData theme, PaymentMethod method, bool disabled, bool codAvailable) {
    final l10n = AppLocalizations.of(context)!;

    // Cash on Delivery is disabled when the cart/address doesn't support it.
    final bool isCod = method.type == PaymentMethodType.cod;
    final bool codBlocked = isCod && !codAvailable;
    final bool effectiveDisabled = disabled || codBlocked;

    final bool selected =
        !effectiveDisabled && _selectedPaymentMethodId == method.id;

    return Opacity(
      opacity: effectiveDisabled ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: effectiveDisabled,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPaymentMethodId = method.id;
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color:
                    selected ? AppTheme.primaryColor : theme.colorScheme.outline,
                width: selected ? 1.4 : 0.5,
              ),
            ),
            child: Row(
              children: [
                method.getDisplayWidget(size: 24),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        PaymentConfig.localizedName(context, method),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      if (codBlocked) ...[
                        SizedBox(height: 2.h),
                        Text(
                          l10n.notAvailable,
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? AppTheme.primaryColor
                      : theme.colorScheme.onSecondaryContainer,
                  size: 20.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(
      AppLocalizations l10n, ThemeData theme, bool loading) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: CustomButton(
        isLoading: _busy,
        isDisabled: loading,
        onPressed: _onPlaceOrder,
        child: Text(
          l10n.placeOrder,
          style: AppTextStyles.titleMedium,
        ),
      ),
    );
  }

  String _fmt(double amount, PaymentSummary? summary) {
    if (summary?.format != null) {
      return PriceUtils.formatWithFormat(
          amount, summary!.format!, summary.currencySymbol);
    }
    return PriceUtils.formatWithSymbol(
        amount, summary?.currencySymbol ?? AppHelpers.currency);
  }

  // ---- order placement ----

  double get _payableAmount {
    return _lastCartData?.first.data?.paymentSummary?.payableAmount
            ?.toDouble() ??
        0.0;
  }

  bool get _codAvailable =>
      _lastCartData?.first.data?.paymentSummary?.codAvailable ?? false;

  /// The selected payment method, ignoring a stale COD selection that is no
  /// longer available (e.g. after an address change disabled COD).
  String? get _effectiveSelectedPaymentMethodId {
    if (_selectedPaymentMethodId == 'cod' && !_codAvailable) return null;
    return _selectedPaymentMethodId;
  }

  void _onPlaceOrder() {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (_selectedAddress == null) {
      ToastManager.show(
        context: context,
        message: l10n?.chooseAddressForDelivery ?? 'Choose delivery address',
        type: ToastType.error,
      );
      return;
    }
    final double payable = _payableAmount;
    if (payable > 0 && _effectiveSelectedPaymentMethodId == null) {
      ToastManager.show(
        context: context,
        message: l10n?.selectPaymentMethod ?? 'Select payment method',
        type: ToastType.error,
      );
      return;
    }
    _createOrder();
  }

  /// Order-first: always create the order, then let the response decide.
  /// COD / wallet are confirmed here; online methods hand back a
  /// payment_response and move on to the confirming screen.
  void _createOrder() {
    final attachmentState = context.read<AttachmentBloc>().state;
    final attachments = attachmentState is AttachmentLoaded
        ? attachmentState.attachments
        : <int, List<CartItemAttachment>>{};

    final double payable = _payableAmount;
    final String paymentType =
        payable <= 0 ? 'wallet' : (_effectiveSelectedPaymentMethodId ?? 'wallet');

    _idempotencyKey = generateUuidV4();

    context.read<CreateOrderBloc>().add(CreateOrderRequest(
          paymentType: paymentType,
          addressId: _selectedAddress!.id!,
          promoCode: _promoCode,
          orderNote: _orderNote,
          attachments: attachments,
          useWallet: _userWantsWallet,
          idempotencyKey: _idempotencyKey,
        ));
  }

  void _onCreateOrderState(BuildContext context, CreateOrderState state) {
    if (state is CreateOrderSuccess) {
      setState(() => _busy = false);
      final String? displayAddress = _selectedAddress != null
          ? formatAddressFromModel(_selectedAddress!)
          : null;

      if (state.needsGateway) {
        GoRouter.of(context).pop();
        GoRouter.of(context).push(
          AppRoutes.paymentConfirmation,
          extra: {
            'orderSlug': state.orderSlug,
            'orderItemId': state.orderItemId,
            'paymentType': state.paymentType,
            'paymentResponse': state.paymentResponse,
            'address': displayAddress ?? '',
            'addressType': _selectedAddress?.addressType ?? '',
            'contact': Global.userData?.mobile.toString() ?? '',
            'email': Global.userData?.email.toString() ?? '',
          },
        );
      } else {
        GoRouter.of(context).pop();
        GoRouter.of(context).push(
          AppRoutes.orderSuccess,
          extra: {
            'address': displayAddress,
            'addressType': _selectedAddress!.addressType,
            'orderSlug': state.orderSlug,
            'orderItemId': state.orderItemId,
          },
        );
      }
    } else if (state is CreateOrderFailure) {
      setState(() => _busy = false);
      ToastManager.show(
          context: context, message: state.error, type: ToastType.error);
    } else if (state is CreateOrderProgress) {
      setState(() => _busy = true);
    }
  }

  // ---- delivery date helpers ----

  DateTime? _etaDate(DateTime from, int? amount, String? unit) {
    if (amount == null) return null;
    switch ((unit ?? 'days').toLowerCase()) {
      case 'minute':
      case 'minutes':
        return from.add(Duration(minutes: amount));
      case 'hour':
      case 'hours':
        return from.add(Duration(hours: amount));
      case 'week':
      case 'weeks':
        return from.add(Duration(days: amount * 7));
      case 'month':
      case 'months':
        return DateTime(from.year, from.month + amount, from.day);
      default:
        return from.add(Duration(days: amount));
    }
  }

  DateTime? _deliveryDateFor(CartItem item) {
    final eta = item.deliveryEta;
    if (eta == null) return null;
    final now = DateTime.now();
    return _etaDate(now, eta.max, eta.unit) ?? _etaDate(now, eta.min, eta.unit);
  }

  List<_DeliveryGroup> _groupItemsByDelivery(List<CartItem> items) {
    final List<_DeliveryGroup> groups = [];
    final Map<String, _DeliveryGroup> byKey = {};
    for (final item in items) {
      final date = _deliveryDateFor(item);
      final key = date == null ? '' : DateFormat('yyyy-MM-dd').format(date);
      final group = byKey.putIfAbsent(key, () {
        final g = _DeliveryGroup(date);
        groups.add(g);
        return g;
      });
      group.items.add(item);
    }
    groups.sort((a, b) {
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
    return groups;
  }

  String? _earliestDeliveryText(List<CartItem> items) {
    DateTime? latest;
    for (final item in items) {
      final date = _deliveryDateFor(item);
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    if (latest == null) return null;
    return DateFormat('d MMM').format(latest);
  }
}

class _DeliveryGroup {
  final DateTime? date;
  final List<CartItem> items = [];
  _DeliveryGroup(this.date);
}
