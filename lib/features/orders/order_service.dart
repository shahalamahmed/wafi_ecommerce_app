import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_model.dart';
import 'order_model.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> placeOrder(OrderDraft draft) async {
    final doc = _firestore.collection('orders').doc();

    await _firestore.runTransaction((transaction) async {
      final reservedStock = await _reserveInventory(
        transaction,
        items: draft.items,
      );
      transaction.set(doc, draft.toMap(stockBeforeByProduct: reservedStock));
    });
  }

  Future<List<CustomerOrder>> fetchOrders(String userId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    return _sortOrders(
      snapshot.docs
          .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Stream<List<CustomerOrder>> watchOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => _sortOrders(
            snapshot.docs
                .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  List<CustomerOrder> _sortOrders(List<CustomerOrder> orders) {
    return orders..sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }
}

class OrderInventoryException implements Exception {
  const OrderInventoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension on OrderService {
  Future<Map<String, int>> _reserveInventory(
    Transaction transaction, {
    required List<CartItem> items,
  }) async {
    final requestedByProduct = <String, int>{};
    for (final item in items) {
      final productId = item.productId.trim();
      final quantity = item.quantity;
      if (productId.isEmpty || quantity <= 0) continue;
      requestedByProduct.update(
        productId,
        (current) => current + quantity,
        ifAbsent: () => quantity,
      );
    }

    if (requestedByProduct.isEmpty) {
      throw const OrderInventoryException('Your cart is empty.');
    }

    final stockBeforeByProduct = <String, int>{};
    for (final entry in requestedByProduct.entries) {
      final productRef = _firestore.collection('products').doc(entry.key);
      final productSnap = await transaction.get(productRef);
      if (!productSnap.exists) {
        throw const OrderInventoryException(
          'Some items are no longer available.',
        );
      }

      final product = productSnap.data() ?? <String, dynamic>{};
      final isActive = product['isActive'] as bool? ?? false;
      final stock = (product['stock'] as num?)?.toInt() ?? 0;
      final name = (product['name'] as String?)?.trim() ?? 'This product';

      if (!isActive) {
        throw OrderInventoryException('$name is no longer available.');
      }
      if (stock < entry.value) {
        throw OrderInventoryException(
          stock <= 0
              ? '$name is out of stock.'
              : 'Only $stock unit(s) left for $name.',
        );
      }

      stockBeforeByProduct[entry.key] = stock;
      transaction.update(productRef, {
        'stock': stock - entry.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return stockBeforeByProduct;
  }
}
