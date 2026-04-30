import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';

class OwnerManagementService {
  OwnerManagementService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<List<ProductModel>> fetchProducts() async {
    final snapshot = await _products.get();
    final products =
        snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) {
            final aDate =
                a.updatedAt ??
                a.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.updatedAt ??
                b.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
    return products;
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final snapshot = await _categories.get();
    final categories =
        snapshot.docs
            .map((doc) => ProductCategory.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return categories;
  }

  Future<void> createProduct(OwnerProductDraft draft) async {
    await _products.add(draft.toMap());
  }

  Future<void> updateProduct(String productId, OwnerProductDraft draft) async {
    await _products.doc(productId).update(draft.toMap(includeCreatedAt: false));
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  Future<List<String>> uploadProductImages(
    List<String> imagePaths, {
    required String folderId,
  }) async {
    final uploads = <String>[];

    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('Selected image file was not found on device.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basename(imagePath);
      final ref = _storage.ref().child(
        'products/$folderId/${timestamp}_$fileName',
      );

      final snapshot = await ref.putFile(file);
      uploads.add(await snapshot.ref.getDownloadURL());
    }

    return uploads;
  }

  Future<List<CustomerOrder>> fetchOrders() async {
    final snapshot = await _orders.get();
    final orders =
        snapshot.docs
            .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
    return orders;
  }

  Future<void> updateOrderStatus({
    required String orderDocId,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'confirmed') {
      payload['confirmedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'shipped') {
      payload['shippedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'delivered') {
      payload['deliveredAt'] = FieldValue.serverTimestamp();
    }

    await _orders.doc(orderDocId).update(payload);
  }

  Future<List<AppUser>> fetchUsers() async {
    final snapshot = await _users.get();
    final users =
        snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList()
          ..sort((a, b) {
            if (a.isOwner != b.isOwner) {
              return a.isOwner ? -1 : 1;
            }

            final aDate =
                a.updatedAt ??
                a.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.updatedAt ??
                b.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
    return users;
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    await _users.doc(userId).update({
      'role': role.name,
      'isShopOwner': role == UserRole.owner,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class OwnerProductDraft {
  const OwnerProductDraft({
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.sku,
    required this.price,
    required this.originalPrice,
    required this.categoryId,
    required this.subCategoryId,
    required this.stock,
    required this.lowStockThreshold,
    required this.images,
    required this.isActive,
  });

  final String name;
  final String description;
  final String shortDescription;
  final String sku;
  final double price;
  final double originalPrice;
  final String categoryId;
  final String? subCategoryId;
  final int stock;
  final int lowStockThreshold;
  final List<String> images;
  final bool isActive;

  Map<String, dynamic> toMap({bool includeCreatedAt = true}) {
    return {
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'sku': sku,
      'price': price,
      'originalPrice': originalPrice,
      'category': categoryId,
      'subCategory': subCategoryId,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'images': images,
      'rating': 0,
      'reviewCount': 0,
      'isActive': isActive,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory OwnerProductDraft.fromProduct(ProductModel product) {
    return OwnerProductDraft(
      name: product.name,
      description: product.description,
      shortDescription: product.shortDescription,
      sku: product.sku,
      price: product.price,
      originalPrice: product.originalPrice,
      categoryId: product.categoryId,
      subCategoryId: product.subCategoryId,
      stock: product.stock,
      lowStockThreshold: product.lowStockThreshold,
      images: product.images,
      isActive: product.isActive,
    );
  }
}
