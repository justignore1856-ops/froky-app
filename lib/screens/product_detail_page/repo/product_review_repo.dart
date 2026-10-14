import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';

class ProductReviewRepository {
  final ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  /// Product reviews are gated by the X-Market header. No lat/long required.
  Future<Map<String, dynamic>> fetchProductReview({required String productSlug}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.productDetailApi}$productSlug/reviews',
        const <String, dynamic>{},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
