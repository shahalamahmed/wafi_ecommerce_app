import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController(text: 'Dhaka');
  final _postalController = TextEditingController();
  final _countryController = TextEditingController(text: 'Bangladesh');
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1));

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
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final orderState = ref.watch(orderProvider);
    final authState = ref.watch(authProvider);

    final subtotal = cartState.subtotal;
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
                  hint: 'Enter full name',
                ),
                const SizedBox(height: AppSizes.md),
                _FormInput(
                  controller: _phoneController,
                  label: AppStrings.phone,
                  hint: '01XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSizes.md),
                _FormInput(
                  controller: _addressLine1Controller,
                  label: AppStrings.addressLine1,
                  hint: 'House, road, area',
                ),
                const SizedBox(height: AppSizes.md),
                _FormInput(
                  controller: _addressLine2Controller,
                  label: AppStrings.addressLine2,
                  hint: 'Apartment, landmark',
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: _FormInput(
                        controller: _cityController,
                        label: AppStrings.city,
                        hint: 'City',
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _FormInput(
                        controller: _postalController,
                        label: AppStrings.postalCode,
                        hint: 'Postal code',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                _FormInput(
                  controller: _countryController,
                  label: AppStrings.country,
                  hint: 'Country',
                ),
                const SizedBox(height: AppSizes.md),
                _FormInput(
                  controller: _notesController,
                  label: 'Order Notes',
                  hint: 'Notes about your order, e.g. special notes for delivery.',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          _DeliveryDateTile(
            deliveryDate: _deliveryDate,
            onTap: _pickDeliveryDate,
          ),
          const SizedBox(height: AppSizes.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _FormInput(
                  controller: _couponController,
                  label: 'Coupon Code',
                  hint: 'Have a coupon code?',
                ),
              ),
              const SizedBox(width: AppSizes.md),
              SizedBox(
                width: 110,
                child: GlassButton(
                  label: 'APPLY',
                  isFullWidth: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coupon validation is not implemented yet.')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          _SectionCard(
            title: 'Order Summary',
            child: Column(
              children: [
                _SummaryRow(label: 'SubTotal', value: subtotal),
                _SummaryRow(label: 'Item Discount', value: 0),
                _SummaryRow(label: 'Order Discount', value: 0),
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
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.cashOnDelivery,
                  groupValue: _paymentMethod,
                  title: const Text('Cash On Delivery'),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
                  },
                ),
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.payOnline,
                  groupValue: _paymentMethod,
                  title: const Text('Pay Online'),
                  subtitle: const Text('Payment gateway integration pending'),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
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
            onPressed: cartState.items.isEmpty ? null : () => _submitOrder(authState.user?.uid ?? ''),
          ),
          const SizedBox(height: AppSizes.xl2),
        ],
      ),
    );
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  Future<void> _submitOrder(String userId) async {
    final errors = [
      AppValidators.name(_nameController.text),
      AppValidators.phone(_phoneController.text),
      AppValidators.required(_addressLine1Controller.text),
      AppValidators.required(_cityController.text),
      AppValidators.required(_postalController.text),
      AppValidators.required(_countryController.text),
    ].whereType<String>().toList();

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }

    final cartState = ref.read(cartProvider);
    final draft = OrderDraft(
      userId: userId,
      items: cartState.items,
      address: CheckoutAddress(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalController.text.trim(),
        country: _countryController.text.trim(),
      ),
      notes: _notesController.text.trim(),
      couponCode: _couponController.text.trim(),
      deliveryDate: _deliveryDate,
      paymentMethod: _paymentMethod,
      subtotal: cartState.subtotal,
      tax: cartState.tax,
      deliveryCharge: _deliveryCharge,
      total: cartState.subtotal + cartState.tax + _deliveryCharge,
    );

    await ref.read(orderProvider.notifier).placeOrder(draft);
    final nextState = ref.read(orderProvider);
    if (!mounted) return;

    if (nextState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nextState.errorMessage!)),
      );
      return;
    }

    await ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed successfully.')),
    );
    Navigator.of(context).pop();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return GlassInput(
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) {},
    );
  }
}

class _DeliveryDateTile extends StatelessWidget {
  const _DeliveryDateTile({
    required this.deliveryDate,
    required this.onTap,
  });

  final DateTime deliveryDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE, MMM d, yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Row(
          children: [
            Text(
              'Delivery Date',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            Text(
              formatter.format(deliveryDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: AppSizes.sm),
            const Icon(Icons.chevron_right_rounded),
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
