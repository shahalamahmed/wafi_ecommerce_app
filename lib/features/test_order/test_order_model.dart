class TestOrderModel {

  const TestOrderModel({
    required this.productId, 
    required this.amount,
    required this.orderId,
  });

  final int amount;
  final String orderId;
  final String productId;

  factory TestOrderModel.fromMap(Map<String, dynamic> map) {
    return TestOrderModel(
      amount: (map['Amount'] as int?) ?? 0,
      orderId: map['orderId']?.toString().trim() ?? '',
      productId: (map['productId'] as String?)?.trim() ?? '',
    );
  }
}