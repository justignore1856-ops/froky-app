import 'package:hyper_commerce/config/api_base_helper.dart';

import '../../../../config/api_routes.dart';
import '../../../../config/helper.dart';

class HomeLayoutRepository {
  /// Fetches the server-driven home layout, paginated by section
  /// ([page] / [perPage]). Pass [categorySlug] for a category-scoped layout;
  /// empty fetches the global layout.
  Future<Map<String, dynamic>> fetchHomeLayout({
    String categorySlug = '',
    Map<String, dynamic>? layoutQuery,
    int page = 1,
    int perPage = 5,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (layoutQuery != null && layoutQuery.isNotEmpty) {
        query.addAll(layoutQuery);
      } else if (categorySlug.isNotEmpty) {
        query['category_slug'] = categorySlug;
      }

      // 1. Fetch the default layout
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.homeLayoutApi,
        query,
      );
      final data = response.data as Map<String, dynamic>;

      // 2. Auto-Fallback: If mobile has 0 sections, automatically fetch the Web layout!
      final sections =
          (data['data'] as Map<String, dynamic>?)?['sections'] as List?;
      if (sections == null || sections.isEmpty) {
        final webQuery = Map<String, dynamic>.from(query);
        webQuery['platform'] = 'web';
        final webResponse = await AppHelpers.apiBaseHelper.getAPICall(
          ApiRoutes.homeLayoutApi,
          webQuery,
        );
        final webData = webResponse.data as Map<String, dynamic>;
        final webSections =
            (webData['data'] as Map<String, dynamic>?)?['sections'] as List?;
        if (webSections != null && webSections.isNotEmpty) {
          return webData;
        }
      }

      return data;
    } catch (e) {
      throw ApiException('Failed to fetch home layout');
    }
  }
}
