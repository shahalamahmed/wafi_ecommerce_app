import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_model.dart';

enum PaymentMethod { cashOnDelivery, payOnline }

extension PaymentMethodX on PaymentMethod {
  String get code => switch (this) {
    PaymentMethod.cashOnDelivery => 'cod',
    PaymentMethod.payOnline => 'online',
  };

  String get label => switch (this) {
    PaymentMethod.cashOnDelivery => 'Cash on Delivery',
    PaymentMethod.payOnline => 'Online Payment',
  };

  static PaymentMethod? fromCode(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'cod' => PaymentMethod.cashOnDelivery,
      'online' => PaymentMethod.payOnline,
      _ => null,
    };
  }
}

enum OnlinePaymentMethod { bkash, nagad, rocket, card }

extension OnlinePaymentMethodX on OnlinePaymentMethod {
  String get code => switch (this) {
    OnlinePaymentMethod.bkash => 'bkash',
    OnlinePaymentMethod.nagad => 'nagad',
    OnlinePaymentMethod.rocket => 'rocket',
    OnlinePaymentMethod.card => 'card',
  };

  String get label => switch (this) {
    OnlinePaymentMethod.bkash => 'bKash',
    OnlinePaymentMethod.nagad => 'Nagad',
    OnlinePaymentMethod.rocket => 'Rocket',
    OnlinePaymentMethod.card => 'Card / Bank Payment',
  };

  static OnlinePaymentMethod? fromCode(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'bkash' => OnlinePaymentMethod.bkash,
      'nagad' => OnlinePaymentMethod.nagad,
      'rocket' => OnlinePaymentMethod.rocket,
      'card' => OnlinePaymentMethod.card,
      _ => null,
    };
  }
}

enum PaymentGateway { sslcommerz }

extension PaymentGatewayX on PaymentGateway {
  String get code => switch (this) {
    PaymentGateway.sslcommerz => 'sslcommerz',
  };

  String get label => switch (this) {
    PaymentGateway.sslcommerz => 'SSLCOMMERZ',
  };

  String get description => switch (this) {
    PaymentGateway.sslcommerz =>
      'Hosted checkout with bKash, Nagad, cards, and bank payment options.',
  };

  static PaymentGateway? fromCode(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'sslcommerz' => PaymentGateway.sslcommerz,
      _ => null,
    };
  }
}

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
    required this.customerEmail,
    required this.items,
    required this.address,
    required this.notes,
    required this.couponCode,
    required this.deliveryDate,
    required this.paymentMethod,
    this.paymentGateway,
    this.onlinePaymentMethod,
    this.paymentStatus,
    this.gatewayTransactionId,
    this.gatewayValidationId,
    required this.subtotal,
    required this.tax,
    required this.deliveryCharge,
    required this.total,
  });

  final String userId;
  final String customerEmail;
  final List<CartItem> items;
  final CheckoutAddress address;
  final String notes;
  final String couponCode;
  final DateTime deliveryDate;
  final PaymentMethod paymentMethod;
  final PaymentGateway? paymentGateway;
  final OnlinePaymentMethod? onlinePaymentMethod;
  final String? paymentStatus;
  final String? gatewayTransactionId;
  final String? gatewayValidationId;
  final double subtotal;
  final double tax;
  final double deliveryCharge;
  final double total;

  OrderDraft copyWith({
    String? userId,
    String? customerEmail,
    List<CartItem>? items,
    CheckoutAddress? address,
    String? notes,
    String? couponCode,
    DateTime? deliveryDate,
    PaymentMethod? paymentMethod,
    PaymentGateway? paymentGateway,
    OnlinePaymentMethod? onlinePaymentMethod,
    String? paymentStatus,
    String? gatewayTransactionId,
    String? gatewayValidationId,
    double? subtotal,
    double? tax,
    double? deliveryCharge,
    double? total,
  }) {
    return OrderDraft(
      userId: userId ?? this.userId,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      couponCode: couponCode ?? this.couponCode,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      onlinePaymentMethod: onlinePaymentMethod ?? this.onlinePaymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayValidationId: gatewayValidationId ?? this.gatewayValidationId,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    final gatewayCode = paymentGateway?.code;
    final onlineMethodCode = onlinePaymentMethod?.code;
    final txId = gatewayTransactionId?.trim() ?? '';
    final validationId = gatewayValidationId?.trim() ?? '';
    final paymentMetadata = <String, dynamic>{
      if (txId.isNotEmpty) 'gatewayTransactionId': txId,
      if (validationId.isNotEmpty) 'gatewayValidationId': validationId,
      if (paymentMethod == PaymentMethod.payOnline) 'mode': 'demo',
    };

    if (gatewayCode != null) {
      paymentMetadata['gateway'] = gatewayCode;
    }
    if (onlineMethodCode != null) {
      paymentMetadata['onlinePaymentMethod'] = onlineMethodCode;
    }

    return {
      'orderId': generateOrderNumber(),
      'userId': userId,
      'customerEmail': customerEmail,
      'items': items.map(_cartItemToMap).toList(),
      'status': 'pending',
      'paymentMethod': paymentMethod.code,
      'paymentStatus':
          paymentStatus ??
          (paymentMethod == PaymentMethod.cashOnDelivery ? 'pending' : 'paid'),
      'paymentGateway': gatewayCode,
      'onlinePaymentMethod': paymentMethod == PaymentMethod.payOnline
          ? onlineMethodCode
          : null,
      'gatewayTransactionId': txId.isEmpty ? null : txId,
      'gatewayValidationId': validationId.isEmpty ? null : validationId,
      'paymentMetadata': paymentMetadata,
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

  Map<String, dynamic> toPaymentPayload({required PaymentGateway gateway}) {
    return {
      'userId': userId,
      'customerEmail': customerEmail,
      'items': items.map(_cartItemToMap).toList(),
      'deliveryAddress': address.toMap(),
      'notes': notes,
      'couponCode': couponCode,
      'deliveryDate': deliveryDate.toIso8601String(),
      'paymentMethod': PaymentMethod.payOnline.code,
      'paymentGateway': gateway.code,
      'subtotal': subtotal,
      'tax': tax,
      'deliveryCharge': deliveryCharge,
      'total': total,
      'currency': 'BDT',
    };
  }

  static Map<String, dynamic> _cartItemToMap(CartItem item) {
    return {
      'productId': item.productId,
      'productName': item.productName,
      'quantity': item.quantity,
      'price': item.unitPrice,
      'originalPrice': item.originalPrice,
      'subtotal': item.subtotal,
      'discount': item.totalDiscount,
      'selectedOptionLabel': item.selectedOptionLabel,
      'selectedOptionKey': item.selectedOptionKey,
    };
  }

  static String generateOrderNumber() {
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
      selectedOptionLabel:
          (map['selectedOptionLabel'] as String?)?.trim() ?? '',
    );
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.customerEmail,
    required this.items,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentGateway,
    required this.onlinePaymentMethod,
    required this.gatewayTransactionId,
    required this.gatewayValidationId,
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
  final String customerEmail;
  final List<OrderItemModel> items;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentGateway;
  final String onlinePaymentMethod;
  final String gatewayTransactionId;
  final String gatewayValidationId;
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

  String get paymentStatusLabel => switch (paymentStatus.trim().toLowerCase()) {
    'paid' => 'Paid',
    'failed' => 'Failed',
    'cancelled' => 'Cancelled',
    'invalid' => 'Invalid',
    'unpaid' => 'Unpaid',
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

  bool get isCashOnDelivery =>
      PaymentMethodX.fromCode(paymentMethod) == PaymentMethod.cashOnDelivery;

  String get paymentMethodLabel =>
      PaymentMethodX.fromCode(paymentMethod)?.label ?? 'Payment';

  String get paymentGatewayLabel =>
      PaymentGatewayX.fromCode(paymentGateway)?.label ?? '';

  String get onlinePaymentMethodLabel =>
      OnlinePaymentMethodX.fromCode(onlinePaymentMethod)?.label ?? '';

  String get paymentChannelLabel {
    if (paymentGatewayLabel.isNotEmpty) return paymentGatewayLabel;
    if (onlinePaymentMethodLabel.isNotEmpty) return onlinePaymentMethodLabel;
    return '';
  }

  String get paymentSummaryLabel {
    final channel = paymentChannelLabel;
    if (channel.isEmpty || isCashOnDelivery) {
      return paymentMethodLabel;
    }
    return '$paymentMethodLabel - $channel';
  }

  factory CustomerOrder.fromMap(String id, Map<String, dynamic> map) {
    final paymentMetadata = Map<String, dynamic>.from(
      map['paymentMetadata'] as Map? ?? <String, dynamic>{},
    );

    return CustomerOrder(
      id: id,
      orderId: (map['orderId'] as String?)?.trim() ?? id,
      userId: (map['userId'] as String?)?.trim() ?? '',
      customerEmail: (map['customerEmail'] as String?)?.trim() ?? '',
      items: (map['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) =>
                OrderItemModel.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      status: (map['status'] as String?)?.trim() ?? 'pending',
      paymentMethod: (map['paymentMethod'] as String?)?.trim() ?? '',
      paymentStatus: (map['paymentStatus'] as String?)?.trim() ?? '',
      paymentGateway:
          (map['paymentGateway'] as String?)?.trim() ??
          (paymentMetadata['gateway'] as String?)?.trim() ??
          '',
      onlinePaymentMethod:
          (map['onlinePaymentMethod'] as String?)?.trim() ??
          (paymentMetadata['onlinePaymentMethod'] as String?)?.trim() ??
          '',
      gatewayTransactionId:
          (map['gatewayTransactionId'] as String?)?.trim() ??
          (paymentMetadata['gatewayTransactionId'] as String?)?.trim() ??
          '',
      gatewayValidationId:
          (map['gatewayValidationId'] as String?)?.trim() ??
          (paymentMetadata['gatewayValidationId'] as String?)?.trim() ??
          '',
      deliveryAddress: Map<String, dynamic>.from(
        map['deliveryAddress'] as Map? ?? <String, dynamic>{},
      ),
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
