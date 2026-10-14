import 'package:hyper_commerce/utils/money_format.dart';

class WishlistProductModel {
  bool? success;
  String? message;
  WishlistData? data;

  WishlistProductModel({this.success, this.message, this.data});

  WishlistProductModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? WishlistData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class WishlistData {
  int? id;
  String? title;
  String? slug;
  int? itemsCount;
  List<WishlistProductItems>? items;
  String? createdAt;
  String? updatedAt;

  WishlistData(
      {this.id,
        this.title,
        this.slug,
        this.itemsCount,
        this.items,
        this.createdAt,
        this.updatedAt});

  WishlistData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    slug = json['slug'];
    itemsCount = json['items_count'];
    if (json['items'] != null) {
      items = <WishlistProductItems>[];
      json['items'].forEach((v) {
        items!.add(WishlistProductItems.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['items_count'] = itemsCount;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class WishlistProductItems {
  int? id;
  int? wishlistId;
  Product? product;
  Variant? variant;
  Store? store;
  String? createdAt;
  String? updatedAt;

  WishlistProductItems(
      {this.id,
        this.wishlistId,
        this.product,
        this.variant,
        this.store,
        this.createdAt,
        this.updatedAt});

  WishlistProductItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    wishlistId = json['wishlist_id'];
    product =
    json['product'] != null ? Product.fromJson(json['product']) : null;
    variant =
    json['variant'] != null ? Variant.fromJson(json['variant']) : null;
    store = json['store'] != null ? Store.fromJson(json['store']) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['wishlist_id'] = wishlistId;
    if (product != null) {
      data['product'] = product!.toJson();
    }
    if (variant != null) {
      data['variant'] = variant!.toJson();
    }
    if (store != null) {
      data['store'] = store!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Product {
  int? id;
  String? title;
  String? slug;
  String? image;
  int? minimumOrderQuantity;
  int? quantityStepSize;
  int? totalAllowedQuantity;
  String? shortDescription;
  String? estimatedDeliveryTime;
  String? imageFit;
  StoreStatus? storeStatus;
  // `ratings` is the product's average rating — the API sends a decimal
  // (e.g. 4.5), so it must be parsed as a double, not an int.
  double? ratings;
  int? ratingCount;

  Product(
      {this.id,
        this.title,
        this.slug,
        this.image,
        this.minimumOrderQuantity,
        this.quantityStepSize,
        this.totalAllowedQuantity,
        this.shortDescription,
        this.estimatedDeliveryTime,
        this.imageFit,
        this.storeStatus,
        this.ratings,
        this.ratingCount});

  Product.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    slug = json['slug'];
    image = json['image'];
    minimumOrderQuantity = json['minimum_order_quantity'];
    quantityStepSize = json['quantity_step_size'];
    totalAllowedQuantity = json['total_allowed_quantity'];
    shortDescription = json['short_description'];
    estimatedDeliveryTime = json['estimated_delivery_time'].toString();
    imageFit = json['image_fit'];
    storeStatus = json['store_status'] != null
        ? StoreStatus.fromJson(json['store_status'])
        : null;
    ratings = json['ratings'] is num ? (json['ratings'] as num).toDouble() : null;
    ratingCount = json['rating_count'] is num ? (json['rating_count'] as num).toInt() : 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    data['minimum_order_quantity'] = minimumOrderQuantity;
    data['quantity_step_size'] = quantityStepSize;
    data['total_allowed_quantity'] = totalAllowedQuantity;
    data['short_description'] = shortDescription;
    data['estimated_delivery_time'] = estimatedDeliveryTime;
    data['image_fit'] = imageFit;
    if (storeStatus != null) {
      data['store_status'] = storeStatus!.toJson();
    }
    data['ratings'] = ratings;
    data['rating_count'] = ratingCount;
    return data;
  }
}

class StoreStatus {
  bool? isOpen;
  String? status;

  StoreStatus({this.isOpen, this.status});

  StoreStatus.fromJson(Map<String, dynamic> json) {
    isOpen = json['is_open'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['status'] = status;
    return data;
  }
}

class Variant {
  int? id;
  String? sku;
  String? image;
  num? price;
  num? specialPrice;
  double? priceBase;
  double? specialPriceBase;
  String? currencyCode;
  String? currencySymbol;
  double? fxRate;
  String formatted = '';
  MoneyFormat format = MoneyFormat.defaults;
  int? storeId;
  String? storeSlug;
  String? storeName;
  int? stock;
  bool? isInStock;

  Variant(
      {this.id,
        this.sku,
        this.image,
        this.price,
        this.specialPrice,
        this.priceBase,
        this.specialPriceBase,
        this.currencyCode,
        this.currencySymbol,
        this.fxRate,
        this.formatted = '',
        this.format = MoneyFormat.defaults,
        this.storeId,
        this.storeSlug,
        this.storeName,
        this.stock,
        this.isInStock
      });

  Variant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sku = json['sku'];
    image = json['image'];
    price = json['price'] is num ? json['price'] as num : null;
    specialPrice = json['special_price'] is num ? json['special_price'] as num : null;
    priceBase = (json['price_base'] ?? json['price']) is num
        ? (json['price_base'] ?? json['price']).toDouble()
        : null;
    specialPriceBase = (json['special_price_base'] ?? json['special_price']) is num
        ? (json['special_price_base'] ?? json['special_price']).toDouble()
        : null;
    currencyCode = json['currency_code'];
    currencySymbol = json['currency_symbol'];
    fxRate = json['fx_rate'] is num ? (json['fx_rate'] as num).toDouble() : null;
    formatted = (json['formatted'] ?? '').toString();
    format = json['format'] is Map<String, dynamic>
        ? MoneyFormat.fromJson(Map<String, dynamic>.from(json['format']))
        : MoneyFormat.defaults;
    storeId = json['store_id'];
    storeSlug = json['store_slug'];
    storeName = json['store_name'];
    stock = json['stock'];
    isInStock = json['is_in_stock'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sku'] = sku;
    data['image'] = image;
    data['price'] = price;
    data['special_price'] = specialPrice;
    data['price_base'] = priceBase;
    data['special_price_base'] = specialPriceBase;
    data['currency_code'] = currencyCode;
    data['currency_symbol'] = currencySymbol;
    data['fx_rate'] = fxRate;
    data['formatted'] = formatted;
    data['format'] = format.toJson();
    data['store_id'] = storeId;
    data['store_slug'] = storeSlug;
    data['store_name'] = storeName;
    data['stock'] = stock;
    data['is_in_stock'] = isInStock;
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? slug;

  Store({this.id, this.name, this.slug});

  Store.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    return data;
  }
}
