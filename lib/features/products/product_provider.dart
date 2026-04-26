import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product_model.dart';
import 'product_service.dart';

class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier(this._service) : super(const ProductState.initial()) {
    load();
  }

  final ProductService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final categories = await _service.fetchCategories();
      final products = await _service.fetchProducts();

      state = state.copyWith(
        categories: categories,
        products: products,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      state = state.copyWith(
        clearSelectedCategory: true,
        clearSelectedSubCategory: true,
      );
      return;
    }

    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearSelectedSubCategory: true,
    );
  }

  void selectSubCategory(String? subCategoryId) {
    if (subCategoryId == null || subCategoryId.isEmpty) {
      state = state.copyWith(clearSelectedSubCategory: true);
      return;
    }

    state = state.copyWith(selectedSubCategoryId: subCategoryId);
  }

  void toggleInStockOnly() {
    state = state.copyWith(inStockOnly: !state.inStockOnly);
  }

  void setViewMode(ProductViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }
}

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref.read(productServiceProvider));
});
