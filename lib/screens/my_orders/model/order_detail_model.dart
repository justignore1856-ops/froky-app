import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/utils/money_format.dart';

class OrderDetailModel {
  final bool? success;
  final String? message;
  final OrderDetailData? data;

  OrderDetailModel({
    this.success,
    this.message,
    this.data,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: json['data'] != null ? OrderDetailData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}

class OrderDetailData {
  final int? id;
  final String? uuid;
  final String? slug;
  final int? userId;
  final String? email;
  final String? currencyCode;
  final String? currencyRate;
  final String? currencySymbol;
  final MoneyFormat format;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? status;
  final String? statusLabel;
  final CustomerStatus? customerStatus;
  final List<OrderTimelineStage> orderTimeline;
  final bool? isRushOrder;
  final String? invoice;
  final String? fulfillmentType;
  // Hypercommerce fulfillment rollup + per-shipment tracking.
  final String? fulfillmentStatus;
  final String? fulfillmentStatusLabel;
  // Seller-acceptance rollup (separate axis from fulfillment).
  final String? acceptanceStatus;
  final String? acceptanceStatusLabel;
  final List<OrderShipment> shipments;
  final int? estimatedDeliveryTime;
  final dynamic deliveryTimeSlotId;
  final dynamic deliveryBoyId;
  final String? deliveryBoyName;
  final int? deliveryBoyPhone;
  final String? deliveryBoyProfile;
  final String? walletBalance;
  final dynamic promoCode;
  final String? promoDiscount;
  final dynamic giftCard;
  final String? giftCardDiscount;
  final String? deliveryCharge;
  final String? platformFee;
  final String? codFee;
  final String? handlingCharges;
  final String? perStoreDropOffFee;
  final String? subtotal;
  final String? totalPayable;
  final String? finalTotal;
  final String? shippingName;
  final String? shippingAddress1;
  final dynamic shippingAddress2;
  final String? shippingLandmark;
  final String? shippingZip;
  final String? shippingPhone;
  final String? shippingAddressType;
  final String? shippingLatitude;
  final String? shippingLongitude;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingCountry;
  final String? shippingCountryCode;
  final String? orderNote;
  final List<OrderItems> items;
  final List<SellerFeedback> sellerFeedbacks;
  final dynamic promoLine;
  final dynamic paymentResponse;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? orderSummary;

  OrderDetailData({
    this.id,
    this.uuid,
    this.slug,
    this.userId,
    this.email,
    this.currencyCode,
    this.currencyRate,
    this.currencySymbol,
    this.format = MoneyFormat.defaults,
    this.paymentMethod,
    this.paymentStatus,
    this.status,
    this.statusLabel,
    this.customerStatus,
    this.orderTimeline = const [],
    this.isRushOrder,
    this.invoice,
    this.fulfillmentType,
    this.fulfillmentStatus,
    this.fulfillmentStatusLabel,
    this.acceptanceStatus,
    this.acceptanceStatusLabel,
    this.shipments = const [],
    this.estimatedDeliveryTime,
    this.deliveryTimeSlotId,
    this.deliveryBoyId,
    this.deliveryBoyName,
    this.deliveryBoyPhone,
    this.deliveryBoyProfile,
    this.walletBalance,
    this.promoCode,
    this.promoDiscount,
    this.giftCard,
    this.giftCardDiscount,
    this.deliveryCharge,
    this.platformFee,
    this.codFee,
    this.handlingCharges,
    this.perStoreDropOffFee,
    this.subtotal,
    this.totalPayable,
    this.finalTotal,
    this.shippingName,
    this.shippingAddress1,
    this.shippingAddress2,
    this.shippingLandmark,
    this.shippingZip,
    this.shippingPhone,
    this.shippingAddressType,
    this.shippingLatitude,
    this.shippingLongitude,
    this.shippingCity,
    this.shippingState,
    this.shippingCountry,
    this.shippingCountryCode,
    this.orderNote,
    this.items = const [],
    this.sellerFeedbacks = const [],
    this.promoLine,
    this.paymentResponse,
    this.createdAt,
    this.updatedAt,
    this.orderSummary,
  });

  factory OrderDetailData.fromJson(Map<String, dynamic> json) {
    return OrderDetailData(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      slug: parseString(json['slug']),
      userId: parseInt(json['user_id']),
      email: parseString(json['email']),
      currencyCode: parseString(json['currency_code']),
      currencyRate: parseString(json['currency_rate']),
      currencySymbol: parseString(json['currency_symbol']),
      format: MoneyFormat.fromJson(json['format'] is Map<String, dynamic> ? json['format'] as Map<String, dynamic> : null),
      paymentMethod: parseString(json['payment_method']),
      paymentStatus: parseString(json['payment_status']),
      status: parseString(json['status']),
      statusLabel: parseString(json['status_label']),
      customerStatus: json['customer_status'] is Map<String, dynamic>
          ? CustomerStatus.fromJson(json['customer_status'] as Map<String, dynamic>)
          : null,
      orderTimeline: _parseOrderTimeline(json['order_timeline']),
      isRushOrder: json['is_rush_order'] != null ? parseBool(json['is_rush_order']) : null,
      invoice: parseString(json['invoice']),
      fulfillmentType: parseString(json['fulfillment_type']),
      fulfillmentStatus: parseString(json['fulfillment_status']),
      fulfillmentStatusLabel: parseString(json['fulfillment_status_label']),
      acceptanceStatus: parseString(json['acceptance_status']),
      acceptanceStatusLabel: parseString(json['acceptance_status_label']),
      shipments: _parseShipments(json['shipments']),
      estimatedDeliveryTime: parseInt(json['estimated_delivery_time']),
      deliveryTimeSlotId: json['delivery_time_slot_id'],
      deliveryBoyId: json['delivery_boy_id'],
      deliveryBoyName: parseString(json['delivery_boy_name']),
      deliveryBoyPhone: parseInt(json['delivery_boy_phone']),
      deliveryBoyProfile: parseString(json['delivery_boy_profile']),
      walletBalance: parseString(json['wallet_balance']),
      promoCode: json['promo_code'],
      promoDiscount: parseString(json['promo_discount']),
      giftCard: json['gift_card'],
      giftCardDiscount: parseString(json['gift_card_discount']),
      deliveryCharge: parseString(json['delivery_charge']),
      platformFee: parseString(json['platform_fee']),
      codFee: parseString(json['cod_fee']),
      handlingCharges: parseString(json['handling_charges']),
      perStoreDropOffFee: parseString(json['per_store_drop_off_fee']),
      subtotal: parseString(json['subtotal']),
      totalPayable: parseString(json['total_payable']),
      finalTotal: parseString(json['final_total']),
      shippingName: parseString(json['shipping_name']),
      shippingAddress1: parseString(json['shipping_address_1']),
      shippingAddress2: json['shipping_address_2'],
      shippingLandmark: parseString(json['shipping_landmark']),
      shippingZip: parseString(json['shipping_zip']),
      shippingPhone: parseString(json['shipping_phone']),
      shippingAddressType: parseString(json['shipping_address_type']),
      shippingLatitude: parseString(json['shipping_latitude']),
      shippingLongitude: parseString(json['shipping_longitude']),
      shippingCity: parseString(json['shipping_city']),
      shippingState: parseString(json['shipping_state']),
      shippingCountry: parseString(json['shipping_country']),
      shippingCountryCode: parseString(json['shipping_country_code']),
      orderNote: parseString(json['order_note']),
      items: _parseOrderItems(json['items']),
      sellerFeedbacks: _parseSellerFeedbacks(json['seller_feedbacks']),
      promoLine: json['promo_line'],
      paymentResponse: json['payment_response'],
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
      orderSummary: json['order_summary'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'slug': slug,
    'user_id': userId,
    'email': email,
    'currency_code': currencyCode,
    'currency_rate': currencyRate,
    'currency_symbol': currencySymbol,
    'format': format.toJson(),
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'status': status,
    'status_label': statusLabel,
    if (customerStatus != null) 'customer_status': customerStatus!.toJson(),
    'order_timeline': orderTimeline.map((e) => e.toJson()).toList(),
    'is_rush_order': isRushOrder,
    'invoice': invoice,
    'fulfillment_type': fulfillmentType,
    'fulfillment_status': fulfillmentStatus,
    'fulfillment_status_label': fulfillmentStatusLabel,
    'acceptance_status': acceptanceStatus,
    'acceptance_status_label': acceptanceStatusLabel,
    'shipments': shipments.map((e) => e.toJson()).toList(),
    'estimated_delivery_time': estimatedDeliveryTime,
    'delivery_time_slot_id': deliveryTimeSlotId,
    'delivery_boy_id': deliveryBoyId,
    'delivery_boy_name': deliveryBoyName,
    'delivery_boy_phone': deliveryBoyPhone,
    'delivery_boy_profile': deliveryBoyProfile,
    'wallet_balance': walletBalance,
    'promo_code': promoCode,
    'promo_discount': promoDiscount,
    'gift_card': giftCard,
    'gift_card_discount': giftCardDiscount,
    'delivery_charge': deliveryCharge,
    'platform_fee': platformFee,
    'cod_fee': codFee,
    'handling_charges': handlingCharges,
    'per_store_drop_off_fee': perStoreDropOffFee,
    'subtotal': subtotal,
    'total_payable': totalPayable,
    'final_total': finalTotal,
    'shipping_name': shippingName,
    'shipping_address_1': shippingAddress1,
    'shipping_address_2': shippingAddress2,
    'shipping_landmark': shippingLandmark,
    'shipping_zip': shippingZip,
    'shipping_phone': shippingPhone,
    'shipping_address_type': shippingAddressType,
    'shipping_latitude': shippingLatitude,
    'shipping_longitude': shippingLongitude,
    'shipping_city': shippingCity,
    'shipping_state': shippingState,
    'shipping_country': shippingCountry,
    'shipping_country_code': shippingCountryCode,
    'order_note': orderNote,
    'items': items.map((e) => e.toJson()).toList(),
    'seller_feedbacks': sellerFeedbacks.map((e) => e.toJson()).toList(),
    'promo_line': promoLine,
    'payment_response': paymentResponse,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'order_summary': orderSummary,
  };

  static List<OrderItems> _parseOrderItems(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(OrderItems.fromJson)
        .toList();
  }

  static List<SellerFeedback> _parseSellerFeedbacks(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(SellerFeedback.fromJson)
        .toList();
  }

  static List<OrderShipment> _parseShipments(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(OrderShipment.fromJson)
        .toList();
  }

  static List<OrderTimelineStage> _parseOrderTimeline(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(OrderTimelineStage.fromJson)
        .toList();
  }
}

/// One physical shipment (= one location+zone shipment group) for the order.
/// `status` is the granular delivery state; `fulfillmentStatus` is the seller
/// order's rollup. Mirrors the backend User\OrderResource `shipments` payload.
class OrderShipment {
  final int? id;
  final int? sellerOrderId;
  final String? status;
  final String? statusLabel;
  final String? customerStatus;
  final String? customerStatusLabel;
  final int? customerStatusStage;
  final String? providerCode;
  final String? carrierName;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? fulfillmentStatus;
  final String? pickedUpAt;
  final String? deliveredAt;
  final List<ShipmentProduct> products;

  OrderShipment({
    this.id,
    this.sellerOrderId,
    this.status,
    this.statusLabel,
    this.customerStatus,
    this.customerStatusLabel,
    this.customerStatusStage,
    this.providerCode,
    this.carrierName,
    this.trackingNumber,
    this.trackingUrl,
    this.fulfillmentStatus,
    this.pickedUpAt,
    this.deliveredAt,
    this.products = const [],
  });

  factory OrderShipment.fromJson(Map<String, dynamic> json) {
    return OrderShipment(
      id: parseInt(json['id']),
      sellerOrderId: parseInt(json['seller_order_id']),
      status: parseString(json['status']),
      statusLabel: parseString(json['status_label']),
      customerStatus: parseString(json['customer_status']),
      customerStatusLabel: parseString(json['customer_status_label']),
      customerStatusStage: parseInt(json['customer_status_stage']),
      providerCode: parseString(json['provider_code']),
      carrierName: parseString(json['carrier_name']),
      trackingNumber: parseString(json['tracking_number']),
      trackingUrl: parseString(json['tracking_url']),
      fulfillmentStatus: parseString(json['fulfillment_status']),
      pickedUpAt: parseString(json['picked_up_at']),
      deliveredAt: parseString(json['delivered_at']),
      products: (json['products'] is Iterable)
          ? (json['products'] as Iterable)
              .whereType<Map<String, dynamic>>()
              .map(ShipmentProduct.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_order_id': sellerOrderId,
        'status': status,
        'status_label': statusLabel,
        'customer_status': customerStatus,
        'customer_status_label': customerStatusLabel,
        'customer_status_stage': customerStatusStage,
        'provider_code': providerCode,
        'carrier_name': carrierName,
        'tracking_number': trackingNumber,
        'tracking_url': trackingUrl,
        'fulfillment_status': fulfillmentStatus,
        'picked_up_at': pickedUpAt,
        'delivered_at': deliveredAt,
        'products': products.map((e) => e.toJson()).toList(),
      };

  bool get isDelivered =>
      status == 'DELIVERED' || status == 'PICKED_UP';
}

/// One product line included in a shipment (= the seller order's items).
class ShipmentProduct {
  final String? title;
  final String? variant;
  final int? quantity;

  ShipmentProduct({this.title, this.variant, this.quantity});

  factory ShipmentProduct.fromJson(Map<String, dynamic> json) {
    return ShipmentProduct(
      title: parseString(json['title']),
      variant: parseString(json['variant']),
      quantity: parseInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'variant': variant,
        'quantity': quantity,
      };
}

class SellerFeedback {
  final int? sellerId;
  final bool? isFeedbackGiven;
  final SellerFeedbackData? feedback;

  SellerFeedback({
    this.sellerId,
    this.isFeedbackGiven,
    this.feedback,
  });

  factory SellerFeedback.fromJson(Map<String, dynamic> json) {
    return SellerFeedback(
      sellerId: parseInt(json['seller_id']),
      isFeedbackGiven: parseBool(json['is_feedback_given']),
      feedback: json['feedback'] != null && json['feedback'] is Map<String, dynamic>
          ? SellerFeedbackData.fromJson(json['feedback'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'seller_id': sellerId,
    'is_feedback_given': isFeedbackGiven,
    if (feedback != null) 'feedback': feedback!.toJson(),
  };
}

class SellerFeedbackData {
  final int? id;
  final int? userId;
  final int? sellerId;
  final int? orderId;
  final int? orderItemId;
  final int? storeId;
  final int? rating;
  final String? title;
  final String? slug;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  SellerFeedbackData({
    this.id,
    this.userId,
    this.sellerId,
    this.orderId,
    this.orderItemId,
    this.storeId,
    this.rating,
    this.title,
    this.slug,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerFeedbackData.fromJson(Map<String, dynamic> json) {
    return SellerFeedbackData(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      sellerId: parseInt(json['seller_id']),
      orderId: parseInt(json['order_id']),
      orderItemId: parseInt(json['order_item_id']),
      storeId: parseInt(json['store_id']),
      rating: parseInt(json['rating']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      description: parseString(json['description']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'seller_id': sellerId,
    'order_id': orderId,
    'order_item_id': orderItemId,
    'store_id': storeId,
    'rating': rating,
    'title': title,
    'slug': slug,
    'description': description,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class OrderItems {
  final int? id;
  final int? orderId;
  final int? productId;
  final int? productVariantId;
  final int? storeId;
  final int? sellerId;
  final String? sellerName;
  final String? title;
  final String? variantTitle;
  final String? giftCardDiscount;
  final String? adminCommissionAmount;
  final String? sellerCommissionAmount;
  final String? commissionSettled;
  final String? discountedPrice;
  final String? promoDiscount;
  final String? discount;
  final String? taxAmount;
  final String? taxPercent;
  final String? sku;
  final bool? returnEligible;
  final String? returnDeadline;
  final int? returnableQuantity;
  final int? quantity;
  final String? price;
  final String? subtotal;
  final int? etaMin;
  final int? etaMax;
  final String? etaUnit;
  final DeliveryEst? deliveryEstimate;
  final String? status;
  final String? statusLabel;
  final OrderItemCustomerStatus? orderItemCustomerStatus;
  final List<OrderTimelineStage> timeline;
  final bool? canCancel;
  final int? cancelableQuantity;
  final String? cancellationReason;
  final String? deliveryFailReason;
  final dynamic otp;
  final bool? otpVerified;
  final bool? isUserReviewGiven;
  final UserReview? userReview;
  final OrderDetailProduct? product;
  final OrderDetailVariant? variant;
  final Store? store;
  final List<ItemReturn> returns;
  final List<String> attachments;

  /// Addons selected on this order item.
  final List<OrderItemAddon> addons;

  /// Server-computed addon subtotal for this order item (unit addon.
  final double? addonsTotal;

  final String? createdAt;
  final String? updatedAt;

  OrderItems({
    this.id,
    this.orderId,
    this.productId,
    this.productVariantId,
    this.storeId,
    this.sellerId,
    this.sellerName,
    this.title,
    this.variantTitle,
    this.giftCardDiscount,
    this.adminCommissionAmount,
    this.sellerCommissionAmount,
    this.commissionSettled,
    this.discountedPrice,
    this.promoDiscount,
    this.discount,
    this.taxAmount,
    this.taxPercent,
    this.sku,
    this.returnEligible,
    this.returnDeadline,
    this.returnableQuantity,
    this.quantity,
    this.price,
    this.subtotal,
    this.etaMin,
    this.etaMax,
    this.etaUnit,
    this.deliveryEstimate,
    this.status,
    this.statusLabel,
    this.orderItemCustomerStatus,
    this.timeline = const [],
    this.canCancel,
    this.cancelableQuantity,
    this.cancellationReason,
    this.deliveryFailReason,
    this.otp,
    this.otpVerified,
    this.isUserReviewGiven,
    this.userReview,
    this.product,
    this.variant,
    this.store,
    this.returns = const [],
    this.attachments = const [],
    this.addons = const [],
    this.addonsTotal,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderItems.fromJson(Map<String, dynamic> json) {
    return OrderItems(
      id: parseInt(json['id']),
      orderId: parseInt(json['order_id']),
      productId: parseInt(json['product_id']),
      productVariantId: parseInt(json['product_variant_id']),
      storeId: parseInt(json['store_id']),
      sellerId: parseInt(json['seller_id']),
      sellerName: parseString(json['seller_name']),
      title: parseString(json['title']),
      variantTitle: parseString(json['variant_title']),
      giftCardDiscount: parseString(json['gift_card_discount']),
      adminCommissionAmount: parseString(json['admin_commission_amount']),
      sellerCommissionAmount: parseString(json['seller_commission_amount']),
      commissionSettled: parseString(json['commission_settled']),
      discountedPrice: parseString(json['discounted_price']),
      promoDiscount: parseString(json['promo_discount']),
      discount: parseString(json['discount']),
      taxAmount: parseString(json['tax_amount']),
      taxPercent: parseString(json['tax_percent']),
      sku: parseString(json['sku']),
      returnEligible: parseBool(json['return_eligible']),
      returnDeadline: parseString(json['return_deadline']),
      returnableQuantity: json['returnable_quantity'] != null
          ? parseInt(json['returnable_quantity'])
          : null,
      quantity: parseInt(json['quantity']),
      price: parseString(json['price']),
      subtotal: parseString(json['subtotal']),
      etaMin: json['eta_min'] != null ? parseInt(json['eta_min']) : null,
      etaMax: json['eta_max'] != null ? parseInt(json['eta_max']) : null,
      etaUnit: parseString(json['eta_unit']),
      deliveryEstimate: json['delivery_estimate'] is Map<String, dynamic>
          ? DeliveryEst.fromJson(json['delivery_estimate'] as Map<String, dynamic>)
          : null,
      status: parseString(json['status']),
      statusLabel: parseString(json['status_label']),
      orderItemCustomerStatus: json['customer_status'] is Map<String, dynamic>
          ? OrderItemCustomerStatus.fromJson(json['customer_status'] as Map<String, dynamic>)
          : null,
      timeline: _parseItemTimeline(json['timeline']),
      canCancel: parseBool(json['can_cancel']),
      cancelableQuantity: parseInt(json['cancelable_quantity']),
      cancellationReason: parseString(json['cancellation_reason']),
      deliveryFailReason: parseString(json['delivery_fail_reason']),
      otp: json['otp'],
      otpVerified: parseBool(json['otp_verified']),
      isUserReviewGiven: parseBool(json['is_user_review_given']),
      userReview: json['user_review'] != null
          ? UserReview.fromJson(json['user_review'])
          : null,
      product: json['product'] != null ? OrderDetailProduct.fromJson(json['product']) : null,
      variant: json['variant'] != null ? OrderDetailVariant.fromJson(json['variant']) : null,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      returns: _parseReturns(json['returns']),
      attachments: _parseAttachments(json['attachments']),
      addons: _parseAddons(json['addons']),
      addonsTotal: parseDouble(json['addons_total']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'product_variant_id': productVariantId,
    'store_id': storeId,
    'seller_id': sellerId,
    'seller_name': sellerName,
    'title': title,
    'variant_title': variantTitle,
    'gift_card_discount': giftCardDiscount,
    'admin_commission_amount': adminCommissionAmount,
    'seller_commission_amount': sellerCommissionAmount,
    'commission_settled': commissionSettled,
    'discounted_price': discountedPrice,
    'promo_discount': promoDiscount,
    'discount': discount,
    'tax_amount': taxAmount,
    'tax_percent': taxPercent,
    'sku': sku,
    'return_eligible': returnEligible,
    'return_deadline': returnDeadline,
    'returnable_quantity': returnableQuantity,
    'quantity': quantity,
    'price': price,
    'subtotal': subtotal,
    'eta_min': etaMin,
    'eta_max': etaMax,
    'eta_unit': etaUnit,
    'delivery_estimate': deliveryEstimate?.toJson(),
    'status': status,
    'status_label': statusLabel,
    if (orderItemCustomerStatus != null) 'customer_status': orderItemCustomerStatus!.toJson(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'can_cancel': canCancel,
    'cancelable_quantity': cancelableQuantity,
    'cancellation_reason': cancellationReason,
    'delivery_fail_reason': deliveryFailReason,
    'otp': otp,
    'otp_verified': otpVerified,
    'is_user_review_given': isUserReviewGiven,
    if (userReview != null) 'user_review': userReview!.toJson(),
    if (product != null) 'product': product!.toJson(),
    if (variant != null) 'variant': variant!.toJson(),
    if (store != null) 'store': store!.toJson(),
    'returns': returns.map((e) => e.toJson()).toList(),
    'attachments': attachments,
    'addons': addons.map((e) => e.toJson()).toList(),
    'addons_total': addonsTotal,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  static List<ItemReturn> _parseReturns(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ItemReturn.fromJson)
        .toList();
  }

  static List<String> _parseAttachments(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  static List<OrderTimelineStage> _parseItemTimeline(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(OrderTimelineStage.fromJson)
        .toList();
  }

  static List<OrderItemAddon> _parseAddons(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(OrderItemAddon.fromJson)
        .toList();
  }
}

class ItemReturn {
  final int? id;
  final int? orderItemId;
  final int? orderId;
  final int? userId;
  final int? sellerId;
  final int? storeId;
  final dynamic deliveryBoyId;
  final String? reason;
  final String? sellerComment;
  final List<String> images;
  final int? quantity;
  final int? refundAmount;
  final String? pickupStatus;
  final String? returnStatus;
  final CustomerStatus? returnItemCustomerStatus;
  final List<ReturnTimelineStep> returnTimeline;
  final String? sellerApprovedAt;
  final String? pickedUpAt;
  final String? receivedAt;
  final String? refundProcessedAt;
  final String? createdAt;
  final String? updatedAt;

  ItemReturn({
    this.id,
    this.orderItemId,
    this.orderId,
    this.userId,
    this.sellerId,
    this.storeId,
    this.deliveryBoyId,
    this.reason,
    this.sellerComment,
    this.images = const [],
    this.quantity,
    this.refundAmount,
    this.pickupStatus,
    this.returnStatus,
    this.returnItemCustomerStatus,
    this.returnTimeline = const [],
    this.sellerApprovedAt,
    this.pickedUpAt,
    this.receivedAt,
    this.refundProcessedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemReturn.fromJson(Map<String, dynamic> json) {
    return ItemReturn(
      id: parseInt(json['id']),
      orderItemId: parseInt(json['order_item_id']),
      orderId: parseInt(json['order_id']),
      userId: parseInt(json['user_id']),
      sellerId: parseInt(json['seller_id']),
      storeId: parseInt(json['store_id']),
      deliveryBoyId: json['delivery_boy_id'],
      reason: parseString(json['reason']),
      sellerComment: parseString(json['seller_comment']),
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
      quantity: json['quantity'] != null ? parseInt(json['quantity']) : null,
      refundAmount: parseInt(json['refund_amount']),
      pickupStatus: parseString(json['pickup_status']),
      returnStatus: parseString(json['return_status']),
      returnItemCustomerStatus: json['customer_status'] is Map<String, dynamic>
          ? CustomerStatus.fromJson(json['customer_status'] as Map<String, dynamic>)
          : null,
      returnTimeline: _parseReturnTimeline(json['return_timeline']),
      sellerApprovedAt: parseString(json['seller_approved_at']),
      pickedUpAt: parseString(json['picked_up_at']),
      receivedAt: parseString(json['received_at']),
      refundProcessedAt: parseString(json['refund_processed_at']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_item_id': orderItemId,
    'order_id': orderId,
    'user_id': userId,
    'seller_id': sellerId,
    'store_id': storeId,
    'delivery_boy_id': deliveryBoyId,
    'reason': reason,
    'seller_comment': sellerComment,
    'images': images,
    'quantity': quantity,
    'refund_amount': refundAmount,
    'pickup_status': pickupStatus,
    'return_status': returnStatus,
    if (returnItemCustomerStatus != null) 'customer_status': returnItemCustomerStatus!.toJson(),
    'return_timeline': returnTimeline.map((e) => e.toJson()).toList(),
    'seller_approved_at': sellerApprovedAt,
    'picked_up_at': pickedUpAt,
    'received_at': receivedAt,
    'refund_processed_at': refundProcessedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  static List<ReturnTimelineStep> _parseReturnTimeline(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ReturnTimelineStep.fromJson)
        .toList();
  }
}

// ────────────────────────────────────────────────

class OrderDetailProduct {
  final int? id;
  final String? name;
  final String? slug;
  final bool? isReturnable;
  final int? returnableDays;
  final bool? isCancelable;
  final String? cancelableTill;
  final String? image;
  final int? requiresOtp;
  final String? category;
  final String? brand;

  OrderDetailProduct({
    this.id,
    this.name,
    this.slug,
    this.isReturnable,
    this.returnableDays,
    this.isCancelable,
    this.cancelableTill,
    this.image,
    this.requiresOtp,
    this.category,
    this.brand,
  });

  factory OrderDetailProduct.fromJson(Map<String, dynamic> json) {
    return OrderDetailProduct(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      slug: parseString(json['slug']),
      isReturnable: parseBool(json['is_returnable']),
      returnableDays: parseInt(json['returnable_days']),
      isCancelable: parseBool(json['is_cancelable']),
      cancelableTill: parseString(json['cancelable_till']),
      image: parseString(json['image']),
      requiresOtp: parseInt(json['requires_otp']),
      category: parseString(json['category']),
      brand: parseString(json['brand'])
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'is_returnable': isReturnable,
    'returnable_days': returnableDays,
    'is_cancelable': isCancelable,
    'cancelable_till': cancelableTill,
    'image': image,
    'requires_otp': requiresOtp,
    'category': category,
    'brand': brand,
  };
}

class OrderDetailVariant {
  final int? id;
  final String? title;
  final String? slug;
  final String? image;

  OrderDetailVariant({
    this.id,
    this.title,
    this.slug,
    this.image,
  });

  factory OrderDetailVariant.fromJson(Map<String, dynamic> json) {
    return OrderDetailVariant(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      image: parseString(json['image']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'image': image,
  };
}

class Store {
  final int? id;
  final String? name;
  final String? slug;

  Store({
    this.id,
    this.name,
    this.slug,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      slug: parseString(json['slug']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
  };
}

class UserReview {
  final int? id;
  final int? productId;
  final int? rating;
  final String? title;
  final String? slug;
  final String? comment;
  final List<String> reviewImages;
  final User? user;
  final String? createdAt;

  UserReview({
    this.id,
    this.productId,
    this.rating,
    this.title,
    this.slug,
    this.comment,
    this.reviewImages = const [],
    this.user,
    this.createdAt,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: parseInt(json['id']),
      productId: parseInt(json['product_id']),
      rating: parseInt(json['rating']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      comment: parseString(json['comment']),
      reviewImages: (json['review_images'] as List<dynamic>?)?.cast<String>() ?? const [],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      createdAt: parseString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'rating': rating,
    'title': title,
    'slug': slug,
    'comment': comment,
    'review_images': reviewImages,
    if (user != null) 'user': user!.toJson(),
    'created_at': createdAt,
  };
}

class User {
  final int? id;
  final String? name;

  User({
    this.id,
    this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: parseInt(json['id']),
      name: parseString(json['name']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

/// A single selected addon attached to an [OrderItems] row.
class OrderItemAddon {
  final int? id;
  final String? uuid;
  final int? addonGroupId;
  final int? addonItemId;
  final double? price;
  final OrderItemAddonGroup? group;
  final OrderItemAddonItem? item;

  OrderItemAddon({
    this.id,
    this.uuid,
    this.addonGroupId,
    this.addonItemId,
    this.price,
    this.group,
    this.item,
  });

  factory OrderItemAddon.fromJson(Map<String, dynamic> json) {
    return OrderItemAddon(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      addonGroupId: parseInt(json['addon_group_id']),
      addonItemId: parseInt(json['addon_item_id']),
      price: parseDouble(json['price']),
      group: json['group'] != null && json['group'] is Map<String, dynamic>
          ? OrderItemAddonGroup.fromJson(json['group'] as Map<String, dynamic>)
          : null,
      item: json['item'] != null && json['item'] is Map<String, dynamic>
          ? OrderItemAddonItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'addon_group_id': addonGroupId,
        'addon_item_id': addonItemId,
        'price': price,
        if (group != null) 'group': group!.toJson(),
        if (item != null) 'item': item!.toJson(),
      };
}

class OrderItemAddonGroup {
  final int? id;
  final String? title;
  final String? selectionType;
  final bool? isRequired;

  OrderItemAddonGroup({
    this.id,
    this.title,
    this.selectionType,
    this.isRequired,
  });

  factory OrderItemAddonGroup.fromJson(Map<String, dynamic> json) {
    return OrderItemAddonGroup(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      selectionType: parseString(json['selection_type']),
      isRequired: parseBool(json['is_required']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'selection_type': selectionType,
        'is_required': isRequired,
      };
}

class OrderItemAddonItem {
  final int? id;
  final String? title;
  final String? indicator;

  OrderItemAddonItem({
    this.id,
    this.title,
    this.indicator,
  });

  factory OrderItemAddonItem.fromJson(Map<String, dynamic> json) {
    return OrderItemAddonItem(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      indicator: parseString(json['indicator']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'indicator': indicator,
      };
}


class CustomerStatus {
  final String? code;
  final String? label;
  final String? description;
  final int? stage;
  final bool? isException;

  CustomerStatus({
    this.code,
    this.label,
    this.description,
    this.stage,
    this.isException,
  });

  factory CustomerStatus.fromJson(Map<String, dynamic> json) {
    return CustomerStatus(
      code: parseString(json['code']),
      label: parseString(json['label']),
      description: parseString(json['description']),
      stage: json['stage'] != null ? parseInt(json['stage']) : null,
      isException: json['is_exception'] != null ? parseBool(json['is_exception']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
        'description': description,
        'stage': stage,
        'is_exception': isException,
      };
}

class OrderItemCustomerStatus {
  final String? code;
  final String? label;
  final String? at;

  OrderItemCustomerStatus({
    this.code,
    this.label,
    this.at,
  });

  factory OrderItemCustomerStatus.fromJson(Map<String, dynamic> json) {
    return OrderItemCustomerStatus(
      code: parseString(json['code']),
      label: parseString(json['label']),
      at: parseString(json['at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'label': label,
    'at': at
  };
}

/// Delivery window for an order item. [from] and [to] are ISO dates.
class DeliveryEst {
  final String? from;
  final String? to;
  final String? unit;

  DeliveryEst({
    this.from,
    this.to,
    this.unit,
  });

  factory DeliveryEst.fromJson(Map<String, dynamic> json) {
    return DeliveryEst(
      from: parseString(json['from']),
      to: parseString(json['to']),
      unit: parseString(json['unit']),
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'unit': unit,
  };

  bool get isEmpty =>
      (from ?? '').trim().isEmpty && (to ?? '').trim().isEmpty;
}

class OrderTimelineStage {
  final String? key;
  final String? label;
  final bool? done;
  final bool? current;
  final String? marker;
  final String? at;
  final List<OrderTimelineEvent> events;

  OrderTimelineStage({
    this.key,
    this.label,
    this.done,
    this.current,
    this.marker,
    this.at,
    this.events = const [],
  });

  factory OrderTimelineStage.fromJson(Map<String, dynamic> json) {
    return OrderTimelineStage(
      key: parseString(json['key']),
      label: parseString(json['label']),
      done: parseBool(json['done']),
      current: parseBool(json['current']),
      marker: parseString(json['marker']),
      at: parseString(json['at']),
      events: _parseEvents(json['events']),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'done': done,
        'current': current,
        'marker': marker,
        'at': at,
        'events': events.map((e) => e.toJson()).toList(),
      };

  static List<OrderTimelineEvent> _parseEvents(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(OrderTimelineEvent.fromJson)
        .toList();
  }
}

/// A single event within an [OrderTimelineStage]. [meta] is free-form per event.
class OrderTimelineEvent {
  final String? code;
  final String? label;
  final bool? done;
  final String? at;
  final bool? isException;
  final Map<String, dynamic>? meta;

  OrderTimelineEvent({
    this.code,
    this.label,
    this.done,
    this.at,
    this.isException,
    this.meta,
  });

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      code: parseString(json['code']),
      label: parseString(json['label']),
      done: parseBool(json['done']),
      at: json['at'] != null ? parseString(json['at']) : null,
      isException: parseBool(json['is_exception']),
      meta: json['meta'] is Map<String, dynamic> ? json['meta'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
        'done': done,
        'at': at,
        'is_exception': isException,
        'meta': meta,
      };
}

/// One step of a return/refund progress timeline.
class ReturnTimelineStep {
  final String? key;
  final String? label;
  final bool? done;
  final String? at;

  ReturnTimelineStep({
    this.key,
    this.label,
    this.done,
    this.at,
  });

  factory ReturnTimelineStep.fromJson(Map<String, dynamic> json) {
    return ReturnTimelineStep(
      key: parseString(json['key']),
      label: parseString(json['label']),
      done: parseBool(json['done']),
      at: json['at'] != null ? parseString(json['at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'done': done,
        'at': at,
      };
}