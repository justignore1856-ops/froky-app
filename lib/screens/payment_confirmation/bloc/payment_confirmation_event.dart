part of 'payment_confirmation_bloc.dart';

abstract class PaymentConfirmationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Fired once when the screen opens: kicks off the first gateway launch.
class ConfirmationStarted extends PaymentConfirmationEvent {
  final String slug;
  final String paymentType;
  final PaymentResponse paymentResponse;
  final String? contact;
  final String? email;

  ConfirmationStarted({
    required this.slug,
    required this.paymentType,
    required this.paymentResponse,
    this.contact,
    this.email,
  });

  @override
  List<Object?> get props => [slug, paymentType, paymentResponse, contact, email];
}

/// The page reports the coarse outcome of opening the gateway SDK.
class GatewayLaunchCompleted extends PaymentConfirmationEvent {
  final GatewayLaunchResult result;
  final int token;

  GatewayLaunchCompleted(this.result, this.token);

  @override
  List<Object?> get props => [result.status, result.message, token];
}

/// User tapped Retry on a failed payment.
class RetryRequested extends PaymentConfirmationEvent {}

/// User tapped Cancel (or dismissed the gateway).
class CancelRequested extends PaymentConfirmationEvent {}

class _PollTick extends PaymentConfirmationEvent {}

class _PushStatus extends PaymentConfirmationEvent {
  final OrderPaymentStatus status;
  _PushStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class _TimedOut extends PaymentConfirmationEvent {}
