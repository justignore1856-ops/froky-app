part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

final class SendResetOtp extends ForgotPasswordEvent {
  final String identifier;
  const SendResetOtp({required this.identifier});

  @override
  List<Object?> get props => [identifier];
}

final class VerifyResetOtp extends ForgotPasswordEvent {
  final String identifier;
  final String otp;
  final String? verificationId;
  final bool firebase;

  const VerifyResetOtp({
    required this.identifier,
    required this.otp,
    this.verificationId,
    this.firebase = false,
  });

  @override
  List<Object?> get props => [identifier, otp, verificationId, firebase];
}

final class SubmitNewPassword extends ForgotPasswordEvent {
  final String identifier;
  final String token;
  final String password;
  final String confirmPassword;

  const SubmitNewPassword({
    required this.identifier,
    required this.token,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [identifier, token, password, confirmPassword];
}
