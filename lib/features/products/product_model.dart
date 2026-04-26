import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductViewMode { grid, list }

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.parentId,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final String image;
  final String? parentId;
  final int displayOrder;
  final bool isActive;

  bool get isTopLevel => parentId == null || parentId!.isEmpty;

  factory ProductCategory.fromMap(String id, Map<String, dynamic> map) {
    return ProductCategory(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      description: (map['description'] as String?)?.trim() ?? '',
      image: (map['image'] as String?)?.trim() ?? '',
      parentId: (map['parentId'] as String?)?.trim(),
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? false,
    );
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
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
    required this.rating,
    required this.reviewCount,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
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
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasDiscount => originalPrice > price;
  bool get inStock => stock > 0;
  bool get isLowStock => inStock && stock <= lowStockThreshold;
  int get discountPercent {
    if (!hasDiscount || originalPrice <= 0) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }

  String get primaryImage => images.isEmpty ? '' : images.first;

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      description: (map['description'] as String?)?.trim() ?? '',
      shortDescription: (map['shortDescription'] as String?)?.trim() ?? '',
      sku: (map['sku'] as String?)?.trim() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0,
      categoryId: (map['category'] as String?)?.trim() ?? '',
      subCategoryId: (map['subCategory'] as String?)?.trim(),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 0,
      images: (map['images'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class ProductState {
  const ProductState({
    required this.products,
    required this.categories,
    required this.isLoading,
    required this.viewMode,
    this.selectedCategoryId,
    this.selectedSubCategoryId,
    this.searchQuery = '',
    this.errorMessage,
    this.inStockOnly = false,
  });

  const ProductState.initial()
      : products = const [],
        categories = const [],
        isLoading = true,
        viewMode = ProductViewMode.grid,
        selectedCategoryId = null,
        selectedSubCategoryId = null,
        searchQuery = '',
        errorMessage = null,
        inStockOnly = false;

  final List<ProductModel> products;
  final List<ProductCategory> categories;
  final bool isLoading;
  final ProductViewMode viewMode;
  final String? selectedCategoryId;
  final String? selectedSubCategoryId;
  final String searchQuery;
  final String? errorMessage;
  final bool inStockOnly;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  List<ProductCategory> get topLevelCategories => categories
      .where((category) => category.isActive && category.isTopLevel)
      .toList()
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  List<ProductCategory> get subCategories {
    if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
      return const [];
    }

    final filtered = categories.where((category) {
      return category.isActive && category.parentId == selectedCategoryId;
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return filtered;
  }

  List<ProductModel> get visibleProducts {
    Iterable<ProductModel> filtered = products.where((product) => product.isActive);

    if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
      filtered = filtered.where((product) => product.categoryId == selectedCategoryId);
    }

    if (selectedSubCategoryId != null && selectedSubCategoryId!.isNotEmpty) {
      filtered = filtered.where((product) => product.subCategoryId == selectedSubCategoryId);
    }

    if (inStockOnly) {
      filtered = filtered.where((product) => product.inStock);
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.shortDescription.toLowerCase().contains(query) ||
            product.sku.toLowerCase().contains(query);
      });
    }

    final result = filtered.toList()
      ..sort((a, b) {
        final updatedA = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final updatedB = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return updatedB.compareTo(updatedA);
      });
    return result;
  }

  ProductState copyWith({
    List<ProductModel>? products,
    List<ProductCategory>? categories,
    bool? isLoading,
    ProductViewMode? viewMode,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? selectedSubCategoryId,
    bool clearSelectedSubCategory = false,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    bool? inStockOnly,
  }) {
    return ProductState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      viewMode: viewMode ?? this.viewMode,
      selectedCategoryId: clearSelectedCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      selectedSubCategoryId: clearSelectedSubCategory
          ? null
          : selectedSubCategoryId ?? this.selectedSubCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }
}
