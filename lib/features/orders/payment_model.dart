import 'package:wafi_ecommerce_app/features/orders/order_model.dart';

enum PaymentAttemptStatus {
  initiated,
  pending,
  verifying,
  paid,
  failed,
  cancelled,
  invalid,
  unknown,
}

extension PaymentAttemptStatusX on PaymentAttemptStatus {
  String get code => switch (this) {
    PaymentAttemptStatus.initiated => 'initiated',
    PaymentAttemptStatus.pending => 'pending',
    PaymentAttemptStatus.verifying => 'verifying',
    PaymentAttemptStatus.paid => 'paid',
    PaymentAttemptStatus.failed => 'failed',
    PaymentAttemptStatus.cancelled => 'cancelled',
    PaymentAttemptStatus.invalid => 'invalid',
    PaymentAttemptStatus.unknown => 'unknown',
  };

  String get label => switch (this) {
    PaymentAttemptStatus.initiated => 'Initiated',
    PaymentAttemptStatus.pending => 'Pending',
    PaymentAttemptStatus.verifying => 'Verifying',
    PaymentAttemptStatus.paid => 'Paid',
    PaymentAttemptStatus.failed => 'Failed',
    PaymentAttemptStatus.cancelled => 'Cancelled',
    PaymentAttemptStatus.invalid => 'Invalid',
    PaymentAttemptStatus.unknown => 'Unknown',
  };

  bool get isTerminal => switch (this) {
    PaymentAttemptStatus.paid ||
    PaymentAttemptStatus.failed ||
    PaymentAttemptStatus.cancelled ||
    PaymentAttemptStatus.invalid => true,
    _ => false,
  };

  static PaymentAttemptStatus fromCode(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'initiated' => PaymentAttemptStatus.initiated,
      'pending' => PaymentAttemptStatus.pending,
      'verifying' => PaymentAttemptStatus.verifying,
      'paid' => PaymentAttemptStatus.paid,
      'failed' => PaymentAttemptStatus.failed,
      'cancelled' => PaymentAttemptStatus.cancelled,
      'invalid' => PaymentAttemptStatus.invalid,
      _ => PaymentAttemptStatus.unknown,
    };
  }
}

class PaymentSession {
  const PaymentSession({
    required this.attemptId,
    required this.gateway,
    required this.gatewayUrl,
    required this.transactionId,
    required this.status,
    this.message,
  });

  final String attemptId;
  final PaymentGateway gateway;
  final String gatewayUrl;
  final String transactionId;
  final PaymentAttemptStatus status;
  final String? message;

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      'gateway': gateway.code,
      'gatewayUrl': gatewayUrl,
      'transactionId': transactionId,
      'status': status.code,
      'message': message,
    };
  }

  factory PaymentSession.fromMap(Map<String, dynamic> map) {
    return PaymentSession(
      attemptId: (map['attemptId'] as String?)?.trim() ?? '',
      gateway:
          PaymentGatewayX.fromCode(map['gateway'] as String?) ??
          PaymentGateway.sslcommerz,
      gatewayUrl: (map['gatewayUrl'] as String?)?.trim() ?? '',
      transactionId: (map['transactionId'] as String?)?.trim() ?? '',
      status: PaymentAttemptStatusX.fromCode(map['status'] as String?),
      message: (map['message'] as String?)?.trim(),
    );
  }
}

class PaymentStatusSnapshot {
  const PaymentStatusSnapshot({
    required this.attemptId,
    required this.gateway,
    required this.status,
    required this.paymentStatus,
    required this.gatewayUrl,
    required this.transactionId,
    required this.orderId,
    this.message,
  });

  final String attemptId;
  final PaymentGateway gateway;
  final PaymentAttemptStatus status;
  final String paymentStatus;
  final String gatewayUrl;
  final String transactionId;
  final String orderId;
  final String? message;

  bool get isPaid => status == PaymentAttemptStatus.paid;

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      'gateway': gateway.code,
      'status': status.code,
      'paymentStatus': paymentStatus,
      'gatewayUrl': gatewayUrl,
      'transactionId': transactionId,
      'orderId': orderId,
      'message': message,
    };
  }

  factory PaymentStatusSnapshot.fromMap(Map<String, dynamic> map) {
    return PaymentStatusSnapshot(
      attemptId: (map['attemptId'] as String?)?.trim() ?? '',
      gateway:
          PaymentGatewayX.fromCode(map['gateway'] as String?) ??
          PaymentGateway.sslcommerz,
      status: PaymentAttemptStatusX.fromCode(map['status'] as String?),
      paymentStatus: (map['paymentStatus'] as String?)?.trim() ?? '',
      gatewayUrl: (map['gatewayUrl'] as String?)?.trim() ?? '',
      transactionId: (map['transactionId'] as String?)?.trim() ?? '',
      orderId: (map['orderId'] as String?)?.trim() ?? '',
      message: (map['message'] as String?)?.trim(),
    );
  }
}
