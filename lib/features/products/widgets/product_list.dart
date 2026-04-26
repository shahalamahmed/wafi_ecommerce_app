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
    required this.onTap,
    required this.onAddToCart,
  });

  final List<ProductModel> products;
  final ProductViewMode viewMode;
  final Map<String, String> categoryLookup;
  final ValueChanged<ProductModel> onTap;
  final ValueChanged<ProductModel> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final product = products[index];

        return ProductCard(
          product: product,
          categoryName: categoryLookup[product.categoryId],
          onTap: () => onTap(product),
          onAddToCart: () => onAddToCart(product),
        );
      },
    );
  }
}