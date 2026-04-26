import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/core/storage/local_storage.dart';

import 'cart_model.dart';

class CartService {
  CartService({
    FirebaseFirestore? firestore,
    LocalStorage? localStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localStorage = localStorage ?? LocalStorage();

  final FirebaseFirestore _firestore;
  final LocalStorage _localStorage;

  Future<List<CartItem>> loadCart({String? userId}) async {
    if (userId == null || userId.isEmpty) {
      final items = await _localStorage.getAnonymousCart();
      return items.map(CartItem.fromMap).toList();
    }

    final doc = await _firestore.collection('carts').doc(userId).get();
    final rawItems = (doc.data()?['items'] as List<dynamic>? ?? const <dynamic>[]);
    return rawItems
        .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveCart({
    required List<CartItem> items,
    String? userId,
  }) async {
    if (userId == null || userId.isEmpty) {
      await _localStorage.saveAnonymousCart(
        items.map((item) => item.toMap()).toList(),
      );
      return;
    }

    final subtotal = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final tax = double.parse((subtotal * 0.05).toStringAsFixed(2));
    final total = subtotal + tax;

    await _firestore.collection('carts').doc(userId).set({
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
