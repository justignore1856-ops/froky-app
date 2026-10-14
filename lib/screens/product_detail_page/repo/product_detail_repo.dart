import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';

class ProductDetailRepository {
  final ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  /// Product detail is gated by the X-Market header. No lat/long required.
  /// When [addressId] is provided, delivery/pricing is resolved for that address.
  /// [marketCode] overrides X-Market for this call only, so the page can show a
  /// different market's catalog without switching the app's active market.
  Future<Map<String, dynamic>> fetchProductDetail({
    required String productSlug,
    String? addressId,
    String? marketCode,
  }) async {
    try {
      final query = <String, dynamic>{
        if (addressId != null) 'country_iso2': addressId.toString(),
      };
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.productDetailApi}$productSlug',
        query,
        extraHeaders: marketCode != null ? {'X-Market': marketCode} : null,
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Similar products are gated by the X-Market header. No lat/long required.
  Future<Map<String, dynamic>> fetchSimilarProduct({required List<String> excludeProductSlug}) async {
    try {
      final query = <String, dynamic>{
        if (excludeProductSlug.isNotEmpty)
          'exclude_product': excludeProductSlug.join(','),
      };
      final response = await apiBaseHelper.getAPICall(
        ApiRoutes.getSimilarProductApi,
        query,
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch similar product');
    }
  }
}
