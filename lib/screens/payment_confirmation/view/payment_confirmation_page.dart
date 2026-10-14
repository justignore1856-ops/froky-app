import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../payment_options/model/payment_response_model.dart';
import '../../payment_options/repo/gateway_launcher.dart';
import '../bloc/payment_confirmation_bloc.dart';
import '../repo/payment_confirmation_repository.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class PaymentConfirmationPage extends StatelessWidget {
  final String orderSlug;
  final int orderItemId;
  final String paymentType;
  final PaymentResponse paymentResponse;
  final String address;
  final String addressType;
  final String? contact;
  final String? email;

  const PaymentConfirmationPage({
    super.key,
    required this.orderSlug,
    required this.orderItemId,
    required this.paymentType,
    required this.paymentResponse,
    required this.address,
    required this.addressType,
    this.contact,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentConfirmationBloc(
        repository: PaymentConfirmationRepository(),
      )..add(ConfirmationStarted(
          slug: orderSlug,
          paymentType: paymentType,
          paymentResponse: paymentResponse,
          contact: contact,
          email: email,
        )),
      child: _PaymentConfirmationView(
        orderSlug: orderSlug,
        orderItemId: orderItemId,
        address: address,
        addressType: addressType,
        contact: contact,
        email: email,
      ),
    );
  }
}

class _PaymentConfirmationView extends StatefulWidget {
  final String orderSlug;
  final int orderItemId;
  final String address;
  final String addressType;
  final String? contact;
  final String? email;

  const _PaymentConfirmationView({
    required this.orderSlug,
    required this.orderItemId,
    required this.address,
    required this.addressType,
    this.contact,
    this.email,
  });

  @override
  State<_PaymentConfirmationView> createState() =>
      _PaymentConfirmationViewState();
}

class _PaymentConfirmationViewState extends State<_PaymentConfirmationView> {
  final GatewayLauncher _launcher = const GatewayLauncher();
  int _handledToken = 0;

  Future<void> _launch(LaunchGatewayState state) async {
    if (state.token == _handledToken) return;
    _handledToken = state.token;

    final result = await _launcher.open(
      context: context,
      paymentType: state.paymentType,
      paymentResponse: state.paymentResponse,
      contact: widget.contact,
      email: widget.email,
    );
    if (!mounted) return;
    context
        .read<PaymentConfirmationBloc>()
        .add(GatewayLaunchCompleted(result, state.token));
  }

  void _goToSuccess() {
    GoRouter.of(context).pushReplacement(
      AppRoutes.orderSuccess,
      extra: {
        'address': widget.address,
        'addressType': widget.addressType,
        'orderSlug': widget.orderSlug,
        'orderItemId': widget.orderItemId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: TabletConstrainedBody(
        child: SafeArea(
          child: BlocConsumer<PaymentConfirmationBloc,
              PaymentConfirmationState>(
            listener: (context, state) {
              log('Hellooo $state');
              if (state is LaunchGatewayState) {
                _launch(state);
              } else if (state is PaymentSucceededState) {
                _goToSuccess();
              }
            },
            builder: (context, state) => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: _buildBody(context, state),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PaymentConfirmationState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state is PaymentFailedState || state is PaymentLaunchErrorState) {
      final message = state is PaymentFailedState
          ? state.message
          : (state as PaymentLaunchErrorState).message;
      return _statusView(
        icon: Icons.error_outline,
        color: AppTheme.errorColor,
        title: l10n.paymentFailed,
        subtitle: message?.isNotEmpty == true ? message! : l10n.paymentFailedSubtitle,
        primaryLabel: l10n.retryPayment,
        onPrimary: () =>
            context.read<PaymentConfirmationBloc>().add(RetryRequested()),
        secondaryLabel: l10n.cancel,
        onSecondary: () =>
            context.read<PaymentConfirmationBloc>().add(CancelRequested()),
      );
    }

    if (state is PaymentCancelledState) {
      return _statusView(
        icon: Icons.cancel_outlined,
        color: AppTheme.errorColor,
        title: l10n.paymentCancelledTitle,
        subtitle: state.message?.isNotEmpty == true
            ? state.message!
            : l10n.paymentCancelledSubtitle,
        primaryLabel: l10n.backToCart,
        onPrimary: () => context.pop(),
      );
    }

    if (state is PaymentTimedOutState) {
      return _statusView(
        icon: Icons.access_time,
        color: AppTheme.primaryColor,
        title: l10n.paymentStillConfirmingTitle,
        subtitle: l10n.paymentStillConfirmingSubtitle,
        primaryLabel: l10n.viewMyOrders,
        onPrimary: () => context.pop(),
        secondaryLabel: l10n.continueShopping,
        onSecondary: () => context.go(AppRoutes.home),
      );
    }

    // Initial / LaunchGateway / Confirming / Succeeded (navigating away).
    final String message = state is ConfirmingPaymentState &&
            (state.message?.isNotEmpty ?? false)
        ? state.message!
        : l10n.confirmingPaymentTitle;
    return _spinnerView(message, l10n.confirmingPaymentSubtitle);
  }

  Widget _spinnerView(String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 54.r,
          height: 54.r,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.tertiary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSecondaryContainer,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _statusView({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 84.r, color: color),
        SizedBox(height: 20.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.tertiary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSecondaryContainer,
            height: 1.4,
          ),
        ),
        SizedBox(height: 28.h),
        SizedBox(
          width: double.infinity,
          height: 45.h,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: onPrimary,
            child: Text(
              primaryLabel,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 45.h,
            child: TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
