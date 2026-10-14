import 'dart:async';

import '../../payment_options/model/payment_status.dart';

/// A single payment-status push, surfaced from an FCM message
/// (data: type == "payment", carrying order_slug + payment_status).
class PaymentPushEvent {
  final String orderSlug;
  final OrderPaymentStatus paymentStatus;

  const PaymentPushEvent({
    required this.orderSlug,
    required this.paymentStatus,
  });
}

/// App-wide broadcast of payment pushes. `notification_service` emits onto this
/// bus; the confirming-payment bloc listens (filtered by slug). Broadcast so it
/// works with zero or many listeners and never buffers.
class PaymentEventBus {
  PaymentEventBus._();

  static final PaymentEventBus instance = PaymentEventBus._();

  final StreamController<PaymentPushEvent> _controller =
      StreamController<PaymentPushEvent>.broadcast();

  Stream<PaymentPushEvent> get stream => _controller.stream;

  void emit(PaymentPushEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }
}
