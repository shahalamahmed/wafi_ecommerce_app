import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/dashboard/dashboard_model.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_management_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';

final ownerDashboardProvider = FutureProvider<OwnerDashboardSnapshot>((
  ref,
) async {
  final service = ref.read(ownerManagementServiceProvider);

  final results = await Future.wait<dynamic>([
    service.fetchOrders(),
    service.fetchProducts(),
    service.fetchCategories(),
    service.fetchUsers(),
  ]);

  final orders = results[0] as List<CustomerOrder>;
  final products = results[1] as List<ProductModel>;
  final categories = results[2] as List<ProductCategory>;
  final users = results[3] as List<AppUser>;

  return _buildSnapshot(
    orders: orders,
    products: products,
    categories: categories,
    users: users,
  );
});

OwnerDashboardSnapshot _buildSnapshot({
  required List<CustomerOrder> orders,
  required List<ProductModel> products,
  required List<ProductCategory> categories,
  required List<AppUser> users,
}) {
  final revenueOrders = orders.where(_countsTowardRevenue).toList();
  final totalRevenue = revenueOrders.fold<double>(
    0,
    (sum, order) => sum + order.total,
  );

  final pendingOrders = orders
      .where((order) => order.status == 'pending')
      .length;
  final confirmedOrders = orders
      .where((order) => order.status == 'confirmed')
      .length;
  final shippedOrders = orders
      .where((order) => order.status == 'shipped')
      .length;
  final deliveredOrders = orders
      .where((order) => order.status == 'delivered')
      .length;
  final cancelledOrders = orders
      .where((order) => order.status == 'cancelled')
      .length;

  final activeProducts = products.where((product) => product.isActive).length;
  final lowStockAlerts =
      products
          .where((product) => product.isActive && product.isLowStock)
          .map(
            (product) => LowStockAlert(
              productId: product.id,
              productName: product.name,
              stock: product.stock,
              threshold: product.lowStockThreshold,
            ),
          )
          .toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));

  final productSales = <String, TopProductMetric>{};
  for (final order in revenueOrders) {
    for (final item in order.items) {
      final existing = productSales[item.productId];
      if (existing == null) {
        productSales[item.productId] = TopProductMetric(
          productId: item.productId,
          productName: item.productName,
          quantitySold: item.quantity,
          revenue: item.subtotal,
        );
      } else {
        productSales[item.productId] = TopProductMetric(
          productId: existing.productId,
          productName: existing.productName,
          quantitySold: existing.quantitySold + item.quantity,
          revenue: existing.revenue + item.subtotal,
        );
      }
    }
  }

  final recentOrders = [...orders]
    ..sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

  return OwnerDashboardSnapshot(
    totalRevenue: totalRevenue,
    totalOrders: orders.length,
    averageOrderValue: revenueOrders.isEmpty
        ? 0
        : totalRevenue / revenueOrders.length,
    pendingOrders: pendingOrders,
    confirmedOrders: confirmedOrders,
    shippedOrders: shippedOrders,
    deliveredOrders: deliveredOrders,
    cancelledOrders: cancelledOrders,
    activeProducts: activeProducts,
    lowStockProducts: lowStockAlerts.length,
    categoryCount: categories.where((category) => category.isActive).length,
    customerCount: users.where((user) => !user.isOwner).length,
    ownerCount: users.where((user) => user.isOwner).length,
    recentOrders: recentOrders.take(6).toList(),
    lowStockAlerts: lowStockAlerts.take(6).toList(),
    topProducts: productSales.values.toList()
      ..sort((a, b) {
        final quantityCompare = b.quantitySold.compareTo(a.quantitySold);
        if (quantityCompare != 0) return quantityCompare;
        return b.revenue.compareTo(a.revenue);
      }),
    dailySeries: _buildDailySeries(revenueOrders),
    monthlySeries: _buildMonthlySeries(revenueOrders),
    statusBuckets: [
      StatusBucket(status: 'pending', label: 'Pending', count: pendingOrders),
      StatusBucket(
        status: 'confirmed',
        label: 'Confirmed',
        count: confirmedOrders,
      ),
      StatusBucket(status: 'shipped', label: 'Shipped', count: shippedOrders),
      StatusBucket(
        status: 'delivered',
        label: 'Delivered',
        count: deliveredOrders,
      ),
      StatusBucket(
        status: 'cancelled',
        label: 'Cancelled',
        count: cancelledOrders,
      ),
    ],
  );
}

bool _countsTowardRevenue(CustomerOrder order) {
  return order.status == 'delivered' ||
      order.paymentStatus.trim().toLowerCase() == 'paid';
}

List<TimeSeriesPoint> _buildDailySeries(List<CustomerOrder> orders) {
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final buckets = <DateTime, TimeSeriesPoint>{};

  for (var index = 0; index < 7; index++) {
    final date = start.add(Duration(days: index));
    buckets[date] = TimeSeriesPoint(date: date, revenue: 0, orderCount: 0);
  }

  for (final order in orders) {
    final createdAt = order.createdAt;
    if (createdAt == null) continue;
    final key = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (!buckets.containsKey(key)) continue;
    final current = buckets[key]!;
    buckets[key] = TimeSeriesPoint(
      date: current.date,
      revenue: current.revenue + order.total,
      orderCount: current.orderCount + 1,
    );
  }

  return buckets.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

List<MonthlySeriesPoint> _buildMonthlySeries(List<CustomerOrder> orders) {
  final now = DateTime.now();
  final points = <MonthlySeriesPoint>[];

  for (var offset = 5; offset >= 0; offset--) {
    final monthDate = DateTime(now.year, now.month - offset, 1);
    points.add(
      MonthlySeriesPoint(monthStart: monthDate, revenue: 0, orderCount: 0),
    );
  }

  for (final order in orders) {
    final createdAt = order.createdAt;
    if (createdAt == null) continue;
    final monthKey = DateTime(createdAt.year, createdAt.month, 1);
    final index = points.indexWhere(
      (point) =>
          point.monthStart.year == monthKey.year &&
          point.monthStart.month == monthKey.month,
    );
    if (index < 0) continue;
    final current = points[index];
    points[index] = MonthlySeriesPoint(
      monthStart: current.monthStart,
      revenue: current.revenue + order.total,
      orderCount: current.orderCount + 1,
    );
  }

  return points;
}

String compactCurrency(double value) {
  const suffixes = ['', 'K', 'M', 'B'];
  var current = value;
  var suffixIndex = 0;
  while (current.abs() >= 1000 && suffixIndex < suffixes.length - 1) {
    current /= 1000;
    suffixIndex++;
  }
  final decimals = current.abs() >= 100 ? 0 : 1;
  return '৳${current.toStringAsFixed(decimals)}${suffixes[suffixIndex]}';
}

String compactCount(num value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}

String formatMonthLabel(DateTime date) => DateFormat('MMM').format(date);

String formatDayLabel(DateTime date) => DateFormat('E').format(date);

double nonZeroMax(Iterable<double> values) {
  final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max).toDouble();
  return maxValue <= 0 ? 1 : maxValue;
}
