import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, this.immersiveShell = false});

  final bool immersiveShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderProvider);
    final notifier = ref.read(orderProvider.notifier);
    final topInset = immersiveShell
        ? WafiAppBar.compactOverlayTopInset(
            context,
            hasSubtitle: false,
            revealAmount: AppSizes.xl5,
          )
        : AppSizes.screenPaddingH;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.loadOrders,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            _EmptyOrders(),
            SizedBox(height: 100),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.loadOrders,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          topInset,
          AppSizes.screenPaddingH,
          100,
        ),
        itemCount: state.orders.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.md),
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderDetailsScreen(order: order),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: GlassCard(
              variant: GlassCardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderId,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _OrderStatusChip(status: order.statusLabel),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    '${order.items.length} items - ${AppStrings.currencySymbol}${order.total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _paymentSummary(order),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    order.createdAt == null
                        ? 'Recent order'
                        : DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(order.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _paymentSummary(CustomerOrder order) {
    return order.paymentSummaryLabel;
  }
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WafiAppBar(
        title: AppStrings.orderDetails,
        subtitle: 'Review your order items, totals, and delivery details',
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
                  order.orderId,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSizes.sm),
                _OrderStatusChip(status: order.statusLabel),
                const SizedBox(height: AppSizes.md),
                if (order.createdAt != null)
                  Text(
                    '${AppStrings.orderDate}: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  _paymentDetails(order),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (order.gatewayTransactionId.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Txn ID: ${order.gatewayTransactionId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                Text('Items', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSizes.md),
                for (final item in order.items) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (item.selectedOptionLabel.isNotEmpty)
                              Text(
                                item.selectedOptionLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              'Qty ${item.quantity} x ${AppStrings.currencySymbol}${item.price.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${AppStrings.currencySymbol}${item.subtotal.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
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
                  AppStrings.deliveryAddress,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  order.addressText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (order.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Notes: ${order.notes}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              children: [
                _MoneyRow(label: AppStrings.subtotal, value: order.subtotal),
                _MoneyRow(label: AppStrings.tax, value: order.tax),
                _MoneyRow(
                  label: 'Delivery Charge',
                  value: order.deliveryCharge,
                ),
                const Divider(height: AppSizes.lg),
                _MoneyRow(
                  label: AppStrings.total,
                  value: order.total,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  static String _paymentDetails(CustomerOrder order) {
    return 'Payment: ${order.paymentSummaryLabel} (${order.paymentStatusLabel})';
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            '${AppStrings.currencySymbol}${value.toStringAsFixed(0)}',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status.toLowerCase()) {
      'confirmed' => scheme.primary,
      'shipped' => Colors.orange,
      'delivered' => Colors.green,
      'cancelled' => scheme.error,
      _ => Colors.amber.shade700,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            children: [
              const Icon(Icons.receipt_long_outlined, size: AppSizes.iconXl),
              const SizedBox(height: AppSizes.md),
              Text(
                AppStrings.noOrders,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
