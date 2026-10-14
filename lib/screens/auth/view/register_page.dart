import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_commerce/screens/auth/bloc/user_verification/user_verification_state.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/shake_widget.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/utils/widgets/phone_number_field.dart';
import '../../../config/helper.dart';
import '../../../router/app_routes.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/user_verification/user_verification_bloc.dart';
import '../bloc/user_verification/user_verification_event.dart';

typedef _FieldHandle = ({
  GlobalKey<ShakeWidgetState> shakeKey,
  FocusNode focusNode,
});

enum _VerifyingField { none, email, phone }

class RegisterPage extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  const RegisterPage({super.key, this.userName, this.userEmail});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ─── Form ────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  // ─── Password visibility ─────────────────────────────────────────────────
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // ─── Phone field data ────────────────────────────────────────────────────
  String _completePhoneNumber = '';
  String _countryCode = '';
  String _phoneNumber = '';
  String _countryIso2 = '';
  String _countryName = '';

  // ─── Verification tracking ───────────────────────────────────────────────
  _VerifyingField _activeVerifyField = _VerifyingField.none;

  bool? _phoneVerified; // null = unknown, true = available, false = taken
  String? _phoneHelperText;
  Widget? _phoneStatusIcon;

  String? _phoneErrorText;
  bool _phoneSubmitAttempted = false;

  // ─── Debounce timers ─────────────────────────────────────────────────────
  DateTime? _lastEmailChange;
  DateTime? _lastPhoneChange;

  // ─── Shake + focus handles ───────────────────────────────────────────────
  final GlobalKey<ShakeWidgetState> _nameShakeKey = GlobalKey<ShakeWidgetState>();
  final GlobalKey<ShakeWidgetState> _emailShakeKey = GlobalKey<ShakeWidgetState>();
  final GlobalKey<ShakeWidgetState> _phoneShakeKey = GlobalKey<ShakeWidgetState>();
  final GlobalKey<ShakeWidgetState> _passwordShakeKey = GlobalKey<ShakeWidgetState>();
  final GlobalKey<ShakeWidgetState> _confirmPasswordShakeKey = GlobalKey<ShakeWidgetState>();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName ?? '';
    _emailController.text = widget.userEmail ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserVerificationBloc>().add(ResetVerification());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // ─── Email change handler ─────────────────────────────────────────────────
  void _onEmailChanged(String value) {
    if (value.isEmpty) {
      setState(() => _activeVerifyField = _VerifyingField.none);
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    final now = DateTime.now();
    _lastEmailChange = now;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_lastEmailChange != now) return; // superseded by newer keystroke
      if (_emailController.text != value) return;

      final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) return; // don't verify malformed emails

      setState(() => _activeVerifyField = _VerifyingField.email);
      context
          .read<UserVerificationBloc>()
          .add(VerifyUser(value: value, type: 'email'));
    });
  }

  // ─── Phone change handler ─────────────────────────────────────────────────
  void _onPhoneChanged(String number) {
    if (number.isEmpty) {
      setState(() {
        _activeVerifyField = _VerifyingField.none;
        _phoneVerified = null;
        _phoneHelperText = null;
        _phoneStatusIcon = null;
      });
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    final now = DateTime.now();
    _lastPhoneChange = now;

    // Reset phone helper while the user is still typing
    setState(() {
      _phoneVerified = null;
      _phoneHelperText = null;
      _phoneStatusIcon = null;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_lastPhoneChange != now) return;
      if (_phoneNumber != number) return;

      setState(() => _activeVerifyField = _VerifyingField.phone);
      String cleanPhone = _phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      context
          .read<UserVerificationBloc>()
          .add(VerifyUser(value: cleanPhone, type: 'mobile'));
    });
  }

  // ─── Consume verification bloc state for phone ───────────────────────────
  void _applyPhoneVerificationState(
      UserVerificationState state, AppLocalizations l10n) {
    if (_activeVerifyField != _VerifyingField.phone) return;

    if (state is VerifyingUser) {
      setState(() {
        _phoneVerified = null;
        _phoneHelperText = l10n.verifying;
        _phoneStatusIcon = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: context.appColors.warning),
        );
      });
    } else if (state is UserVerified) {
      // On REGISTER the phone must be NEW (not already registered)
      final alreadyTaken = state.isUserVerified == true;
      setState(() {
        _phoneVerified = alreadyTaken ? false : true;
        _phoneHelperText = alreadyTaken
            ? l10n.phoneNumberAlreadyRegistered
            : l10n.phoneNumberAvailable;
        _phoneStatusIcon = Icon(
          alreadyTaken
              ? Icons.cancel
              : Icons.check_circle,
          color: alreadyTaken
              ? Theme.of(context).colorScheme.error
              : context.appColors.success,
          size: 16,
        );
      });
    } else if (state is UserVerificationFailed) {
      setState(() {
        _phoneVerified = null;
        _phoneHelperText = l10n.unableToVerifyUser;
        _phoneStatusIcon =
        Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 16);
      });
    }
  }

  // ─── Field-level validators (reused by form + submit) ────────────────────
  String? _validateName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.pleaseEnterYourFullName;
    }
    if (value.trim().length < 2) {
      return l10n.nameMustBeAtLeast2Characters;
    }
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      if (!AppHelpers.isEmailRequired) return null;
      return l10n.pleaseEnterYourEmail;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n.pleaseEnterAValidEmail;
    }
    return null;
  }

  String? _validatePhoneString(String? number, AppLocalizations l10n) {
    if (number == null || number.isEmpty) {
      if (!AppHelpers.isMobileRequired) return null;
      return l10n.pleaseEnterYourPhoneNumber;
    }
    final trimmed = number.trim();
    if (trimmed.length < 5) return l10n.phoneNumberTooShort;
    if (trimmed.length > 16) return l10n.phoneNumberTooLong;
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return l10n.onlyNumbersAllowed;
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterYourPassword;
    }
    if (value.length < 8) {
      return l10n.passwordMustBeAtLeast8Characters;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseConfirmYourPassword;
    }
    if (value != _passwordController.text) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }

  /// Returns the first field (top-to-bottom) that fails its validator, or.
  _FieldHandle? _firstInvalidField(AppLocalizations l10n) {
    if (_validateName(_nameController.text, l10n) != null) {
      return (shakeKey: _nameShakeKey, focusNode: _nameFocus);
    }
    if (_validateEmail(_emailController.text, l10n) != null) {
      return (shakeKey: _emailShakeKey, focusNode: _emailFocus);
    }
    if (_validatePhoneString(_phoneNumber, l10n) != null) {
      return (shakeKey: _phoneShakeKey, focusNode: _phoneFocus);
    }
    if (_validatePassword(_passwordController.text, l10n) != null) {
      return (shakeKey: _passwordShakeKey, focusNode: _passwordFocus);
    }
    if (_validateConfirmPassword(_confirmPasswordController.text, l10n) !=
        null) {
      return (
        shakeKey: _confirmPasswordShakeKey,
        focusNode: _confirmPasswordFocus,
      );
    }
    return null;
  }

  Future<void> _shakeFocusScroll(_FieldHandle field) async {
    field.shakeKey.currentState?.shake();
    HapticFeedback.heavyImpact();
    final ctx = field.shakeKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    }
    if (!mounted) return;
    field.focusNode.requestFocus();
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;

    final bool mobileProvided =
        _phoneNumber.isNotEmpty && _completePhoneNumber.isNotEmpty;

    // Flag that a submit has been attempted — phone errorText will now track
    setState(() {
      _phoneSubmitAttempted = true;
      _phoneErrorText = _validatePhoneString(_phoneNumber, l10n);
    });

    // 1.
    final invalid = _firstInvalidField(l10n);
    if (invalid != null) {
      _formKey.currentState?.validate();
      _shakeFocusScroll(invalid);
      return;
    }

    // 2. Phone is only mandatory when the active mode requires mobile.
    if (AppHelpers.isMobileRequired && !mobileProvided) {
      ToastManager.show(
          context: context,
          message: l10n.pleaseEnterValidPhoneNumber,
          type: ToastType.error);
      return;
    }

    // 3. Email verification gate
    final verState = context.read<UserVerificationBloc>().state;
    if (_activeVerifyField == _VerifyingField.email && verState is VerifyingUser) {
      // Still checking – the button should already be disabled, but guard anyway
      return;
    }
    if (verState is UserVerified && verState.isUserVerified == true &&
        _activeVerifyField == _VerifyingField.email) {
      ToastManager.show(
          context: context,
          message: l10n.emailAlreadyRegisteredUseDifferent,
          type: ToastType.error);
      return;
    }
    if (verState is UserVerificationFailed &&
        _activeVerifyField == _VerifyingField.email) {
      ToastManager.show(
          context: context,
          message: l10n.errorVerifyingEmail,
          type: ToastType.error);
      return;
    }

    // 4. Phone verification gate (phone must be available / not taken)
    if (_phoneVerified == false) {
      ToastManager.show(
          context: context,
          message: l10n.phoneNumberAlreadyRegistered,
          type: ToastType.error);
      return;
    }

    // 5. Country metadata is only needed when a mobile number is being sent.
    if (mobileProvided &&
        (_countryCode.isEmpty || _countryIso2.isEmpty || _countryName.isEmpty)) {
      ToastManager.show(
          context: context,
          message: l10n.pleaseSelectAValidCountryCode,   // add to ARB
          type: ToastType.error);
      return;
    }

    // 6a. Mobile provided → keep the existing phone-OTP registration flow.
    if (mobileProvided) {
      final registrationData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _phoneNumber,
        'password': _passwordController.text,
        'country': _countryName,
        'iso2': _countryIso2,
        'countryCode': _countryCode,
        'completePhoneNumber': _completePhoneNumber,
        'confirmPassword': _confirmPasswordController.text,
        'referralCode': _referralCodeController.text
      };

      context.read<AuthBloc>().add(StoreRegistrationDataEvent(
        registrationData: registrationData,
        phoneNumber: _phoneNumber,
        countryCode: _countryCode,
        isoCode: _countryIso2,
      ));

      context.read<AuthBloc>().add(SendOtpToPhoneEvent(
        number: _phoneNumber,
        countryCode: _countryCode,
        isoCode: _countryIso2,
      ));
      return;
    }

    // 6b. Mobile omitted (only reachable when the mode makes it optional) →
    // register directly with no OTP step. AuthSuccess is handled by the
    // BlocListener in build().
    final String iso2 =
        _countryIso2.isNotEmpty ? _countryIso2 : AppHelpers.isoCode;
    final String country =
        _countryName.isNotEmpty ? _countryName : AppHelpers.isoCode.toUpperCase();

    context.read<AuthBloc>().add(RegisterRequest(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          mobile: '',
          password: _passwordController.text,
          country: country,
          iso2: iso2,
          countryCode: _countryCode,
          completePhoneNumber: '',
          confirmPassword: _confirmPasswordController.text,
          referralCode: _referralCodeController.text,
        ));
  }

  // ─── OTP navigation ───────────────────────────────────────────────────────
  void _handleRegister(String verificationId) {
    final l10n = AppLocalizations.of(context)!;
    final authBloc = context.read<AuthBloc>();
    final registrationData = authBloc.getPendingRegistrationData();

    if (registrationData == null) {
      ToastManager.show(
          context: context,
          message: l10n.registrationDataNotFound,
          type: ToastType.error);
      return;
    }
    if (!mounted) return;

    // Resend re-emits this state while the OTP page is already on top — only
    // push when this page is still the current route.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    GoRouter.of(context).push(
      AppRoutes.otpVerification,
      extra: {
        'phoneNumber': registrationData['completePhoneNumber'],
        'registrationData': registrationData,
        'verificationId': verificationId,
        'userNumber': authBloc.getPendingPhoneNumber(),
        'countryCode': authBloc.getPendingCountryCode(),
        'isoCode': authBloc.getPendingIsoCode(),
        'isUpdate': false,
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScaffold(
      title: l10n.register,
      showAppBar: true,
      showViewCart: false,
      body: MultiBlocListener(
        listeners: [
          // Auth events
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is LoginPhoneCodeSentState) {
                _handleRegister(state.verificationId ?? '');
              }
              if (state is AuthSuccess) {
                // Only the direct (no-OTP) register path completes here; the
                // OTP path finishes on the OTP screen. Guard on the current
                // route so we don't double-handle while the OTP page is on top.
                if (ModalRoute.of(context)?.isCurrent != true) return;
                context.read<AuthBloc>().add(ClearRegistrationDataEvent());
                ToastManager.show(
                    context: context,
                    message: state.message,
                    type: ToastType.success);
                GoRouter.of(context).pushReplacement(AppRoutes.splashScreen);
              }
              if (state is AuthFailed) {
                ToastManager.show(
                    context: context,
                    message: state.error,
                    type: ToastType.error);
              }
            },
          ),
          // Verification events – snapshot phone results before they're lost
          BlocListener<UserVerificationBloc, UserVerificationState>(
            listener: (context, state) {
              _applyPhoneVerificationState(state, l10n);
            },
          ),
        ],
        child: Stack(
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 8.h),

                    // ── Header ──────────────────────────────────────────────
                    Text(
                      l10n.createAccount,
                      style: AppTextStyles.displayLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      l10n.pleaseFillDetailsCreateYourAccount,
                      style: AppTextStyles.body.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // ── Full Name ────────────────────────────────────────────
                    ShakeWidget(
                      key: _nameShakeKey,
                      shakeOffset: 8,
                      child: CustomTextFormField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        labelText: l10n.fullName,
                        hintText: l10n.enterYourFullName,
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        borderColor: Colors.transparent,
                        borderRadius: 14,
                        borderWidth: 1.5,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                        validator: (value) => _validateName(value, l10n),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Email ────────────────────────────────────────────────
                    ShakeWidget(
                      key: _emailShakeKey,
                      shakeOffset: 8,
                      child: _EmailField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        onChanged: _onEmailChanged,
                        validator: (value) => _validateEmail(value, l10n),
                        labelText: AppHelpers.isEmailRequired
                            ? l10n.email
                            : '${l10n.email} (${l10n.optional})',
                        // Only show email verification state when email is the active field
                        showVerificationState: _activeVerifyField == _VerifyingField.email,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Phone ────────────────────────────────────────────────
                    ShakeWidget(
                      key: _phoneShakeKey,
                      shakeOffset: 8,
                      child: _buildPhoneField(l10n),
                    ),
                    const SizedBox(height: 16),

                    // ── Password ─────────────────────────────────────────────
                    ShakeWidget(
                      key: _passwordShakeKey,
                      shakeOffset: 8,
                      child: CustomTextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        labelText: l10n.password,
                        hintText: l10n.enterYourPassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onSuffixIconTap: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.next,
                        borderColor: Colors.transparent,
                        borderRadius: 14,
                        borderWidth: 1.5,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                        validator: (value) => _validatePassword(value, l10n),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Confirm Password ──────────────────────────────────────
                    ShakeWidget(
                      key: _confirmPasswordShakeKey,
                      shakeOffset: 8,
                      child: CustomTextFormField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        labelText: l10n.confirmPassword,
                        hintText: l10n.confirmYourPassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: _isConfirmPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onSuffixIconTap: () => setState(() =>
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        obscureText: !_isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        borderColor: Colors.transparent,
                        borderRadius: 14,
                        borderWidth: 1.5,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                        validator: (value) =>
                            _validateConfirmPassword(value, l10n),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if(SettingsData.instance.system!.referEarnStatus == true)...[
                      CustomTextFormField(
                        controller: _referralCodeController,
                        labelText: l10n.referralCode,
                        hintText: l10n.referralCodeHintText,
                        prefixIcon: Icons.card_giftcard_outlined,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.done,
                        borderColor: Colors.transparent,
                        borderRadius: 14,
                        borderWidth: 1.5,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                      ),
                      SizedBox(height: 28.h),
                    ],

                    // ── Submit button ─────────────────────────────────────────
                    _SubmitButton(onPressed: _submit),
                    const SizedBox(height: 16),

                    // ── Login link ────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.alreadyHaveAnAccount,
                          style: AppTextStyles.body,
                        ),
                        GestureDetector(
                          onTap: () => GoRouter.of(context).pop(),
                          child: Text(
                            l10n.login,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Phone field widget ───────────────────────────────────────────────────
  Widget _buildPhoneField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Separate country-code picker + number field (renders its own error).
        PhoneNumberField(
          focusNode: _phoneFocus,
          initialIso:
              _countryIso2.isNotEmpty ? _countryIso2 : AppHelpers.isoCode,
          labelText: AppHelpers.isMobileRequired
              ? l10n.phoneNumber
              : '${l10n.phoneNumber} (${l10n.optional})',
          hintText: l10n.enterYourPhoneNumber,
          errorText: _phoneErrorText,
          onChanged: (data) {
            setState(() {
              _completePhoneNumber = data.complete;
              _countryCode = data.dialCode;
              _phoneNumber = data.national;
              _countryIso2 = data.iso;
              _countryName = data.iso.toUpperCase();
              if (_phoneSubmitAttempted) {
                _phoneErrorText = _validatePhoneString(data.national, l10n);
              }
            });
            _onPhoneChanged(data.national);
          },
        ),

        // Helper row – driven by snapshotted phone state
        if (_phoneHelperText != null) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              if (_phoneStatusIcon != null) ...[
                _phoneStatusIcon!,
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: Text(
                  _phoneHelperText!,
                  style: AppTextStyles.label.copyWith(
                    color: _phoneVerified == true
                        ? context.appColors.success
                        : _phoneVerified == false
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
  }
}

// ─── Email field (extracted widget) ──────────────────────────────────────────
class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool showVerificationState;
  final String labelText;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;

  const _EmailField({
    required this.controller,
    required this.onChanged,
    required this.showVerificationState,
    required this.labelText,
    this.focusNode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, state) {
        // Determine helper content
        bool? isVerified;
        String? helperText;
        Widget? statusIcon;

        if (showVerificationState && controller.text.isNotEmpty) {
          if (state is VerifyingUser) {
            // spinner shown inline via Stack below
          } else if (state is UserVerified) {
            isVerified = state.isUserVerified; // true = already registered
            // On REGISTER: already registered = BAD (red), not registered = GOOD (green)
            helperText = isVerified == true
                ? l10n.emailAlreadyRegistered
                : l10n.emailAvailable;
            statusIcon = Icon(
              isVerified == true ? Icons.cancel : Icons.check_circle,
              color: isVerified == true
                  ? Theme.of(context).colorScheme.error
                  : context.appColors.success,
              size: 16,
            );
          } else if (state is UserVerificationFailed) {
            helperText = l10n.errorVerifyingEmail;
            statusIcon =
                Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 16);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Stack(
                children: [
                  CustomTextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    labelText: labelText,
                    hintText: l10n.enterYourEmail,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    borderColor: Colors.transparent,
                    borderRadius: 14,
                    borderWidth: 1.5,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                    onChanged: onChanged,
                    validator: validator,
                  ),
                  // Inline spinner while verifying
                  if (showVerificationState && state is VerifyingUser)
                    const Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: 40,
                      child: Center(
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (helperText != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (statusIcon != null) ...[
                    statusIcon,
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      helperText,
                      style: AppTextStyles.label.copyWith(
                        color: isVerified == true
                            ? Theme.of(context).colorScheme.error
                            : context.appColors.success,
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
}

// ─── Submit button (extracted widget) ────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SubmitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuthLoading =
            authState is AuthLoading || authState is LoginCodeSentProgress;

        return BlocBuilder<UserVerificationBloc, UserVerificationState>(
          builder: (context, verState) {
            final isVerifying = verState is VerifyingUser;
            final isDisabled = isAuthLoading || isVerifying;

            return CustomButton(
              height: isTablet(context) ? 70 : 50,
              onPressed: isDisabled ? null : onPressed,
              child: isAuthLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : isVerifying
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.checkingEmail),
                ],
              )
                  : Text(
                l10n.createAccount,
                style: AppTextStyles.titleMedium,
              ),
            );
          },
        );
      },
    );
  }
}