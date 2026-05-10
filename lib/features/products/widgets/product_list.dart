import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/widgets/product_card.dart';

class ProductList extends StatelessWidget {
  const ProductList({
    super.key,
    required this.products,
    required this.viewMode,
    required this.categoryLookup,
    required this.quantityForProduct,
    required this.onTap,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.isWishlisted,
    required this.onToggleWishlist,
  });

  final List<ProductModel> products;
  final ProductViewMode viewMode;
  final Map<String, String> categoryLookup;
  final int Function(String productId) quantityForProduct;
  final ValueChanged<ProductModel> onTap;
  final ValueChanged<ProductModel> onAddToCart;
  final ValueChanged<ProductModel> onIncrement;
  final ValueChanged<ProductModel> onDecrement;
  final bool Function(String productId) isWishlisted;
  final ValueChanged<ProductModel> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: products.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (context, index) {
        final product = products[index];
        final categoryLabel =
            categoryLookup[product.subCategoryId] ??
            categoryLookup[product.categoryId];

        return ProductCard(
          product: product,
          categoryName: categoryLabel,
          quantityInCart: quantityForProduct(product.id),
          onTap: () => onTap(product),
          onAddToCart: () => onAddToCart(product),
          onIncrement: () => onIncrement(product),
          onDecrement: () => onDecrement(product),
          isWishlisted: isWishlisted(product.id),
          onToggleWishlist: () => onToggleWishlist(product),
        );
      },
    );
  }
}
