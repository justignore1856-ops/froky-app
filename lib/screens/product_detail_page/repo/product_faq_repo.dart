import 'package:hyper_commerce/config/api_base_helper.dart';
import 'package:hyper_commerce/config/api_routes.dart';

class ProductFAQRepository {
  final ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  /// Product FAQs are gated by the X-Market header. No lat/long required.
  Future<Map<String, dynamic>> fetchProductFAQ({required String productSlug}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.productDetailApi}$productSlug/faqs',
        const <String, dynamic>{},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
