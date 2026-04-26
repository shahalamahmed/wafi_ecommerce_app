import 'package:wafi_ecommerce_app/features/products/product_model.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.selectedOptionLabel,
    required this.selectedOptionKey,
    required this.stock,
  });

  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final String selectedOptionLabel;
  final String selectedOptionKey;
  final int stock;

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    String? selectedOptionLabel,
    String? selectedOptionKey,
    int? stock,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      selectedOptionLabel: selectedOptionLabel ?? this.selectedOptionLabel,
      selectedOptionKey: selectedOptionKey ?? this.selectedOptionKey,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': unitPrice,
      'quantity': quantity,
      'selectedOptionLabel': selectedOptionLabel,
      'selectedOptionKey': selectedOptionKey,
      'stock': stock,
      'subtotal': subtotal,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final productId = (map['productId'] as String?)?.trim() ?? '';
    final selectedOptionKey = (map['selectedOptionKey'] as String?)?.trim() ?? '';
    final fallbackId = selectedOptionKey.isEmpty ? productId : '$productId::$selectedOptionKey';

    return CartItem(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? (map['id'] as String).trim()
          : fallbackId,
      productId: productId,
      productName: (map['productName'] as String?)?.trim() ?? '',
      imageUrl: (map['imageUrl'] as String?)?.trim() ?? '',
      unitPrice: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      selectedOptionLabel: (map['selectedOptionLabel'] as String?)?.trim() ?? '',
      selectedOptionKey: selectedOptionKey,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  factory CartItem.fromProduct(
    ProductModel product, {
    int quantity = 1,
    String selectedOptionLabel = '',
    String selectedOptionKey = '',
  }) {
    final normalizedOptionKey = selectedOptionKey.trim();
    final normalizedOptionLabel = selectedOptionLabel.trim();
    final id = normalizedOptionKey.isEmpty
        ? product.id
        : '${product.id}::$normalizedOptionKey';

    return CartItem(
      id: id,
      productId: product.id,
      productName: product.name,
      imageUrl: product.primaryImage,
      unitPrice: product.price,
      quantity: quantity,
      selectedOptionLabel: normalizedOptionLabel,
      selectedOptionKey: normalizedOptionKey,
      stock: product.stock,
    );
  }
}

class CartState {
  const CartState({
    required this.items,
    required this.isLoading,
    required this.isSyncing,
    this.errorMessage,
  });

  const CartState.initial()
      : items = const [],
        isLoading = true,
        isSyncing = false,
        errorMessage = null;

  final List<CartItem> items;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.subtotal);
  double get tax => double.parse((subtotal * 0.05).toStringAsFixed(2));
  double get total => subtotal + tax;

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
