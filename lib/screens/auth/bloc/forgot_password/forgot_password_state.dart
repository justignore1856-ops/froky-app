part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

final class ForgotPasswordInitial extends ForgotPasswordState {}

final class ForgotPasswordLoading extends ForgotPasswordState {}

final class ResetOtpSent extends ForgotPasswordState {
  final String channel; // 'email' | 'mobile'
  final bool firebase;
  final String? verificationId;

  const ResetOtpSent({
    required this.channel,
    this.firebase = false,
    this.verificationId,
  });

  @override
  List<Object?> get props => [channel, firebase, verificationId];
}

final class ResetOtpVerified extends ForgotPasswordState {
  final String token;
  final String identifier;

  const ResetOtpVerified({required this.token, required this.identifier});

  @override
  List<Object?> get props => [token, identifier];
}

final class ResetPasswordDone extends ForgotPasswordState {
  final String message;

  const ResetPasswordDone({required this.message});

  @override
  List<Object?> get props => [message];
}

final class ForgotPasswordFailed extends ForgotPasswordState {
  final String message;

  const ForgotPasswordFailed({required this.message});

  @override
  List<Object?> get props => [message];
}
