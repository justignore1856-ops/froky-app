import '../../../config/api_routes.dart';
import '../../../config/helper.dart';
import '../../payment_options/model/payment_response_model.dart';
import '../../payment_options/model/payment_status.dart';

/// A snapshot of the two order fields checkout cares about.
class OrderStatusSnapshot {
  final OrderPaymentStatus paymentStatus;
  final OrderTopStatus topStatus;

  const OrderStatusSnapshot({
    required this.paymentStatus,
    required this.topStatus,
  });

  bool get isCompleted => paymentStatus.isCompleted;
  bool get isFailed => paymentStatus.isFailed || topStatus.isCancelled;
  bool get isPending => !isCompleted && !isFailed;
}

/// Result of a `/pay` retry — a fresh gateway handle to reopen the SDK with.
class PayRetryResult {
  final bool success;
  final String message;
  final PaymentResponse? paymentResponse;

  const PayRetryResult({
    required this.success,
    required this.message,
    required this.paymentResponse,
  });
}

class PaymentConfirmationRepository {
  /// GET user/orders/{slug} — reads top-level payment_status / status. The
  /// order may sit at the root or under a `data` envelope; handle both.
  Future<OrderStatusSnapshot> fetchStatus(String slug) async {
    final response =
        await AppHelpers.apiBaseHelper.getAPICall(ApiRoutes.orderDetailApi + slug, {});
    final body = parseMap(response.data);
    final order = body.containsKey('payment_status') || body.containsKey('status')
        ? body
        : parseMap(body['data']);
    return OrderStatusSnapshot(
      paymentStatus:
          OrderPaymentStatus.fromString(parseString(order['payment_status'])),
      topStatus: OrderTopStatus.fromString(parseString(order['status'])),
    );
  }

  /// POST user/orders/{slug}/pay — reuses the same order (server-enforced max 3
  /// attempts). Returns a fresh payment_response on success.
  Future<PayRetryResult> retryPayment(String slug) async {
    final response =
        await AppHelpers.apiBaseHelper.postAPICall(ApiRoutes.payOrderApi(slug), {});
    final body = parseMap(response.data);
    final data = parseMap(body['data']);
    return PayRetryResult(
      success: body['success'] == true,
      message: parseString(body['message']),
      paymentResponse: PaymentResponse.fromNullable(data['payment_response']),
    );
  }

  /// POST user/orders/{slug}/cancel-payment — marks the order failed and
  /// releases stock when the user dismisses the gateway.
  Future<void> cancelPayment(String slug) async {
    await AppHelpers.apiBaseHelper.postAPICall(ApiRoutes.cancelPaymentApi(slug), {});
  }
}
