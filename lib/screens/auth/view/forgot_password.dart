import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/auth/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:hyper_commerce/utils/widgets/phone_number_field.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/whole_page_progress.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import '../../../config/helper.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  static const int _resendSecondsTotal = 30;

  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0; // 0 = identifier, 1 = otp, 2 = new password

  // ─── Step 0 identifier mode ────────────────────────────────────────────
  /// true → collecting a phone number (with country picker),
  /// false → collecting an email address.
  bool _phoneMode = true;
  String? _completePhoneNumber; // e.g. +14155550123
  String _phoneNumber = ''; // national part only
  String _countryCode = getDialCodeFromIso(AppHelpers.isoCode) ?? '+91';
  String _countryIso2 = AppHelpers.isoCode;

  /// The identifier actually dispatched for the current OTP request. Kept so
  /// the confirmation step can echo it back regardless of input mode.
  String _pendingIdentifier = '';

  String _identifier = '';
  bool _firebase = false;
  String? _verificationId;
  String _resetToken = '';

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _otpSubmitted = false;

  int _resendSeconds = _resendSecondsTotal;
  bool _canResend = false;
  Timer? _resendTicker;

  @override
  void dispose() {
    _resendTicker?.cancel();
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTicker?.cancel();
    setState(() {
      _resendSeconds = _resendSecondsTotal;
      _canResend = false;
    });
    _resendTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
        if (_resendSeconds == 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  bool _isValidIdentifier(String s) {
    final t = s.trim();
    if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(t)) {
      return true;
    }
    final cleaned = t.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    return RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned) && !t.contains('@');
  }

  void _sendOtp() {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;

    final String identifier;
    if (_phoneMode) {
      if (_phoneNumber.trim().length < 5) {
        ToastManager.show(
            context: context,
            message: l10n.pleaseEnterYourPhoneNumber,
            type: ToastType.error);
        return;
      }
      // Full E.164 (e.g. +14155550123) so the bloc/Firebase gets the exact
      // country code the user picked, instead of inferring it from the market.
      identifier = _completePhoneNumber ?? '$_countryCode$_phoneNumber';
    } else {
      final email = _identifierController.text.trim();
      if (!_isValidIdentifier(email) || !email.contains('@')) {
        ToastManager.show(
            context: context,
            message: l10n.enterValidEmailOrPhone,
            type: ToastType.error);
        return;
      }
      identifier = email;
    }

    _pendingIdentifier = identifier;
    context.read<ForgotPasswordBloc>().add(SendResetOtp(identifier: identifier));
  }

  void _switchMode(bool phoneMode) {
    if (_phoneMode == phoneMode) return;
    setState(() => _phoneMode = phoneMode);
  }

  void _submitOtp(String otp) {
    if (_otpSubmitted || otp.length != 6) return;
    _otpSubmitted = true;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<ForgotPasswordBloc>().add(VerifyResetOtp(
          identifier: _identifier,
          otp: otp,
          verificationId: _verificationId,
          firebase: _firebase,
        ));
  }

  void _resendOtp() {
    if (!_canResend) return;
    _otpSubmitted = false;
    _otpController.clear();
    context
        .read<ForgotPasswordBloc>()
        .add(SendResetOtp(identifier: _identifier));
  }

  void _submitNewPassword() {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;
    final pass = _passwordController.text;
    final confirm = _confirmController.text;
    if (pass.length < 8) {
      ToastManager.show(
          context: context,
          message: l10n.passwordMustBeAtLeast8Characters,
          type: ToastType.error);
      return;
    }
    if (pass != confirm) {
      ToastManager.show(
          context: context,
          message: l10n.passwordsDoNotMatch,
          type: ToastType.error);
      return;
    }
    context.read<ForgotPasswordBloc>().add(SubmitNewPassword(
          identifier: _identifier,
          token: _resetToken,
          password: pass,
          confirmPassword: confirm,
        ));
  }


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ResetOtpSent) {
          _firebase = state.firebase;
          _verificationId = state.verificationId;
          _identifier = _pendingIdentifier;
          _otpSubmitted = false;
          _startResendTimer();
          setState(() => _step = 1);
        } else if (state is ResetOtpVerified) {
          _resetToken = state.token;
          setState(() => _step = 2);
        } else if (state is ResetPasswordDone) {
          ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.success);
          Future.delayed(const Duration(milliseconds: 600), () {
            if (context.mounted) {
              GoRouter.of(context).pushReplacement(AppRoutes.login);
            }
          });
        } else if (state is ForgotPasswordFailed) {
          _otpSubmitted = false;
          ToastManager.show(
              context: context, message: state.message, type: ToastType.error);
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgotPasswordLoading;
        return Stack(
          children: [
            Scaffold(
              backgroundColor: scheme.surface,
              appBar: AppBar(
                backgroundColor: scheme.surface,
                elevation: 0,
                scrolledUnderElevation: 0,
                /*leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      size: 20.sp, color: scheme.tertiary),
                  onPressed: _handleBack,
                ),*/
              ),
              body: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
                      child: _buildStep(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading) const WholePageProgress(),
          ],
        );
      },
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 1:
        return _buildOtpStep(context);
      case 2:
        return _buildPasswordStep(context);
      default:
        return _buildIdentifierStep(context);
    }
  }

  Widget _stepDots(int active) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 20.h),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 7.w : 0),
              height: 5,
              decoration: BoxDecoration(
                color: i <= active
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _heading(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headline.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.tertiary,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: isTablet(context) ? 70 : 45,
      width: double.infinity,
      child: CustomButton(
        onPressed: onTap,
        child: Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.secondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildIdentifierStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepDots(0),
        _heading(l10n.resetPassword, l10n.resetPasswordSubtitle),
        Center(child: _buildModeToggle(l10n)),
        SizedBox(height: 16.h),
        _phoneMode ? _buildPhoneField(l10n) : _buildEmailField(l10n),
        SizedBox(height: 26.h),
        _primaryButton(l10n.sendOtp, _sendOtp),
      ],
    );
  }

  Widget _buildModeToggle(AppLocalizations l10n) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        textStyle: WidgetStatePropertyAll(
          AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      segments: [
        ButtonSegment<bool>(
          value: true,
          icon: const Icon(Icons.phone_outlined, size: 18),
          label: Text(l10n.phoneNumber),
        ),
        ButtonSegment<bool>(
          value: false,
          icon: const Icon(Icons.alternate_email, size: 18),
          label: Text(l10n.email),
        ),
      ],
      selected: {_phoneMode},
      onSelectionChanged: (selection) => _switchMode(selection.first),
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return CustomTextFormField(
      controller: _identifierController,
      labelText: l10n.email,
      hintText: l10n.enterYourEmail,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      fillColor: Theme.of(context).colorScheme.surface,
      borderColor: Colors.transparent,
      borderRadius: 14,
      borderWidth: 1.5,
      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
    );
  }

  Widget _buildPhoneField(AppLocalizations l10n) {
    return PhoneNumberField(
      initialIso: _countryIso2,
      labelText: l10n.phoneNumber,
      hintText: l10n.enterYourPhoneNumber,
      onChanged: (data) {
        setState(() {
          _completePhoneNumber = data.complete;
          _countryCode = data.dialCode;
          _phoneNumber = data.national;
          _countryIso2 = data.iso;
        });
      },
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepDots(1),
        _heading(l10n.verifyOtp, l10n.otpSentTo(_identifier)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Material(
            color: Colors.transparent,
            child: PinFieldAutoFill(
              controller: _otpController,
              currentCode: _otpController.text,
              codeLength: 6,
              cursor: Cursor(
                width: 2,
                height: 20,
                color: Colors.black,
                enabled: true,
              ),
              onCodeChanged: (code) {
                final val = code ?? '';
                if (val.length == 6) {
                  HapticFeedback.lightImpact();
                  _submitOtp(val);
                }
              },
              onCodeSubmitted: _submitOtp,
              decoration: BoxLooseDecoration(
                radius: Radius.circular(6.r),
                strokeWidth: 2,
                gapSpace: 6,
                textStyle: TextStyle(
                    fontSize: 20.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400),
                strokeColorBuilder: FixedColorBuilder(
                    Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
          ),
        ),
        SizedBox(height: 26.h),
        _primaryButton(l10n.verifyOtp, () {
          final otp = _otpController.text.trim();
          if (otp.length < 6) {
            ToastManager.show(
                context: context,
                message: l10n.pleaseEnterCompleteOTP,
                type: ToastType.error);
            return;
          }
          _submitOtp(otp);
        }),
        SizedBox(height: 18.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.didntReceiveCode,
                style: AppTextStyles.bodySmall
                    .copyWith(color: scheme.onSurfaceVariant)),
            SizedBox(width: 4.w),
            if (_canResend)
              GestureDetector(
                onTap: _resendOtp,
                child: Text(l10n.resendOtp,
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700)),
              )
            else
              Text(l10n.resendInSeconds(_resendSeconds),
                  style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepDots(2),
        _heading(l10n.setNewPassword, l10n.resetPasswordSubtitle),
        CustomTextFormField(
          controller: _passwordController,
          labelText: l10n.newPassword,
          hintText: l10n.enterYourPassword,
          prefixIcon: Icons.lock_outline,
          obscureText: !_isPasswordVisible,
          suffixIcon: _isPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixIconTap: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          borderColor: Colors.transparent,
          focusedBorderColor: AppTheme.primaryColor,
          borderRadius: 14,
          borderWidth: 1.5,
          contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _confirmController,
          labelText: l10n.confirmPassword,
          hintText: l10n.confirmYourPassword,
          prefixIcon: Icons.lock_outline,
          obscureText: !_isConfirmVisible,
          suffixIcon: _isConfirmVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixIconTap: () =>
              setState(() => _isConfirmVisible = !_isConfirmVisible),
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          borderColor: Colors.transparent,
          focusedBorderColor: AppTheme.primaryColor,
          borderRadius: 14,
          borderWidth: 1.5,
          contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        ),
        SizedBox(height: 26.h),
        _primaryButton(l10n.resetPassword, _submitNewPassword),
      ],
    );
  }
}
