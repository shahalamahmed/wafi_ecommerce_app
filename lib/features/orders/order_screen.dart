import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_provider.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_provider.dart';
import 'package:wafi_ecommerce_app/features/reviews/widgets/review_composer.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, this.immersiveShell = false});

  final bool immersiveShell;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final notifier = ref.read(orderProvider.notifier);
    final topInset = widget.immersiveShell
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

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CustomerOrder? liveOrder;
    for (final candidate in ref.watch(orderProvider).orders) {
      if (candidate.id == order.id) {
        liveOrder = candidate;
        break;
      }
    }
    final effectiveOrder = liveOrder ?? order;
    final isDelivered =
        effectiveOrder.status.trim().toLowerCase() == 'delivered';

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
                  effectiveOrder.orderId,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSizes.sm),
                _OrderStatusChip(status: effectiveOrder.statusLabel),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Order Tracking',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.md),
                _OrderTrackingTimeline(order: effectiveOrder),
                const SizedBox(height: AppSizes.md),
                if (effectiveOrder.createdAt != null)
                  Text(
                    '${AppStrings.orderDate}: ${DateFormat('dd MMM yyyy, hh:mm a').format(effectiveOrder.createdAt!)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  _paymentDetails(effectiveOrder),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (effectiveOrder.paymentCollectedAt != null) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Collected: ${DateFormat('dd MMM yyyy, hh:mm a').format(effectiveOrder.paymentCollectedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (effectiveOrder.paymentCollectedBy.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Collected by: ${effectiveOrder.paymentCollectedBy}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (effectiveOrder.gatewayTransactionId.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Txn ID: ${effectiveOrder.gatewayTransactionId}',
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
                for (final item in effectiveOrder.items) ...[
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
                            if (isDelivered && item.productId.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.sm),
                              _OrderItemReviewAction(
                                productId: item.productId,
                                productName: item.productName,
                              ),
                            ],
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
                  effectiveOrder.addressText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (effectiveOrder.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Notes: ${effectiveOrder.notes}',
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
                _MoneyRow(
                  label: AppStrings.subtotal,
                  value: effectiveOrder.subtotal,
                ),
                _MoneyRow(label: AppStrings.tax, value: effectiveOrder.tax),
                _MoneyRow(
                  label: 'Delivery Charge',
                  value: effectiveOrder.deliveryCharge,
                ),
                const Divider(height: AppSizes.lg),
                _MoneyRow(
                  label: AppStrings.total,
                  value: effectiveOrder.total,
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

class _OrderItemReviewAction extends ConsumerWidget {
  const _OrderItemReviewAction({
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReviewAsync = ref.watch(myProductReviewProvider(productId));

    return myReviewAsync.when(
      data: (myReview) {
        final hasReview = myReview != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassButton(
              label: hasReview ? AppStrings.editReview : AppStrings.writeReview,
              variant: hasReview
                  ? GlassButtonVariant.ghost
                  : GlassButtonVariant.primary,
              isFullWidth: false,
              onPressed: () => showReviewComposer(
                context,
                ref,
                productId: productId,
                productName: productName,
                existingReview: myReview,
              ),
            ),
            if (hasReview) ...[
              const SizedBox(height: AppSizes.sm),
              GlassChip(
                label: 'Your review is live',
                variant: GlassChipVariant.success,
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => GlassButton(
        label: AppStrings.writeReview,
        variant: GlassButtonVariant.primary,
        isFullWidth: false,
        onPressed: () => showReviewComposer(
          context,
          ref,
          productId: productId,
          productName: productName,
          existingReview: null,
        ),
      ),
    );
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
    final color = _statusAccentColor(status, scheme);

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

Color _statusAccentColor(String status, ColorScheme scheme) {
  return switch (status.trim().toLowerCase()) {
    'pending' => const Color(0xFFE6A700),
    'confirmed' => const Color(0xFF3B82F6),
    'shipped' => const Color(0xFF14B8A6),
    'delivered' => const Color(0xFF16A34A),
    'cancelled' => scheme.error,
    _ => scheme.primary,
  };
}

class _OrderTrackingTimeline extends StatelessWidget {
  const _OrderTrackingTimeline({required this.order});

  final CustomerOrder order;

  static const _steps = <String>[
    'Pending',
    'Confirmed',
    'Shipped',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _statusIndex(order.status);
    final isCancelled = order.status.trim().toLowerCase() == 'cancelled';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 0; index < _steps.length; index++) ...[
              _TrackingNode(
                label: _steps[index],
                isActive: !isCancelled && index <= currentIndex,
                isCurrent: !isCancelled && index == currentIndex,
                activeColor: _stepColor(_steps[index]),
              ),
              if (index < _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      color: !isCancelled && index < currentIndex
                          ? _connectorColor(index).withValues(alpha: 0.78)
                          : theme.dividerColor.withValues(alpha: 0.55),
                    ),
                  ),
                ),
            ],
          ],
        ),
        if (isCancelled) ...[
          const SizedBox(height: AppSizes.sm),
          Text(
            'This order was cancelled before completion.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  int _statusIndex(String status) {
    return switch (status.trim().toLowerCase()) {
      'confirmed' => 1,
      'shipped' => 2,
      'delivered' => 3,
      _ => 0,
    };
  }

  Color _stepColor(String status) {
    return switch (status.trim().toLowerCase()) {
      'pending' => const Color(0xFFE6A700),
      'confirmed' => const Color(0xFF3B82F6),
      'shipped' => const Color(0xFF14B8A6),
      'delivered' => const Color(0xFF16A34A),
      _ => const Color(0xFF64748B),
    };
  }

  Color _connectorColor(int completedStepIndex) {
    return switch (completedStepIndex) {
      0 => const Color(0xFFD9A321),
      1 => const Color(0xFF2F9FD8),
      2 => const Color(0xFF15A883),
      _ => const Color(0xFF16A34A),
    };
  }
}

class _TrackingNode extends StatelessWidget {
  const _TrackingNode({
    required this.label,
    required this.isActive,
    required this.isCurrent,
    required this.activeColor,
  });

  final String label;
  final bool isActive;
  final bool isCurrent;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.dividerColor.withValues(alpha: 0.9);
    final iconColor = isActive
        ? Colors.white
        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72) ??
              Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isCurrent ? 24 : 20,
          height: isCurrent ? 24 : 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : inactiveColor,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.22)
                  : inactiveColor.withValues(alpha: 0.3),
              width: isCurrent ? 3 : 2,
            ),
          ),
          child: Icon(
            _iconFor(label),
            size: isCurrent ? 13 : 11,
            color: iconColor,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        SizedBox(
          width: 62,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive ? activeColor : theme.textTheme.bodySmall?.color,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String label) {
    return switch (label.trim().toLowerCase()) {
      'pending' => Icons.hourglass_top_rounded,
      'confirmed' => Icons.check_circle_outline_rounded,
      'shipped' => Icons.local_shipping_outlined,
      'delivered' => Icons.inventory_2_outlined,
      _ => Icons.radio_button_checked_rounded,
    };
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
