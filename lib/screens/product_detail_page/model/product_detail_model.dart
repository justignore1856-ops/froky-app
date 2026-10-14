import 'dart:developer' as developer;

import '../../../config/helper.dart';
import '../../../utils/money_format.dart';

class ProductDetailModel {
  final bool success;
  final String message;
  final ProductData? data;

  ProductDetailModel({
    bool? success,
    String? message,
    this.data,
  })  : success = success ?? false,
        message = message ?? '';

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProductDetailModel(
        success: parseBool(json['success']),
        message: parseString(json['message']),
        data: json['data'] != null ? ProductData.fromJson(json['data']) : null,
      );
    } catch (e, stack) {
      developer.log('Error parsing ProductDetailModel: $e', stackTrace: stack);
      return ProductDetailModel(success: false, message: 'Failed to parse');
    }
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}

class ProductData {
  final int id;
  final String uuid;
  final int categoryId;
  final int brandId;
  final int sellerId;
  final String title;
  final String slug;
  final String type;
  final String shortDescription;
  final String description;
  final String category;
  final String brand;
  final String seller;
  final String categoryName;
  final String brandName;
  final String indicator;
  final List<FavoriteItem> favorite;
  final String estimatedDeliveryTime;
  final int basePrepTime;
  final DeliveryEta? deliveryEta;
  final double ratings;
  final int ratingCount;
  final String mainImage;
  final String imageFit;
  final String itemCountInCart;
  final bool isSaveForLater;
  final List<String> additionalImages;
  final int minimumOrderQuantity;
  final int quantityStepSize;
  final int totalAllowedQuantity;
  final bool isReturnable;
  final int returnableDays;
  final bool allowCod;
  final bool isAttachmentRequired;
  final String attachmentMode;
  final bool requiresOtp;
  final List<String> tags;
  final List<CustomField> customFields;
  final String warrantyPeriod;
  final String guaranteePeriod;
  final String madeIn;
  final bool isInclusiveTax;
  final String videoType;
  final String videoLink;
  final String status;
  final String featured;
  final Badge? badge;
  final dynamic metadata;
  final String createdAt;
  final String updatedAt;
  final StoreStatus? storeStatus;
  final List<ProductVariants> variants;
  final List<ProductAttributes> attributes;
  final List<CustomProductFeaturedSections> customProductFeaturedSections;
  final bool isSponsored;
  final int campaignId;
  final String visitorKey;

  ProductData({
    int? id,
    String? uuid,
    int? categoryId,
    int? brandId,
    int? sellerId,
    String? title,
    String? slug,
    String? type,
    String? shortDescription,
    String? description,
    String? category,
    String? brand,
    String? seller,
    String? categoryName,
    String? brandName,
    String? indicator,
    List<FavoriteItem>? favorite,
    String? estimatedDeliveryTime,
    int? basePrepTime,
    this.deliveryEta,
    double? ratings,
    int? ratingCount,
    String? mainImage,
    String? imageFit,
    String? itemCountInCart,
    bool? isSaveForLater,
    List<String>? additionalImages,
    int? minimumOrderQuantity,
    int? quantityStepSize,
    int? totalAllowedQuantity,
    bool? isReturnable,
    int? returnableDays,
    bool? allowCod,
    bool? isAttachmentRequired,
    String? attachmentMode,
    bool? requiresOtp,
    List<String>? tags,
    List<CustomField>? customFields,
    String? warrantyPeriod,
    String? guaranteePeriod,
    String? madeIn,
    bool? isInclusiveTax,
    String? videoType,
    String? videoLink,
    String? status,
    String? featured,
    this.badge,
    this.metadata,
    String? createdAt,
    String? updatedAt,
    this.storeStatus,
    List<ProductVariants>? variants,
    List<ProductAttributes>? attributes,
    List<CustomProductFeaturedSections>? customProductFeaturedSections,
    bool? isSponsored,
    int? campaignId,
    String? visitorKey,
  })  : id = id ?? 0,
        uuid = uuid ?? '',
        categoryId = categoryId ?? 0,
        brandId = brandId ?? 0,
        sellerId = sellerId ?? 0,
        title = title ?? '',
        slug = slug ?? '',
        type = type ?? '',
        shortDescription = shortDescription ?? '',
        description = description ?? '',
        category = category ?? '',
        brand = brand ?? '',
        seller = seller ?? '',
        categoryName = categoryName ?? '',
        brandName = brandName ?? '',
        indicator = indicator ?? '',
        favorite = favorite ?? const [],
        estimatedDeliveryTime = estimatedDeliveryTime ?? '',
        basePrepTime = basePrepTime ?? 0,
        ratings = ratings ?? 0.0,
        ratingCount = ratingCount ?? 0,
        mainImage = mainImage ?? '',
        imageFit = imageFit ?? '',
        itemCountInCart = itemCountInCart ?? '0',
        isSaveForLater = isSaveForLater ?? false,
        additionalImages = additionalImages ?? const [],
        minimumOrderQuantity = minimumOrderQuantity ?? 0,
        quantityStepSize = quantityStepSize ?? 1,
        totalAllowedQuantity = totalAllowedQuantity ?? 0,
        isReturnable = isReturnable ?? false,
        returnableDays = returnableDays ?? 7,
        allowCod = allowCod ?? true,
        isAttachmentRequired = isAttachmentRequired ?? false,
        attachmentMode = attachmentMode ?? '',
        requiresOtp = requiresOtp ?? false,
        tags = tags ?? const [],
        customFields = customFields ?? const [],
        warrantyPeriod = warrantyPeriod ?? '',
        guaranteePeriod = guaranteePeriod ?? '',
        madeIn = madeIn ?? '',
        isInclusiveTax = isInclusiveTax ?? false,
        videoType = videoType ?? '',
        videoLink = videoLink ?? '',
        status = status ?? '',
        featured = featured ?? '',
        createdAt = createdAt ?? '',
        updatedAt = updatedAt ?? '',
        variants = variants ?? const [],
        attributes = attributes ?? const [],
        customProductFeaturedSections = customProductFeaturedSections ?? const [],
        isSponsored = isSponsored ?? false,
        campaignId = campaignId ?? 0,
        visitorKey = visitorKey ?? '';

  factory ProductData.fromJson(Map<String, dynamic> json) {
    try {
      return ProductData(
        id: parseInt(json['id']),
        uuid: parseString(json['uuid']),
        categoryId: parseInt(json['category_id']),
        brandId: parseInt(json['brand_id']),
        sellerId: parseInt(json['seller_id']),
        title: parseString(json['title']),
        slug: parseString(json['slug']),
        type: parseString(json['type']),
        shortDescription: parseString(json['short_description']),
        description: parseString(json['description']),
        category: parseString(json['category']),
        brand: parseString(json['brand']),
        seller: parseString(json['seller']),
        categoryName: parseString(json['category_name']),
        brandName: parseString(json['brand_name']),
        indicator: parseString(json['indicator']),
        favorite: _parseFavoriteItems(json['favorite']),
        estimatedDeliveryTime: parseString(json['estimated_delivery_time']),
        basePrepTime: parseInt(json['base_prep_time']),
        deliveryEta: json['delivery_eta'] != null ? DeliveryEta.fromJson(json['delivery_eta']) : null,
        ratings: parseDouble(json['ratings']),
        ratingCount: parseInt(json['rating_count']),
        mainImage: parseString(json['main_image']),
        imageFit: parseString(json['image_fit']),
        itemCountInCart: parseString(json['item_count_in_cart']),
        isSaveForLater: parseBool(json['is_save_for_later']),
        additionalImages: _parseStringList(json['additional_images']),
        minimumOrderQuantity: parseInt(json['minimum_order_quantity']),
        quantityStepSize: parseInt(json['quantity_step_size']),
        totalAllowedQuantity: parseInt(json['total_allowed_quantity']),
        isReturnable: parseBool(json['is_returnable']),
        returnableDays: parseInt(json['returnable_days']),
        allowCod: parseBool(json['allow_cod']),
        isAttachmentRequired: parseBool(json['is_attachment_required']),
        attachmentMode: parseString(json['attachment_mode']),
        requiresOtp: parseBool(json['requires_otp']),
        tags: _parseTags(json['tags']),
        customFields: _parseCustomFields(json['custom_fields']),
        warrantyPeriod: parseString(json['warranty_period']),
        guaranteePeriod: parseString(json['guarantee_period']),
        madeIn: parseString(json['made_in']),
        isInclusiveTax: parseBool(json['is_inclusive_tax']),
        videoType: parseString(json['video_type']),
        videoLink: parseString(json['video_link']),
        status: parseString(json['status']),
        featured: parseString(json['featured']),
        badge: json['badge'] != null ? Badge.fromJson(json['badge']) : null,
        metadata: json['metadata'],
        createdAt: parseString(json['created_at']),
        updatedAt: parseString(json['updated_at']),
        storeStatus: json['store_status'] != null
            ? StoreStatus.fromJson(json['store_status'])
            : null,
        variants: _parseVariants(json['variants']),
        attributes: _parseAttributes(json['attributes']),
        customProductFeaturedSections: _parseCustomProductFeaturedSections(json['custom_product_sections']),
        isSponsored: parseBool(json['is_sponsored']),
        campaignId: parseInt(json['campaign_id']),
        visitorKey: parseString(json['visitor_key']),
      );
    } catch (e, stack) {
      developer.log('Error parsing ProductData: $e', stackTrace: stack);
      return ProductData();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'category_id': categoryId,
    'brand_id': brandId,
    'seller_id': sellerId,
    'title': title,
    'slug': slug,
    'type': type,
    'short_description': shortDescription,
    'description': description,
    'category': category,
    'brand': brand,
    'seller': seller,
    'category_name': categoryName,
    'brand_name': brandName,
    'indicator': indicator,
    if (favorite.isNotEmpty) 'favorite': favorite.map((e) => e.toJson()).toList(),
    'estimated_delivery_time': estimatedDeliveryTime,
    'base_prep_time': basePrepTime,
    'delivery_eta': deliveryEta?.toJson(),
    'ratings': ratings,
    'rating_count': ratingCount,
    'main_image': mainImage,
    'image_fit': imageFit,
    'item_count_in_cart': itemCountInCart,
    'is_save_for_later': isSaveForLater,
    'additional_images': additionalImages,
    'minimum_order_quantity': minimumOrderQuantity,
    'quantity_step_size': quantityStepSize,
    'total_allowed_quantity': totalAllowedQuantity,
    'is_returnable': isReturnable,
    'returnable_days': returnableDays,
    'allow_cod': allowCod,
    'is_attachment_required': isAttachmentRequired,
    'attachment_mode': attachmentMode,
    'requires_otp': requiresOtp,
    'tags': tags,
    'custom_fields': customFields.map((e) => {'key': e.key, 'value': e.value}).toList(),
    'warranty_period': warrantyPeriod,
    'guarantee_period': guaranteePeriod,
    'made_in': madeIn,
    'is_inclusive_tax': isInclusiveTax,
    'video_type': videoType,
    'video_link': videoLink,
    'status': status,
    'featured': featured,
    if (badge != null) 'badge': badge!.toJson(),
    'metadata': metadata,
    'created_at': createdAt,
    'updated_at': updatedAt,
    if (storeStatus != null) 'store_status': storeStatus!.toJson(),
    'variants': variants.map((e) => e.toJson()).toList(),
    'attributes': attributes.map((e) => e.toJson()).toList(),

    if (customProductFeaturedSections.isNotEmpty)
      'custom_product_featured_sections':
      customProductFeaturedSections.map((e) => e.toJson()).toList(),
    'is_sponsored': isSponsored,
    'campaign_id': campaignId,
    'visitor_key': visitorKey
  };

  static List<FavoriteItem> _parseFavoriteItems(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(FavoriteItem.fromJson)
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is String) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is Iterable) {
      return value.whereType<String>().where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }

  static List<String> _parseTags(dynamic value) {
    return _parseStringList(value);
  }

  static List<CustomField> _parseCustomFields(dynamic value) {
    if (value is! Map<String, dynamic>) return const [];
    return value.entries.map((e) => CustomField(key: e.key, value: e.value)).toList();
  }

  static List<ProductVariants> _parseVariants(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ProductVariants.fromJson)
        .toList();
  }

  static List<ProductAttributes> _parseAttributes(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ProductAttributes.fromJson)
        .toList();
  }

  static List<CustomProductFeaturedSections> _parseCustomProductFeaturedSections(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CustomProductFeaturedSections.fromJson)
        .toList();
  }
}

class StoreStatus {
  final bool isOpen;
  final CurrentSlot? currentSlot;
  final String nextOpeningTime;

  StoreStatus({
    bool? isOpen,
    this.currentSlot,
    String? nextOpeningTime,
  })  : isOpen = isOpen ?? false,
        nextOpeningTime = nextOpeningTime ?? '';

  factory StoreStatus.fromJson(Map<String, dynamic> json) {
    return StoreStatus(
      isOpen: parseBool(json['is_open']),
      currentSlot: json['current_slot'] != null
          ? CurrentSlot.fromJson(json['current_slot'])
          : null,
      nextOpeningTime: parseString(json['next_opening_time']),
    );
  }

  Map<String, dynamic> toJson() => {
    'is_open': isOpen,
    if (currentSlot != null) 'current_slot': currentSlot!.toJson(),
    'next_opening_time': nextOpeningTime,
  };
}

class CurrentSlot {
  final String from;
  final String to;

  CurrentSlot({
    String? from,
    String? to,
  })  : from = from ?? '',
        to = to ?? '';

  factory CurrentSlot.fromJson(Map<String, dynamic> json) {
    return CurrentSlot(
      from: parseString(json['from']),
      to: parseString(json['to']),
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
  };
}

class CustomField {
  final String key;
  final dynamic value;

  CustomField({required this.key, required this.value});

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}

class ProductVariants {
  final int id;
  final String title;
  final String slug;
  final String image;
  final int weight;
  final int height;
  final int breadth;
  final int length;
  final bool availability;
  final String barcode;
  final bool isDefault;
  final double price;
  final double specialPrice;
  final double priceBase;
  final double specialPriceBase;
  final String currencyCode;
  final String currencySymbol;
  final double fxRate;
  final String formatted;
  final MoneyFormat format;
  final int storeId;
  final String storeSlug;
  final String storeName;
  final int? storeLocationId;
  final String? storeLocationName;
  final int? stock;
  final bool isInStock;
  final String sku;
  final Map<String, dynamic> attributes;
  final List<AddonGroup> addonGroups;
  final VariantCartItem? cartItem;

  ProductVariants({
    int? id,
    String? title,
    String? slug,
    String? image,
    int? weight,
    int? height,
    int? breadth,
    int? length,
    bool? availability,
    String? barcode,
    bool? isDefault,
    double? price,
    double? specialPrice,
    double? priceBase,
    double? specialPriceBase,
    String? currencyCode,
    String? currencySymbol,
    double? fxRate,
    String? formatted,
    MoneyFormat? format,
    int? storeId,
    String? storeSlug,
    String? storeName,
    this.storeLocationId,
    this.storeLocationName,
    this.stock,
    bool? isInStock,
    String? sku,
    Map<String, dynamic>? attributes,
    List<AddonGroup>? addonGroups,
    this.cartItem,
  })  : id = id ?? 0,
        title = title ?? '',
        slug = slug ?? '',
        image = image ?? '',
        weight = weight ?? 0,
        height = height ?? 0,
        breadth = breadth ?? 0,
        length = length ?? 0,
        availability = availability ?? false,
        barcode = barcode ?? '',
        isDefault = isDefault ?? false,
        price = price ?? 0.0,
        specialPrice = specialPrice ?? 0.0,
        priceBase = priceBase ?? (price ?? 0.0),
        specialPriceBase = specialPriceBase ?? (specialPrice ?? 0.0),
        currencyCode = currencyCode ?? '',
        currencySymbol = currencySymbol ?? '',
        fxRate = fxRate ?? 1.0,
        formatted = formatted ?? '',
        format = format ?? MoneyFormat.defaults,
        storeId = storeId ?? 0,
        storeSlug = storeSlug ?? '',
        storeName = storeName ?? '',
        isInStock = isInStock ?? (stock == null || stock > 0),
        sku = sku ?? '',
        attributes = attributes ?? const {},
        addonGroups = addonGroups ?? const [];

  factory ProductVariants.fromJson(Map<String, dynamic> json) {
    return ProductVariants(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      image: parseString(json['image']),
      weight: parseInt(json['weight']),
      height: parseInt(json['height']),
      breadth: parseInt(json['breadth']),
      length: parseInt(json['length']),
      availability: parseBool(json['availability']),
      barcode: parseString(json['barcode']),
      isDefault: parseBool(json['is_default']),
      price: parseDouble(json['price'].toString()),
      specialPrice: parseDouble(json['special_price'].toString()),
      priceBase: parseDouble(json['price_base']?.toString()),
      specialPriceBase: parseDouble(json['special_price_base']?.toString()),
      currencyCode: parseString(json['currency_code']),
      currencySymbol: parseString(json['currency_symbol']),
      fxRate: parseDouble(json['fx_rate']?.toString()),
      formatted: parseString(json['formatted']),
      format: json['format'] is Map<String, dynamic>
          ? MoneyFormat.fromJson(Map<String, dynamic>.from(json['format']))
          : MoneyFormat.defaults,
      storeId: parseInt(json['store_id']),
      storeSlug: parseString(json['store_slug']),
      storeName: parseString(json['store_name']),
      storeLocationId: parseInt(json['store_location_id']),
      storeLocationName: parseString(json['store_location_name']),
      stock: parseInt(json['stock']),
      isInStock: parseBool(json['is_in_stock']),
      sku: parseString(json['sku']),
      attributes: json['attributes'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['attributes'])
          : const {},
      addonGroups: _parseAddonGroups(json['addon_groups']),
      cartItem: json['cart_item'] != null
          ? VariantCartItem.fromJson(json['cart_item'] is Map<String, dynamic>
              ? json['cart_item']
              : Map<String, dynamic>.from(json['cart_item'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'image': image,
    'weight': weight,
    'height': height,
    'breadth': breadth,
    'length': length,
    'availability': availability,
    'barcode': barcode,
    'is_default': isDefault,
    'price': price,
    'special_price': specialPrice,
    'price_base': priceBase,
    'special_price_base': specialPriceBase,
    'currency_code': currencyCode,
    'currency_symbol': currencySymbol,
    'fx_rate': fxRate,
    'formatted': formatted,
    'format': format.toJson(),
    'store_id': storeId,
    'store_slug': storeSlug,
    'store_name': storeName,
    if (storeLocationId != null) 'store_location_id': storeLocationId,
    if (storeLocationName != null) 'store_location_name': storeLocationName,
    'stock': stock,
    'is_in_stock': isInStock,
    'sku': sku,
    'attributes': attributes,
    'addon_groups': addonGroups.map((e) => e.toJson()).toList(),
    if (cartItem != null) 'cart_item': cartItem!.toJson(),
  };

  static List<AddonGroup> _parseAddonGroups(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(AddonGroup.fromJson)
        .toList();
  }
}

class VariantCartItem {
  final bool exists;
  final int? cartItemId;

  VariantCartItem({this.exists = false, this.cartItemId});

  factory VariantCartItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VariantCartItem();
    return VariantCartItem(
      exists: parseBool(json['exists']),
      cartItemId: parseInt(json['cart_item_id']),
    );
  }

  Map<String, dynamic> toJson() => {
    'exists': exists,
    'cart_item_id': cartItemId,
  };
}

/// A group of addon items attached to a product variant.
class AddonGroup {
  final int id;
  final String uuid;
  final String title;
  final String slug;
  final String selectionType; // "single" | "multiple"
  final bool isRequired;
  final int sortOrder;
  final List<AddonItem> items;

  AddonGroup({
    int? id,
    String? uuid,
    String? title,
    String? slug,
    String? selectionType,
    bool? isRequired,
    int? sortOrder,
    List<AddonItem>? items,
  })  : id = id ?? 0,
        uuid = uuid ?? '',
        title = title ?? '',
        slug = slug ?? '',
        selectionType = selectionType ?? '',
        isRequired = isRequired ?? false,
        sortOrder = sortOrder ?? 0,
        items = items ?? const [];

  factory AddonGroup.fromJson(Map<String, dynamic> json) {
    return AddonGroup(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      selectionType: parseString(json['selection_type']),
      isRequired: parseBool(json['is_required']),
      sortOrder: parseInt(json['sort_order']),
      items: _parseAddonItems(json['items']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'title': title,
    'slug': slug,
    'selection_type': selectionType,
    'is_required': isRequired,
    'sort_order': sortOrder,
    'items': items.map((e) => e.toJson()).toList(),
  };

  static List<AddonItem> _parseAddonItems(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(AddonItem.fromJson)
        .toList();
  }
}

/// An individual addon item inside an [AddonGroup].
class AddonItem {
  final int id;
  final String uuid;
  final String title;
  final String slug;
  final String indicator;
  final double price;
  final double priceBase;
  final double cost;
  final int stock;
  final bool isAvailable;

  AddonItem({
    int? id,
    String? uuid,
    String? title,
    String? slug,
    String? indicator,
    double? price,
    double? priceBase,
    double? cost,
    int? stock,
    bool? isAvailable,
  })  : id = id ?? 0,
        uuid = uuid ?? '',
        title = title ?? '',
        slug = slug ?? '',
        indicator = indicator ?? '',
        price = price ?? 0.0,
        priceBase = priceBase ?? (price ?? 0.0),
        cost = cost ?? 0.0,
        stock = stock ?? 0,
        isAvailable = isAvailable ?? false;

  factory AddonItem.fromJson(Map<String, dynamic> json) {
    return AddonItem(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      indicator: parseString(json['indicator']),
      price: parseDouble(json['price'].toString()),
      priceBase: parseDouble(json['price_base']?.toString()),
      cost: parseDouble(json['cost'].toString()),
      stock: parseInt(json['stock']),
      isAvailable: parseBool(json['is_available']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'title': title,
    'slug': slug,
    'indicator': indicator,
    'price': price,
    'price_base': priceBase,
    'cost': cost,
    'stock': stock,
    'is_available': isAvailable,
  };
}

class ProductAttributes {
  final String name;
  final String slug;
  final String swatcheType;
  final List<String> values;
  final List<SwatchValues> swatchValues;

  ProductAttributes({
    String? name,
    String? slug,
    String? swatcheType,
    List<String>? values,
    List<SwatchValues>? swatchValues,
  })  : name = name ?? '',
        slug = slug ?? '',
        swatcheType = swatcheType ?? '',
        values = values ?? const [],
        swatchValues = swatchValues ?? const [];

  factory ProductAttributes.fromJson(Map<String, dynamic> json) {
    return ProductAttributes(
      name: parseString(json['name']),
      slug: parseString(json['slug']),
      swatcheType: parseString(json['swatche_type']),
      values: (json['values'] as List<dynamic>?)?.cast<String>() ?? const [],
      swatchValues: _parseSwatchValues(json['swatch_values']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'swatche_type': swatcheType,
    'values': values,
    'swatch_values': swatchValues.map((e) => e.toJson()).toList(),
  };

  static List<SwatchValues> _parseSwatchValues(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(SwatchValues.fromJson)
        .toList();
  }
}

class SwatchValues {
  final String value;
  final String swatch;

  SwatchValues({
    String? value,
    String? swatch,
  })  : value = value ?? '',
        swatch = swatch ?? '';

  factory SwatchValues.fromJson(Map<String, dynamic> json) {
    return SwatchValues(
      value: parseString(json['value']),
      swatch: parseString(json['swatch']),
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'swatch': swatch,
  };

  // Value equality keeps a selection matching after the product is re-fetched.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwatchValues && other.value == value && other.swatch == swatch;

  @override
  int get hashCode => Object.hash(value, swatch);
}

class CustomProductFeaturedSections {
  int? id;
  String? uuid;
  String? title;
  String? description;
  int? sortOrder;
  List<ProductFeaturedSectionFields>? fields;

  CustomProductFeaturedSections(
      {this.id,
        this.uuid,
        this.title,
        this.description,
        this.sortOrder,
        this.fields});

  CustomProductFeaturedSections.fromJson(Map<String, dynamic> json) {
    id = parseInt(json['id']);
    uuid = parseString(json['uuid']);
    title = parseString(json['title']);
    description = parseString(json['description']);
    sortOrder = parseInt(json['sort_order']);
    if (json['fields'] != null) {
      fields = <ProductFeaturedSectionFields>[];
      json['fields'].forEach((v) {
        fields!.add(ProductFeaturedSectionFields.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['title'] = title;
    data['description'] = description;
    data['sort_order'] = sortOrder;
    if (fields != null) {
      data['fields'] = fields!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductFeaturedSectionFields {
  int? id;
  String? uuid;
  String? title;
  String? description;
  String? image;
  int? sortOrder;

  ProductFeaturedSectionFields(
      {this.id,
        this.uuid,
        this.title,
        this.description,
        this.image,
        this.sortOrder});

  ProductFeaturedSectionFields.fromJson(Map<String, dynamic> json) {
    id = parseInt(json['id']);
    uuid = parseString(json['uuid']);
    title = parseString(json['title']);
    description = parseString(json['description']);
    image = parseString(json['image']);
    sortOrder = parseInt(json['sort_order']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['title'] = title;
    data['description'] = description;
    data['image'] = image;
    data['sort_order'] = sortOrder;
    return data;
  }
}

class Badge {
  int? id;
  String? label;
  String? bgColor;
  String? textColor;
  String? borderColor;

  Badge({this.id, this.label, this.bgColor, this.textColor, this.borderColor});

  Badge.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    label = json['label'];
    bgColor = json['bg_color'];
    textColor = json['text_color'];
    borderColor = json['border_color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['label'] = label;
    data['bg_color'] = bgColor;
    data['text_color'] = textColor;
    data['border_color'] = borderColor;
    return data;
  }
}

class DeliveryEta {
  int? min;
  int? max;
  String? unit;

  DeliveryEta({this.min, this.max, this.unit});

  DeliveryEta.fromJson(Map<String, dynamic> json) {
    min = parseInt(json['min']);
    max = parseInt(json['max']);
    unit = parseString(json['unit']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min'] = min;
    data['max'] = max;
    data['unit'] = unit;
    return data;
  }
}

class FavoriteItem {
  final int? id;
  final int? wishlistId;
  final String? wishlistTitle;
  final int? variantId;
  final String? variantName;
  final int? storeId;
  final String? storeName;

  FavoriteItem({
    this.id,
    this.wishlistId,
    this.wishlistTitle,
    this.variantId,
    this.variantName,
    this.storeId,
    this.storeName,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: parseInt(json['id']),
      wishlistId: parseInt(json['wishlist_id']),
      wishlistTitle: parseString(json['wishlist_title']),
      variantId: parseInt(json['variant_id']),
      variantName: parseString(json['variant_name']),
      storeId: parseInt(json['store_id']),
      storeName: parseString(json['store_name']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (wishlistId != null) 'wishlist_id': wishlistId,
        if (wishlistTitle != null) 'wishlist_title': wishlistTitle,
        if (variantId != null) 'variant_id': variantId,
        if (variantName != null) 'variant_name': variantName,
        if (storeId != null) 'store_id': storeId,
        if (storeName != null) 'store_name': storeName,
      };
}