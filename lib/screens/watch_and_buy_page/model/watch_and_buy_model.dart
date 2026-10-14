import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart';

class WatchAndBuyResponse {
  final bool success;
  final String message;
  final List<WatchAndBuyItem> items;
  final WatchAndBuyMeta? meta;

  const WatchAndBuyResponse({
    required this.success,
    required this.message,
    required this.items,
    this.meta,
  });

  factory WatchAndBuyResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<WatchAndBuyItem> itemsList = [];
    WatchAndBuyMeta? metaData;

    if (data is Map<String, dynamic>) {
      if (data['items'] is List) {
        itemsList = (data['items'] as List)
            .map((item) =>
                WatchAndBuyItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      if (data['meta'] is Map<String, dynamic>) {
        metaData =
            WatchAndBuyMeta.fromJson(Map<String, dynamic>.from(data['meta']));
      }
    } else if (json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((item) =>
              WatchAndBuyItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return WatchAndBuyResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      items: itemsList,
      meta: metaData,
    );
  }
}

class WatchAndBuyMeta {
  final String? sessionId;
  final String? nextCursor;
  final int perPage;
  final bool slugNotFound;

  const WatchAndBuyMeta({
    this.sessionId,
    this.nextCursor,
    this.perPage = 10,
    this.slugNotFound = false,
  });

  factory WatchAndBuyMeta.fromJson(Map<String, dynamic> json) {
    return WatchAndBuyMeta(
      sessionId: json['session_id'] != null ? parseString(json['session_id']) : null,
      nextCursor: json['next_cursor'] != null ? parseString(json['next_cursor']) : null,
      perPage: parseInt(json['per_page']),
      slugNotFound: parseBool(json['slug_not_found']),
    );
  }
}

class WatchAndBuyItem {
  final int id;
  final String uuid;
  final String slug;
  final String? caption;
  final String status;
  final String source;
  final String videoUrl;
  final String? coverUrl;
  final int durationMs;
  final int width;
  final int height;
  final WatchProfile profile;
  final int likeCount;
  final bool likedByMe;
  final List<WatchProductItem> products;
  final String? publishedAt;

  const WatchAndBuyItem({
    required this.id,
    required this.uuid,
    required this.slug,
    this.caption,
    required this.status,
    required this.source,
    required this.videoUrl,
    this.coverUrl,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.profile,
    required this.likeCount,
    required this.likedByMe,
    required this.products,
    this.publishedAt,
  });

  // UI backward-compatibility getters
  String get title =>
      (caption != null && caption!.trim().isNotEmpty)
          ? caption!
          : profile.username;
  String get thumbnailUrl =>
      (coverUrl != null && coverUrl!.trim().isNotEmpty)
          ? coverUrl!
          : (profile.photoUrl.trim().isNotEmpty ? profile.photoUrl : '');
  String get storeName => profile.username;
  String get storeLogo => profile.photoUrl;
  int get initialLikes => likeCount;
  int get viewCount =>
      likeCount > 0 ? (likeCount * 32 + 180) : 240;

  List<ProductData> get legacyProducts =>
      products.map((p) => p.toProductData()).toList();

  WatchAndBuyItem copyWith({
    int? id,
    String? uuid,
    String? slug,
    String? caption,
    String? status,
    String? source,
    String? videoUrl,
    String? coverUrl,
    int? durationMs,
    int? width,
    int? height,
    WatchProfile? profile,
    int? likeCount,
    bool? likedByMe,
    List<WatchProductItem>? products,
    String? publishedAt,
  }) {
    return WatchAndBuyItem(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      slug: slug ?? this.slug,
      caption: caption ?? this.caption,
      status: status ?? this.status,
      source: source ?? this.source,
      videoUrl: videoUrl ?? this.videoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      profile: profile ?? this.profile,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      products: products ?? this.products,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchAndBuyItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          likeCount == other.likeCount &&
          likedByMe == other.likedByMe;

  @override
  int get hashCode => id.hashCode ^ likeCount.hashCode ^ likedByMe.hashCode;

  factory WatchAndBuyItem.fromJson(Map<String, dynamic> json) {
    return WatchAndBuyItem(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      slug: json['slug'] != null ? parseString(json['slug']) : parseString(json['id']),
      caption: json['caption'] != null
          ? parseString(json['caption'])
          : json['title'] != null
              ? parseString(json['title'])
              : null,
      status: parseString(json['status']),
      source: parseString(json['source']),
      videoUrl: json['video_url'] != null
          ? parseString(json['video_url'])
          : parseString(json['videoUrl']),
      coverUrl: json['cover_url'] != null
          ? parseString(json['cover_url'])
          : json['thumbnail_url'] != null
              ? parseString(json['thumbnail_url'])
              : null,
      durationMs: parseInt(json['duration_ms']),
      width: parseInt(json['width']) > 0 ? parseInt(json['width']) : 720,
      height: parseInt(json['height']) > 0 ? parseInt(json['height']) : 1280,
      profile: json['profile'] is Map<String, dynamic>
          ? WatchProfile.fromJson(Map<String, dynamic>.from(json['profile']))
          : WatchProfile(
              id: 0,
              type: 'seller',
              username: parseString(json['store_name']),
              photoUrl: parseString(json['store_logo']),
              status: 'active',
              hasActiveStatus: true,
              hasUnseenStatus: false,
            ),
      likeCount: json['like_count'] != null
          ? parseInt(json['like_count'])
          : parseInt(json['likes']),
      likedByMe: parseBool(json['liked_by_me']),
      products: json['products'] is List
          ? (json['products'] as List)
              .map((p) =>
                  WatchProductItem.fromJson(Map<String, dynamic>.from(p)))
              .toList()
          : [],
      publishedAt: json['published_at'] != null
          ? parseString(json['published_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'slug': slug,
        'caption': caption,
        'status': status,
        'source': source,
        'video_url': videoUrl,
        'cover_url': coverUrl,
        'duration_ms': durationMs,
        'width': width,
        'height': height,
        'profile': profile.toJson(),
        'like_count': likeCount,
        'liked_by_me': likedByMe,
        'products': products.map((p) => p.toJson()).toList(),
        'published_at': publishedAt,
      };
}

class WatchProfile {
  final int id;
  final String type;
  final String username;
  final String? bio;
  final String photoUrl;
  final String status;
  final bool hasActiveStatus;
  final bool hasUnseenStatus;

  const WatchProfile({
    required this.id,
    required this.type,
    required this.username,
    this.bio,
    required this.photoUrl,
    required this.status,
    required this.hasActiveStatus,
    required this.hasUnseenStatus,
  });

  factory WatchProfile.fromJson(Map<String, dynamic> json) {
    return WatchProfile(
      id: parseInt(json['id']),
      type: parseString(json['type']),
      username: parseString(json['username']),
      bio: json['bio'] != null ? parseString(json['bio']) : null,
      photoUrl: json['photo_url'] != null
          ? parseString(json['photo_url'])
          : parseString(json['avatar']),
      status: parseString(json['status']),
      hasActiveStatus: parseBool(json['has_active_status']),
      hasUnseenStatus: parseBool(json['has_unseen_status']),
    );
  }

  WatchProfile copyWith({
    int? id,
    String? type,
    String? username,
    String? bio,
    String? photoUrl,
    String? status,
    bool? hasActiveStatus,
    bool? hasUnseenStatus,
  }) {
    return WatchProfile(
      id: id ?? this.id,
      type: type ?? this.type,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      hasActiveStatus: hasActiveStatus ?? this.hasActiveStatus,
      hasUnseenStatus: hasUnseenStatus ?? this.hasUnseenStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'username': username,
        'bio': bio,
        'photo_url': photoUrl,
        'status': status,
        'has_active_status': hasActiveStatus,
        'has_unseen_status': hasUnseenStatus,
      };
}

class WatchProductItem {
  final int productId;
  final String productSlug;
  final String title;
  final String image;
  final int storeId;
  final String storeSlug;
  final String storeName;
  final int variantId;
  final String variantTitle;
  final double price;
  final double? specialPrice;
  final String currencyCode;
  final String currencySymbol;
  final bool available;
  final int sortOrder;
  final bool isPrimary;
  final double? ratings;
  final int? ratingCount;

  double get displayPrice =>
      specialPrice != null && specialPrice! > 0 ? specialPrice! : price;
  bool get hasDiscount =>
      specialPrice != null && specialPrice! > 0 && specialPrice! < price;

  const WatchProductItem({
    required this.productId,
    required this.productSlug,
    required this.title,
    required this.image,
    required this.storeId,
    required this.storeSlug,
    required this.storeName,
    required this.variantId,
    required this.variantTitle,
    required this.price,
    this.specialPrice,
    required this.currencyCode,
    required this.currencySymbol,
    required this.available,
    required this.sortOrder,
    required this.isPrimary,
    this.ratings,
    this.ratingCount,
  });

  factory WatchProductItem.fromJson(Map<String, dynamic> json) {
    return WatchProductItem(
      productId: parseInt(json['product_id'] ?? json['id']),
      productSlug: parseString(json['product_slug'] ?? json['slug']),
      title: parseString(json['title'] ?? json['name']),
      image: parseString(json['image'] ?? json['main_image']),
      storeId: parseInt(json['store_id']),
      storeSlug: parseString(json['store_slug']),
      storeName: parseString(json['store_name'] ?? json['brand_name']),
      variantId: parseInt(json['variant_id']),
      variantTitle: parseString(json['variant_title']),
      price: parseDouble(json['price']),
      specialPrice: json['special_price'] != null
          ? parseDouble(json['special_price'])
          : null,
      currencyCode: parseString(json['currency_code']),
      currencySymbol: parseString(json['currency_symbol']),
      available: parseBool(json['available'] ?? json['is_in_stock'] ?? true),
      sortOrder: parseInt(json['sort_order']),
      isPrimary: parseBool(json['is_primary']),
      ratings: json['ratings'] != null
          ? parseDouble(json['ratings'])
          : (json['rating'] != null ? parseDouble(json['rating']) : null),
      ratingCount: json['rating_count'] != null
          ? parseInt(json['rating_count'])
          : (json['ratings_count'] != null
              ? parseInt(json['ratings_count'])
              : (json['ratingCount'] != null
                  ? parseInt(json['ratingCount'])
                  : null)),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_slug': productSlug,
        'title': title,
        'image': image,
        'store_id': storeId,
        'store_slug': storeSlug,
        'store_name': storeName,
        'variant_id': variantId,
        'variant_title': variantTitle,
        'price': price,
        'special_price': specialPrice,
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'available': available,
        'sort_order': sortOrder,
        'is_primary': isPrimary,
        'ratings': ratings,
        'rating_count': ratingCount,
      };

  ProductData toProductData() {
    return ProductData(
      id: productId,
      title: title,
      slug: productSlug,
      mainImage: image,
      brandName: storeName,
      ratings: ratings ?? 4.8,
      ratingCount: ratingCount ?? 120,
      estimatedDeliveryTime: 'Standard Delivery',
      minimumOrderQuantity: 1,
      totalAllowedQuantity: 10,
      variants: [
        ProductVariants(
          id: variantId,
          title: variantTitle.isNotEmpty ? variantTitle : title,
          price: price,
          specialPrice: specialPrice ?? price,
          currencySymbol: currencySymbol,
          isDefault: true,
          stock: available ? 99 : 0,
          isInStock: available,
          storeId: storeId,
          addonGroups: [],
        ),
      ],
      favorite: [],
    );
  }
}

class ReelLikeSyncItem {
  final int reelId;
  final int likeCount;
  final bool likedByMe;

  const ReelLikeSyncItem({
    required this.reelId,
    required this.likeCount,
    required this.likedByMe,
  });

  factory ReelLikeSyncItem.fromJson(Map<String, dynamic> json) {
    return ReelLikeSyncItem(
      reelId: parseInt(json['reel_id']),
      likeCount: parseInt(json['like_count']),
      likedByMe: parseBool(json['liked_by_me']),
    );
  }
}

class WatchAndBuyMockData {
  static List<WatchAndBuyItem> getDummyList() {
    return [];
  }
}
