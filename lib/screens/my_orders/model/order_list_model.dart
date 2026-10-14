import 'package:hyper_commerce/config/helper.dart';

class OrderListResponse {
  final bool? success;
  final String? message;
  final OrderListData? data;

  OrderListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: json['data'] is Map<String, dynamic>
          ? OrderListData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}

class OrderListData {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;
  final List<OrderListItem> items;

  OrderListData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.items = const [],
  });

  factory OrderListData.fromJson(Map<String, dynamic> json) {
    return OrderListData(
      currentPage: parseInt(json['current_page']),
      lastPage: parseInt(json['last_page']),
      perPage: parseInt(json['per_page']),
      total: parseInt(json['total']),
      items: _parseItems(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
    'current_page': currentPage,
    'last_page': lastPage,
    'per_page': perPage,
    'total': total,
    'data': items.map((e) => e.toJson()).toList(),
  };

  static List<OrderListItem> _parseItems(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(OrderListItem.fromJson)
        .toList();
  }
}

class OrderListItem {
  final int? id;
  final int? orderId;
  final String? title;
  final String? variantTitle;
  final String? slug;
  final String? sku;
  final int? quantity;
  final String? price;
  final String? subtotal;
  final String? status;
  final OrderListCustomerStatus? customerStatus;
  final bool? returnEligible;
  final String? returnDeadline;
  final bool? canCancel;
  final int? cancelableQuantity;
  final int? sellerId;
  final String? sellerName;
  final bool? isUserReviewGiven;
  final OrderListUserReview? userReview;
  final OrderListProduct? product;
  final OrderListVariant? variant;
  final OrderListStore? store;
  final OrderListOrder? order;
  final String? createdAt;

  OrderListItem({
    this.id,
    this.orderId,
    this.title,
    this.variantTitle,
    this.slug,
    this.sku,
    this.quantity,
    this.price,
    this.subtotal,
    this.status,
    this.customerStatus,
    this.returnEligible,
    this.returnDeadline,
    this.canCancel,
    this.cancelableQuantity,
    this.sellerId,
    this.sellerName,
    this.isUserReviewGiven,
    this.userReview,
    this.product,
    this.variant,
    this.store,
    this.order,
    this.createdAt,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      id: parseInt(json['id']),
      orderId: parseInt(json['order_id']),
      title: parseString(json['title']),
      variantTitle: parseString(json['variant_title']),
      slug: parseString(json['slug']),
      sku: parseString(json['sku']),
      quantity: parseInt(json['quantity']),
      price: parseString(json['price']),
      subtotal: parseString(json['subtotal']),
      status: parseString(json['status']),
      customerStatus: json['customer_status'] is Map<String, dynamic>
          ? OrderListCustomerStatus.fromJson(json['customer_status'])
          : null,
      returnEligible: parseBool(json['return_eligible']),
      returnDeadline: parseString(json['return_deadline']),
      canCancel: parseBool(json['can_cancel']),
      cancelableQuantity: parseInt(json['cancelable_quantity']),
      sellerId: parseInt(json['seller_id']),
      sellerName: parseString(json['seller_name']),
      isUserReviewGiven: parseBool(json['is_user_review_given']),
      userReview: json['user_review'] is Map<String, dynamic>
          ? OrderListUserReview.fromJson(json['user_review'])
          : null,
      product: json['product'] is Map<String, dynamic>
          ? OrderListProduct.fromJson(json['product'])
          : null,
      variant: json['variant'] is Map<String, dynamic>
          ? OrderListVariant.fromJson(json['variant'])
          : null,
      store: json['store'] is Map<String, dynamic>
          ? OrderListStore.fromJson(json['store'])
          : null,
      order: json['order'] is Map<String, dynamic>
          ? OrderListOrder.fromJson(json['order'])
          : null,
      createdAt: parseString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'title': title,
    'variant_title': variantTitle,
    'slug': slug,
    'sku': sku,
    'quantity': quantity,
    'price': price,
    'subtotal': subtotal,
    'status': status,
    if (customerStatus != null) 'customer_status': customerStatus!.toJson(),
    'return_eligible': returnEligible,
    'return_deadline': returnDeadline,
    'can_cancel': canCancel,
    'cancelable_quantity': cancelableQuantity,
    'seller_id': sellerId,
    'seller_name': sellerName,
    'is_user_review_given': isUserReviewGiven,
    if (userReview != null) 'user_review': userReview!.toJson(),
    if (product != null) 'product': product!.toJson(),
    if (variant != null) 'variant': variant!.toJson(),
    if (store != null) 'store': store!.toJson(),
    if (order != null) 'order': order!.toJson(),
    'created_at': createdAt,
  };
}

class OrderListCustomerStatus {
  final String? code;
  final String? label;
  final String? at;

  OrderListCustomerStatus({
    this.code,
    this.label,
    this.at,
  });

  factory OrderListCustomerStatus.fromJson(Map<String, dynamic> json) {
    return OrderListCustomerStatus(
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

class OrderListProduct {
  final int? id;
  final String? name;
  final String? slug;
  final String? image;
  final String? category;
  final String? brand;

  OrderListProduct({
    this.id,
    this.name,
    this.slug,
    this.image,
    this.category,
    this.brand,
  });

  factory OrderListProduct.fromJson(Map<String, dynamic> json) {
    return OrderListProduct(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      slug: parseString(json['slug']),
      image: parseString(json['image']),
      category: parseString(json['category']),
      brand: parseString(json['brand'])
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'image': image,
    'category': category,
    'brand': brand,
  };
}

class OrderListVariant {
  final int? id;
  final String? title;
  final String? image;

  OrderListVariant({
    this.id,
    this.title,
    this.image,
  });

  factory OrderListVariant.fromJson(Map<String, dynamic> json) {
    return OrderListVariant(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      image: parseString(json['image']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image': image,
  };
}

class OrderListStore {
  final int? id;
  final String? name;
  final String? slug;

  OrderListStore({
    this.id,
    this.name,
    this.slug,
  });

  factory OrderListStore.fromJson(Map<String, dynamic> json) {
    return OrderListStore(
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

class OrderListOrder {
  final int? id;
  final String? uuid;
  final String? slug;
  final String? orderDate;
  final String? status;
  final String? statusLabel;
  final String? paymentMethod;
  final String? paymentStatus;
  final OrderListCurrency? currency;
  final double? finalTotal;
  final double? totalPayable;

  OrderListOrder({
    this.id,
    this.uuid,
    this.slug,
    this.orderDate,
    this.status,
    this.statusLabel,
    this.paymentMethod,
    this.paymentStatus,
    this.currency,
    this.finalTotal,
    this.totalPayable,
  });

  factory OrderListOrder.fromJson(Map<String, dynamic> json) {
    return OrderListOrder(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      slug: parseString(json['slug']),
      orderDate: parseString(json['order_date']),
      status: parseString(json['status']),
      statusLabel: parseString(json['status_label']),
      paymentMethod: parseString(json['payment_method']),
      paymentStatus: parseString(json['payment_status']),
      currency: json['currency'] is Map<String, dynamic>
          ? OrderListCurrency.fromJson(json['currency'])
          : null,
      finalTotal: parseDouble(json['final_total']),
      totalPayable: parseDouble(json['total_payable']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'slug': slug,
    'order_date': orderDate,
    'status': status,
    'status_label': statusLabel,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    if (currency != null) 'currency': currency!.toJson(),
    'final_total': finalTotal,
    'total_payable': totalPayable,
  };
}

class OrderListCurrency {
  final String? code;
  final String? symbol;
  final OrderListCurrencyFormat? format;

  OrderListCurrency({
    this.code,
    this.symbol,
    this.format,
  });

  factory OrderListCurrency.fromJson(Map<String, dynamic> json) {
    return OrderListCurrency(
      code: parseString(json['code']),
      symbol: parseString(json['symbol']),
      format: json['format'] is Map<String, dynamic>
          ? OrderListCurrencyFormat.fromJson(json['format'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'symbol': symbol,
    if (format != null) 'format': format!.toJson(),
  };
}

class OrderListCurrencyFormat {
  final String? symbolPosition;
  final bool? spaceBetweenSymbol;
  final String? thousandSeparator;
  final String? decimalSeparator;
  final String? groupingStyle;
  final int? decimalPlaces;
  final String? negativeFormat;

  OrderListCurrencyFormat({
    this.symbolPosition,
    this.spaceBetweenSymbol,
    this.thousandSeparator,
    this.decimalSeparator,
    this.groupingStyle,
    this.decimalPlaces,
    this.negativeFormat,
  });

  factory OrderListCurrencyFormat.fromJson(Map<String, dynamic> json) {
    return OrderListCurrencyFormat(
      symbolPosition: parseString(json['symbol_position']),
      spaceBetweenSymbol: parseBool(json['space_between_symbol']),
      thousandSeparator: parseString(json['thousand_separator']),
      decimalSeparator: parseString(json['decimal_separator']),
      groupingStyle: parseString(json['grouping_style']),
      decimalPlaces: parseInt(json['decimal_places']),
      negativeFormat: parseString(json['negative_format']),
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol_position': symbolPosition,
    'space_between_symbol': spaceBetweenSymbol,
    'thousand_separator': thousandSeparator,
    'decimal_separator': decimalSeparator,
    'grouping_style': groupingStyle,
    'decimal_places': decimalPlaces,
    'negative_format': negativeFormat,
  };
}

class OrderListUserReview {
  final int? id;
  final int? productId;
  final int? storeId;
  final int? orderId;
  final int? orderItemId;
  final int? rating;
  final String? title;
  final String? slug;
  final String? comment;
  final List<String> reviewImages;
  final OrderListReviewUser? user;
  final String? createdAt;

  OrderListUserReview({
    this.id,
    this.productId,
    this.storeId,
    this.orderId,
    this.orderItemId,
    this.rating,
    this.title,
    this.slug,
    this.comment,
    this.reviewImages = const [],
    this.user,
    this.createdAt,
  });

  factory OrderListUserReview.fromJson(Map<String, dynamic> json) {
    return OrderListUserReview(
      id: parseInt(json['id']),
      productId: parseInt(json['product_id']),
      storeId: parseInt(json['store_id']),
      orderId: parseInt(json['order_id']),
      orderItemId: parseInt(json['order_item_id']),
      rating: parseInt(json['rating']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      comment: parseString(json['comment']),
      reviewImages: (json['review_images'] as List<dynamic>?)?.cast<String>() ??
          const [],
      user: json['user'] is Map<String, dynamic>
          ? OrderListReviewUser.fromJson(json['user'])
          : null,
      createdAt: parseString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'store_id': storeId,
    'order_id': orderId,
    'order_item_id': orderItemId,
    'rating': rating,
    'title': title,
    'slug': slug,
    'comment': comment,
    'review_images': reviewImages,
    if (user != null) 'user': user!.toJson(),
    'created_at': createdAt,
  };
}

class OrderListReviewUser {
  final int? id;
  final String? name;

  OrderListReviewUser({
    this.id,
    this.name,
  });

  factory OrderListReviewUser.fromJson(Map<String, dynamic> json) {
    return OrderListReviewUser(
      id: parseInt(json['id']),
      name: parseString(json['name']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}
