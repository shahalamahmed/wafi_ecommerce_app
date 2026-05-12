import 'package:wafi_ecommerce_app/features/orders/order_model.dart';

class OwnerDashboardSnapshot {
  const OwnerDashboardSnapshot({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.categoryCount,
    required this.customerCount,
    required this.ownerCount,
    required this.recentOrders,
    required this.lowStockAlerts,
    required this.topProducts,
    required this.dailySeries,
    required this.monthlySeries,
    required this.statusBuckets,
  });

  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final int pendingOrders;
  final int confirmedOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int activeProducts;
  final int lowStockProducts;
  final int categoryCount;
  final int customerCount;
  final int ownerCount;
  final List<CustomerOrder> recentOrders;
  final List<LowStockAlert> lowStockAlerts;
  final List<TopProductMetric> topProducts;
  final List<TimeSeriesPoint> dailySeries;
  final List<MonthlySeriesPoint> monthlySeries;
  final List<StatusBucket> statusBuckets;

  bool get hasOrders => totalOrders > 0;
  double get fulfilmentRatio =>
      totalOrders == 0 ? 0 : deliveredOrders / totalOrders;
  double get cancellationRatio =>
      totalOrders == 0 ? 0 : cancelledOrders / totalOrders;

  TimeSeriesPoint? get bestSalesDay {
    final valid = dailySeries.where((point) => point.revenue > 0).toList();
    if (valid.isEmpty) return null;
    valid.sort((a, b) => b.revenue.compareTo(a.revenue));
    return valid.first;
  }

  TimeSeriesPoint? get worstSalesDay {
    final valid = dailySeries.where((point) => point.orderCount > 0).toList();
    if (valid.isEmpty) return null;
    valid.sort((a, b) => a.revenue.compareTo(b.revenue));
    return valid.first;
  }
}

class LowStockAlert {
  const LowStockAlert({
    required this.productId,
    required this.productName,
    required this.stock,
    required this.threshold,
  });

  final String productId;
  final String productName;
  final int stock;
  final int threshold;
}

class TopProductMetric {
  const TopProductMetric({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;
}

class TimeSeriesPoint {
  const TimeSeriesPoint({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  final DateTime date;
  final double revenue;
  final int orderCount;
}

class MonthlySeriesPoint {
  const MonthlySeriesPoint({
    required this.monthStart,
    required this.revenue,
    required this.orderCount,
  });

  final DateTime monthStart;
  final double revenue;
  final int orderCount;
}

class StatusBucket {
  const StatusBucket({
    required this.status,
    required this.label,
    required this.count,
  });

  final String status;
  final String label;
  final int count;
}
