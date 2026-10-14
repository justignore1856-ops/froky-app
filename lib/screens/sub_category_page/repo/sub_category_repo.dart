import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../config/helper.dart';

class SubCategoryRepository {
  /// Sub-categories are gated by the X-Market header. No latitude/longitude.
  Future<Map<String, dynamic>> fetchSubCategory({
    required String slug,
    required bool isForAllCategory,
    int? page,
    int? perPage,
    bool? isFiltered = false,
  }) async {
    try {
      final query = <String, dynamic>{
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      };

      String apiUrl;
      if (isForAllCategory) {
        if (isFiltered == true) {
          query['filter'] = 'top_category';
        }
        apiUrl = ApiRoutes.allTabSubCategoryApi;
      } else {
        query['slug'] = slug;
        apiUrl = ApiRoutes.subCategoryApi;
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        apiUrl,
        query,
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch Sub-categories');
    }
  }
}
