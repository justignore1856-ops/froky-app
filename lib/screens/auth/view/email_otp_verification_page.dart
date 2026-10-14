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
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/whole_page_progress.dart';
import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';

/// Verifies the email login OTP, then logs the user in.
class EmailOtpVerificationPage extends StatefulWidget {
  final String email;
  const EmailOtpVerificationPage({super.key, required this.email});

  @override
  State<EmailOtpVerificationPage> createState() =>
      _EmailOtpVerificationPageState();
}

class _EmailOtpVerificationPageState extends State<EmailOtpVerificationPage> {
  static const int _resendSecondsTotal = 30;

  final _otpController = TextEditingController();
  int _resendSeconds = _resendSecondsTotal;
  bool _canResend = false;
  Timer? _resendTicker;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startResendTimer());
  }

  @override
  void dispose() {
    _resendTicker?.cancel();
    _otpController.dispose();
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

  void _submitOtp(String otp) {
    if (_submitted || otp.length != 6) return;
    _submitted = true;
    FocusManager.instance.primaryFocus?.unfocus();
    context
        .read<AuthBloc>()
        .add(VerifyEmailOtpEvent(email: widget.email, otp: otp));
  }

  void _onVerifyPressed() {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.pleaseEnterCompleteOTP,
        type: ToastType.error,
      );
      return;
    }
    _submitOtp(otp);
  }

  void _onResend() {
    if (!_canResend) return;
    _submitted = false;
    _startResendTimer();
    context.read<AuthBloc>().add(SendEmailOtpEvent(email: widget.email));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ToastManager.show(
              context: context, message: state.message, type: ToastType.success);
          GoRouter.of(context).pushReplacement(AppRoutes.splashScreen);
        } else if (state is AuthFailed) {
          _submitted = false;
          ToastManager.show(
              context: context, message: state.error, type: ToastType.error);
        } else if (state is EmailOtpSent) {
          ToastManager.show(
              context: context,
              message: l10n.otpSentTo(widget.email),
              type: ToastType.success);
        }
      },
      builder: (context, state) {
        final isLoading = state is VerifyingOTP || state is AuthLoading;
        return Stack(
          children: [
            Scaffold(
              backgroundColor: scheme.surface,
              appBar: AppBar(
                backgroundColor: scheme.surface,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      size: 20.sp, color: scheme.tertiary),
                  onPressed: () => GoRouter.of(context).pop(),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 78.w,
                          height: 78.w,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(22.r),
                          ),
                          child: Icon(Icons.mark_email_read_outlined,
                              color: AppTheme.primaryColor, size: 36.sp),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      Text(
                        l10n.verifyOtp,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: scheme.tertiary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.otpSentTo(widget.email),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
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
                      SizedBox(height: 28.h),
                      CustomButton(
                        height: isTablet(context) ? 52.h : 54,
                        onPressed: isLoading ? null : _onVerifyPressed,
                        child: Text(
                          l10n.verifyOtp,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildResendRow(l10n, scheme),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoading) const WholePageProgress(),
          ],
        );
      },
    );
  }

  Widget _buildResendRow(AppLocalizations l10n, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.didntReceiveCode,
          style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(width: 4.w),
        if (_canResend)
          GestureDetector(
            onTap: _onResend,
            child: Text(
              l10n.resendOtp,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Text(
            l10n.resendInSeconds(_resendSeconds),
            style: TextStyle(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}
