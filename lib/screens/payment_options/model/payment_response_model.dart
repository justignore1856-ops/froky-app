import '../../../config/helper.dart';

/// Gateway handle returned inside `order.payment_response` on order creation
/// (and again on `/pay` retry). Only the keys for the chosen gateway are set;
/// COD / wallet return no handle (payment_response is null).
class PaymentResponse {
  // Stripe
  final String? clientSecret;
  final String? paymentIntentId;

  // Razorpay
  final String? razorpayOrderId;
  final String? keyId;
  final int? amount; // minor units (paise)
  final String? currency;

  // Paystack
  final String? authorizationUrl;
  final String? accessCode;
  final String? reference;

  // Flutterwave / Mercado Pago / Xendit / Generic Hosted Webview
  final String? link;
  final String? initPoint;
  final String? invoiceUrl;
  final String? checkoutUrl;

  const PaymentResponse({
    this.clientSecret,
    this.paymentIntentId,
    this.razorpayOrderId,
    this.keyId,
    this.amount,
    this.currency,
    this.authorizationUrl,
    this.accessCode,
    this.reference,
    this.link,
    this.initPoint,
    this.invoiceUrl,
    this.checkoutUrl,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final initPt = json['init_point']?.toString() ??
        json['initPoint']?.toString() ??
        json['sandbox_init_point']?.toString();
    final invUrl = json['invoice_url']?.toString() ?? json['invoiceUrl']?.toString();
    final chkUrl = json['checkout_url']?.toString() ?? json['checkoutUrl']?.toString();
    final genericLink = json['link']?.toString() ??
        json['url']?.toString() ??
        initPt ??
        invUrl ??
        chkUrl;

    return PaymentResponse(
      clientSecret: json['clientSecret']?.toString(),
      paymentIntentId: json['paymentIntentId']?.toString(),
      razorpayOrderId: json['razorpay_order_id']?.toString(),
      keyId: json['key_id']?.toString(),
      amount: json['amount'] == null ? null : parseInt(json['amount']),
      currency: json['currency']?.toString(),
      authorizationUrl: json['authorization_url']?.toString(),
      accessCode: json['access_code']?.toString(),
      reference: json['reference']?.toString(),
      link: genericLink,
      initPoint: initPt,
      invoiceUrl: invUrl,
      checkoutUrl: chkUrl,
    );
  }

  static PaymentResponse? fromNullable(dynamic json) {
    final map = parseMap(json);
    if (map.isEmpty) return null;
    return PaymentResponse.fromJson(map);
  }
}
