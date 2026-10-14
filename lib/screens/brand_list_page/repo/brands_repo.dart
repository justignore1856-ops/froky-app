import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../config/helper.dart';

class BrandsRepository {
  /// Brands are gated by the X-Market header. No latitude/longitude.
  Future<Map<String, dynamic>> fetchBrands({required String categorySlug}) async {
    try {
      final query = <String, dynamic>{
        if (categorySlug.isNotEmpty) 'scope_category_slug': categorySlug,
      };
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.brandsApi,
        query,
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch Brands');
    }
  }

  Future<Map<String, dynamic>> fetchFilterBrands({
    required String categorySlug,
    required List<int>? brandIds,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.filterBrandsApi,
        {
          if (categorySlug.isNotEmpty) 'scope_category_slug': categorySlug,
          if (brandIds != null && brandIds.isNotEmpty) 'ids[]': brandIds,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch Brands');
    }
  }
}
