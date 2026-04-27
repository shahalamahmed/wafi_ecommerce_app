import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_model.dart';

enum PaymentMethod { cashOnDelivery, payOnline }

class CheckoutAddress {
  const CheckoutAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postalCode;
  final String country;

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

class OrderDraft {
  const OrderDraft({
    required this.userId,
    required this.items,
    required this.address,
    required this.notes,
    required this.couponCode,
    required this.deliveryDate,
    required this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.deliveryCharge,
    required this.total,
  });

  final String userId;
  final List<CartItem> items;
  final CheckoutAddress address;
  final String notes;
  final String couponCode;
  final DateTime deliveryDate;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double tax;
  final double deliveryCharge;
  final double total;

  Map<String, dynamic> toMap() {
    return {
      'orderId': _generateOrderNumber(),
      'userId': userId,
      'items': items
          .map(
            (item) => {
              'productId': item.productId,
              'productName': item.productName,
              'quantity': item.quantity,
              'price': item.unitPrice,
              'subtotal': item.subtotal,
              'selectedOptionLabel': item.selectedOptionLabel,
            },
          )
          .toList(),
      'status': 'pending',
      'paymentMethod': paymentMethod == PaymentMethod.cashOnDelivery ? 'cod' : 'online',
      'paymentStatus': paymentMethod == PaymentMethod.cashOnDelivery ? 'pending' : 'unpaid',
      'deliveryAddress': address.toMap(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryCharge': deliveryCharge,
      'total': total,
      'notes': notes,
      'couponCode': couponCode,
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'createdAt': FieldValue.serverTimestamp(),
      'confirmedAt': null,
      'shippedAt': null,
      'deliveredAt': null,
    };
  }

  static String _generateOrderNumber() {
    final now = DateTime.now();
    return 'WAFI-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.selectedOptionLabel,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  final String selectedOptionLabel;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: (map['productId'] as String?)?.trim() ?? '',
      productName: (map['productName'] as String?)?.trim() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      selectedOptionLabel: (map['selectedOptionLabel'] as String?)?.trim() ?? '',
    );
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.subtotal,
    required this.tax,
    required this.deliveryCharge,
    required this.total,
    required this.notes,
    required this.couponCode,
    this.deliveryDate,
    this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  final String id;
  final String orderId;
  final String userId;
  final List<OrderItemModel> items;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final Map<String, dynamic> deliveryAddress;
  final double subtotal;
  final double tax;
  final double deliveryCharge;
  final double total;
  final String notes;
  final String couponCode;
  final DateTime? deliveryDate;
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  String get statusLabel => switch (status) {
        'confirmed' => 'Confirmed',
        'shipped' => 'Shipped',
        'delivered' => 'Delivered',
        'cancelled' => 'Cancelled',
        _ => 'Pending',
      };

  String get addressText => [
        deliveryAddress['fullName'] ?? '',
        deliveryAddress['phone'] ?? '',
        deliveryAddress['addressLine1'] ?? '',
        deliveryAddress['addressLine2'] ?? '',
        deliveryAddress['city'] ?? '',
        deliveryAddress['postalCode'] ?? '',
        deliveryAddress['country'] ?? '',
      ].where((part) => part.toString().trim().isNotEmpty).join(', ');

  factory CustomerOrder.fromMap(String id, Map<String, dynamic> map) {
    return CustomerOrder(
      id: id,
      orderId: (map['orderId'] as String?)?.trim() ?? id,
      userId: (map['userId'] as String?)?.trim() ?? '',
      items: (map['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => OrderItemModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      status: (map['status'] as String?)?.trim() ?? 'pending',
      paymentMethod: (map['paymentMethod'] as String?)?.trim() ?? '',
      paymentStatus: (map['paymentStatus'] as String?)?.trim() ?? '',
      deliveryAddress: Map<String, dynamic>.from(map['deliveryAddress'] as Map? ?? <String, dynamic>{}),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      notes: (map['notes'] as String?)?.trim() ?? '',
      couponCode: (map['couponCode'] as String?)?.trim() ?? '',
      deliveryDate: _readDate(map['deliveryDate']),
      createdAt: _readDate(map['createdAt']),
      confirmedAt: _readDate(map['confirmedAt']),
      shippedAt: _readDate(map['shippedAt']),
      deliveredAt: _readDate(map['deliveredAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
