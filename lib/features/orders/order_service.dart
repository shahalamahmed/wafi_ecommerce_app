import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_model.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> placeOrder(OrderDraft draft) async {
    final doc = _firestore.collection('orders').doc();
    await doc.set(draft.toMap());
  }

  Future<List<CustomerOrder>> fetchOrders(String userId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    final orders = snapshot.docs
        .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return orders;
  }
}
