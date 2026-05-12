import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_model.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/payment_selection_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.selectedAddress});

  final AddressModel selectedAddress;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, String?> _errors = {};

  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  final DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1));

  static const double _deliveryCharge = 160;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.displayName;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final orderState = ref.watch(orderProvider);
    final authState = ref.watch(authProvider);
    final productState = ref.watch(productProvider);

    final subtotal = cartState.subtotal;
    final itemDiscount = _calculateItemDiscount(
      cartState.items,
      productState.products,
    );
    final tax = cartState.tax;
    final total = subtotal + tax + _deliveryCharge;

    return Scaffold(
      appBar: const WafiAppBar(
        title: AppStrings.checkout,
        subtitle: 'Confirm delivery details and place your order',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          _SectionCard(
            title: 'Delivery Address',
            child: Column(
              children: [
                _FormInput(
                  controller: _nameController,
                  label: 'Full Name',
                  isRequired: true,
                  hint: 'Enter full name',
                  errorText: _errors['name'],
                  onChanged: (value) => _clearFieldError('name', value),
                ),
                const SizedBox(height: AppSizes.md),
                _FormInput(
                  controller: _phoneController,
                  label: AppStrings.phone,
                  isRequired: true,
                  hint: '01XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  errorText: _errors['phone'],
                  onChanged: (value) => _clearFieldError('phone', value),
                ),
                const SizedBox(height: AppSizes.md),
                _SelectedAddressPreview(address: widget.selectedAddress),
                const SizedBox(height: AppSizes.md),
                _FormInput(
                  controller: _notesController,
                  label: 'Order Notes',
                  hint:
                      'Notes about your order, e.g. special notes for delivery.',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          _SectionCard(
            title: 'Order Summary',
            child: Column(
              children: [
                _SummaryRow(label: 'SubTotal', value: subtotal),
                _SummaryRow(label: 'Item Discount', value: itemDiscount),
                _SummaryRow(label: 'Delivery Charge', value: _deliveryCharge),
                _SummaryRow(label: 'Tax', value: tax),
                const Divider(height: AppSizes.xl),
                _SummaryRow(label: 'Total Payable', value: total, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          _SectionCard(
            title: 'Payment Method',
            child: Column(
              children: [
                _PaymentMethodOption(
                  title: 'Cash On Delivery',
                  subtitle: 'Pay by hand when the order arrives.',
                  isSelected: _paymentMethod == PaymentMethod.cashOnDelivery,
                  onTap: () {
                    setState(
                      () => _paymentMethod = PaymentMethod.cashOnDelivery,
                    );
                  },
                ),
                const SizedBox(height: AppSizes.md),
                _PaymentMethodOption(
                  title: 'Pay Online',
                  subtitle: 'Select your payment provider on the next screen.',
                  isSelected: _paymentMethod == PaymentMethod.payOnline,
                  onTap: () {
                    setState(() => _paymentMethod = PaymentMethod.payOnline);
                  },
                ),
              ],
            ),
          ),
          if (orderState.hasError) ...[
            const SizedBox(height: AppSizes.lg),
            Text(
              orderState.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xl2),
          GlassButton(
            label: 'PLACE ORDER',
            isLoading: orderState.isSubmitting,
            onPressed: cartState.items.isEmpty
                ? null
                : () => _handlePlaceOrder(authState.user?.uid ?? ''),
          ),
          const SizedBox(height: AppSizes.xl2),
        ],
      ),
    );
  }

  double _calculateItemDiscount(
    List<CartItem> items,
    List<ProductModel> products,
  ) {
    final originalPriceLookup = <String, double>{
      for (final product in products)
        product.id: product.originalPrice > 0
            ? product.originalPrice
            : product.price,
    };

    double totalDiscount = 0;
    for (final item in items) {
      final storedOriginalPrice = item.originalPrice;
      final fallbackOriginalPrice =
          originalPriceLookup[item.productId] ?? item.unitPrice;
      final originalPrice = storedOriginalPrice > item.unitPrice
          ? storedOriginalPrice
          : fallbackOriginalPrice;

      if (originalPrice > item.unitPrice) {
        totalDiscount += (originalPrice - item.unitPrice) * item.quantity;
      }
    }

    return totalDiscount;
  }

  Future<void> _handlePlaceOrder(String userId) async {
    final nextErrors = <String, String?>{
      'name': AppValidators.name(_nameController.text),
      'phone': AppValidators.phone(_phoneController.text),
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });

    if (nextErrors.values.any((error) => error != null)) return;

    if (userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before placing an order.'),
        ),
      );
      return;
    }

    final stockError = await _validateCartInventory();
    if (!mounted) return;
    if (stockError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(stockError)));
      return;
    }

    final cartState = ref.read(cartProvider);
    final draft = OrderDraft(
      userId: userId,
      customerEmail: ref.read(authProvider).user?.email ?? '',
      items: cartState.items,
      address: CheckoutAddress(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: widget.selectedAddress.addressLine1,
        addressLine2: widget.selectedAddress.addressLine2,
        city: widget.selectedAddress.city,
        postalCode: widget.selectedAddress.postalCode,
        country: widget.selectedAddress.country,
      ),
      notes: _notesController.text.trim(),
      couponCode: '',
      deliveryDate: _deliveryDate,
      paymentMethod: _paymentMethod,
      paymentGateway: null,
      onlinePaymentMethod: null,
      subtotal: cartState.subtotal,
      tax: cartState.tax,
      deliveryCharge: _deliveryCharge,
      total: cartState.subtotal + cartState.tax + _deliveryCharge,
    );

    if (_paymentMethod == PaymentMethod.payOnline) {
      final didPlaceOrder = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PaymentSelectionScreen(draft: draft),
        ),
      );
      if (didPlaceOrder == true && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    await ref.read(orderProvider.notifier).placeOrder(draft);
    final nextState = ref.read(orderProvider);
    if (!mounted) return;

    if (nextState.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(nextState.errorMessage!)));
      return;
    }

    await ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order placed successfully.')));
    Navigator.of(context).pop();
  }

  void _clearFieldError(String fieldKey, String value) {
    if (value.trim().isEmpty || _errors[fieldKey] == null) return;
    setState(() => _errors[fieldKey] = null);
  }

  Future<String?> _validateCartInventory() async {
    await ref.read(productProvider.notifier).load();
    final products = ref.read(productProvider).products;
    final cartItems = ref.read(cartProvider).items;
    final requestedByProduct = <String, int>{};
    for (final item in cartItems) {
      requestedByProduct.update(
        item.productId,
        (current) => current + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    final productById = <String, ProductModel>{
      for (final product in products) product.id: product,
    };

    for (final entry in requestedByProduct.entries) {
      final product = productById[entry.key];
      if (product == null || !product.isActive) {
        return 'Some items are no longer available.';
      }
      if (product.stock < entry.value) {
        return product.stock <= 0
            ? '${product.name} is out of stock.'
            : 'Only ${product.stock} unit(s) left for ${product.name}.';
      }
    }

    return null;
  }
}

class _SelectedAddressPreview extends StatelessWidget {
  const _SelectedAddressPreview({required this.address});

  final AddressModel address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                address.typeLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              if (address.isDefault)
                Text(
                  AppStrings.defaultAddress,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            address.formatted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSizes.lg),
          child,
        ],
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.errorText,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return GlassInput(
      controller: controller,
      label: label,
      isRequired: isRequired,
      hint: hint,
      errorText: errorText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
          color: isSelected ? primary.withValues(alpha: 0.10) : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.45)
                : theme.dividerColor.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? primary : theme.iconTheme.color,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSizes.xs),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final textStyle = isBold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textStyle)),
          Text(
            '${AppStrings.currencySymbol} ${value.toStringAsFixed(0)}',
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
