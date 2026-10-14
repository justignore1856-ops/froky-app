import 'dart:convert';

import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/screens/product_detail_page/model/product_detail_model.dart'
    show ProductData;

import '../../brand_list_page/model/brands_model.dart';
import '../widgets/home_helpers.dart';
import 'category_model.dart';

class HomeLayoutResponse {
  final bool success;
  final String message;
  final String scopeType;
  final int? scopeId;
  final List<HomeSection> sections;

  HomeLayoutResponse({
    required this.success,
    required this.message,
    required this.scopeType,
    required this.scopeId,
    required this.sections,
  });

  factory HomeLayoutResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawSections = (data['sections'] as List?) ?? const [];
    return HomeLayoutResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      scopeType: data['scope_type']?.toString() ?? 'global',
      scopeId: data['scope_id'] is int ? data['scope_id'] as int : null,
      sections: rawSections
          .whereType<Map>()
          .map((e) => HomeSection.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class HomeSection {
  final int id;
  final String type; // hero | categories | banners | brands | products
  final String? title;
  final String? style;
  final dynamic config; // Map or List ([]) depending on type
  final String? backgroundImage;
  final String? heroMedia;
  final String? cardBackgroundImage;
  final Map<String, dynamic> content;

  HomeSection({
    required this.id,
    required this.type,
    required this.title,
    required this.style,
    required this.config,
    required this.backgroundImage,
    required this.heroMedia,
    required this.cardBackgroundImage,
    required this.content,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      id: json['id'] is int ? json['id'] as int : 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString(),
      style: json['style']?.toString(),
      config: json['config'],
      backgroundImage: json['background_image']?.toString(),
      heroMedia: json['hero_media']?.toString(),
      cardBackgroundImage: json['card_background_image']?.toString(),
      content: (json['content'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  // ── config helpers (config may be a Map or an empty List) ──────────────────
  String? configStr(String key) {
    if (config is Map && (config as Map)[key] != null) {
      return (config as Map)[key].toString();
    }
    return null;
  }

  // ── typed content accessors (reuse the app's existing models) ──────────────
  List<dynamic> _list(String key) =>
      (content[key] is List) ? content[key] as List : const [];

  List<HeroItem> get heroItems => _list('items')
      .whereType<Map>()
      .map((e) => HeroItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<BannerItem> get bannerItems => _list('items')
      .whereType<Map>()
      .map((e) => BannerItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<CategoryData> get categories => _list('categories')
      .whereType<Map>()
      .map((e) => CategoryData.fromJson(e.cast<String, dynamic>()))
      .toList();

  HomeCategoryConfig get categoryConfig => HomeCategoryConfig.fromJson(
      (config is Map) ? (config as Map).cast<String, dynamic>() : null);

  List<HomeCategoryItem> get categoryItems => _list('categories')
      .whereType<Map>()
      .map((e) => HomeCategoryItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<BrandData> get brands => _list('brands')
      .whereType<Map>()
      .map((e) => BrandData.fromJson(e.cast<String, dynamic>()))
      .toList();

  HomeBrandConfig get brandConfig => HomeBrandConfig.fromJson(
      (config is Map) ? (config as Map).cast<String, dynamic>() : null);

  List<HomeBrandItem> get brandItems => _list('brands')
      .whereType<Map>()
      .map((e) => HomeBrandItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  HomeProductConfig get productConfig => HomeProductConfig.fromJson(
      (config is Map) ? (config as Map).cast<String, dynamic>() : null);

  List<ProductData> get products => _list('products')
      .whereType<Map>()
      .map((e) => ProductData.fromJson(e.cast<String, dynamic>()))
      .toList();

  PlayImageSectionConfig get playImageConfig => (config is Map)
      ? PlayImageSectionConfig.fromJson((config as Map).cast<String, dynamic>())
      : PlayImageSectionConfig();

  List<PlayImageRow> get playImageRows {
    final rowsRaw = _list('rows');
    final sectionConfig = playImageConfig;
    if (rowsRaw.isNotEmpty) {
      return rowsRaw
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map((e) {
            final rowMap = e.value.cast<String, dynamic>();
            final rowIndex = e.key;
            final sectionRowConfig = (sectionConfig.rows.length > rowIndex)
                ? sectionConfig.rows[rowIndex]
                : null;
            return PlayImageRow.fromJson(
              rowMap,
              indexFallback: rowIndex,
              fallbackConfig: sectionRowConfig,
              sectionAspectRatio: sectionConfig.aspectRatio,
            );
          })
          .toList();
    }
    final itemsRaw = _list('items');
    if (itemsRaw.isNotEmpty) {
      final items = itemsRaw
          .whereType<Map>()
          .map((e) => PlayImageItem.fromJson(
                e.cast<String, dynamic>(),
                fallbackAspectRatio: sectionConfig.aspectRatio,
              ))
          .toList();
      return [
        PlayImageRow(
          rowIndex: 0,
          style: style ?? 'grid',
          config: PlayImageRowConfig.fromJson((config is Map)
              ? (config as Map).cast<String, dynamic>()
              : null),
          items: items,
        ),
      ];
    }
    return const [];
  }
}

class HeroItem {
  final int id;
  final String title;
  final String? image;
  final String? defaultImage;
  final String type;
  final int? targetId;
  final String slug;

  HeroItem({
    required this.id,
    required this.title,
    required this.image,
    required this.defaultImage,
    required this.type,
    required this.targetId,
    required this.slug,
  });

  factory HeroItem.fromJson(Map<String, dynamic> json) => HeroItem(
        id: json['id'] is int ? json['id'] as int : 0,
        title: json['title']?.toString() ?? '',
        image: (json['image']?.toString().isNotEmpty ?? false)
            ? json['image'].toString()
            : null,
        defaultImage: (json['default_image']?.toString().isNotEmpty ?? false)
            ? json['default_image'].toString()
            : null,
        type: json['type']?.toString() ?? '',
        targetId: json['target_id'] is int ? json['target_id'] as int : null,
        slug: json['slug']?.toString() ?? '',
      );
}

class BannerItem {
  final int id;
  final String image;
  final String? linkType;
  final String? linkUrl;
  final int? targetId;
  final String? slug;

  BannerItem({
    required this.id,
    required this.image,
    required this.linkType,
    required this.linkUrl,
    required this.targetId,
    required this.slug,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
        id: json['id'] is int ? json['id'] as int : 0,
        image: json['image']?.toString() ?? '',
        linkType: json['link_type']?.toString(),
        linkUrl: json['link_url']?.toString(),
        targetId: json['target_id'] is int ? json['target_id'] as int : null,
        slug: json['slug']?.toString(),
      );
}

class PlayImageSectionConfig {
  final double outerPadding;
  final double gridGap;
  final double borderRadius;
  final String hoverEffect;
  final double itemsToShow;
  final double itemsToShowMobile;
  final bool showScrollButtons;
  final bool showBullets;
  final bool autoScroll;
  final int autoScrollTime;
  final List<PlayImageRowConfig> rows;
  final String? legacyBannerStyle;
  final String? aspectRatio;

  PlayImageSectionConfig({
    this.outerPadding = 0,
    this.gridGap = 0,
    this.borderRadius = 0,
    this.hoverEffect = 'none',
    this.itemsToShow = 2.0,
    this.itemsToShowMobile = 1.0,
    this.showScrollButtons = false,
    this.showBullets = false,
    this.autoScroll = false,
    this.autoScrollTime = 3,
    this.rows = const [],
    this.legacyBannerStyle,
    this.aspectRatio,
  });

  factory PlayImageSectionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PlayImageSectionConfig();
    final sectionAutoScroll = _toBool(json['auto_scroll']);
    final sectionAutoScrollTime = _toInt(json['auto_scroll_time'], 3);
    final sectionShowBullets = _toBool(json['show_bullets']);
    final sectionShowScrollButtons = _toBool(json['show_scroll_buttons']);
    final sectionOuterPadding = _toDouble(json['outer_padding'], 0);
    final sectionGridGap = _toDouble(json['grid_gap'], 0);
    final sectionBorderRadius = _toDouble(json['border_radius'], 0);
    final sectionHoverEffect = json['hover_effect']?.toString() ?? 'none';
    final sectionItemsToShow = _toDouble(json['items_to_show'], 2.0);
    final sectionItemsToShowMobile = _toDouble(json['items_to_show_mobile'], 1.0);
    final sectionAspectRatio = (json['aspect_ratio'] ?? json['aspectRatio'])?.toString();

    final sectionFallback = PlayImageRowConfig(
      autoScroll: sectionAutoScroll,
      autoScrollTime: sectionAutoScrollTime,
      showBullets: sectionShowBullets,
      showScrollButtons: sectionShowScrollButtons,
      outerPadding: sectionOuterPadding,
      gridGap: sectionGridGap,
      borderRadius: sectionBorderRadius,
      hoverEffect: sectionHoverEffect,
      itemsToShow: sectionItemsToShow,
      itemsToShowMobile: sectionItemsToShowMobile,
      aspectRatio: sectionAspectRatio,
    );

    final rowsRaw = json['rows'] as List?;
    final parsedRows = (rowsRaw != null)
        ? rowsRaw
            .whereType<Map>()
            .map((e) => PlayImageRowConfig.fromJson(
                  e.cast<String, dynamic>(),
                  fallback: sectionFallback,
                ))
            .toList()
        : <PlayImageRowConfig>[];

    return PlayImageSectionConfig(
      outerPadding: sectionOuterPadding,
      gridGap: sectionGridGap,
      borderRadius: sectionBorderRadius,
      hoverEffect: sectionHoverEffect,
      itemsToShow: sectionItemsToShow,
      itemsToShowMobile: sectionItemsToShowMobile,
      showScrollButtons: sectionShowScrollButtons,
      showBullets: sectionShowBullets,
      autoScroll: sectionAutoScroll,
      autoScrollTime: sectionAutoScrollTime,
      rows: parsedRows,
      legacyBannerStyle: json['_legacy_banner_style']?.toString(),
      aspectRatio: sectionAspectRatio,
    );
  }
}

class PlayImageRow {
  final int rowIndex;
  final String style; // 'grid' | 'scroll'
  final PlayImageRowConfig config;
  final List<PlayImageItem> items;

  PlayImageRow({
    required this.rowIndex,
    required this.style,
    required this.config,
    required this.items,
  });

  factory PlayImageRow.fromJson(
    Map<String, dynamic> json, {
    int indexFallback = 0,
    PlayImageRowConfig? fallbackConfig,
    String? sectionAspectRatio,
  }) {
    Map<String, dynamic>? rawConfig;
    if (json['config'] is Map) {
      rawConfig = (json['config'] as Map).cast<String, dynamic>();
    } else if (json['config'] is String && (json['config'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['config'] as String);
        if (decoded is Map) rawConfig = decoded.cast<String, dynamic>();
      } catch (_) {}
    }

    final parsedConfig = rawConfig != null
        ? PlayImageRowConfig.fromJson(rawConfig, fallback: fallbackConfig)
        : (fallbackConfig ?? PlayImageRowConfig());

    final rawItems = (json['items'] as List?) ?? const [];
    final rowStyle = json['style']?.toString() ??
        rawConfig?['style']?.toString() ??
        fallbackConfig?.style ??
        'grid';

    final effectiveAspectRatio = parsedConfig.aspectRatio ?? sectionAspectRatio;

    return PlayImageRow(
      rowIndex: _toInt(json['row_index'], indexFallback),
      style: rowStyle,
      config: parsedConfig,
      items: rawItems
          .whereType<Map>()
          .map((e) => PlayImageItem.fromJson(
                e.cast<String, dynamic>(),
                fallbackAspectRatio: effectiveAspectRatio,
              ))
          .toList(),
    );
  }
}

class PlayImageRowConfig {
  final String style;
  final String containerWidth;
  final double outerPadding;
  final String? outerPaddingCustom;
  final double gridGap;
  final double borderRadius;
  final String hoverEffect;
  final double itemsToShow;
  final double itemsToShowMobile;
  final bool showScrollButtons;
  final bool showBullets;
  final bool autoScroll;
  final int autoScrollTime;
  final String? mediaKey;
  final String? backgroundImage;
  final String? aspectRatio;

  PlayImageRowConfig({
    this.style = 'grid',
    this.containerWidth = 'container',
    this.outerPadding = 0,
    this.outerPaddingCustom,
    this.gridGap = 0,
    this.borderRadius = 0,
    this.hoverEffect = 'none',
    this.itemsToShow = 2.0,
    this.itemsToShowMobile = 1.0,
    this.showScrollButtons = false,
    this.showBullets = false,
    this.autoScroll = false,
    this.autoScrollTime = 3,
    this.mediaKey,
    this.backgroundImage,
    this.aspectRatio,
  });

  factory PlayImageRowConfig.fromJson(
    Map<String, dynamic>? json, {
    PlayImageRowConfig? fallback,
  }) {
    if (json == null) return fallback ?? PlayImageRowConfig();
    return PlayImageRowConfig(
      style: json['style']?.toString() ?? fallback?.style ?? 'grid',
      containerWidth: json['container_width']?.toString() ?? fallback?.containerWidth ?? 'container',
      outerPadding: json['outer_padding'] != null
          ? _toDouble(json['outer_padding'], 0)
          : (fallback?.outerPadding ?? 0),
      outerPaddingCustom: json['outer_padding_custom']?.toString() ?? fallback?.outerPaddingCustom,
      gridGap: json['grid_gap'] != null
          ? _toDouble(json['grid_gap'], 0)
          : (fallback?.gridGap ?? 0),
      borderRadius: json['border_radius'] != null
          ? _toDouble(json['border_radius'], 0)
          : (fallback?.borderRadius ?? 0),
      hoverEffect: json['hover_effect']?.toString() ?? fallback?.hoverEffect ?? 'none',
      itemsToShow: json['items_to_show'] != null
          ? _toDouble(json['items_to_show'], 2.0)
          : (fallback?.itemsToShow ?? 2.0),
      itemsToShowMobile: json['items_to_show_mobile'] != null
          ? _toDouble(json['items_to_show_mobile'], 1.0)
          : (fallback?.itemsToShowMobile ?? 1.0),
      showScrollButtons: json['show_scroll_buttons'] != null
          ? _toBool(json['show_scroll_buttons'])
          : (fallback?.showScrollButtons ?? false),
      showBullets: json['show_bullets'] != null
          ? _toBool(json['show_bullets'])
          : (fallback?.showBullets ?? false),
      autoScroll: json['auto_scroll'] != null
          ? _toBool(json['auto_scroll'])
          : (fallback?.autoScroll ?? false),
      autoScrollTime: json['auto_scroll_time'] != null
          ? _toInt(json['auto_scroll_time'], 3)
          : (fallback?.autoScrollTime ?? 3),
      mediaKey: json['media_key']?.toString() ?? fallback?.mediaKey,
      backgroundImage: json['background_image']?.toString() ?? fallback?.backgroundImage,
      aspectRatio: (json['aspect_ratio'] ?? json['aspectRatio'])?.toString() ?? fallback?.aspectRatio,
    );
  }
}

class PlayImageItem {
  final int id;
  final String image;
  final String? mobileImage;
  final String? linkType;
  final String? linkUrl;
  final int? targetId;
  final String? slug;
  final PlayImageItemConfig config;

  PlayImageItem({
    required this.id,
    required this.image,
    required this.mobileImage,
    required this.linkType,
    required this.linkUrl,
    required this.targetId,
    required this.slug,
    required this.config,
  });

  factory PlayImageItem.fromJson(
    Map<String, dynamic> json, {
    String? fallbackAspectRatio,
  }) {
    Map<String, dynamic>? rawConfig;
    if (json['config'] is Map) {
      rawConfig = (json['config'] as Map).cast<String, dynamic>();
    } else if (json['config'] is String && (json['config'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['config'] as String);
        if (decoded is Map) rawConfig = decoded.cast<String, dynamic>();
      } catch (_) {}
    }

    return PlayImageItem(
      id: _toInt(json['id'], 0),
      image: json['image']?.toString() ?? '',
      mobileImage: (json['mobile_image']?.toString().isNotEmpty ?? false)
          ? json['mobile_image'].toString()
          : (json['mobileImage']?.toString().isNotEmpty ?? false)
              ? json['mobileImage'].toString()
              : null,
      linkType: (json['link_type'] ?? json['linkType'])?.toString(),
      linkUrl: (json['link_url'] ?? json['linkUrl'])?.toString(),
      targetId: _toIntNullable(json['target_id'] ?? json['targetId']),
      slug: json['slug']?.toString(),
      config: PlayImageItemConfig.fromJson(
        rawConfig,
        itemRootJson: json,
        fallbackAspectRatio: fallbackAspectRatio,
      ),
    );
  }
}

class PlayImageItemConfig {
  final String? rowIndex;
  final String cols;
  final String colsMobile;
  final String aspectRatio;
  final double? parsedAspectRatio;
  final String? mediaType;

  PlayImageItemConfig({
    this.rowIndex,
    this.cols = 'auto',
    this.colsMobile = 'auto',
    this.aspectRatio = 'original',
    this.mediaType,
    this.parsedAspectRatio,
  });

  factory PlayImageItemConfig.fromJson(
    Map<String, dynamic>? json, {
    Map<String, dynamic>? itemRootJson,
    String? fallbackAspectRatio,

  }) {


    final raw = json ?? const {};
    final root = itemRootJson ?? const {};

    final ratioStr = parseString(raw['aspect_ratio']).toString();
    final rowIndex = raw['row_index']?.toString() ?? root['row_index']?.toString();
    final cols = raw['cols']?.toString() ?? root['cols']?.toString() ?? 'auto';
    final colsMobile = raw['cols_mobile']?.toString() ??
        root['cols_mobile']?.toString() ??
        raw['colsMobile']?.toString() ??
        root['colsMobile']?.toString() ??
        cols;
    final aspectRatio = raw['aspect_ratio']?.toString() ??
        root['aspect_ratio']?.toString() ??
        raw['aspectRatio']?.toString() ??
        root['aspectRatio']?.toString() ??
        fallbackAspectRatio ??
        'original';
    final mediaType = raw['media_type']?.toString() ??
        root['media_type']?.toString() ??
        raw['mediaType']?.toString() ??
        root['mediaType']?.toString();

    return PlayImageItemConfig(
      rowIndex: rowIndex,
      cols: cols,
      colsMobile: colsMobile,
      aspectRatio: aspectRatio,
      mediaType: mediaType,
      parsedAspectRatio: parseAspectRatio(ratioStr),
    );
  }
}

// ── parsing helpers ────────────────────────────────────────────────────────
double _toDouble(dynamic val, double fallback) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? fallback;
}

int _toInt(dynamic val, int fallback) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

int? _toIntNullable(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString());
}

bool _toBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  final s = val.toString().trim().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes';
}

// ── Categories Section Models ──────────────────────────────────────────────
class HomeCategoryConfig {
  final String? source;
  final String? backgroundType;
  final String? backgroundColor;

  HomeCategoryConfig({
    this.source,
    this.backgroundType,
    this.backgroundColor,
  });

  factory HomeCategoryConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HomeCategoryConfig();
    return HomeCategoryConfig(
      source: json['source']?.toString(),
      backgroundType: json['background_type']?.toString(),
      backgroundColor: json['background_color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'background_type': backgroundType,
    'background_color': backgroundColor,
  };
}

class HomeCategoryItem {
  final int id;
  final String title;
  final String slug;
  final String? image;
  final String? banner;
  final List<String> searchLabels;
  final int? parentId;
  final String? commission;
  final String? parentSlug;
  final String? description;
  final String? status;
  final bool requiresApproval;
  final dynamic metadata;
  final int subcategoryCount;
  final int productCount;
  final bool enabled;

  HomeCategoryItem({
    required this.id,
    required this.title,
    required this.slug,
    this.image,
    this.banner,
    this.searchLabels = const [],
    this.parentId,
    this.commission,
    this.parentSlug,
    this.description,
    this.status,
    this.requiresApproval = false,
    this.metadata,
    this.subcategoryCount = 0,
    this.productCount = 0,
    this.enabled = true,
  });

  factory HomeCategoryItem.fromJson(Map<String, dynamic> json) {
    return HomeCategoryItem(
      id: _toInt(json['id'], 0),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      image: (json['image']?.toString().isNotEmpty ?? false)
          ? json['image'].toString()
          : null,
      banner: (json['banner']?.toString().isNotEmpty ?? false)
          ? json['banner'].toString()
          : null,
      searchLabels: (json['search_labels'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      parentId: _toIntNullable(json['parent_id']),
      commission: json['commission']?.toString(),
      parentSlug: json['parent_slug']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      requiresApproval: _toBool(json['requires_approval']),
      metadata: json['metadata'],
      subcategoryCount: _toInt(json['subcategory_count'], 0),
      productCount: _toInt(json['product_count'], 0),
      enabled: _toBool(json['enabled'] ?? true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'image': image,
    'banner': banner,
    'search_labels': searchLabels,
    'parent_id': parentId,
    'commission': commission,
    'parent_slug': parentSlug,
    'description': description,
    'status': status,
    'requires_approval': requiresApproval,
    'metadata': metadata,
    'subcategory_count': subcategoryCount,
    'product_count': productCount,
    'enabled': enabled,
  };
}

// ── Brands Section Models ──────────────────────────────────────────────────
class HomeBrandConfig {
  final String? source;

  HomeBrandConfig({this.source});

  factory HomeBrandConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HomeBrandConfig();
    return HomeBrandConfig(
      source: json['source']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
  };
}

class HomeBrandItem {
  final int id;
  final String title;
  final String slug;
  final String? logo;
  final String? status;
  final String? scopeType;
  final String? scopeId;
  final String? scopeCategorySlug;
  final String? scopeCategoryTitle;
  final String? description;
  final dynamic metadata;
  final int totalProducts;
  final bool enabled;

  HomeBrandItem({
    required this.id,
    required this.title,
    required this.slug,
    this.logo,
    this.status,
    this.scopeType,
    this.scopeId,
    this.scopeCategorySlug,
    this.scopeCategoryTitle,
    this.description,
    this.metadata,
    this.totalProducts = 0,
    this.enabled = true,
  });

  factory HomeBrandItem.fromJson(Map<String, dynamic> json) {
    return HomeBrandItem(
      id: _toInt(json['id'], 0),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      logo: (json['logo']?.toString().isNotEmpty ?? false)
          ? json['logo'].toString()
          : null,
      status: json['status']?.toString(),
      scopeType: json['scope_type']?.toString(),
      scopeId: json['scope_id']?.toString(),
      scopeCategorySlug: json['scope_category_slug']?.toString(),
      scopeCategoryTitle: json['scope_category_title']?.toString(),
      description: json['description']?.toString(),
      metadata: json['metadata'],
      totalProducts: _toInt(json['total_products'], 0),
      enabled: _toBool(json['enabled'] ?? true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'logo': logo,
    'status': status,
    'scope_type': scopeType,
    'scope_id': scopeId,
    'scope_category_slug': scopeCategorySlug,
    'scope_category_title': scopeCategoryTitle,
    'description': description,
    'metadata': metadata,
    'total_products': totalProducts,
    'enabled': enabled,
  };
}

// ── Products Section Models ────────────────────────────────────────────────
class HomeProductConfig {
  final String? source;
  final String? orientation;
  final String? backgroundType;
  final String? backgroundColor;

  HomeProductConfig({
    this.source,
    this.orientation,
    this.backgroundType,
    this.backgroundColor,
  });

  factory HomeProductConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HomeProductConfig();
    return HomeProductConfig(
      source: json['source']?.toString(),
      orientation: json['orientation']?.toString(),
      backgroundType: json['background_type']?.toString(),
      backgroundColor: json['background_color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'orientation': orientation,
    'background_type': backgroundType,
    'background_color': backgroundColor,
  };
}

