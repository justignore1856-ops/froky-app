part of 'payment_confirmation_bloc.dart';

abstract class PaymentConfirmationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentConfirmationInitial extends PaymentConfirmationState {}

/// Page should open the gateway SDK with [paymentResponse]. [token] guards
/// against launching twice for the same request across widget rebuilds.
class LaunchGatewayState extends PaymentConfirmationState {
  final PaymentResponse paymentResponse;
  final String paymentType;
  final int token;

  LaunchGatewayState({
    required this.paymentResponse,
    required this.paymentType,
    required this.token,
  });

  @override
  List<Object?> get props => [paymentResponse, paymentType, token];
}

/// Waiting on the server (polling + push). Spinner state.
class ConfirmingPaymentState extends PaymentConfirmationState {
  final String? message;
  ConfirmingPaymentState({this.message});

  @override
  List<Object?> get props => [message];
}

class PaymentSucceededState extends PaymentConfirmationState {}

/// Payment failed but the order is still alive — offer Retry / Cancel.
class PaymentFailedState extends PaymentConfirmationState {
  final String? message;
  PaymentFailedState({this.message});

  @override
  List<Object?> get props => [message];
}

/// Order terminated (user cancel, retry limit, or server cancel). Terminal.
class PaymentCancelledState extends PaymentConfirmationState {
  final String? message;
  PaymentCancelledState({this.message});

  @override
  List<Object?> get props => [message];
}

/// 90s elapsed with no server result — order stays alive, notify later.
class PaymentTimedOutState extends PaymentConfirmationState {}

/// The SDK could not be launched (bad handle / config). Offer Retry / Cancel.
class PaymentLaunchErrorState extends PaymentConfirmationState {
  final String? message;
  PaymentLaunchErrorState({this.message});

  @override
  List<Object?> get props => [message];
}
