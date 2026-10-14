import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../payment_options/model/payment_response_model.dart';
import '../../payment_options/model/payment_status.dart';
import '../../payment_options/repo/gateway_launcher.dart';
import '../repo/payment_confirmation_repository.dart';
import '../service/payment_event_bus.dart';

part 'payment_confirmation_event.dart';
part 'payment_confirmation_state.dart';

class PaymentConfirmationBloc
    extends Bloc<PaymentConfirmationEvent, PaymentConfirmationState> {
  final PaymentConfirmationRepository repository;

  static const Duration _pollInterval = Duration(seconds: 3);
  static const Duration _timeout = Duration(seconds: 90);

  String _slug = '';
  String _paymentType = '';
  int _launchToken = 0;
  bool _resolved = false;

  Timer? _pollTimer;
  Timer? _timeoutTimer;
  StreamSubscription<PaymentPushEvent>? _pushSub;

  PaymentConfirmationBloc({required this.repository})
      : super(PaymentConfirmationInitial()) {
    on<ConfirmationStarted>(_onStarted);
    on<GatewayLaunchCompleted>(_onLaunchCompleted);
    on<RetryRequested>(_onRetry);
    on<CancelRequested>(_onCancel);
    on<_PollTick>(_onPollTick);
    on<_PushStatus>(_onPushStatus);
    on<_TimedOut>(_onTimedOut);
  }

  void _onStarted(
      ConfirmationStarted event, Emitter<PaymentConfirmationState> emit) {
    _slug = event.slug;
    _paymentType = event.paymentType;

    _pushSub ??= PaymentEventBus.instance.stream
        .where((e) => e.orderSlug == _slug)
        .listen((e) => add(_PushStatus(e.paymentStatus)));

    _launchToken++;
    emit(LaunchGatewayState(
      paymentResponse: event.paymentResponse,
      paymentType: _paymentType,
      token: _launchToken,
    ));
  }

  Future<void> _onLaunchCompleted(GatewayLaunchCompleted event,
      Emitter<PaymentConfirmationState> emit) async {
    if (event.token != _launchToken) return; // stale launch

    log('Launch Complete ${event.result.status}');
    log('Launch Complete ${event.result.isDismissed}');
    log('Launch Complete ${event.result.isError}');
    log('Launch Complete ${event.result.isSubmitted}');
    if (event.result.isDismissed) {
      await _cancelOrder(emit, message: event.result.message ?? 'Payment cancelled');
      return;
    }
    if (event.result.isError) {
      _cancelTimers();
      emit(PaymentLaunchErrorState(message: event.result.message));
      return;
    }
    // submitted → wait for the server to confirm.
    _startWaiting(emit);
  }

  Future<void> _onPollTick(
      _PollTick event, Emitter<PaymentConfirmationState> emit) async {
    if (_resolved) return;
    try {
      final snapshot = await repository.fetchStatus(_slug);
      _applySnapshot(snapshot, emit);
    } catch (_) {
      // Transient network/parse error — keep polling until timeout.
    }
  }

  void _onPushStatus(
      _PushStatus event, Emitter<PaymentConfirmationState> emit) {
    if (_resolved) return;
    if (event.status.isCompleted) {
      _succeed(emit);
    } else if (event.status.isFailed) {
      _failRetryable(emit);
    }
  }

  void _onTimedOut(_TimedOut event, Emitter<PaymentConfirmationState> emit) {
    if (_resolved) return;
    _resolved = true;
    _cancelTimers();
    emit(PaymentTimedOutState());
  }

  Future<void> _onRetry(
      RetryRequested event, Emitter<PaymentConfirmationState> emit) async {
    _cancelTimers();
    _resolved = false;
    emit(ConfirmingPaymentState(message: 'Retrying…'));
    try {
      final result = await repository.retryPayment(_slug);
      if (result.success && result.paymentResponse != null) {
        _launchToken++;
        emit(LaunchGatewayState(
          paymentResponse: result.paymentResponse!,
          paymentType: _paymentType,
          token: _launchToken,
        ));
      } else if (result.success) {
        _startWaiting(emit);
      } else {
        // success:false → server hit the retry limit and cancelled the order.
        _resolved = true;
        emit(PaymentCancelledState(message: result.message));
      }
    } catch (e) {
      emit(PaymentFailedState(message: e.toString()));
    }
  }

  Future<void> _onCancel(
      CancelRequested event, Emitter<PaymentConfirmationState> emit) async {
    await _cancelOrder(emit, message: 'Payment cancelled');
  }

  Future<void> _cancelOrder(Emitter<PaymentConfirmationState> emit,
      {required String message}) async {
    _resolved = true;
    _cancelTimers();
    emit(ConfirmingPaymentState(message: 'Cancelling…'));
    try {
      await repository.cancelPayment(_slug);
    } catch (_) {
      // Even if the release call fails, the server auto-cancels later.
    }
    emit(PaymentCancelledState(message: message));
  }

  void _applySnapshot(
      OrderStatusSnapshot snapshot, Emitter<PaymentConfirmationState> emit) {
    if (snapshot.isCompleted) {
      _succeed(emit);
    } else if (snapshot.isFailed) {
      _failRetryable(emit);
    }
  }

  void _succeed(Emitter<PaymentConfirmationState> emit) {
    _resolved = true;
    _cancelTimers();
    emit(PaymentSucceededState());
  }

  void _failRetryable(Emitter<PaymentConfirmationState> emit) {
    _resolved = true;
    _cancelTimers();
    emit(PaymentFailedState());
  }

  void _startWaiting(Emitter<PaymentConfirmationState> emit) {
    _cancelTimers();
    _resolved = false;
    emit(ConfirmingPaymentState());
    _pollTimer = Timer.periodic(_pollInterval, (_) => add(_PollTick()));
    _timeoutTimer = Timer(_timeout, () => add(_TimedOut()));
  }

  void _cancelTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    _pushSub?.cancel();
    return super.close();
  }
}
