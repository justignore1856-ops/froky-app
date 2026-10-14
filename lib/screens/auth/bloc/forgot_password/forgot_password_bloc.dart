import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/screens/auth/repo/auth_repo.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository _repository = AuthRepository();

  ForgotPasswordBloc() : super(ForgotPasswordInitial()) {
    on<SendResetOtp>(_onSendResetOtp);
    on<VerifyResetOtp>(_onVerifyResetOtp);
    on<SubmitNewPassword>(_onSubmitNewPassword);
  }

  bool _isEmail(String v) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(v.trim());

  String _fullPhone(String raw) {
    final trimmed = raw.trim();
    // If the caller already supplied an explicit country code (E.164, e.g.
    // "+14155550123" from the country picker), trust it and use it as-is
    // instead of forcing the app's market dial code.
    if (trimmed.startsWith('+')) {
      return '+${trimmed.replaceAll(RegExp(r'[^\d]'), '')}';
    }
    final dial = getDialCodeFromIso(AppHelpers.isoCode) ?? '+91';
    var digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    final dialDigits = dial.replaceAll('+', '');
    if (digits.length > 10 && digits.startsWith(dialDigits)) {
      digits = digits.substring(dialDigits.length);
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '$dial$digits';
  }

  Future<void> _onSendResetOtp(
      SendResetOtp event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    try {
      final identifier = event.identifier.trim();
      if (_isEmail(identifier)) {
        await _repository.sendForgotPasswordOtp(identifier: identifier);
        emit(const ResetOtpSent(channel: 'email'));
      } else {
        if (AppHelpers.smsGatewayIsFirebase) {
          final result =
              await _repository.sendOTPWithCallback(phoneNumber: _fullPhone(identifier));
          emit(ResetOtpSent(
            channel: 'mobile',
            firebase: true,
            verificationId: result['verificationId'],
          ));
        } else {
          await _repository.sendForgotPasswordOtp(identifier: identifier);
          emit(const ResetOtpSent(channel: 'mobile', firebase: false));
        }
      }
    } catch (e) {
      emit(ForgotPasswordFailed(message: e.toString()));
    }
  }

  Future<void> _onVerifyResetOtp(
      VerifyResetOtp event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    try {
      Map<String, dynamic> resp;
      if (event.firebase) {
        await _repository.verifyOTP(
            verificationId: event.verificationId ?? '', otpCode: event.otp);
        final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
        resp = await _repository.verifyForgotPasswordOtp(
            identifier: event.identifier, idToken: idToken);
      } else {
        resp = await _repository.verifyForgotPasswordOtp(
            identifier: event.identifier, otp: event.otp);
      }
      final data = resp['data'] as Map<String, dynamic>?;
      final token = data?['token']?.toString() ?? '';
      emit(ResetOtpVerified(token: token, identifier: event.identifier));
    } catch (e) {
      emit(ForgotPasswordFailed(message: e.toString()));
    }
  }

  Future<void> _onSubmitNewPassword(
      SubmitNewPassword event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    try {
      final resp = await _repository.resetPassword(
        identifier: event.identifier,
        token: event.token,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );
      emit(ResetPasswordDone(
          message: resp['message']?.toString() ??
              'Your password has been reset.'));
    } catch (e) {
      emit(ForgotPasswordFailed(message: e.toString()));
    }
  }
}
