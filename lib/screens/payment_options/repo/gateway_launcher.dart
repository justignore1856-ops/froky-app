import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe hide PaymentMethodType;
import 'package:hyper_commerce/screens/payment_options/widgets/webview_payment.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../config/constant.dart';
import '../../../config/settings_data_instance.dart';
import '../model/payment_response_model.dart';

/// Outcome of opening a gateway SDK. Never treated as the source of truth for
/// whether the order is paid — the server (poll/push) decides that. Only tells
/// the caller how to proceed:
///  - submitted: user went through the gateway; poll the server for the result.
///  - dismissed: user cancelled/closed without paying; release via cancel-payment.
///  - error: could not launch (bad handle / config); let the user retry.
enum GatewayLaunchStatus { submitted, dismissed, error }

class GatewayLaunchResult {
  final GatewayLaunchStatus status;
  final String? message;
  final String? reference;

  const GatewayLaunchResult(this.status, {this.message, this.reference});

  bool get isSubmitted => status == GatewayLaunchStatus.submitted;
  bool get isDismissed => status == GatewayLaunchStatus.dismissed;
  bool get isError => status == GatewayLaunchStatus.error;
}

/// Opens the correct gateway SDK from a server-issued [PaymentResponse].
/// The amount and order are fixed server-side — this never computes an amount.
class GatewayLauncher {
  const GatewayLauncher();

  Future<GatewayLaunchResult> open({
    required BuildContext context,
    required String paymentType,
    required PaymentResponse paymentResponse,
    String? contact,
    String? email,
  }) async {
    final type = paymentType.toLowerCase().replaceAll('payment', '');
    switch (type) {
      case 'razorpay':
        return _openRazorpay(paymentResponse, contact: contact, email: email);
      case 'stripe':
        return _openStripe(context, paymentResponse);
      case 'paystack':
        return _openWebview(context, paymentResponse.authorizationUrl);
      case 'flutterwave':
      case 'mercadopago':
      case 'mercado_pago':
      case 'xendit':
        return _openWebview(context, paymentResponse.link ?? paymentResponse.initPoint ?? paymentResponse.invoiceUrl ?? paymentResponse.checkoutUrl);
      default:
        return const GatewayLaunchResult(
          GatewayLaunchStatus.error,
          message: 'Unsupported payment method',
        );
    }
  }

  Future<GatewayLaunchResult> _openRazorpay(
    PaymentResponse pr, {
    String? contact,
    String? email,
  }) async {
    final orderId = pr.razorpayOrderId;
    final keyId = pr.keyId;
    if (orderId == null || orderId.isEmpty || keyId == null || keyId.isEmpty) {
      return const GatewayLaunchResult(
        GatewayLaunchStatus.error,
        message: 'Invalid Razorpay session',
      );
    }

    final completer = Completer<GatewayLaunchResult>();
    final razorpay = Razorpay();

    void finish(GatewayLaunchResult result) {
      if (!completer.isCompleted) completer.complete(result);
      razorpay.clear();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
      finish(GatewayLaunchResult(GatewayLaunchStatus.submitted,
          reference: response.paymentId));
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        finish(const GatewayLaunchResult(GatewayLaunchStatus.dismissed,
            message: 'Payment cancelled'));
      } else {
        // An attempt was made; let the server confirm the real outcome.
        finish(GatewayLaunchResult(GatewayLaunchStatus.error,
            message: response.message));
      }
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
        (ExternalWalletResponse response) {
      finish(const GatewayLaunchResult(GatewayLaunchStatus.submitted));
    });

    final options = <String, dynamic>{
      'key': keyId,
      'order_id': orderId,
      'name': AppConstant.appName,
      'description': 'Order',
      if (pr.amount != null) 'amount': pr.amount,
      if (pr.currency != null && pr.currency!.isNotEmpty) 'currency': pr.currency,
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? '',
      },
    };

    try {
      razorpay.open(options);
    } catch (e) {
      finish(GatewayLaunchResult(GatewayLaunchStatus.error,
          message: e.toString()));
    }
    return completer.future;
  }

  Future<GatewayLaunchResult> _openStripe(
      BuildContext context, PaymentResponse pr) async {
    final clientSecret = pr.clientSecret;
    if (clientSecret == null || clientSecret.isEmpty) {
      return const GatewayLaunchResult(
        GatewayLaunchStatus.error,
        message: 'Invalid Stripe session',
      );
    }

    final settings = SettingsData.instance.payment;
    final publishableKey = settings?.stripePublishableKey ?? '';
    if (publishableKey.isEmpty) {
      return const GatewayLaunchResult(
        GatewayLaunchStatus.error,
        message: 'Stripe not configured',
      );
    }

    try {
      stripe.Stripe.publishableKey = publishableKey;
      final currency = (settings?.stripeCurrencyCode?.isNotEmpty ?? false)
          ? settings!.stripeCurrencyCode
          : SettingsData.instance.system?.currency?.toString();

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          merchantDisplayName: AppConstant.appName,
          paymentIntentClientSecret: clientSecret,
          googlePay: stripe.PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
            currencyCode: currency,
          ),
          billingDetailsCollectionConfiguration:
              const stripe.BillingDetailsCollectionConfiguration(
            name: stripe.CollectionMode.always,
            email: stripe.CollectionMode.always,
          ),
          allowsDelayedPaymentMethods: true,
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();
      return const GatewayLaunchResult(GatewayLaunchStatus.submitted);
    } on stripe.StripeException catch (e) {
      if (e.error.code == stripe.FailureCode.Canceled) {
        return const GatewayLaunchResult(GatewayLaunchStatus.dismissed,
            message: 'Payment cancelled');
      }
      // A non-cancel Stripe error still routes through server confirmation.
      return GatewayLaunchResult(GatewayLaunchStatus.submitted,
          message: e.error.message);
    } catch (e) {
      return GatewayLaunchResult(GatewayLaunchStatus.error,
          message: e.toString());
    }
  }

  Future<GatewayLaunchResult> _openWebview(
      BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      return const GatewayLaunchResult(
        GatewayLaunchStatus.error,
        message: 'Invalid payment link',
      );
    }
    if (!context.mounted) {
      return const GatewayLaunchResult(
        GatewayLaunchStatus.error,
        message: 'Context not available',
      );
    }

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => WebViewPaymentPage(
          paymentUrl: url,
          onPaymentSuccess: () {},
          onPaymentFailure: () {},
        ),
      ),
    );

    final map = result is Map ? result : const {};
    if (map['success'] == true) {
      return GatewayLaunchResult(GatewayLaunchStatus.submitted,
          reference: map['reference']?.toString());
    }
    // Webview closed / cancelled / failed → dismissed, so the caller releases
    // the order via cancel-payment rather than polling to a 90s timeout.
    return const GatewayLaunchResult(GatewayLaunchStatus.dismissed,
        message: 'Payment cancelled or failed');
  }
}
