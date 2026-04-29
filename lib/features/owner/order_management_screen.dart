import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_management_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerOrderManagementProvider);
    final notifier = ref.read(ownerOrderManagementProvider.notifier);

    ref.listen(ownerOrderManagementProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.errorMessage != previous?.errorMessage && next.hasError) {
        messenger.showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.successMessage != previous?.successMessage &&
          (next.successMessage?.isNotEmpty ?? false)) {
        messenger.showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Fulfillment Management',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Track every order from intake to delivery with status controls.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final status in _statusFilters) ...[
                        GlassChip(
                          label: status.label,
                          variant: status.value == state.selectedStatus
                              ? GlassChipVariant.primary
                              : GlassChipVariant.neutral,
                          isSelected: status.value == state.selectedStatus,
                          onTap: () => notifier.setStatusFilter(status.value),
                        ),
                        const SizedBox(width: AppSizes.sm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xl3),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.visibleOrders.isEmpty)
            GlassCard(
              variant: GlassCardVariant.elevated,
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: AppSizes.iconXl,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No orders in this queue',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            ...state.visibleOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _OwnerOrderCard(order: order, isSaving: state.isSaving),
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnerOrderCard extends ConsumerWidget {
  const _OwnerOrderCard({required this.order, required this.isSaving});

  final CustomerOrder order;
  final bool isSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(ownerOrderManagementProvider.notifier);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      order.createdAt == null
                          ? 'New order'
                          : DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(order.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.statusLabel),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              GlassChip(
                label: '${order.items.length} items',
                variant: GlassChipVariant.primary,
              ),
              GlassChip(
                label:
                    '${AppStrings.currencySymbol}${order.total.toStringAsFixed(0)}',
                variant: GlassChipVariant.success,
              ),
              GlassChip(
                label: order.paymentStatus.toUpperCase(),
                variant: GlassChipVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            order.addressText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.md),
          for (final item in order.items.take(3)) ...[
            Text(
              '${item.productName} x${item.quantity}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.xs),
          ],
          if (order.items.length > 3)
            Text(
              '+${order.items.length - 3} more items',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              if (order.status == 'pending')
                GlassButton(
                  label: AppStrings.confirmOrder,
                  prefixIcon: Icons.check_circle_outline_rounded,
                  isFullWidth: false,
                  isLoading: isSaving,
                  onPressed: () => notifier.updateOrderStatus(
                    orderId: order.id,
                    status: 'confirmed',
                  ),
                ),
              if (order.status == 'confirmed')
                GlassButton(
                  label: AppStrings.shipOrder,
                  prefixIcon: Icons.local_shipping_outlined,
                  isFullWidth: false,
                  isLoading: isSaving,
                  onPressed: () => notifier.updateOrderStatus(
                    orderId: order.id,
                    status: 'shipped',
                  ),
                ),
              if (order.status == 'shipped')
                GlassButton(
                  label: AppStrings.deliverOrder,
                  prefixIcon: Icons.inventory_2_outlined,
                  isFullWidth: false,
                  isLoading: isSaving,
                  onPressed: () => notifier.updateOrderStatus(
                    orderId: order.id,
                    status: 'delivered',
                  ),
                ),
              if (order.status != 'delivered' && order.status != 'cancelled')
                GlassButton(
                  label: 'Cancel Order',
                  prefixIcon: Icons.cancel_outlined,
                  variant: GlassButtonVariant.danger,
                  isFullWidth: false,
                  isLoading: isSaving,
                  onPressed: () => notifier.updateOrderStatus(
                    orderId: order.id,
                    status: 'cancelled',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

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

class _StatusFilter {
  const _StatusFilter(this.value, this.label);

  final String value;
  final String label;
}

const List<_StatusFilter> _statusFilters = [
  _StatusFilter('all', 'All'),
  _StatusFilter('pending', 'Pending'),
  _StatusFilter('confirmed', 'Confirmed'),
  _StatusFilter('shipped', 'Shipped'),
  _StatusFilter('delivered', 'Delivered'),
  _StatusFilter('cancelled', 'Cancelled'),
];
