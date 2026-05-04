

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/features/test_order/test_order_model.dart';

class TestOrderService {
  TestOrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<TestOrderModel>> fetchOrders() async {
    final snapshot = await _firestore
        .collection('test-orders')
        .get();
    return snapshot.docs
        .map((doc) => TestOrderModel.fromMap(doc.data()))
        .toList();
  }
}