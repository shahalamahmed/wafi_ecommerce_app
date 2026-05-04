import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/core/storage/local_storage.dart';

import 'wishlist_model.dart';

class WishlistService {
  WishlistService({FirebaseFirestore? firestore, LocalStorage? localStorage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _localStorage = localStorage ?? LocalStorage();

  final FirebaseFirestore _firestore;
  final LocalStorage _localStorage;

  Future<List<WishlistItem>> loadWishlist({String? userId}) async {
    if (userId == null || userId.isEmpty) {
      final items = await _localStorage.getAnonymousWishlist();
      return items.map(WishlistItem.fromMap).toList();
    }

    final doc = await _firestore.collection('wishlists').doc(userId).get();
    final rawItems =
        (doc.data()?['items'] as List<dynamic>? ?? const <dynamic>[]);
    return rawItems
        .map(
          (item) =>
              WishlistItem.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> saveWishlist({
    required List<WishlistItem> items,
    String? userId,
  }) async {
    if (userId == null || userId.isEmpty) {
      await _localStorage.saveAnonymousWishlist(
        items.map((item) => item.toMap()).toList(),
      );
      return;
    }

    await _firestore.collection('wishlists').doc(userId).set({
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'itemCount': items.length,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
