import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WebViewPaymentPage extends StatefulWidget {
  final Function()? onPaymentSuccess;
  final Function()? onPaymentFailure;
  final String paymentUrl;

  const WebViewPaymentPage({
    super.key,
    this.onPaymentSuccess,
    required this.onPaymentFailure,
    required this.paymentUrl
  });

  @override
  State<WebViewPaymentPage> createState() => _WebViewPaymentPageState();
}

class _WebViewPaymentPageState extends State<WebViewPaymentPage> {
  late final WebViewController _controller;
  bool isLoading = true;
  late String checkoutUrl = '';

  // Flag to track if we've already handled redirection
  bool hasRedirected = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    checkoutUrl = widget.paymentUrl;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
            _checkForRedirection(url);
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            _checkForRedirection(url);
          },
          onUrlChange: (UrlChange change) {
            _checkForRedirection(change.url ?? '');
          },
          onWebResourceError: (WebResourceError error) {
            log('Webview load error: ${error.description}');
            if (!mounted || hasRedirected) return;
            setState(() {
              isLoading = false;
              loadError = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            /*if (!_isAllowedGatewayHost(request.url)) {
              log('Blocked navigation to non-gateway host: ${request.url}');
              return NavigationDecision.prevent;
            }*/
            _checkForRedirection(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  void _checkForRedirection(String url) {
    if (kDebugMode) log('Redirection URL check: $url');
    if (hasRedirected) return;
    // if (!_isAllowedGatewayHost(url)) return;
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('cancel') ||
        lowerUrl.contains('payment_intent=failed') ||
        lowerUrl.contains('status=failed') ||
        lowerUrl.contains('status=rejected') ||
        lowerUrl.contains('collection_status=rejected') ||
        lowerUrl.contains('collection_status=cancelled') ||
        lowerUrl.contains('congrats/rejected') ||
        lowerUrl.contains('status=expired') ||
        lowerUrl.contains('status=cancelled') ||
        lowerUrl.contains('error')) {

      hasRedirected = true;
      _handleFailure();
    } else if (lowerUrl.contains('success') ||
        lowerUrl.contains('congrats') ||
        lowerUrl.contains('payment_intent=succeeded') ||
        lowerUrl.contains('status=succeeded') ||
        lowerUrl.contains('status=completed') ||
        lowerUrl.contains('status=approved') ||
        lowerUrl.contains('collection_status=approved') ||
        lowerUrl.contains('payment_status=approved') ||
        lowerUrl.contains('status=paid') ||
        lowerUrl.contains('status=settled') ||
        lowerUrl.contains('payment_status=paid') ||
        lowerUrl.contains('trxref')) {

      final uri = Uri.tryParse(url);
      final ref = uri?.queryParameters['reference'] ??
          uri?.queryParameters['trxref'] ??
          uri?.queryParameters['payment_id'] ??
          uri?.queryParameters['collection_id'] ??
          uri?.queryParameters['preference_id'] ??
          uri?.queryParameters['preference-id'] ??
          uri?.queryParameters['external_reference'] ??
          uri?.queryParameters['external_id'] ??
          uri?.queryParameters['id'];
      hasRedirected = true;
      _handleSuccess(ref);
    }
  }

  void _handleSuccess(String? reference) {
    // Show success message
    ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.paymentSuccessful,
        type: ToastType.success
    );

    // Delay to allow the user to see the message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop({
          'success': true,
          'message': 'Payment completed successfully',
          'payment_id': null,
          'signature': null,
          'order_id': reference,
          'reference': reference,
        });
      }
    });
  }

  void _handleFailure() {
    // Show failure message
    ToastManager.show(
      context: context,
      message: AppLocalizations.of(context)!.paymentFailedOrCancelled,
      type: ToastType.error
    );

    // Delay to allow the user to see the message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop({
          'success': false,
          'error': 'Payment cancelled or failed',
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: hasRedirected,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !hasRedirected) {
          // If user tried to pop but we're not allowing it, treat as cancellation
          _handleFailure();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F2027),
          title: Text(
            AppLocalizations.of(context)!.paymentMethod,
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Handle manual back button press
              if (!hasRedirected) {
                _handleFailure();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          elevation: 0,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (loadError != null)
              Container(
                color: Colors.white,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.paymentFailedOrCancelled,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16.sp, color: const Color(0xFF203A43)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loadError ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          loadError = null;
                          isLoading = true;
                        });
                        _controller.loadRequest(Uri.parse(checkoutUrl));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2C5364),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.loadingPaymentPage,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF203A43),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}