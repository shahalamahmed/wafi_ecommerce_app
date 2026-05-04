import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';

class WishlistItem {
  const WishlistItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.stock,
    this.addedAt,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int stock;
  final DateTime? addedAt;

  bool get inStock => stock > 0;

  WishlistItem copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    double? price,
    int? stock,
    DateTime? addedAt,
  }) {
    return WishlistItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'stock': stock,
      'addedAt': (addedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      productId: (map['productId'] as String?)?.trim() ?? '',
      productName: (map['productName'] as String?)?.trim() ?? '',
      imageUrl: (map['imageUrl'] as String?)?.trim() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      addedAt: _readDate(map['addedAt']),
    );
  }

  factory WishlistItem.fromProduct(ProductModel product) {
    return WishlistItem(
      productId: product.id,
      productName: product.name,
      imageUrl: product.primaryImage,
      price: product.price,
      stock: product.stock,
      addedAt: DateTime.now(),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}

class WishlistState {
  const WishlistState({
    required this.items,
    required this.isLoading,
    required this.isSyncing,
    this.errorMessage,
  });

  const WishlistState.initial()
    : items = const [],
      isLoading = true,
      isSyncing = false,
      errorMessage = null;

  final List<WishlistItem> items;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;

  WishlistState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
