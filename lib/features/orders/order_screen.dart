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
  String _selectedStatus = _orderStatusFilters.first.value;

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
    final visibleOrders = state.orders.where(_matchesSelectedStatus).toList();

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
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          topInset,
          AppSizes.screenPaddingH,
          100,
        ),
        children: [
          _OrdersHeader(
            selectedStatus: _selectedStatus,
            onStatusSelected: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: AppSizes.lg),
          if (visibleOrders.isEmpty)
            _FilteredOrdersEmptyState(selectedStatus: _selectedStatus)
          else
            ...[
              for (var index = 0; index < visibleOrders.length; index++) ...[
                _OrderListCard(
                  order: visibleOrders[index],
                  onViewDetails: () => _openOrderDetails(visibleOrders[index]),
                  onReorder: () => _showComingSoonMessage(
                    context,
                    'Reorder will be available soon for ${visibleOrders[index].orderId}.',
                  ),
                ),
                if (index < visibleOrders.length - 1)
                  const SizedBox(height: AppSizes.md),
              ],
            ],
        ],
      ),
    );
  }

  bool _matchesSelectedStatus(CustomerOrder order) {
    if (_selectedStatus == _OrderStatusFilterValue.all) {
      return true;
    }

    return order.status.trim().toLowerCase() == _selectedStatus;
  }

  void _openOrderDetails(CustomerOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsScreen(order: order),
      ),
    );
  }

  void _showComingSoonMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _paymentSummary(CustomerOrder order) {
    return order.paymentSummaryLabel;
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xs),
          child: Row(
            children: [
              for (final filter in _orderStatusFilters)
                _OrderStatusTab(
                  filter: filter,
                  isSelected: filter.value == selectedStatus,
                  onTap: () => onStatusSelected(filter.value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusTab extends StatelessWidget {
  const _OrderStatusTab({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final _OrderStatusFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.xs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surface.withValues(alpha: 0.95)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? primary
                          : theme.textTheme.bodyMedium?.color?.withValues(
                              alpha: 0.80,
                            ),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: AppSizes.animNormal),
                    height: 2.5,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({
    required this.order,
    required this.onViewDetails,
    required this.onReorder,
  });

  final CustomerOrder order;
  final VoidCallback onViewDetails;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: AppSizes.trackingTight,
      fontSize: 15,
    );

    return GlassTappableCard(
      onTap: onViewDetails,
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderIconBadge(status: order.status),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            order.orderId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: AppSizes.trackingTight,
                              height: 1.0,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _OrderStatusChip(status: order.statusLabel),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _formatOrderDate(order),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.78,
                            ),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.55,
                            ),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _formatOrderTime(order),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.78,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: AppSizes.md,
                            runSpacing: 4,
                            children: [
                              _OrderMetaPill(
                                icon: Icons.shopping_bag_outlined,
                                label:
                                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                                tint: theme.colorScheme.primary,
                              ),
                              _OrderMetaPill(
                                icon: order.isCashOnDelivery
                                    ? Icons.payments_outlined
                                    : Icons.wallet_outlined,
                                label: _OrderScreenState._paymentSummary(order),
                                tint: const Color(0xFFD9A321),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          _formatMoney(order.total),
                          style: amountStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Divider(
              color: theme.dividerColor.withValues(alpha: 0.24),
              height: 1,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _CompactActionButton(
                  label: 'View Details',
                  icon: Icons.description_outlined,
                  onTap: onViewDetails,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _CompactActionButton(
                  label: AppStrings.reorder,
                  icon: Icons.refresh_rounded,
                  onTap: onReorder,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatOrderDate(CustomerOrder order) {
    if (order.createdAt == null) {
      return 'Recent order';
    }

    return DateFormat('dd MMM yyyy').format(order.createdAt!);
  }

  static String _formatOrderTime(CustomerOrder order) {
    if (order.createdAt == null) {
      return 'Just now';
    }

    return DateFormat('hh:mm a').format(order.createdAt!);
  }

  static String _formatMoney(double amount) {
    return NumberFormat.currency(
      locale: 'en_BD',
      symbol: AppStrings.currencySymbol,
      decimalDigits: 0,
    ).format(amount);
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final foreground = isPrimary ? Colors.white : primary;
    final background = isPrimary
        ? primary
        : theme.colorScheme.surface.withValues(alpha: 0.72);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Ink(
          height: 29,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isPrimary ? primary : primary.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderIconBadge extends StatelessWidget {
  const _OrderIconBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final accent = _statusAccentColor(status, Theme.of(context).colorScheme);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.12),
      ),
      child: Icon(
        _iconForStatus(status),
        color: accent,
        size: 28,
      ),
    );
  }

  IconData _iconForStatus(String value) {
    return switch (value.trim().toLowerCase()) {
      'pending' => Icons.inventory_2_outlined,
      'cancelled' => Icons.cancel_outlined,
      _ => Icons.inventory_2_rounded,
    };
  }
}

class _OrderMetaPill extends StatelessWidget {
  const _OrderMetaPill({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tint.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 14, color: tint),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.84),
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilteredOrdersEmptyState extends StatelessWidget {
  const _FilteredOrdersEmptyState({required this.selectedStatus});

  final String selectedStatus;

  @override
  Widget build(BuildContext context) {
    final label = _orderStatusFilters
        .firstWhere((filter) => filter.value == selectedStatus)
        .label;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: AppSizes.iconXl),
          const SizedBox(height: AppSizes.md),
          Text(
            'No $label orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Try another order status to view more history.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _OrderStatusFilter {
  const _OrderStatusFilter({required this.value, required this.label});

  final String value;
  final String label;
}

abstract class _OrderStatusFilterValue {
  static const String all = 'all';
  static const String delivered = 'delivered';
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String shipped = 'shipped';
}

const List<_OrderStatusFilter> _orderStatusFilters = [
  _OrderStatusFilter(value: _OrderStatusFilterValue.all, label: 'All Orders'),
  _OrderStatusFilter(
    value: _OrderStatusFilterValue.delivered,
    label: AppStrings.statusDelivered,
  ),
  _OrderStatusFilter(
    value: _OrderStatusFilterValue.pending,
    label: AppStrings.statusPending,
  ),
  _OrderStatusFilter(
    value: _OrderStatusFilterValue.confirmed,
    label: AppStrings.statusConfirmed,
  ),
  _OrderStatusFilter(
    value: _OrderStatusFilterValue.shipped,
    label: AppStrings.statusShipped,
  ),
];

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          AppSizes.md,
          AppSizes.screenPaddingH,
          100,
        ),
        children: [
          GlassCard(
            variant: GlassCardVariant.elevated,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effectiveOrder.orderId,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Order overview and fulfillment progress',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    _OrderStatusChip(status: effectiveOrder.statusLabel),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                _DetailSectionTitle(
                  title: 'Order Tracking',
                  subtitle: 'Live progress from placement to delivery',
                ),
                const SizedBox(height: AppSizes.md),
                _OrderTrackingTimeline(order: effectiveOrder),
                const SizedBox(height: AppSizes.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.34,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (effectiveOrder.createdAt != null)
                        _OrderMetaLine(
                          label: AppStrings.orderDate,
                          value: DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(effectiveOrder.createdAt!),
                        ),
                      _OrderMetaLine(
                        label: 'Payment',
                        value:
                            '${effectiveOrder.paymentSummaryLabel} (${effectiveOrder.paymentStatusLabel})',
                      ),
                      if (effectiveOrder.paymentCollectedAt != null)
                        _OrderMetaLine(
                          label: 'Collected',
                          value: DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(effectiveOrder.paymentCollectedAt!),
                        ),
                      if (effectiveOrder.paymentCollectedBy.isNotEmpty)
                        _OrderMetaLine(
                          label: 'Collected by',
                          value: effectiveOrder.paymentCollectedBy,
                        ),
                      if (effectiveOrder.gatewayTransactionId.isNotEmpty)
                        _OrderMetaLine(
                          label: 'Txn ID',
                          value: effectiveOrder.gatewayTransactionId,
                          isLast: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          GlassCard(
            variant: GlassCardVariant.elevated,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DetailSectionTitle(
                  title: 'Items',
                  subtitle: 'Products included in this order',
                ),
                const SizedBox(height: AppSizes.md),
                for (
                  var index = 0;
                  index < effectiveOrder.items.length;
                  index++
                ) ...[
                  _OrderItemBlock(
                    item: effectiveOrder.items[index],
                    isDelivered: isDelivered,
                  ),
                  if (index < effectiveOrder.items.length - 1) ...[
                    const SizedBox(height: AppSizes.md),
                    Divider(color: theme.dividerColor.withValues(alpha: 0.36)),
                    const SizedBox(height: AppSizes.md),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          GlassCard(
            variant: GlassCardVariant.elevated,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DetailSectionTitle(
                  title: AppStrings.deliveryAddress,
                  subtitle: 'Shipping destination for this order',
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  effectiveOrder.addressText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: AppSizes.lineHeightNormal,
                  ),
                ),
                if (effectiveOrder.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Text(
                      'Notes: ${effectiveOrder.notes}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          GlassCard(
            variant: GlassCardVariant.elevated,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.lg,
              AppSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DetailSectionTitle(
                  title: 'Payment Summary',
                  subtitle: 'A final breakdown of this order',
                ),
                const SizedBox(height: AppSizes.md),
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
        ],
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }
}

class _OrderMetaLine extends StatelessWidget {
  const _OrderMetaLine({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.72,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _OrderItemBlock extends StatelessWidget {
  const _OrderItemBlock({required this.item, required this.isDelivered});

  final OrderItemModel item;
  final bool isDelivered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.selectedOptionLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      item.selectedOptionLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.74,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Qty ${item.quantity} x ${AppStrings.currencySymbol}${item.price.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.86,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Text(
              '${AppStrings.currencySymbol}${item.subtotal.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (isDelivered && item.productId.isNotEmpty) ...[
          const SizedBox(height: AppSizes.md),
          _OrderItemReviewAction(
            productId: item.productId,
            productName: item.productName,
          ),
        ],
      ],
    );
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
            Row(
              children: [
                Flexible(
                  child: GlassButton(
                    label: hasReview
                        ? AppStrings.editReview
                        : AppStrings.writeReview,
                    variant: hasReview
                        ? GlassButtonVariant.ghost
                        : GlassButtonVariant.primary,
                    size: GlassButtonSize.sm,
                    prefixIcon: hasReview
                        ? Icons.edit_outlined
                        : Icons.rate_review_outlined,
                    isFullWidth: false,
                    onPressed: () => showReviewComposer(
                      context,
                      ref,
                      productId: productId,
                      productName: productName,
                      existingReview: myReview,
                    ),
                  ),
                ),
              ],
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
        size: GlassButtonSize.sm,
        prefixIcon: Icons.rate_review_outlined,
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
    final theme = Theme.of(context);
    final labelStyle = isBold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.82),
          );
    final valueStyle = isBold
        ? theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(
            '${AppStrings.currencySymbol}${value.toStringAsFixed(0)}',
            style: valueStyle,
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
        horizontal: AppSizes.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                    margin: const EdgeInsets.only(bottom: 14),
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
