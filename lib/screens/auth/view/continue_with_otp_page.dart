import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/utils/widgets/phone_number_field.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/whole_page_progress.dart';
import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/user_verification/user_verification_bloc.dart';
import '../bloc/user_verification/user_verification_event.dart';
import '../bloc/user_verification/user_verification_state.dart';

class ContinueWithOtpPage extends StatefulWidget {
  const ContinueWithOtpPage({super.key});

  @override
  State<ContinueWithOtpPage> createState() => _ContinueWithOtpPageState();
}

class _ContinueWithOtpPageState extends State<ContinueWithOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // ─── Phone-mode state (populated by PhoneNumberField) ──────────────────
  /// true → collecting a phone number (with country picker),
  /// false → collecting an email address.
  bool _phoneMode = true;
  String? _completePhoneNumber; // e.g. +14155550123
  String _phoneNumber = ''; // national part only, e.g. 4155550123
  String _countryCode = getDialCodeFromIso(AppHelpers.isoCode) ?? '+91';
  String _countryIso2 = AppHelpers.isoCode;
  String? _phoneError;

  bool? isUserVerified;
  String? helperText;
  Widget? statusIcon;

  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserVerificationBloc>().add(ResetVerification());
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(s.trim());

  // ─── Verification (debounced) ──────────────────────────────────────────
  void _handleEmailChange(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    if (!_isValidEmail(trimmed)) {
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }
    _debounceTimer = Timer(_debounceDuration, () {
      if (_emailController.text.trim() == trimmed) {
        context
            .read<UserVerificationBloc>()
            .add(VerifyUser(value: trimmed, type: 'email'));
      }
    });
  }

  void _handlePhoneChange(String national) {
    _debounceTimer?.cancel();
    if (national.isEmpty) {
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }
    _debounceTimer = Timer(_debounceDuration, () {
      if (_phoneNumber == national) {
        final cleanPhone = national.replaceAll(RegExp(r'[^\d]'), '');
        context
            .read<UserVerificationBloc>()
            .add(VerifyUser(value: cleanPhone, type: 'mobile'));
      }
    });
  }

  void _switchMode(bool phoneMode) {
    if (_phoneMode == phoneMode) return;
    _debounceTimer?.cancel();
    setState(() {
      _phoneMode = phoneMode;
      isUserVerified = null;
      helperText = null;
      statusIcon = null;
    });
    context.read<UserVerificationBloc>().add(ResetVerification());
  }

  // ─── Send ──────────────────────────────────────────────────────────────
  String? _validatePhone(AppLocalizations l10n) {
    final n = _phoneNumber.trim();
    if (n.isEmpty) return l10n.pleaseEnterYourPhoneNumber;
    if (n.length < 5) return l10n.phoneNumberTooShort;
    if (n.length > 16) return l10n.phoneNumberTooLong;
    return null;
  }

  void _handleSendCode() {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;

    if (_phoneMode) {
      final err = _validatePhone(l10n);
      setState(() => _phoneError = err);
      if (err != null) return;
    } else {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }

    if (isUserVerified != true) {
      ToastManager.show(
        context: context,
        message: l10n.noAccountFoundWithEmailOrPhone,
        type: ToastType.error,
      );
      return;
    }

    if (_phoneMode) {
      context.read<AuthBloc>().add(SendOtpToPhoneEvent(
            number: _phoneNumber,
            countryCode: _countryCode,
            isoCode: _countryIso2,
            isLogin: true,
          ));
    } else {
      context
          .read<AuthBloc>()
          .add(SendEmailOtpEvent(email: _emailController.text.trim()));
    }
  }

  void _onPhoneCodeSent(LoginPhoneCodeSentState state) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    GoRouter.of(context).push(
      AppRoutes.otpVerification,
      extra: {
        'phoneNumber': _completePhoneNumber ?? '$_countryCode$_phoneNumber',
        'registrationData': <String, dynamic>{},
        'verificationId': state.verificationId,
        'userNumber': _phoneNumber,
        'countryCode': _countryCode,
        'isoCode': _countryIso2,
        'isLogin': true,
        'isUpdate': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return CustomScaffold(
      showViewCart: false,
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is EmailOtpSent) {
            if (ModalRoute.of(context)?.isCurrent != true) return;
            GoRouter.of(context).push(
              AppRoutes.emailOtpVerification,
              extra: {'email': state.email},
            );
          } else if (state is LoginPhoneCodeSentState) {
            _onPhoneCodeSent(state);
          } else if (state is AuthFailed) {
            ToastManager.show(
                context: context, message: state.error, type: ToastType.error);
          }
        },
        builder: (context, authState) {
          final isLoading =
              authState is AuthLoading || authState is LoginCodeSentProgress;
          return Stack(
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
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),
                        Text(
                          l10n.continueWithOtp,
                          style: AppTextStyles.displayLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: scheme.tertiary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          l10n.otpLoginSubtitle,
                          style: AppTextStyles.body.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Center(child: _buildModeToggle(l10n)),
                        SizedBox(height: 18.h),
                        _buildInputField(l10n),
                        SizedBox(height: 26.h),
                        _buildSendButton(l10n),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading) const WholePageProgress(),
            ],
          );
        },
      ),
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

  Widget _buildInputField(AppLocalizations l10n) {
    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, state) {
        _syncVerificationFeedback(state, l10n);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _phoneMode ? _buildPhoneField(l10n) : _buildEmailField(l10n),
            if (helperText != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  if (statusIcon != null) ...[
                    statusIcon!,
                    SizedBox(width: 6.w),
                  ],
                  Expanded(
                    child: Text(
                      helperText!,
                      style: AppTextStyles.label.copyWith(
                        color: isUserVerified == true
                            ? context.appColors.success
                            : isUserVerified == false
                                ? Theme.of(context).colorScheme.error
                                : context.appColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// Recomputes helperText / statusIcon / isUserVerified for the current mode.
  void _syncVerificationFeedback(
      UserVerificationState state, AppLocalizations l10n) {
    final hasInput = _phoneMode
        ? _phoneNumber.isNotEmpty
        : _emailController.text.trim().isNotEmpty;

    if (!hasInput) {
      isUserVerified = null;
      helperText = null;
      statusIcon = null;
    } else if (state is VerifyingUser) {
      isUserVerified = null;
      helperText = l10n.verifying;
      statusIcon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: context.appColors.warning));
    } else if (state is UserVerified) {
      isUserVerified = state.isUserVerified;
      if (isUserVerified == true) {
        helperText = _phoneMode
            ? l10n.phoneNumberVerifiedSuccessfully
            : l10n.emailVerifiedSuccessfully;
      } else {
        helperText = _phoneMode
            ? l10n.thisPhoneNumberIsNotRegistered
            : l10n.thisEmailIsNotRegistered;
      }
      statusIcon = Icon(
        isUserVerified == true ? Icons.check_circle : Icons.cancel,
        color: isUserVerified == true
            ? context.appColors.success
            : Theme.of(context).colorScheme.error,
        size: 16,
      );
    } else if (state is UserVerificationFailed) {
      isUserVerified = false;
      helperText = l10n.unableToVerifyUser;
      statusIcon = Icon(Icons.error,
          color: Theme.of(context).colorScheme.error, size: 16);
    } else {
      isUserVerified = null;
      helperText = null;
      statusIcon = null;
    }
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return CustomTextFormField(
      controller: _emailController,
      labelText: l10n.email,
      hintText: l10n.enterYourEmail,
      prefixIcon: Icons.alternate_email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      borderRadius: 14,
      borderWidth: 1.5,
      borderColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.emailOrPhoneNumberIsRequired;
        }
        if (!_isValidEmail(value)) {
          return l10n.enterValidEmailOrPhone;
        }
        return null;
      },
      onChanged: _handleEmailChange,
    );
  }

  Widget _buildPhoneField(AppLocalizations l10n) {
    return PhoneNumberField(
      initialIso: _countryIso2,
      labelText: l10n.phoneNumber,
      hintText: l10n.enterYourPhoneNumber,
      errorText: _phoneError,
      onChanged: (data) {
        setState(() {
          _completePhoneNumber = data.complete;
          _countryCode = data.dialCode;
          _phoneNumber = data.national;
          _countryIso2 = data.iso;
          if (_phoneError != null) _phoneError = _validatePhone(l10n);
        });
        _handlePhoneChange(data.national);
      },
    );
  }

  Widget _buildSendButton(AppLocalizations l10n) {
    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, verState) {
        final isVerifying = verState is VerifyingUser;
        return SizedBox(
          height: isTablet(context) ? 45.h : 48,
          width: double.infinity,
          child: CustomButton(
            onPressed: isVerifying ? null : _handleSendCode,
            child: Text(
              isVerifying ? l10n.verifying : l10n.sendOtp,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.secondaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
