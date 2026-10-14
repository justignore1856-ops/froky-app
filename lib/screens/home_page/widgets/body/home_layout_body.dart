import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../router/app_routes.dart';
import '../../../product_listing_page/model/product_listing_type.dart';
import '../../model/banner_model.dart';
import '../../model/home_layout_models.dart';
import '../sections/banners/banner_slider.dart';
import '../sections/brands/brand_section.dart';
import '../sections/categories/category_section.dart';
import '../sections/common/sample_section_data.dart';
import '../sections/common/section_background.dart';
import '../sections/hero/hero_section_style.dart';
import '../sections/play_image/play_image_section.dart';
import '../sections/products/dynamic_product_section.dart';

class HomeLayoutBody extends StatelessWidget {
  final List<HomeSection> sections;

  const HomeLayoutBody({
    super.key,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          _section(context, sections[i], i),
        ],
      ],
    );
  }

  static Widget buildSection(BuildContext context, HomeSection s, int index) {
    const instance = HomeLayoutBody(sections: []);
    return instance._section(context, s, index);
  }

  Widget _section(BuildContext context, HomeSection s, int index) {
    switch (s.type) {
      case 'hero':
        return _hero(context, s, index == 0);
      case 'categories':
        return _categories(context, s);
      case 'banners':
        return _banners(s);
      case 'brands':
        return _brands(context, s);
      case 'products':
        return _products(context, s);
      case 'play_image':
        return _playImage(context, s);
      default:
        return const SizedBox.shrink();
    }
  }

  void _openListing(
    BuildContext context, {
    required ProductListingType type,
    required String? slug,
    String? title,
    String? logo,
  }) {
    if (slug == null || slug.isEmpty) return;
    GoRouter.of(context).push(AppRoutes.productListing, extra: {
      'type': type,
      'identifier': slug,
      'title': title ?? '',
      'logo': logo ?? '',
    });
  }

  void _openSeeAll(BuildContext context, HomeSection s) {
    log('Open See All ${s.type}');
    GoRouter.of(context).push(AppRoutes.sectionSeeAll, extra: {
      'section-id': s.id,
      'type': s.type,
      'title': s.title ?? 'Category',
    });
  }

  void _openProductSeeAll(BuildContext context, HomeSection s) {
    GoRouter.of(context).push(AppRoutes.productSectionSeeAll, extra: {
      'section-id': s.id,
      'title': s.title ?? '',
    });
  }

  void _openHeroItem(BuildContext context, HeroItem it) {
    if (it.type == 'product') {
      if (it.slug.isEmpty) return;
      GoRouter.of(context).push(AppRoutes.productDetailPage, extra: {
        'productSlug': it.slug,
        'title': it.title,
        'mainImage': it.defaultImage ?? '',
      });
      return;
    }
    _openListing(
      context,
      type: it.type == 'brand'
          ? ProductListingType.brand
          : ProductListingType.category,
      slug: it.slug,
      title: it.title,
      logo: it.defaultImage,
    );
  }

  Widget _hero(BuildContext context, HomeSection s, bool heroFirst) {
    final mediaType = s.configStr('media_type');
    final layout = s.configStr('layout') == 'items'
        ? HeroLayout.withItems
        : HeroLayout.bannerOnly;
    final cards = s.heroItems
        .map((it) => HeroPromoCard(
              title: it.title,
              imageUrls: it.image != null ? [it.image!] : const [],
              onTap: () => _openHeroItem(context, it),
            ))
        .toList();

    return Column(
      children: [
        HeroSectionStyle(
          bgType: mediaType == 'lottie' ? 'animation' : 'image',
          bgPath: s.heroMedia ?? s.backgroundImage ?? '',
          layout: layout,
          cards: cards,
          cardBgType: s.configStr('card_bg_type'),
          cardBgColor: _parseHex(s.configStr('card_bg_color')),
          cardBgImage: s.cardBackgroundImage,
          heroFirst: heroFirst,
          cardTitleColor: _parseHex(s.configStr('card_title_color')),
          cardStyle: _heroStyle(s.style),
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  HeroCardStyle _heroStyle(String? style) {
    switch (style) {
      case 'full':
        return HeroCardStyle.full;
      case 'image_title':
        return HeroCardStyle.imageTitle;
      default:
        return HeroCardStyle.imageTitle;
    }
  }

  Widget _categories(BuildContext context, HomeSection s) {
    final tiles = s.categoryItems
        .map((c) => SampleTile(
              name: c.title,
              imageUrl: c.image ?? '',
              onTap: () => _openListing(
                context,
                type: ProductListingType.category,
                slug: c.slug,
                title: c.title,
                logo: c.image,
              ),
            ))
        .toList();
    final config = s.categoryConfig;
    final bgType = config.backgroundType ?? s.configStr('background_type');
    SectionBackground background = const SectionBackground.none();
    if (bgType == 'color') {
      final color = _parseHex(config.backgroundColor ?? s.configStr('background_color'));
      if (color != null) background = SectionBackground.color(color);
    } else if (bgType == 'image' && (s.backgroundImage?.isNotEmpty ?? false)) {
      background = SectionBackground.networkImage(s.backgroundImage!);
    }
    return Column(
      children: [
        CategorySection(
          title: s.title ?? '',
          categories: tiles,
          style: _categoryStyle(s.style),
          background: background,
          onSeeAll: () => _openSeeAll(context, s),
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  CategoryCardStyle _categoryStyle(String? style) {
    switch (style) {
      case 'overlay':
        return CategoryCardStyle.overlayTitle;
      case 'full':
        return CategoryCardStyle.imageCards;
      default:
        return CategoryCardStyle.grid;
    }
  }

  Widget _banners(HomeSection s) {
    final banners = s.bannerItems
        .map((b) => BannerData(
              id: b.id,
              type: b.linkType,
              bannerImage: b.image,
              slug: b.slug,
              customUrl: b.linkUrl,
              categorySlug: b.linkType == 'category' ? b.slug : null,
              productSlug: b.linkType == 'product' ? b.slug : null,
              brandSlug: b.linkType == 'brand' ? b.slug : null,
            ))
        .toList();
    if (banners.isEmpty) return const SizedBox.shrink();
    // Section style: 'full' (default) or 'peek'.
    return Column(
      children: [
        AutoPlayCarouselSlider(banners: banners, style: s.style ?? 'full'),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _brands(BuildContext context, HomeSection s) {
    final tiles = s.brandItems
        .map((b) => SampleTile(
              name: b.title,
              imageUrl: b.logo ?? '',
              onTap: () => _openListing(
                context,
                type: ProductListingType.brand,
                slug: b.slug,
                title: b.title,
                logo: b.logo,
              ),
            ))
        .toList();
    return Column(
      children: [
        BrandSection(
          title: s.title ?? '',
          brands: tiles,
          style:
              s.style == 'full' ? BrandCardStyle.cards : BrandCardStyle.grid,
          onSeeAll: () => _openSeeAll(context, s),
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _products(BuildContext context, HomeSection s) {
    final config = s.productConfig;
    final orientation = config.orientation ?? s.configStr('orientation') ?? 'horizontal';
    final bgType = config.backgroundType ?? s.configStr('background_type');
    SectionBackground background = const SectionBackground.none();
    if (bgType == 'color') {
      final color = _parseHex(
          config.backgroundColor ?? s.configStr('background_color') ?? s.configStr('card_bg_color'));
      if (color != null) background = SectionBackground.color(color);
    } else if (bgType == 'image' && (s.backgroundImage?.isNotEmpty ?? false)) {
      background = SectionBackground.networkImage(s.backgroundImage!);
    }

    return s.products.isNotEmpty ? Column(
      children: [
        DynamicProductSection(
          title: s.title ?? '',
          products: s.products,
          orientation: orientation,
          style: s.style,
          background: background,
          onSeeAll: () => _openProductSeeAll(context, s),
        ),
        SizedBox(height: 15.h),
      ],
    ) : const SizedBox.shrink();
  }

  void _openPlayImageItem(BuildContext context, PlayImageItem item) {
    if (item.linkType == 'product') {
      final slug = item.slug ?? '';
      if (slug.isEmpty) return;
      GoRouter.of(context).push(AppRoutes.productDetailPage, extra: {
        'productSlug': slug,
        'title': '',
        'mainImage': item.image,
      });
      return;
    }
    if (item.linkType == 'category') {
      _openListing(
        context,
        type: ProductListingType.category,
        slug: item.slug,
        title: '',
        logo: item.image,
      );
      return;
    }
    if (item.linkType == 'brand') {
      _openListing(
        context,
        type: ProductListingType.brand,
        slug: item.slug,
        title: '',
        logo: item.image,
      );
      return;
    }
    if (item.linkType == 'url' || (item.linkUrl?.isNotEmpty ?? false)) {
      final url = item.linkUrl ?? '';
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      return;
    }
  }

  Widget _playImage(BuildContext context, HomeSection s) {
    return Column(
      children: [
        PlayImageSection(
          section: s,
          onItemTap: (item) => _openPlayImageItem(context, item),
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 3) {
      cleaned = cleaned.split('').map((c) => '$c$c').join();
    }
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16);
    return value != null ? Color(value) : null;
  }
}
