import 'dart:developer';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:intl/intl.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/save_for_later_page/bloc/save_for_later_bloc/save_for_later_event.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_shimmer.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:open_filex/open_filex.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../config/helper.dart';
import '../../../services/user_cart/cart_validation.dart';
import '../../../utils/widgets/custom_toast.dart';
import '../../../utils/widgets/price_utils.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import '../bloc/attachment/attachment_bloc.dart';
import '../model/get_cart_model.dart';
import '../../../l10n/app_localizations.dart';
import 'addon_edit_bottom_sheet.dart';
import 'package:path/path.dart' as path;

class CartItemAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;

  CartItemAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
  });
}

/// Recomputes the cartKey for a server-side [CartItem] so it matches.
String _cartKeyFor(CartItem item) {
  final String productId = (item.product?.id ?? 0).toString();
  final String variantId = (item.productVariantId ?? 0).toString();
  if (item.addons.isEmpty) return '${productId}_$variantId';
  final ids = item.addons
      .map((a) => a.addonItemId ?? 0)
      .where((id) => id > 0)
      .toList()
    ..sort();
  if (ids.isEmpty) return '${productId}_$variantId';
  return '${productId}_${variantId}_${ids.join('-')}';
}

/// Renders the cart as a flat list of item cards (no store grouping).
class CartWidget extends StatelessWidget {
  final List<CartItem> items;
  final String deliveryTime;
  final Function(String itemId, int newQuantity) onQuantityChanged;
  final Function(String itemId) onRemoveItem;
  final VoidCallback? onAddMoreItems;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final TextStyle? headerTextStyle;
  final TextStyle? deliveryTextStyle;
  final Color? quantityButtonColor;
  final Color? priceColor;
  final Color? originalPriceColor;
  final BorderRadius? borderRadius;
  final int? totalItem;

  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final List<SellerShippingCost> sellerShippingCosts;
  final VoidCallback? onAddAddressTap;

  const CartWidget({
    super.key,
    required this.items,
    required this.deliveryTime,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    this.onAddMoreItems,
    this.padding,
    this.backgroundColor,
    this.headerTextStyle,
    this.deliveryTextStyle,
    this.quantityButtonColor,
    this.priceColor,
    this.originalPriceColor,
    this.borderRadius,
    this.totalItem,
    this.addressId,
    this.promoCode,
    this.rushDelivery,
    this.useWallet,
    this.sellerShippingCosts = const [],
    this.onAddAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Divider(
          height: 1,
          thickness: 0.5,
          color: theme.colorScheme.outline,
          indent: 12.w,
          endIndent: 12.w,
        ));
      }
      children.add(CartItemCard(
        item: items[i],
        onQuantityChanged: onQuantityChanged,
        onRemoveItem: onRemoveItem,
        backgroundColor: backgroundColor,
        priceColor: priceColor,
        originalPriceColor: originalPriceColor,
        addressId: addressId,
        promoCode: promoCode,
        rushDelivery: rushDelivery,
        useWallet: useWallet,
        sellerShippingCosts: sellerShippingCosts,
        onAddAddressTap: onAddAddressTap,
      ));
    }

    return Container(
      margin: EdgeInsets.only(bottom: 0.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(0.r),
        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

/// A single cart item card, styled like the product-summary reference.
class CartItemCard extends StatefulWidget {
  final CartItem item;
  final Function(String itemId, int newQuantity) onQuantityChanged;
  final Function(String itemId) onRemoveItem;
  final Color? backgroundColor;
  final Color? priceColor;
  final Color? originalPriceColor;
  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final List<SellerShippingCost> sellerShippingCosts;
  final VoidCallback? onAddAddressTap;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    this.backgroundColor,
    this.priceColor,
    this.originalPriceColor,
    this.addressId,
    this.promoCode,
    this.rushDelivery,
    this.useWallet,
    this.sellerShippingCosts = const [],
    this.onAddAddressTap,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  static const int _moreQtyValue = -1;
  static const int _maxDropdownQty = 5;

  CartItem get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push(
                AppRoutes.productDetailPage,
                extra: {'productSlug': item.product?.slug},
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(item.product?.image ?? ''),
                SizedBox(width: 12.w),
                Expanded(child: _buildDetails(context, l10n)),
              ],
            ),
          ),
          if ((item.product?.returnPolicy ?? '').isNotEmpty) ...[
            SizedBox(height: 10.h),
            _buildReturnRow(item.product!.returnPolicy!),
          ],

          if (item.product?.isAttachmentRequired == true) ...[
            SizedBox(height: 12.h),
            _buildAttachmentsSection(item),
          ],
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildDeliveryRow(l10n)),
              _buildActionsRow(l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final String brand = item.product?.brand ?? '';
    final List<String> variants = item.variant?.variant ?? [];
    final String variantText = variants.join(' / ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (brand.isNotEmpty)
          Text(
            brand.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontFamily: AppTheme.fontFamily,
              color: theme.colorScheme.tertiary,
            ),
          ),

        Text(
          item.product?.name ?? '',
          style: AppTextStyles.label.copyWith(
            fontFamily: AppTheme.fontFamily,
            height: 1.3,
            color: theme.colorScheme.tertiary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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

        const SizedBox(height: 2,),
        if (variantText.isNotEmpty)
          Text(
            variantText,
            style: AppTextStyles.caption.copyWith(
              fontFamily: AppTheme.fontFamily,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        SizedBox(height: 8.h),
        _buildOptionsColumn(l10n),
        if (item.addons.isNotEmpty || item.variant?.isAddons == true)
          _buildEditAddonsLink(l10n),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildOptionsColumn(AppLocalizations l10n) {
    final int stock = item.variant?.stock ?? 0;
    final bool lowStock = stock > 0 && stock <= 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQtyDropdown(l10n),
        SizedBox(height: 5.h,),
        _buildPriceAndSave(l10n),
        if (lowStock)
          Text(
            l10n.onlyNLeft(stock),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }

  Widget _buildQtyDropdown(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final String cartKey = _cartKeyFor(item);

    return BlocSelector<CartBloc, CartState, int?>(
      selector: (state) {
        if (state is CartLoaded) {
          return state.items
              .firstWhereOrNull((i) => i.cartKey == cartKey)
              ?.quantity;
        }
        return null;
      },
      builder: (context, localQty) {
        final int displayQty = localQty ?? item.quantity ?? 1;

        final bool outOfStock = item.variant?.isInStock == false &&
            (item.variant?.stock ?? 0) <= 0;
        if (outOfStock) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              l10n.outOfStock,
              style: AppTextStyles.label.copyWith(
                color: theme.colorScheme.error,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          );
        }

        final int step = (item.product?.quantityStepSize ?? 1)
            .clamp(1, 9999)
            .toInt();
        final int minQ =
            (item.product?.minimumOrderQuantity ?? 1).clamp(1, 9999).toInt();
        final int stock = item.variant?.stock ?? 0;
        final int allowed = item.product?.totalAllowedQuantity ?? 0;
        int realMax = 9999;
        if (stock > 0 && stock < realMax) realMax = stock;
        if (allowed > 0 && allowed < realMax) realMax = allowed;
        if (realMax < minQ) realMax = minQ;

        // Show at most 5 quick options; anything larger uses the "More" dialog.
        final List<int> options = [];
        for (int q = minQ;
            options.length < _maxDropdownQty && q <= realMax;
            q += step) {
          options.add(q);
        }
        if (!options.contains(displayQty)) options.insert(0, displayQty);

        final bool canShowMore = realMax > options.last;

        return Container(
          padding: EdgeInsetsDirectional.only(start: 7.w,),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.qty} ',
                style: AppTextStyles.caption.copyWith(
                  fontFamily: AppTheme.fontFamily,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.h),
                constraints: BoxConstraints(minWidth: 40.w),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: displayQty,
                    isDense: true,
                    isExpanded: false,
                    iconSize: 18.sp,
                    borderRadius: BorderRadius.circular(8.r),
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                      color: theme.colorScheme.tertiary,
                    ),
                    // Closed-state labels — must stay 1:1 with [items] below.
                    selectedItemBuilder: (context) {
                      return [
                        ...options,
                        if (canShowMore) _moreQtyValue,
                      ].map((q) {
                        if (q == _moreQtyValue) {
                          return Center(
                            child: Text(
                              l10n.moreLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          );
                        }
                        return Center(
                          child: Text(
                            '$q',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList();
                    },
                    // Up to 5 quick quantities, then a "More" entry that opens
                    // the manual-input dialog when the cap exceeds the list.
                    items: [
                      ...options.map((q) => DropdownMenuItem<int>(
                            value: q,
                            child: Text('$q'),
                          )),
                      if (canShowMore)
                        DropdownMenuItem<int>(
                          value: _moreQtyValue,
                          child: Text(
                            l10n.moreLabel,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == _moreQtyValue) {
                        _showQtyInputDialog(
                            displayQty, minQ, realMax, stock > 0 || allowed > 0);
                      } else {
                        _onQtySelected(value, displayQty);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onQtySelected(int? value, int currentQty) {
    if (value == null || value == currentQty) return;
    HapticFeedback.selectionClick();
    final String cartKey = _cartKeyFor(item);
    context.read<CartBloc>().add(UpdateCartQty(
          cartKey: cartKey,
          quantity: value,
          cartItemId: item.id,
          context: context,
          addressId: widget.addressId,
          promoCode: widget.promoCode,
          useWallet: widget.useWallet,
          rushDelivery: widget.rushDelivery,
          isFromCartPage: true,
        ));
    widget.onQuantityChanged(item.id.toString(), value);
  }

  Future<void> _showQtyInputDialog(
      int currentQty, int minQ, int maxQ, bool hasCap) async {
    final entered = await showQtyInputDialog(
      context: context,
      currentQty: currentQty,
      minQ: minQ,
      maxQ: maxQ,
      hasCap: hasCap,
      item: item,
    );
    if (entered != null && mounted) {
      _onQtySelected(entered, currentQty);
    }
  }

  Widget _buildEditAddonsLink(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showAddonEditBottomSheet(
              context: context,
              cartItem: item,
              addressId: widget.addressId,
              promoCode: widget.promoCode,
              rushDelivery: widget.rushDelivery,
              useWallet: widget.useWallet,
            );
          },
          borderRadius: BorderRadius.circular(4.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.edit,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  Icons.arrow_right,
                  size: isTablet(context) ? 18 : 14.r,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateTotalAddonPrice() {
    if (item.totalAddonPrice != null) {
      return item.totalAddonPrice!;
    }
    if (item.addons.isEmpty) return 0.0;
    return item.addons
        .fold<double>(0.0, (total, addon) => total + (addon.price ?? 0.0));
  }

  Widget _buildPriceAndSave(AppLocalizations l10n) {
    final String cartKey = _cartKeyFor(item);
    final theme = Theme.of(context);

    return BlocSelector<CartBloc, CartState, int?>(
      selector: (state) {
        if (state is CartLoaded) {
          return state.items
              .firstWhereOrNull((i) => i.cartKey == cartKey)
              ?.quantity;
        }
        return null;
      },
      builder: (context, localQty) {
        final int displayQty = localQty ?? item.quantity ?? 1;

        final double regularPrice = item.variant?.price ?? 0.0;
        final double salePrice = item.variant?.specialPrice ?? 0.0;
        final double addonUnit = _calculateTotalAddonPrice();

        final double totalRegular =
            (regularPrice * displayQty) + (addonUnit * displayQty);
        final double totalSale =
            ((salePrice > 0 ? salePrice : regularPrice) * displayQty) +
                (addonUnit * displayQty);

        final bool hasRealDiscount = salePrice > 0 &&
            salePrice < regularPrice &&
            (regularPrice - salePrice).abs() > 0.01;

        final double mainTotal = hasRealDiscount ? totalSale : totalRegular;
        final double savedAmount = totalRegular - mainTotal;

        final String formattedMain = PriceUtils.formatWithFormat(
            mainTotal, item.variant!.format, item.variant?.currencySymbol);
        final String formattedRegular = PriceUtils.formatWithFormat(
            totalRegular, item.variant!.format, item.variant?.currencySymbol);
        final String formattedSaved = PriceUtils.formatWithFormat(
            savedAmount, item.variant!.format, item.variant?.currencySymbol);

        final int discountPercent = (hasRealDiscount && regularPrice > 0)
            ? (((regularPrice - salePrice) / regularPrice) * 100).round()
            : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6.w,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  formattedMain,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.fontFamily,
                    color: widget.priceColor ?? theme.colorScheme.tertiary,
                  ),
                ),
                if (hasRealDiscount) ...[
                  Text(
                    formattedRegular,
                    style: AppTextStyles.label.copyWith(
                      fontFamily: AppTheme.fontFamily,
                      color: widget.originalPriceColor ??
                          theme.colorScheme.onSecondaryContainer,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: theme.colorScheme.onSecondaryContainer,
                      decorationThickness: 1.5,
                    ),
                  ),
                  if (discountPercent > 0)
                    Text(
                      l10n.percentOff(discountPercent),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                        color: context.appColors.success,
                      ),
                    ),
                ],
              ],
            ),
            if (hasRealDiscount && savedAmount > 0)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  l10n.youSaveAmount(formattedSaved),
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                    color: context.appColors.success,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReturnRow(String returnPolicy) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          TablerIcons.rotate_clockwise,
          size: isTablet(context) ? 18 : 14.r,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            returnPolicy,
            style: AppTextStyles.label.copyWith(
              fontFamily: AppTheme.fontFamily,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

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

  bool? _resolveItemFulfillable() {
    for (final cost in widget.sellerShippingCosts) {
      for (final shippingItem in cost.items) {
        if (shippingItem.cartItemId != null &&
            shippingItem.cartItemId == item.id) {
          return shippingItem.isFulfillable;
        }
      }
    }
    return null;
  }

  Widget _buildDeliveryRow(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (item.product!.name!.isEmpty) {
    log('Item product Name Is Empty ${item.product!.name}');
      return const SizedBox.shrink();
    }

    final eta = item.deliveryEta;
    final bool? isFulfillable = _resolveItemFulfillable();
    final bool hasAddress = widget.addressId != null;

    // Server confirmed this item can't ship to the chosen address.
    if (isFulfillable == false) {
      return Text(
        l10n.notDeliverable,
        style: AppTextStyles.caption.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    final now = DateTime.now();
    final date = eta != null
        ? (_etaDate(now, eta.max, eta.unit) ?? _etaDate(now, eta.min, eta.unit))
        : null;

    if (date != null) {
      final String formatted = DateFormat('d MMM').format(date);
      return Padding(
        padding: EdgeInsets.only(top: 0.h),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: l10n.deliveryByDate(''),
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                  children: [
                    TextSpan(
                      text: formatted,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No address chosen yet — prompt instead of implying it can't ship.
    if (!hasAddress) {
      return InkWell(
        onTap: widget.onAddAddressTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.map_pin_plus,
              size: isTablet(context) ? 16 : 12.sp,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                l10n.chooseAddressForDelivery,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Address set but the delivery estimate is still loading.
    if (widget.sellerShippingCosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: ShimmerWidget.rectangular(
          isBorder: true,
          borderRadius: 4,
          width: 120.w,
          height: isTablet(context) ? 14 : 12.sp,
        ),
      );
    }

    log('Last Option');
    return const SizedBox.shrink();
  }

  Widget _buildActionsRow(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _saveForLater,
          child: Container(
            height: 28.h,
            // width: 70,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            decoration: BoxDecoration(
              // color: Colors.red,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)
            ),
            child: Row(
              children: [
                const Icon(TablerIcons.bookmark, size: 15,),
                SizedBox(width: 10.w,),
                Text(l10n.save),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w,),
        // const Spacer(),
        GestureDetector(
          onTap: _confirmAndRemove,
          child: Container(
            height: 28.h,
            // width: 70,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            decoration: BoxDecoration(
              // color: Colors.red,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)
            ),
            child: Row(
              children: [
                const Icon(TablerIcons.trash, size: 15,),
                SizedBox(width: 10.w,),
                Text(AppLocalizations.of(context)?.remove ?? 'Remove'),
              ],
            ),
          ),
        ),
      ],
    );
  }


  void _saveForLater() {
    if (item.id == null || item.product?.name == null) return;
    context.read<SaveForLaterBloc>().add(SaveForLaterRequest(
          cartItemId: item.id!,
          cartItemName: item.product!.name!,
        ));
  }

  Future<void> _confirmAndRemove() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n?.removeItem ?? 'Remove item'),
          content: Text(
            l10n?.areYouSureYouWantToRemoveItemFromCart(
                    item.product?.name ?? '') ??
                'Are you sure you want to remove ${item.product?.name} from cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            CustomButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n?.remove ?? 'Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      context.read<CartBloc>().add(RemoveFromCart(
            cartKey: _cartKeyFor(item),
            context: context,
            addressId: widget.addressId,
            promoCode: widget.promoCode,
            useWallet: widget.useWallet,
            rushDelivery: widget.rushDelivery,
            isFromCartPage: true,
          ));
      widget.onRemoveItem(item.id.toString());
    }
  }

  Widget _buildProductImage(String imageUrl) {
    final theme = Theme.of(context);
    return Container(
      width: 85.w,
      height: 90.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: CustomImageContainer(imagePath: imageUrl, fit: BoxFit.contain),
      ),
    );
  }

  List<CartItemAttachment> _getAttachmentsForItem(
      CartItem item, AttachmentState state) {
    final key = item.productId ?? item.id;
    if (key == null) {
      log('Warning: Both productId and id are null');
      return [];
    }
    return state.attachments[key] ?? [];
  }

  bool _hasAttachments(CartItem item, AttachmentState state) {
    return _getAttachmentsForItem(item, state).isNotEmpty;
  }

  Widget _buildAttachmentsSection(CartItem item) {
    return BlocBuilder<AttachmentBloc, AttachmentState>(
      builder: (context, state) {
        final attachments = _getAttachmentsForItem(item, state);
        if (attachments.isEmpty) {
          return _buildAddAttachmentButton(item, state);
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isDarkMode(context)
                ? Colors.grey.shade800.withValues(alpha: 0.4)
                : Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(TablerIcons.paperclip,
                      size: 16, color: Colors.grey.shade500),
                  SizedBox(width: 5.w),
                  Text(AppLocalizations.of(context)!.attachments,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              ...attachments
                  .map((attachment) => _buildSingleAttachment(item, attachment)),
              InkWell(
                onTap: () => _showAttachmentOptions(item),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(TablerIcons.plus,
                          size: 16, color: AppTheme.primaryColor),
                      SizedBox(width: 5.w),
                      Text(AppLocalizations.of(context)!.addMoreAttachments,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleAttachment(CartItem item, CartItemAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openAttachment(attachment),
              child: Row(
                children: [
                  _buildFileIcon(attachment.fileType, attachment.filePath),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.fileName,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatFileSize(attachment.fileSize),
                          style: AppTextStyles.label
                              .copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _removeSingleAttachment(item, attachment),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(TablerIcons.x,
                  size: 18, color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String fileType, String filePath) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Icon(TablerIcons.file_type_pdf,
            color: Colors.red, size: 28);
      case 'doc':
      case 'docx':
        return const Icon(TablerIcons.file_type_docx,
            color: Colors.blue, size: 28);
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Container(
          width: 35.w,
          height: 35.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  TablerIcons.photo, color: Colors.green, size: 28),
            ),
          ),
        );
      default:
        return const Icon(TablerIcons.file, color: Colors.grey, size: 28);
    }
  }

  Widget _buildAddAttachmentButton(CartItem item, AttachmentState state) {
    final hasAttachment = _hasAttachments(item, state);
    return Align(
      alignment: AlignmentGeometry.topLeft,
      child: InkWell(
        onTap: () {
          if (hasAttachment) {
            final attachments = _getAttachmentsForItem(item, state);
            _openAttachment(attachments.first);
          } else {
            _showAttachmentOptions(item);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasAttachment ? TablerIcons.eye : TablerIcons.paperclip,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                hasAttachment ? 'View Attachment' : 'Add Attachment',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions(CartItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.addAttachment, style: AppTextStyles.titleLarge),
                SizedBox(height: 8.h),
                Text(AppLocalizations.of(context)!.chooseFileTypeToUpload,
                    style: AppTextStyles.label
                        .copyWith(color: Colors.grey.shade600)),
                SizedBox(height: 20.h),
                _buildAttachmentOption(
                  icon: TablerIcons.photo,
                  label: AppLocalizations.of(context)!.imagesLabel,
                  subtitle: AppLocalizations.of(context)!.imagesSubtitle,
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(item, 'image');
                  },
                ),
                SizedBox(height: 12.h),
                _buildAttachmentOption(
                  icon: TablerIcons.file_type_pdf,
                  label: AppLocalizations.of(context)!.pdfDocumentLabel,
                  subtitle: AppLocalizations.of(context)!.pdfDocumentSubtitle,
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(item, 'pdf');
                  },
                ),
                SizedBox(height: 12.h),
                _buildAttachmentOption(
                  icon: TablerIcons.file_type_docx,
                  label: AppLocalizations.of(context)!.wordDocumentLabel,
                  subtitle: AppLocalizations.of(context)!.wordDocumentSubtitle,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(item, 'docx');
                  },
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.label
                          .copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(CartItem item, String fileType) async {
    List<PlatformFile> result = const [];

    if (fileType == 'image') {
      result = await FilePicker.pickFiles(type: FileType.image);
    } else if (fileType == 'pdf') {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } else if (fileType == 'docx') {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx'],
      );
    }

    if (result.isEmpty) return;

    final newAttachments = <CartItemAttachment>[];
    final platformFile = result.first;

    for (final platformFile in result) {
      if (platformFile.path == null) continue;

      final extension =
          path.extension(platformFile.name).toLowerCase().replaceAll('.', '');

      String detectedType = 'other';
      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        detectedType = 'image';
      } else if (extension == 'pdf') {
        detectedType = 'pdf';
      } else if (['doc', 'docx'].contains(extension)) {
        detectedType = 'docx';
      }

      newAttachments.add(CartItemAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString() + platformFile.name,
        fileName: platformFile.name,
        filePath: platformFile.path!,
        fileType: detectedType,
        fileSize: await platformFile.length(),
      ));
    }

    if (platformFile.path == null) {
      if (mounted) {
        ToastManager.show(
          context: context,
          message: 'Could not get file path',
          type: ToastType.error,
        );
      }
      return;
    }

    if (newAttachments.isNotEmpty && mounted) {
      context.read<AttachmentBloc>().add(AddAttachments(
            productId: item.productId ?? item.id!,
            attachment: newAttachments,
          ));
    }
  }

  Future<void> _openAttachment(CartItemAttachment attachment) async {
    try {
      final result = await OpenFilex.open(attachment.filePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ToastManager.show(
            context: context,
            message: 'Cannot open file: ${result.message}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context: context,
          message: 'Error opening file: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _removeSingleAttachment(CartItem item, CartItemAttachment attachment) {
    context.read<AttachmentBloc>().add(
          RemoveAttachment(
            productId: item.productId ?? item.id!,
            attachment: attachment,
          ),
        );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Owns its own [TextEditingController] so it is disposed only after the
/// dialog route fully unmounts, avoiding "used after being disposed" during
/// the dismiss animation.
///
///


Future<int?> showQtyInputDialog({
  required BuildContext context,
  required int currentQty,
  required int minQ,
  required int maxQ,
  required bool hasCap,
  required CartItem item,
}) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: "QtyDialog",
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),

    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 55),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: _QtyDialogContent(
                currentQty: currentQty,
                minQ: minQ,
                maxQ: maxQ,
                hasCap: hasCap,
                item: item,
              ),
            ),
          ),
        ),
      );
    },

    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
      );
    },
  );
}

class _QtyDialogContent extends StatefulWidget {
  final int currentQty;
  final int minQ;
  final int maxQ;
  final bool hasCap;
  final CartItem item;

  const _QtyDialogContent({
    required this.currentQty,
    required this.minQ,
    required this.maxQ,
    required this.hasCap,
    required this.item,
  });

  @override
  State<_QtyDialogContent> createState() => _QtyDialogContentState();
}

class _QtyDialogContentState extends State<_QtyDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentQty}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Title
        Text(
          l10n.quantity,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        SizedBox(height: 12.h),

        /// Input
        CustomTextFormField(
          controller: _controller,
          keyboardType: TextInputType.text,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hintText: 'Enter the quantity',
        ),

        /// Helper Text
        if (widget.hasCap) ...[
          SizedBox(height: 6.h),
          Text(
            l10n.maximumQuantityAllowed(widget.maxQ),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ],

        SizedBox(height: 16.h),

        /// Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            SizedBox(width: 8.w),

            CustomButton(
              onPressed: () {
                final entered = int.tryParse(_controller.text.trim());

                final error = CartValidation.validateProductAddToCart(
                  context: context,
                  requestedQuantity: entered ?? 0,
                  minQty: widget.item.product?.minimumOrderQuantity ?? 1,
                  maxQty: widget.item.product?.totalAllowedQuantity ?? 0,
                  stock: widget.item.variant?.stock ?? 9999,
                  stepSize: widget.item.product?.quantityStepSize ?? 1,
                  isStoreOpen: true,
                  isInStock: widget.item.variant?.isInStock ?? true,
                );

                if (entered == null || error != null) {
                  ToastManager.show(
                    context: context,
                    message:
                    error ?? l10n.minimumQuantityRequired(widget.minQ),
                    type: ToastType.error,
                  );
                  return;
                }

                Navigator.pop(context, entered);
              },
              child: Text(l10n.update),
            ),
          ],
        ),
      ],
    );
  }
}
