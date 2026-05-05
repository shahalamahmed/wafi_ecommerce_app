import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class PaymentSelectionScreen extends ConsumerStatefulWidget {
  const PaymentSelectionScreen({super.key, required this.draft});

  final OrderDraft draft;

  @override
  ConsumerState<PaymentSelectionScreen> createState() =>
      _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState
    extends ConsumerState<PaymentSelectionScreen> {
  final _accountController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();

  OnlinePaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _accountController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final method = _selectedMethod;
    final isCard = method == OnlinePaymentMethod.card;

    return Scaffold(
      appBar: const WafiAppBar(
        title: 'Select Payment Method',
        subtitle: 'Complete a secure demo checkout before placing the order',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure online payment',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Amount to pay: ${AppStrings.currencySymbol}${widget.draft.total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Choose a wallet or card option. The order will be placed only after payment success.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.lg),
                for (final method in OnlinePaymentMethod.values) ...[
                  _PaymentMethodTile(
                    method: method,
                    isSelected: _selectedMethod == method,
                    onTap: () {
                      setState(() {
                        _selectedMethod = method;
                        _errorMessage = null;
                      });
                    },
                  ),
                  if (method != OnlinePaymentMethod.values.last)
                    const SizedBox(height: AppSizes.md),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  method == null
                      ? 'Select a payment option to enter payment details.'
                      : _fieldIntro(method),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                if (method != null) ...[
                  _PaymentField(
                    controller: _accountController,
                    label: isCard ? 'Card Number' : '${method.label} Number',
                    hint: isCard
                        ? '1234 5678 9012 3456'
                        : '01XXXXXXXXX',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (isCard) ...[
                    _PaymentField(
                      controller: _cardHolderController,
                      label: 'Cardholder Name',
                      hint: 'Name on card',
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentField(
                            controller: _expiryController,
                            label: 'Expiry',
                            hint: 'MM/YY',
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: _PaymentField(
                            controller: _pinController,
                            label: 'CVV',
                            hint: '123',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _PaymentField(
                      controller: _otpController,
                      label: 'OTP Code',
                      hint: '6 digit OTP',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSizes.md),
                    _PaymentField(
                      controller: _pinController,
                      label: method == OnlinePaymentMethod.rocket
                          ? 'Rocket PIN'
                          : '${method.label} PIN',
                      hint: '5 digit PIN',
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo test rules',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Use any valid-looking payment details. For mobile wallet payments, OTP `222222` simulates failure and OTP `333333` simulates cancellation. Any other 6-digit OTP completes payment successfully.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'For card payments, any filled details complete successfully.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if ((_errorMessage?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSizes.lg),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xl2),
          GlassButton(
            label: _selectedMethod == OnlinePaymentMethod.card
                ? 'PAY BY CARD'
                : 'CONFIRM PAYMENT',
            prefixIcon: Icons.lock_outline_rounded,
            isLoading: _isProcessing,
            onPressed: _isProcessing ? null : _submitDemoPayment,
          ),
          const SizedBox(height: AppSizes.md),
          GlassButton(
            label: 'CANCEL',
            variant: GlassButtonVariant.ghost,
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSizes.xl2),
        ],
      ),
    );
  }

  String _fieldIntro(OnlinePaymentMethod method) {
    return switch (method) {
      OnlinePaymentMethod.bkash =>
        'Enter your bKash wallet number, OTP, and PIN to simulate approval.',
      OnlinePaymentMethod.nagad =>
        'Enter your Nagad number, OTP, and PIN to continue.',
      OnlinePaymentMethod.rocket =>
        'Enter your Rocket number and PIN, then verify with OTP.',
      OnlinePaymentMethod.card =>
        'Enter your card details to simulate a bank card payment flow.',
    };
  }

  Future<void> _submitDemoPayment() async {
    final method = _selectedMethod;
    if (method == null) {
      setState(() => _errorMessage = 'Select a payment method to continue.');
      return;
    }

    final validationError = _validateFields(method);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final outcome = _resolveOutcome(method);
    if (outcome != _DemoPaymentOutcome.success) {
      setState(() => _isProcessing = false);
      final message = switch (outcome) {
        _DemoPaymentOutcome.failed =>
          'Payment failed in demo gateway. No order was placed.',
        _DemoPaymentOutcome.cancelled =>
          'Payment was cancelled. Your cart is unchanged.',
        _DemoPaymentOutcome.success => '',
      };
      setState(() => _errorMessage = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final paidDraft = widget.draft.copyWith(
      paymentMethod: PaymentMethod.payOnline,
      paymentGateway: PaymentGateway.sslcommerz,
      onlinePaymentMethod: method,
      paymentStatus: 'paid',
      gatewayTransactionId: _buildTransactionId(method),
      gatewayValidationId: _buildValidationId(method),
    );

    await ref.read(orderProvider.notifier).placeOrder(paidDraft);
    final orderState = ref.read(orderProvider);
    if (!mounted) return;

    if (orderState.hasError) {
      setState(() {
        _isProcessing = false;
        _errorMessage = orderState.errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderState.errorMessage!)),
      );
      return;
    }

    await ref.read(cartProvider.notifier).clear();
    if (!mounted) return;

    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${method.label} payment successful. Order placed successfully.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  String? _validateFields(OnlinePaymentMethod method) {
    final account = _normalizeNumber(_accountController.text);
    if (method == OnlinePaymentMethod.card) {
      if (account.length < 12) return 'Enter a valid card number.';
      if (_cardHolderController.text.trim().length < 3) {
        return 'Enter the cardholder name.';
      }
      if (!_isValidExpiry(_expiryController.text)) {
        return 'Enter a valid expiry date in MM/YY format.';
      }
      if (_normalizeNumber(_pinController.text).length < 3) {
        return 'Enter a valid CVV.';
      }
      return null;
    }

    if (account.length < 11) {
      return 'Enter a valid ${method.label} number.';
    }
    if (_normalizeNumber(_otpController.text).length != 6) {
      return 'OTP must be 6 digits.';
    }
    if (_normalizeNumber(_pinController.text).length < 4) {
      return 'PIN must be at least 4 digits.';
    }
    return null;
  }

  _DemoPaymentOutcome _resolveOutcome(OnlinePaymentMethod method) {
    if (method == OnlinePaymentMethod.card) {
      return _DemoPaymentOutcome.success;
    }

    final otp = _normalizeNumber(_otpController.text);
    return switch (otp) {
      '222222' => _DemoPaymentOutcome.failed,
      '333333' => _DemoPaymentOutcome.cancelled,
      _ => _DemoPaymentOutcome.success,
    };
  }

  String _normalizeNumber(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool _isValidExpiry(String value) {
    final raw = value.trim();
    final match = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').firstMatch(raw);
    return match != null;
  }

  String _buildTransactionId(OnlinePaymentMethod method) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'DEMO-${method.code.toUpperCase()}-$stamp';
  }

  String _buildValidationId(OnlinePaymentMethod method) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return 'VAL-${method.code.toUpperCase()}-$stamp';
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final OnlinePaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animFast),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.45)
                : theme.dividerColor.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(_iconForMethod(method), color: primary),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _descriptionForMethod(method),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? primary : theme.iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForMethod(OnlinePaymentMethod method) {
    return switch (method) {
      OnlinePaymentMethod.bkash => Icons.account_balance_wallet_outlined,
      OnlinePaymentMethod.nagad => Icons.phone_android_rounded,
      OnlinePaymentMethod.rocket => Icons.rocket_launch_outlined,
      OnlinePaymentMethod.card => Icons.credit_card_rounded,
    };
  }

  static String _descriptionForMethod(OnlinePaymentMethod method) {
    return switch (method) {
      OnlinePaymentMethod.bkash =>
        'Wallet payment with number, OTP, and PIN verification.',
      OnlinePaymentMethod.nagad =>
        'Mobile wallet checkout with OTP confirmation flow.',
      OnlinePaymentMethod.rocket =>
        'DBBL Rocket style payment simulation with secure PIN.',
      OnlinePaymentMethod.card =>
        'Card and bank payment style form with card security check.',
    };
  }
}

class _PaymentField extends StatelessWidget {
  const _PaymentField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return GlassInput(
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: (_) {},
    );
  }
}

enum _DemoPaymentOutcome { success, failed, cancelled }
