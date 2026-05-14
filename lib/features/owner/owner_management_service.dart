import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/core/media/cloudinary_media_service.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/offers/offer_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';

class OwnerManagementService {
  OwnerManagementService({
    FirebaseFirestore? firestore,
    CloudinaryMediaService? mediaService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _mediaService = mediaService ?? CloudinaryMediaService();

  final FirebaseFirestore _firestore;
  final CloudinaryMediaService _mediaService;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('offers');
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

  Future<void> createCategory(OwnerCategoryDraft draft) async {
    await _categories.add(draft.toMap());
  }

  Future<void> updateCategory(
    String categoryId,
    OwnerCategoryDraft draft,
  ) async {
    await _categories
        .doc(categoryId)
        .update(draft.toMap(includeCreatedAt: false));
  }

  Future<void> deleteCategory(String categoryId) async {
    final childCategories = await _categories
        .where('parentId', isEqualTo: categoryId)
        .limit(1)
        .get();
    if (childCategories.docs.isNotEmpty) {
      throw const CategoryDeleteBlockedException(
        'Delete blocked: this category still has subcategories.',
      );
    }

    final directProducts = await _products
        .where('category', isEqualTo: categoryId)
        .limit(1)
        .get();
    if (directProducts.docs.isNotEmpty) {
      throw const CategoryDeleteBlockedException(
        'Delete blocked: products still use this category.',
      );
    }

    final childProducts = await _products
        .where('subCategory', isEqualTo: categoryId)
        .limit(1)
        .get();
    if (childProducts.docs.isNotEmpty) {
      throw const CategoryDeleteBlockedException(
        'Delete blocked: products still use this subcategory.',
      );
    }

    await _categories.doc(categoryId).delete();
  }

  Future<void> createProduct(OwnerProductDraft draft) async {
    final productRef = _products.doc();
    final batch = _firestore.batch();

    batch.set(productRef, draft.toMap());
    _syncOfferInBatch(
      batch,
      productId: productRef.id,
      draft: draft,
      includeCreatedAt: true,
    );

    await batch.commit();
  }

  Future<void> updateProduct(String productId, OwnerProductDraft draft) async {
    final batch = _firestore.batch();

    batch.update(
      _products.doc(productId),
      draft.toMap(includeCreatedAt: false),
    );
    _syncOfferInBatch(
      batch,
      productId: productId,
      draft: draft,
      includeCreatedAt: false,
    );

    await batch.commit();
  }

  Future<void> deleteProduct(String productId) async {
    final batch = _firestore.batch();
    batch.delete(_products.doc(productId));
    batch.set(_offers.doc(productId), {
      'productId': productId,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> upsertOfferFromProduct(
    String productId,
    OwnerProductDraft draft, {
    bool includeCreatedAt = false,
  }) async {
    if (!draft.hasDiscount) {
      await deactivateOffer(productId);
      return;
    }

    await _offers
        .doc(productId)
        .set(
          _offerMap(
            productId: productId,
            draft: draft,
            includeCreatedAt: includeCreatedAt,
          ),
          SetOptions(merge: true),
        );
  }

  Future<void> deactivateOffer(String productId) async {
    await _offers.doc(productId).set({
      'productId': productId,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<OfferModel>> fetchOffers() async {
    final snapshot = await _offers.get();
    final offers =
        snapshot.docs
            .map((doc) => OfferModel.fromMap(doc.id, doc.data()))
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

    return offers;
  }

  Future<List<String>> uploadProductImages(
    List<String> imagePaths, {
    required String folderId,
  }) async {
    return _mediaService.uploadProductImages(imagePaths, folderId: folderId);
  }

  Future<List<CustomerOrder>> fetchOrders() async {
    final snapshot = await _orders.get();
    return _sortOrders(
      snapshot.docs
          .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Stream<List<CustomerOrder>> watchOrders() {
    return _orders.snapshots().map(
      (snapshot) => _sortOrders(
        snapshot.docs
            .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
            .toList(),
      ),
    );
  }

  Future<void> updateOrderStatus({
    required String orderDocId,
    required String status,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _orders.doc(orderDocId);
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw const OrderStatusUpdateException('Order not found.');
      }

      final order = orderSnap.data() ?? <String, dynamic>{};
      final currentStatus =
          (order['status'] as String?)?.trim().toLowerCase() ?? 'pending';
      final nextStatus = status.trim().toLowerCase();

      _validateStatusTransition(
        currentStatus: currentStatus,
        nextStatus: nextStatus,
      );

      if (currentStatus == nextStatus) {
        return;
      }

      final payload = <String, dynamic>{
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (nextStatus == 'confirmed') {
        payload['confirmedAt'] = FieldValue.serverTimestamp();
      } else if (nextStatus == 'shipped') {
        payload['shippedAt'] = FieldValue.serverTimestamp();
      } else if (nextStatus == 'delivered') {
        payload['deliveredAt'] = FieldValue.serverTimestamp();
      } else if (nextStatus == 'cancelled') {
        final inventoryReserved = order['inventoryReserved'] as bool? ?? false;
        final inventoryRestocked =
            order['inventoryRestocked'] as bool? ?? false;

        if (inventoryReserved && !inventoryRestocked) {
          final items = (order['items'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          final quantityByProduct = <String, int>{};
          for (final item in items) {
            final productId = (item['productId'] as String?)?.trim() ?? '';
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            if (productId.isEmpty || quantity <= 0) continue;
            quantityByProduct.update(
              productId,
              (current) => current + quantity,
              ifAbsent: () => quantity,
            );
          }

          for (final entry in quantityByProduct.entries) {
            final productRef = _products.doc(entry.key);
            final productSnap = await transaction.get(productRef);
            if (!productSnap.exists) continue;

            final currentStock =
                (productSnap.data()?['stock'] as num?)?.toInt() ?? 0;
            transaction.update(productRef, {
              'stock': currentStock + entry.value,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          payload['inventoryRestocked'] = true;
          payload['inventoryRestockedAt'] = FieldValue.serverTimestamp();
        }
      }

      transaction.update(orderRef, payload);
    });
  }

  Future<void> markCodAsPaid({
    required String orderDocId,
    required AppUser collector,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _orders.doc(orderDocId);
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw const OrderPaymentUpdateException('Order not found.');
      }

      final order = orderSnap.data() ?? <String, dynamic>{};
      final paymentMethod =
          (order['paymentMethod'] as String?)?.trim().toLowerCase() ?? '';
      final paymentStatus =
          (order['paymentStatus'] as String?)?.trim().toLowerCase() ?? '';
      final status = (order['status'] as String?)?.trim().toLowerCase() ?? '';

      if (paymentMethod != PaymentMethod.cashOnDelivery.code) {
        throw const OrderPaymentUpdateException(
          'Only cash on delivery orders can be marked as paid here.',
        );
      }
      if (paymentStatus == 'paid') {
        throw const OrderPaymentUpdateException(
          'This COD order is already marked as paid.',
        );
      }
      if (status != 'delivered') {
        throw const OrderPaymentUpdateException(
          'COD payment can only be collected after delivery.',
        );
      }

      transaction.update(orderRef, {
        'paymentStatus': 'paid',
        'paymentCollectedAt': FieldValue.serverTimestamp(),
        'paymentCollectedBy': collector.email.trim().isNotEmpty
            ? collector.email.trim()
            : collector.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
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

  void _syncOfferInBatch(
    WriteBatch batch, {
    required String productId,
    required OwnerProductDraft draft,
    required bool includeCreatedAt,
  }) {
    final offerRef = _offers.doc(productId);

    if (!draft.hasDiscount) {
      batch.set(offerRef, {
        'productId': productId,
        'productName': draft.name,
        'productImage': draft.primaryImage,
        'categoryId': draft.categoryId,
        'subCategoryId': draft.subCategoryId,
        'originalPrice': draft.originalPrice,
        'offerPrice': draft.price,
        'discountAmount': 0,
        'discountPercent': 0,
        'isActive': false,
        if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    batch.set(
      offerRef,
      _offerMap(
        productId: productId,
        draft: draft,
        includeCreatedAt: includeCreatedAt,
      ),
      SetOptions(merge: true),
    );
  }

  Map<String, dynamic> _offerMap({
    required String productId,
    required OwnerProductDraft draft,
    required bool includeCreatedAt,
  }) {
    return {
      'productId': productId,
      'productName': draft.name,
      'productImage': draft.primaryImage,
      'categoryId': draft.categoryId,
      'subCategoryId': draft.subCategoryId,
      'originalPrice': draft.originalPrice,
      'offerPrice': draft.price,
      'discountAmount': draft.discountAmount,
      'discountPercent': draft.discountPercent,
      'isActive': draft.hasDiscount,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  List<CustomerOrder> _sortOrders(List<CustomerOrder> orders) {
    return orders..sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }
}

class OrderStatusUpdateException implements Exception {
  const OrderStatusUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderPaymentUpdateException implements Exception {
  const OrderPaymentUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension on OwnerManagementService {
  void _validateStatusTransition({
    required String currentStatus,
    required String nextStatus,
  }) {
    if (currentStatus == nextStatus) {
      if (currentStatus == 'cancelled') return;
      throw OrderStatusUpdateException(
        'Order is already ${_labelForStatus(currentStatus)}.',
      );
    }

    final allowedTransitions = <String, Set<String>>{
      'pending': {'confirmed', 'cancelled'},
      'confirmed': {'shipped', 'cancelled'},
      'shipped': {'delivered', 'cancelled'},
      'delivered': <String>{},
      'cancelled': <String>{},
    };

    final allowed = allowedTransitions[currentStatus] ?? const <String>{};
    if (allowed.contains(nextStatus)) return;

    if (currentStatus == 'delivered' && nextStatus == 'cancelled') {
      throw const OrderStatusUpdateException(
        'Delivered orders cannot be cancelled.',
      );
    }

    throw OrderStatusUpdateException(
      'Cannot change an order from ${_labelForStatus(currentStatus)} to ${_labelForStatus(nextStatus)}.',
    );
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
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

  bool get hasDiscount => originalPrice > price;
  double get normalizedOriginalPrice => hasDiscount ? originalPrice : price;
  double get discountAmount =>
      hasDiscount ? normalizedOriginalPrice - price : 0;
  int get discountPercent {
    if (!hasDiscount || normalizedOriginalPrice <= 0) return 0;
    return (((normalizedOriginalPrice - price) / normalizedOriginalPrice) * 100)
        .round();
  }

  String get primaryImage => images.isEmpty ? '' : images.first;

  Map<String, dynamic> toMap({bool includeCreatedAt = true}) {
    return {
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'sku': sku,
      'price': price,
      'originalPrice': normalizedOriginalPrice,
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

class OwnerCategoryDraft {
  const OwnerCategoryDraft({
    required this.name,
    required this.description,
    required this.image,
    required this.parentId,
    required this.displayOrder,
    required this.isActive,
  });

  final String name;
  final String description;
  final String image;
  final String? parentId;
  final int displayOrder;
  final bool isActive;

  Map<String, dynamic> toMap({bool includeCreatedAt = true}) {
    return {
      'name': name,
      'description': description,
      'image': image,
      'parentId': parentId,
      'displayOrder': displayOrder,
      'isActive': isActive,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory OwnerCategoryDraft.fromCategory(ProductCategory category) {
    return OwnerCategoryDraft(
      name: category.name,
      description: category.description,
      image: category.image,
      parentId: category.parentId,
      displayOrder: category.displayOrder,
      isActive: category.isActive,
    );
  }
}

class CategoryDeleteBlockedException implements Exception {
  const CategoryDeleteBlockedException(this.message);

  final String message;

  @override
  String toString() => message;
}
