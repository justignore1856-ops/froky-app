import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/auth/bloc/user_verification/user_verification_bloc.dart';
import 'package:hyper_commerce/screens/auth/bloc/user_verification/user_verification_event.dart';
import 'package:hyper_commerce/screens/auth/bloc/user_verification/user_verification_state.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/whole_page_progress.dart';
import '../../../config/helper.dart';
import '../../../services/referral_prompt_coordinator.dart';
import '../../cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFieldKey = GlobalKey<FormFieldState>();

  bool _isPasswordVisible = false;

  // Verification feedback
  bool? isUserVerified;
  String? helperText;
  Widget? statusIcon;
  String? inputHint;

  // Animation controllers
  late AnimationController _slideController;
  late Animation<double> _fade;

  static const String _demoEmail = '9000000000';
  static const String _demoPassword = '12345678';

  // Debounce
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(duration: const Duration(milliseconds: 550), vsync: this);
    _fade = CurvedAnimation(parent: _slideController, curve: Curves.easeOut);

    if (AppHelpers.isDemo) {
      _identifierController.text = _demoEmail;
      _passwordController.text = _demoPassword;
      // Immediately trigger the verification logic for the pre-filled demo data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleIdentifierChange(_identifierController.text);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _slideController.forward());
  }

  // Smart Detection: Email or Phone?
  String _detectInputType(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'empty';

    // Prefer email if it looks valid
    if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return 'email';
    }

    // Phone: clean typical separators, then strict check
    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned) && !trimmed.contains('@')) {
      return 'phone';
    }

    return 'invalid';
  }

  bool _isValidEmail(String s) => _detectInputType(s) == 'email';
  bool _isValidPhone(String s) => _detectInputType(s) == 'phone';
  bool _isValidIdentifier(String s) => _isValidEmail(s) || _isValidPhone(s);

  void _handleIdentifierChange(String value) {
    _debounceTimer?.cancel();

    final type = _detectInputType(value);
    log('Input typee $type');

    if (type == 'empty' || type == 'invalid') {
      context.read<UserVerificationBloc>().add(ResetVerification());
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      if (_identifierController.text.trim() == value.trim()) {
        if (type == 'email') {
          context.read<UserVerificationBloc>().add(VerifyUser(
              value: value.trim(), type: type));
        } else {
          // Normalize phone: remove all non-digits except +
          String cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
          context.read<UserVerificationBloc>().add(VerifyUser(value: cleanPhone, type: 'mobile'));
        }
      }
    });
  }

  void _handleLogin() {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (isUserVerified != true) {
      final l10n = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        message: l10n.noAccountFoundWithEmailOrPhone,
        type: ToastType.error,
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ToastManager.show(
          context: context,
          message: l10n.pleaseEnterYourPassword,
          type: ToastType.error
      );
      return;
    }

    final identifier = _identifierController.text.trim();

    context.read<AuthBloc>().add(LoginRequest(
      email: _isValidEmail(identifier) ? identifier : null,
      phoneNumber: _isValidPhone(identifier) ? identifier : null,
      password: _passwordController.text,
    ));

  }

  void _goToOtpLogin() {
    FocusManager.instance.primaryFocus?.unfocus();
    GoRouter.of(context).push(
      AppRoutes.continueWithOtp,
      extra: {'isDirectLogin': true, 'isUpdate': false},
    ).then((value) async {
      _handleIdentifierChange(_identifierController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        Global.setIsFirstTime(false);
        GoRouter.of(context).go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        resizeToAvoidBottomInset: true,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              GoRouter.of(context).pushReplacement(AppRoutes.splashScreen);
              ToastManager.show(context: context, message: state.message, type: ToastType.success);
              final getUserCartBloc = context.read<GetUserCartBloc>();

              Future.delayed(const Duration(seconds: 1), () {
                getUserCartBloc.add(SyncCart());
              });
            } else if (state is AuthFailed) {
              ToastManager.show(context: context, message: state.error, type: ToastType.error);
            } else if (state is SocialAuthSuccess) {
              if (SettingsData.instance.system!.referEarnStatus == true && state.isRegister == true) {
                ReferralPromptCoordinator.pending = true;
              }
              GoRouter.of(context).pushReplacement(AppRoutes.splashScreen);
              ToastManager.show(
                context: context,
                message: state.message ?? 'Login successful',
                type: ToastType.success,
              );
              final getUserCartBloc = context.read<GetUserCartBloc>();
              Future.delayed(const Duration(seconds: 1), () {
                getUserCartBloc.add(SyncCart());
              });
            }
          },
          builder: (context, authState) {
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
                  child: FadeTransition(
                    opacity: _fade,
                    child: _buildContent(),
                  ),
                ),
                if (authState is AuthLoading) const WholePageProgress(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Global.setIsFirstTime(false);
                  GoRouter.of(context).go(AppRoutes.home);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.skip,
                  style: AppTextStyles.body.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),


            Text(
              l10n.welcomeBack,
              style: AppTextStyles.displayLarge.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: scheme.tertiary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              l10n.signInToYourAccount,
              style: AppTextStyles.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 28.h),

            _buildIdentifierField(),
            SizedBox(height: 18.h),

            _buildPasswordField(),

            SizedBox(height: 6.h),
            _buildForgotLink(),
            SizedBox(height: 22.h),

            _buildSignInButton(),
            SizedBox(height: 22.h),

            _buildDivider(l10n.or),
            SizedBox(height: 22.h),

            _buildSocialRow(),

            SizedBox(height: 28.h),
            _buildSignUpRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifierField() {
    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, state) {
        // Reset on empty
        if (_identifierController.text.trim().isEmpty) {

          isUserVerified = null;
          helperText = null;
          statusIcon = null;

        } else if (state is VerifyingUser) {
          final l10n = AppLocalizations.of(context)!;
          isUserVerified = null;
          helperText = l10n.verifying;
          statusIcon = SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.appColors.warning,));

        } else if (state is UserVerified) {
          final l10n = AppLocalizations.of(context)!;
          isUserVerified = state.isUserVerified;
          if (isUserVerified == true) {
            helperText = _detectInputType(_identifierController.text) == 'email'
                ? l10n.emailVerifiedSuccessfully
                : l10n.phoneNumberVerifiedSuccessfully;
          } else {
            helperText = _detectInputType(_identifierController.text) == 'email'
                ? l10n.thisEmailIsNotRegistered
                : l10n.thisPhoneNumberIsNotRegistered;
          }
          statusIcon = Icon(
            isUserVerified == true ? Icons.check_circle : Icons.cancel,
            color: isUserVerified == true ? context.appColors.success : Theme.of(context).colorScheme.error,
            size: 16,
          );

        } else if (state is UserVerificationFailed) {
          final l10n = AppLocalizations.of(context)!;
          isUserVerified = false;
          helperText = l10n.unableToVerifyUser;
          statusIcon = Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 16);
        } else if (_identifierController.text.trim().isNotEmpty) {
          final type = _detectInputType(_identifierController.text);
          if (type == 'invalid') {
            isUserVerified = false;
            helperText = AppLocalizations.of(context)!.enterValidEmailOrPhone;
            statusIcon = Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 16);
          } else {
            isUserVerified = null;
            helperText = null;
            statusIcon = null;
          }
        } else {
          isUserVerified = null;
          helperText = null;
          statusIcon = null;
        }

        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFormField(
                key: _identifierFieldKey,
                controller: _identifierController,
                // labelText: l10n.emailOrPhoneNumber,
                hintText: l10n.emailOrPhoneNumber,
                prefixIcon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                borderRadius: 14,
                borderWidth: 1.5,
                borderColor: Colors.transparent,
                // contentPadding: EdgeInsets.symmetric(vertical: .h, horizontal: 8.w),
                validator: (value) {
                  if (state is VerifyingUser ||
                      state is UserVerified ||
                      state is UserVerificationFailed) {
                    return null;
                  }

                  if (value == null || value.isEmpty) {
                    return l10n.emailOrPhoneNumberIsRequired;
                  }
                  if (!_isValidIdentifier(value)) return l10n.enterValidEmailOrPhone;
                  return null;
                },
                onChanged: _handleIdentifierChange,
              ),

            if (helperText != null) ...[
              SizedBox(height: 6.h),
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

  Widget _buildPasswordField() {
    final l10n = AppLocalizations.of(context)!;
    return CustomTextFormField(
        controller: _passwordController,
        // labelText: l10n.password,
        hintText: l10n.password,
        obscureText: !_isPasswordVisible,
        prefixIcon: Icons.lock_outline,
        borderRadius: 14,
        borderWidth: 1.5,
        borderColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        suffixIcon: _isPasswordVisible
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        onSuffixIconTap: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            ToastManager.show(
              context: context,
              message: l10n.passwordIsRequired,
            );
            return null;
          }
          return null;
        },
    );
  }

  Widget _buildForgotLink() {
    final l10n = AppLocalizations.of(context)!;
    final blocked = isUserVerified == false;
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: blocked ? null : () => GoRouter.of(context).push(AppRoutes.forgotPassword),
        child: Text(
          l10n.forgotPassword,
          style: AppTextStyles.label.copyWith(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<UserVerificationBloc, UserVerificationState>(
      builder: (context, verificationState) {
        final isVerifying = verificationState is VerifyingUser;
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isAuthLoading = state is AuthLoading;
            final isButtonEnabled =
                !isVerifying && !isAuthLoading && isUserVerified == true;

            return SizedBox(
              height: isTablet(context) ? 70 : 48,
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (isVerifying) return;
                  if (isButtonEnabled) {
                    _handleLogin();
                  } else {
                    ToastManager.show(
                      context: context,
                      message: l10n.pleaseEnterYourEmail,
                      type: ToastType.error,
                    );
                  }
                },
                child: Text(
                  isVerifying ? l10n.verifying : l10n.signIn,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDivider(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: scheme.outline, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: scheme.outline, thickness: 1)),
      ],
    );
  }

  /// OTP, Google and Apple as icon-only buttons in a single row.
  Widget _buildSocialRow() {
    final auth = SettingsData.instance.authentication!;
    final buttons = <Widget>[
      _iconAuthButton(
        onTap: _goToOtpLogin,
        child: Image.asset('assets/images/icons/otp.png',
            height: 24, width: 24),
      ),
      if (auth.googleLogin)
        _iconAuthButton(
          onTap: () => context.read<AuthBloc>().add(GoogleLoginRequest()),
          child: Image.asset('assets/images/icons/google-logo.png',
              height: 24, width: 24),
        ),
      if (Platform.isIOS && auth.appleLogin)
        _iconAuthButton(
          onTap: () => context.read<AuthBloc>().add(AppleLoginRequest()),
          child: Image.asset('assets/images/icons/apple-logo.png',
              height: 24, width: 24),
        ),
    ];

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) SizedBox(width: 14.w),
          buttons[i],
        ],
      ],
    );
  }

  Widget _iconAuthButton({required Widget child, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSignUpRow() {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.dontHaveAnAccount,
            style: AppTextStyles.body.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => GoRouter.of(context).push(AppRoutes.register),
            child: Text(
              l10n.signUp,
              style: AppTextStyles.body.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _slideController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
