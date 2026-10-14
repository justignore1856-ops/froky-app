import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';
import 'package:hyper_commerce/model/sorting_model/sorting_model.dart';

import '../../../config/helper.dart';
import '../model/product_listing_type.dart';

class CategoryProductRepository {
  /// Catalog listings are gated by the X-Market header. No lat/long required.
  Future<Map<String, dynamic>> fetchProductsByType({
    required ProductListingType type,
    required String identifier,
    String? storeSlug,
    String? sortType,
    required int perPage,
    required int currentPage,
    bool? isSearchInStore,
    String? includeChildCategories,
    required List<String> categorySlugs,
    required List<String> brandSlugs,
    List<int>? attributeIds,
  }) async {
    try {
      String buildListParam(String key, List<dynamic> values) {
        if (values.isEmpty) return '';
        return '&$key=${values.join(',')}';
      }

      final brandQuery = buildListParam('brands', brandSlugs);
      final categoryQuery = buildListParam('categories', categorySlugs);
      final attributeQuery =
          buildListParam('attribute_values', attributeIds ?? const []);

      final commonParams = '&per_page=$perPage'
          '&page=$currentPage'
          '&sort=${sortType ?? SortType.relevance}'
          '$brandQuery'
          '$categoryQuery'
          '$attributeQuery';

      String apiUrl = '';

      if (isSearchInStore == true && storeSlug != null) {
        apiUrl = '${ApiRoutes.searchApi}'
            '?search=$identifier'
            '&store=$storeSlug'
            '$commonParams';
      } else {
        apiUrl = switch (type) {
          ProductListingType.category => '${ApiRoutes.categoryProductApi}'
              '?categories=$identifier'
              '$commonParams'
              '&include_child_categories=${includeChildCategories ?? '1'}',
          ProductListingType.brand => '${ApiRoutes.categoryProductApi}'
              '?brands=$identifier'
              '$commonParams',
          ProductListingType.store => '${ApiRoutes.storeProductApi}'
              '?store=$storeSlug'
              '$commonParams',
          ProductListingType.search => '${ApiRoutes.searchApi}'
              '?search=$identifier'
              '$commonParams',
          ProductListingType.featuredSection =>
              '${ApiRoutes.specificFeatureSectionProductApi}'
                  '$identifier/products'
                  '?$commonParams'
                  .replaceFirst('?&', '?'),
        };
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(apiUrl, {});
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Sidebar filters are gated by the X-Market header. No lat/long required.
  Future<Map<String, dynamic>> fetchFilterProduct({
    List<String>? categorySlugs,
    List<String>? brandSlugs,
    List<int>? attributeValueIds,
    ProductListingType? contextType,
    String? contextValue,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (categorySlugs != null && categorySlugs.isNotEmpty) {
        queryParams['categories'] = categorySlugs.join(',');
      }
      if (brandSlugs != null && brandSlugs.isNotEmpty) {
        queryParams['brands'] = brandSlugs.join(',');
      }
      if (attributeValueIds != null && attributeValueIds.isNotEmpty) {
        queryParams['attribute_values'] = attributeValueIds.join(',');
      }

      if (contextType != null) {
        queryParams['type'] = contextType == ProductListingType.featuredSection
            ? 'featured_section'
            : contextType.name;

        if (contextValue != null && contextValue.isNotEmpty) {
          queryParams['value'] = contextValue;
        }
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.filterProductApi,
        queryParams,
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch categories');
    }
  }
}
