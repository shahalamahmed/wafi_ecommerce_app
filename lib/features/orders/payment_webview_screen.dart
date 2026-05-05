import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/features/orders/payment_model.dart';
import 'package:wafi_ecommerce_app/features/orders/payment_service.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class PaymentWebViewScreen extends ConsumerStatefulWidget {
  const PaymentWebViewScreen({super.key, required this.session});

  final PaymentSession session;

  @override
  ConsumerState<PaymentWebViewScreen> createState() =>
      _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _controller;
  _CheckoutViewState _viewState = _CheckoutViewState.loading;
  bool _hasHandledCallback = false;
  String _statusText = 'Opening secure payment page...';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onNavigationRequest: _onNavigationRequest,
          onWebResourceError: _onWebResourceError,
        ),
      )
      ..loadRequest(Uri.parse(widget.session.gatewayUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _viewState != _CheckoutViewState.verifying,
      child: Scaffold(
        appBar: const WafiAppBar(
          title: 'SSLCOMMERZ Checkout',
          subtitle: 'Complete the payment in the secure hosted page',
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_viewState != _CheckoutViewState.idle)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.10),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: GlassCard(
                        variant: GlassCardVariant.elevated,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSizes.lg),
                            Text(
                              _statusText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onPageStarted(String url) {
    if (_isCallbackUrl(url)) {
      setState(() {
        _viewState = _CheckoutViewState.awaitingCallback;
        _statusText = 'Receiving payment callback...';
      });
      return;
    }

    if (_viewState != _CheckoutViewState.idle) {
      setState(() {
        _viewState = _CheckoutViewState.loading;
        _statusText = 'Opening secure payment page...';
      });
    }
  }

  void _onPageFinished(String url) {
    if (_isCallbackUrl(url)) {
      unawaited(_handleCallback(url));
      return;
    }

    if (mounted) {
      setState(() => _viewState = _CheckoutViewState.idle);
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (_isCallbackUrl(request.url) && mounted) {
      setState(() {
        _viewState = _CheckoutViewState.awaitingCallback;
        _statusText = 'Receiving payment callback...';
      });
    }
    return NavigationDecision.navigate;
  }

  void _onWebResourceError(WebResourceError error) {
    if (!mounted || _hasHandledCallback) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(error.description)));
  }

  Future<void> _handleCallback(String url) async {
    if (_hasHandledCallback) return;
    _hasHandledCallback = true;

    if (mounted) {
      setState(() {
        _viewState = _CheckoutViewState.verifying;
        _statusText = 'Verifying payment with SSLCOMMERZ...';
      });
    }

    try {
      PaymentStatusSnapshot? snapshot;
      for (var attempt = 0; attempt < 5; attempt++) {
        snapshot = await ref
            .read(paymentServiceProvider)
            .fetchPaymentStatus(widget.session.attemptId);

        if (snapshot.status.isTerminal) {
          break;
        }

        await Future<void>.delayed(const Duration(seconds: 1));
      }

      if (!mounted || snapshot == null) return;
      final resolvedSnapshot = snapshot;

      setState(() {
        _viewState = _mapSnapshotState(resolvedSnapshot.status);
        _statusText = resolvedSnapshot.message ?? 'Payment status updated.';
      });

      Navigator.of(context).pop(resolvedSnapshot);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _viewState = _CheckoutViewState.invalid;
        _statusText = error.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      Navigator.of(context).pop();
    }
  }

  bool _isCallbackUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path.toLowerCase() ?? '';
    return path.endsWith('/payments/sslcommerz/success') ||
        path.endsWith('/payments/sslcommerz/fail') ||
        path.endsWith('/payments/sslcommerz/cancel');
  }

  _CheckoutViewState _mapSnapshotState(PaymentAttemptStatus status) {
    return switch (status) {
      PaymentAttemptStatus.paid => _CheckoutViewState.paid,
      PaymentAttemptStatus.failed => _CheckoutViewState.failed,
      PaymentAttemptStatus.cancelled => _CheckoutViewState.cancelled,
      PaymentAttemptStatus.invalid => _CheckoutViewState.invalid,
      _ => _CheckoutViewState.verifying,
    };
  }
}

enum _CheckoutViewState {
  idle,
  loading,
  awaitingCallback,
  verifying,
  paid,
  failed,
  cancelled,
  invalid,
}
