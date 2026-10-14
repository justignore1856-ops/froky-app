part of 'create_order_bloc.dart';

abstract class CreateOrderState extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class CreateOrderInitial extends CreateOrderState {}

class CreateOrderProgress extends CreateOrderState {}

class CreateOrderSuccess extends CreateOrderState {
  final String message;
  final String orderSlug;
  final int orderItemId;
  final String paymentType;
  final PaymentResponse? paymentResponse;
  final OrderPaymentStatus paymentStatus;
  final OrderTopStatus topStatus;

  /// A gateway step is required only when the server handed back a handle.
  /// COD / wallet return a null payment_response and are already confirmed.
  bool get needsGateway => paymentResponse != null;

  CreateOrderSuccess({
    required this.message,
    required this.orderSlug,
    required this.orderItemId,
    required this.paymentType,
    required this.paymentResponse,
    required this.paymentStatus,
    required this.topStatus,
  });
  @override
  // TODO: implement props
  List<Object?> get props => [
        message,
        orderSlug,
        orderItemId,
        paymentType,
        paymentResponse,
        paymentStatus,
        topStatus,
      ];
}

class CreateOrderFailure extends CreateOrderState {
  final String error;
  CreateOrderFailure({required this.error});
  @override
  // TODO: implement props
  List<Object?> get props => [error];
}
