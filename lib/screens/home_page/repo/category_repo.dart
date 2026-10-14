import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';

import '../../../config/helper.dart';

class CategoryRepository {
  /// Categories are gated by the X-Market header. No latitude/longitude.
  Future<Map<String, dynamic>> fetchCategory({
    required int perPage,
    required int currentPage,
    bool? isHome
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.categoryApi,
        {
          'per_page': perPage,
          'page': currentPage,
          'home': isHome ?? true,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch categories');
    }
  }

  Future<Map<String, dynamic>> fetchFilterCategory({
    required int perPage,
    required int currentPage,
    List<int>? categoryIds,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage.toString(),
        'page': currentPage.toString(),
        'home': 'true',
      };

      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['ids[]'] =
            categoryIds.map((id) => id.toString()).toList();
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.filterCategoryApi,
        queryParams,
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch categories');
    }
  }
}
