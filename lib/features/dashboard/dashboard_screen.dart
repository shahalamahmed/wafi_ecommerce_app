import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/dashboard/dashboard_model.dart';
import 'package:wafi_ecommerce_app/features/dashboard/dashboard_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key, required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(ownerDashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(ownerDashboardProvider.future),
      child: analytics.when(
        data: (snapshot) => _DashboardContent(user: user, snapshot: snapshot),
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(ownerDashboardProvider),
        ),
      ),
    );
  }
}

class OwnerAnalyticsScreen extends ConsumerWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(ownerDashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(ownerDashboardProvider.future),
      child: analytics.when(
        data: (snapshot) => _AnalyticsContent(snapshot: snapshot),
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(ownerDashboardProvider),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.user, required this.snapshot});

  final AppUser? user;
  final OwnerDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greetingName = user?.firstName.trim().isNotEmpty == true
        ? user!.firstName
        : 'Owner';
    final headerSubtitle =
        'Snapshot for ${DateFormat('dd MMM yyyy').format(now)}. Monitor fulfillment, revenue, and inventory from one workspace.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        AppSizes.screenPaddingH,
        AppSizes.screenPaddingH,
        120,
      ),
      children: [
        _HeroHeader(
          title: 'Welcome back, $greetingName',
          subtitle: headerSubtitle,
          trailing: Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              _MiniChip(
                label: '${snapshot.totalOrders} orders',
                variant: GlassChipVariant.primary,
              ),
              _MiniChip(
                label: '${snapshot.customerCount} customers',
                variant: GlassChipVariant.success,
              ),
              _MiniChip(
                label: '${snapshot.lowStockProducts} low stock',
                variant: snapshot.lowStockProducts > 0
                    ? GlassChipVariant.warning
                    : GlassChipVariant.neutral,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _KpiGrid(
          children: [
            _KpiCard(
              title: 'Revenue',
              value: compactCurrency(snapshot.totalRevenue),
              subtitle: '${snapshot.deliveredOrders} delivered / paid orders',
              icon: Icons.payments_outlined,
              accent: const Color(0xFF198754),
            ),
            _KpiCard(
              title: 'Orders',
              value: compactCount(snapshot.totalOrders),
              subtitle: '${snapshot.pendingOrders} waiting for action',
              icon: Icons.receipt_long_outlined,
              accent: const Color(0xFF0D6EFD),
            ),
            _KpiCard(
              title: 'Active Products',
              value: compactCount(snapshot.activeProducts),
              subtitle: '${snapshot.categoryCount} active categories',
              icon: Icons.inventory_2_outlined,
              accent: const Color(0xFF0F766E),
            ),
            _KpiCard(
              title: 'Low Stock',
              value: compactCount(snapshot.lowStockProducts),
              subtitle: snapshot.lowStockProducts == 0
                  ? 'Inventory looks healthy'
                  : 'Products need replenishment',
              icon: Icons.warning_amber_rounded,
              accent: const Color(0xFFE67700),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        _KpiGrid(
          children: [
            _CompactMetricCard(
              title: 'Pending',
              value: snapshot.pendingOrders.toString(),
              accent: const Color(0xFFFFB703),
            ),
            _CompactMetricCard(
              title: 'Shipped',
              value: snapshot.shippedOrders.toString(),
              accent: const Color(0xFF219EBC),
            ),
            _CompactMetricCard(
              title: 'Cancelled',
              value: snapshot.cancelledOrders.toString(),
              accent: const Color(0xFFD62828),
            ),
            _CompactMetricCard(
              title: 'Team / Users',
              value: '${snapshot.ownerCount}/${snapshot.customerCount}',
              accent: const Color(0xFF6C5CE7),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        _TwoColumnSection(
          left: _SectionCard(
            title: '7 Day Sales Trend',
            subtitle: 'Revenue movement across the latest 7 days.',
            child: _RevenueTrendChart(points: snapshot.dailySeries),
          ),
          right: _SectionCard(
            title: 'Fulfilment Mix',
            subtitle: 'Operational distribution by order status.',
            child: _StatusDonutChart(buckets: snapshot.statusBuckets),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _TwoColumnSection(
          left: _SectionCard(
            title: 'Recent Orders',
            subtitle: 'Most recent customer checkouts in the system.',
            child: _RecentOrdersPanel(orders: snapshot.recentOrders),
          ),
          right: Column(
            children: [
              _SectionCard(
                title: 'Low Stock Alerts',
                subtitle: 'Items closest to running out.',
                child: _LowStockPanel(items: snapshot.lowStockAlerts),
              ),
              const SizedBox(height: AppSizes.lg),
              _SectionCard(
                title: 'Top Selling Products',
                subtitle: 'Best performing items by unit sales.',
                child: _TopProductsPanel(products: snapshot.topProducts),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.snapshot});

  final OwnerDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final bestDay = snapshot.bestSalesDay;
    final worstDay = snapshot.worstSalesDay;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        AppSizes.screenPaddingH,
        AppSizes.screenPaddingH,
        120,
      ),
      children: [
        _HeroHeader(
          title: 'Analytics Workspace',
          subtitle:
              'A business-facing view of sales movement, order quality, and inventory pressure.',
          trailing: Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              _MiniChip(
                label: 'Last 7 days',
                variant: GlassChipVariant.primary,
              ),
              _MiniChip(
                label: 'Last 6 months',
                variant: GlassChipVariant.success,
              ),
              _MiniChip(label: 'Load based', variant: GlassChipVariant.neutral),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _KpiGrid(
          children: [
            _InsightCard(
              title: 'Best Sales Day',
              value: bestDay == null
                  ? 'No sales yet'
                  : DateFormat('dd MMM').format(bestDay.date),
              subtitle: bestDay == null
                  ? 'Waiting for order data'
                  : compactCurrency(bestDay.revenue),
            ),
            _InsightCard(
              title: 'Lowest Sales Day',
              value: worstDay == null
                  ? 'No fulfilled day'
                  : DateFormat('dd MMM').format(worstDay.date),
              subtitle: worstDay == null
                  ? 'Waiting for order data'
                  : compactCurrency(worstDay.revenue),
            ),
            _InsightCard(
              title: 'Fulfilment Ratio',
              value: '${(snapshot.fulfilmentRatio * 100).toStringAsFixed(0)}%',
              subtitle: '${snapshot.deliveredOrders} delivered orders',
            ),
            _InsightCard(
              title: 'Cancellation Ratio',
              value:
                  '${(snapshot.cancellationRatio * 100).toStringAsFixed(0)}%',
              subtitle: '${snapshot.cancelledOrders} cancelled orders',
            ),
            _InsightCard(
              title: 'Inventory Risk',
              value: snapshot.lowStockProducts.toString(),
              subtitle: snapshot.lowStockProducts == 0
                  ? 'No immediate shortages'
                  : 'Products below safe threshold',
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        _SectionCard(
          title: 'Revenue and Order Momentum',
          subtitle: 'The latest 7-day trend across paid and delivered orders.',
          child: _RevenueOrderComboChart(points: snapshot.dailySeries),
        ),
        const SizedBox(height: AppSizes.lg),
        _TwoColumnSection(
          left: _SectionCard(
            title: 'Monthly Performance',
            subtitle: 'Revenue against order count across the latest 6 months.',
            child: _MonthlyPerformanceChart(points: snapshot.monthlySeries),
          ),
          right: _SectionCard(
            title: 'Order Status Breakdown',
            subtitle: 'Share of orders in each fulfilment stage.',
            child: _StatusBarChart(buckets: snapshot.statusBuckets),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _SectionCard(
          title: 'Top Product Velocity',
          subtitle: 'Highest unit movers backed by order items.',
          child: _TopProductBars(
            products: snapshot.topProducts.take(5).toList(),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 680;
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSizes.sm),
                    Text(subtitle, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: AppSizes.lg),
                    trailing,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.lg),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: trailing,
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.variant});

  final String label;
  final GlassChipVariant variant;

  @override
  Widget build(BuildContext context) {
    return GlassChip(label: label, variant: variant);
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 720
            ? 2
            : 1;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * AppSizes.md)) / columns;

        return Wrap(
          spacing: AppSizes.md,
          runSpacing: AppSizes.md,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSizes.xs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSizes.xs),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TwoColumnSection extends StatelessWidget {
  const _TwoColumnSection({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 920) {
          return Column(
            children: [
              left,
              const SizedBox(height: AppSizes.lg),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSizes.lg),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSizes.xs),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSizes.lg),
          child,
        ],
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  const _RevenueTrendChart({required this.points});

  final List<TimeSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.every((point) => point.revenue <= 0 && point.orderCount <= 0)) {
      return const _EmptyPanelState(
        title: 'No revenue trend yet',
        subtitle: 'Sales movement will appear here as orders start coming in.',
      );
    }

    final maxValue = nonZeroMax(points.map((point) => point.revenue));

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue * 1.25,
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxValue / 4,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxValue / 4,
                getTitlesWidget: (value, meta) => Text(
                  compactCurrency(value),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      formatDayLabel(points[index].date),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 4,
              color: const Color(0xFF0D6EFD),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
              ),
              dotData: const FlDotData(show: false),
              spots: [
                for (var index = 0; index < points.length; index++)
                  FlSpot(index.toDouble(), points[index].revenue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDonutChart extends StatelessWidget {
  const _StatusDonutChart({required this.buckets});

  final List<StatusBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final activeBuckets = buckets.where((bucket) => bucket.count > 0).toList();
    if (activeBuckets.isEmpty) {
      return const _EmptyPanelState(
        title: 'No order mix yet',
        subtitle: 'Status distribution will render once orders are placed.',
      );
    }

    final colors = _statusColors;
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 44,
                sectionsSpace: 3,
                sections: [
                  for (final bucket in activeBuckets)
                    PieChartSectionData(
                      color: colors[bucket.status]!,
                      value: bucket.count.toDouble(),
                      title: bucket.count.toString(),
                      radius: 56,
                      titleStyle: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final bucket in activeBuckets) ...[
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[bucket.status],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          bucket.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        bucket.count.toString(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({required this.orders});

  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _EmptyPanelState(
        title: 'No recent orders',
        subtitle: 'Customer checkouts will appear here.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < orders.length; index++) ...[
          _OrderRow(order: orders[index]),
          if (index != orders.length - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[order.status] ?? const Color(0xFF0D6EFD);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        color: statusColor.withValues(alpha: 0.08),
        border: Border.all(color: statusColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: statusColor),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderId,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${order.items.length} items • ${compactCurrency(order.total)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlassChip(
                label: order.statusLabel,
                variant: _variantForStatus(order.status),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                order.createdAt == null
                    ? 'Recent'
                    : DateFormat('dd MMM').format(order.createdAt!),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  const _LowStockPanel({required this.items});

  final List<LowStockAlert> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyPanelState(
        title: 'No low stock alerts',
        subtitle: 'Inventory thresholds are currently healthy.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _LowStockRow(item: items[index]),
          if (index != items.length - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.item});

  final LowStockAlert item;

  @override
  Widget build(BuildContext context) {
    final progress = item.threshold <= 0
        ? 0.0
        : (item.stock / item.threshold).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.productName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            GlassChip(
              label: '${item.stock} left',
              variant: item.stock <= 2
                  ? GlassChipVariant.error
                  : GlassChipVariant.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Threshold ${item.threshold}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSizes.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.orange.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              item.stock <= 2
                  ? const Color(0xFFD62828)
                  : const Color(0xFFE67700),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopProductsPanel extends StatelessWidget {
  const _TopProductsPanel({required this.products});

  final List<TopProductMetric> products;

  @override
  Widget build(BuildContext context) {
    final items = products.take(4).toList();
    if (items.isEmpty) {
      return const _EmptyPanelState(
        title: 'No product movement yet',
        subtitle: 'Best sellers will appear once revenue orders are available.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(
                  0xFF0D6EFD,
                ).withValues(alpha: 0.12),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF0D6EFD),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[index].productName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '${items[index].quantitySold} units • ${compactCurrency(items[index].revenue)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (index != items.length - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}

class _RevenueOrderComboChart extends StatelessWidget {
  const _RevenueOrderComboChart({required this.points});

  final List<TimeSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.every((point) => point.revenue <= 0 && point.orderCount <= 0)) {
      return const _EmptyPanelState(
        title: 'Not enough trend data',
        subtitle:
            'Orders and revenue trendlines will appear when recent sales exist.',
      );
    }

    final maxRevenue = nonZeroMax(points.map((point) => point.revenue));
    final maxOrders = points
        .map((point) => point.orderCount)
        .fold<int>(0, math.max)
        .toDouble();

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: math.max(maxRevenue * 1.2, math.max(maxOrders * 40, 1)),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  compactCurrency(value),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      formatDayLabel(points[index].date),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: const Color(0xFF0D6EFD),
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.10),
              ),
              spots: [
                for (var index = 0; index < points.length; index++)
                  FlSpot(index.toDouble(), points[index].revenue),
              ],
            ),
            LineChartBarData(
              isCurved: true,
              color: const Color(0xFF198754),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              spots: [
                for (var index = 0; index < points.length; index++)
                  FlSpot(index.toDouble(), points[index].orderCount * 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyPerformanceChart extends StatelessWidget {
  const _MonthlyPerformanceChart({required this.points});

  final List<MonthlySeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.every((point) => point.revenue <= 0 && point.orderCount <= 0)) {
      return const _EmptyPanelState(
        title: 'No monthly movement yet',
        subtitle:
            'Monthly revenue and order bars will render once data exists.',
      );
    }

    final maxRevenue = nonZeroMax(points.map((point) => point.revenue));
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxRevenue * 1.25,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  compactCurrency(value),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      formatMonthLabel(points[index].monthStart),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < points.length; index++)
              BarChartGroupData(
                x: index,
                barsSpace: 6,
                barRods: [
                  BarChartRodData(
                    toY: points[index].revenue,
                    width: 14,
                    color: const Color(0xFF0D6EFD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  BarChartRodData(
                    toY: points[index].orderCount * 120,
                    width: 14,
                    color: const Color(0xFF198754),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBarChart extends StatelessWidget {
  const _StatusBarChart({required this.buckets});

  final List<StatusBucket> buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.every((bucket) => bucket.count == 0)) {
      return const _EmptyPanelState(
        title: 'No status history yet',
        subtitle: 'Order flow will populate this chart after new checkouts.',
      );
    }

    final maxCount = buckets
        .map((bucket) => bucket.count)
        .fold<int>(0, math.max);
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: math.max(maxCount.toDouble() * 1.3, 1),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      buckets[index].label,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < buckets.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: buckets[index].count.toDouble(),
                    width: 22,
                    color: _statusColors[buckets[index].status],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TopProductBars extends StatelessWidget {
  const _TopProductBars({required this.products});

  final List<TopProductMetric> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyPanelState(
        title: 'No top products yet',
        subtitle: 'Product velocity will appear once fulfilled sales exist.',
      );
    }

    final maxUnits = products
        .map((product) => product.quantitySold)
        .fold<int>(0, math.max);

    return Column(
      children: [
        for (final product in products) ...[
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: LinearProgressIndicator(
                    value: maxUnits == 0
                        ? 0
                        : (product.quantitySold / maxUnits)
                              .clamp(0, 1)
                              .toDouble(),
                    minHeight: 10,
                    backgroundColor: const Color(
                      0xFF0D6EFD,
                    ).withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D6EFD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                '${product.quantitySold}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }
}

class _EmptyPanelState extends StatelessWidget {
  const _EmptyPanelState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.insights_outlined, size: AppSizes.iconXl),
          const SizedBox(height: AppSizes.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 200),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.screenPaddingH),
      children: [
        const SizedBox(height: 120),
        GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppSizes.iconXl,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Failed to load analytics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.lg),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final Map<String, Color> _statusColors = {
  'pending': const Color(0xFFFFB703),
  'confirmed': const Color(0xFF0D6EFD),
  'shipped': const Color(0xFF219EBC),
  'delivered': const Color(0xFF198754),
  'cancelled': const Color(0xFFD62828),
};

GlassChipVariant _variantForStatus(String status) {
  switch (status) {
    case 'delivered':
      return GlassChipVariant.success;
    case 'cancelled':
      return GlassChipVariant.error;
    case 'shipped':
      return GlassChipVariant.primary;
    case 'confirmed':
      return GlassChipVariant.primary;
    default:
      return GlassChipVariant.warning;
  }
}
