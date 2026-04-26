import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_model.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<ProductModel>> fetchProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ProductCategory.fromMap(doc.id, doc.data()))
        .toList();
  }
}
