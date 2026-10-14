import 'dart:developer';

import 'package:flutter/material.dart';
import '../../config/settings_data_instance.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/money_format.dart';
import '../../utils/widgets/price_utils.dart';

class CartValidation {
  CartValidation._();

  /// PRODUCT-LEVEL VALIDATIONS.
  ///
  /// Allowed quantities are anchored at [minQty] and increase by [stepSize]:
  /// minQty, minQty+stepSize, minQty+2*stepSize, … up to [maxQty].
  /// Matches the server contract in CartService::validateQuantityRules.
  /// [maxQty] = 0 means "no cap" (unlimited).
  /// [stock] = null means untracked / unlimited stock — never out of stock and
  /// never capped by availability (matches backend stock: null semantics).
  static String? validateProductAddToCart({
    required BuildContext context,
    required int requestedQuantity,
    required int minQty,
    required int maxQty,
    required int? stock,
    int stepSize = 1,
    bool isStoreOpen = true,
    bool isInStock = true,
  }) {
    final l10n = AppLocalizations.of(context)!;

    // Out of stock (only when stock is tracked).
    if (isInStock == false && stock! <= 0) {
      return l10n.outOfStock;
    }



    // Below minimum quantity
    if (requestedQuantity < minQty) {
      return l10n.minimumQuantityRequired(minQty);
    }

    // Exceeds max allowed per product (maxQty == 0 means unlimited).
    if (maxQty > 0 && requestedQuantity > maxQty) {
      return l10n.maximumQuantityAllowed(maxQty);
    }

    // Step is anchored at min, not zero. With min=1, step=2 the allowed
    // values are 1, 3, 5, … — 2 is rejected.
    if (stepSize > 1 && ((requestedQuantity - minQty) % stepSize) != 0) {
      return l10n.quantityMustMatchStepFromMinimum(minQty, stepSize);
    }

    // Exceeds available stock (skip when untracked / unlimited).
    if (stock! > 0 && requestedQuantity > stock) {
      return l10n.onlyXItemsInStock(stock);
    }

    return null; // Valid
  }

  static String? validateBeforeAddToCart({
    required BuildContext context,
    required int currentCartItemCount,
    required int requestedAddQuantity,
    required Set<int> currentStoreIdsInCart,
    required int thisProductStoreId,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final system = SettingsData.instance.system!;

    // 1. Check maximum items allowed in cart (global cart-row cap).
    // The setting is compared against cart-row count (state.items.length on the
    // client; $cart->items->count() on the server). Treat 0 / null as "no cap"
    // so an unconfigured setting doesn't lock the user to a single row.
    final int? maxItemsRaw = system.maximumItemsAllowedInCart;
    if (maxItemsRaw != null && maxItemsRaw > 0) {
      final int maxItems = maxItemsRaw;
      final int newTotalItemsCount =
          currentCartItemCount + requestedAddQuantity;
      if (newTotalItemsCount > maxItems) {
        final int remaining = maxItems - currentCartItemCount;
        if (remaining <= 0) {
          return l10n.youHaveReachedMaximumLimitOfTheCart(system.maximumItemsAllowedInCart!);
        }
        return l10n.cannotAddMoreThanXItems(remaining);
      }
    }

    if(currentStoreIdsInCart.isNotEmpty) {
      if (system.checkoutType == 'single_store' && currentStoreIdsInCart.first != thisProductStoreId) {
        return l10n.onlyOneStoreAtATime;
      }
    }

    // All checks passed
    return null;
  }


  static String? validateCartForCheckout({
    required BuildContext context,
    required double cartItemTotal,
    required int totalItemsCount,
    required Set<int> storeIds,
    double? minimumCartAmount,
    String? currencySymbol,
    MoneyFormat? format,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final system = SettingsData.instance.system!;

    // Minimum cart amount — prefer the server-converted value; fall back to the
    // base-currency setting (treat null/absent as 0 = no minimum).
    final double minAmount =
        minimumCartAmount ?? (system.minimumCartAmount?.toDouble() ?? 0.0);

    // Compare at currency precision (2 decimal places) rather than raw
    // doubles. Without this, floating-point drift from summing taxed line
    // items can leave cartItemTotal a fraction of a cent below the minimum
    // — values that are visually identical fail validation. Rounding both
    // sides to the same precision keeps the comparison apples-to-apples
    // with what the user actually sees.
    final double roundedMin = _roundToCurrencyPrecision(minAmount);
    final double roundedTotal = _roundToCurrencyPrecision(cartItemTotal);
    if (roundedMin > 0 && roundedTotal < roundedMin) {
      final fmt = format ?? MoneyFormat.defaults;
      final shortfall = PriceUtils.formatWithFormat(
          roundedMin - roundedTotal, fmt, currencySymbol);
      final minFormatted =
          PriceUtils.formatWithFormat(roundedMin, fmt, currencySymbol);
      return l10n.minimumCartAmountRequired(shortfall, minFormatted);
    }

    // Maximum items in cart (0 / null = no cap).
    final int? maxItemsRaw = system.maximumItemsAllowedInCart;
    log('MaxItem Raw ${maxItemsRaw != null &&
        maxItemsRaw > 0 &&
        totalItemsCount > maxItemsRaw}');
    if (maxItemsRaw != null &&
        maxItemsRaw > 0 &&
        totalItemsCount > maxItemsRaw) {
      return l10n.youHaveReachedMaximumLimitOfTheCart(system.maximumItemsAllowedInCart!);
    }

    // Multi-store restriction (if your app supports only single store)
    if (system.checkoutType == 'single_store' && storeIds.length > 1) {
      return l10n.onlyOneStoreAtATime;
    }

    return null;
  }

  /// Rounds a money value to 2 decimal places (currency precision) so
  /// floating-point drift can't make two visually-equal amounts compare
  /// unequal. Uses round-half-away-from-zero via `.roundToDouble()`.
  static double _roundToCurrencyPrecision(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  /// Helper: Get user-friendly stock message (not error, just info)
  static String getStockMessage({
    required int? stock,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;

    // null = untracked / unlimited → always in stock.
    if (stock == null) {
      return l10n.inStock;
    }
    else if (stock <= 0) {
      return l10n.outOfStock;
    }
    else if (stock <= 5) {
      return l10n.onlyFewLeft(stock);
    }
    return l10n.inStock;
  }
}