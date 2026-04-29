import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.categoryName,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        variant: GlassCardVariant.elevated,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            _ProductImage(product: product),
            const SizedBox(width: AppSizes.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((categoryName ?? '').isNotEmpty)
                    Text(
                      categoryName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),

                  const SizedBox(height: AppSizes.xs),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSizes.sm),

                  Row(
                    children: [
                      Text(
                        '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      if (product.hasDiscount)
                        Flexible(
                          child: Text(
                            '${AppStrings.currencySymbol}${product.originalPrice.toStringAsFixed(0)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.md),

                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: AppSizes.iconSm,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      _AddButton(
                        inStock: product.inStock,
                        onPressed: product.inStock ? onAddToCart : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final hasImage = product.primaryImage.trim().isNotEmpty;

    return SizedBox(
      width: 92,
      height: 92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: hasImage
            ? Image.network(
          product.primaryImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ProductImageFallback(name: product.name),
        )
            : _ProductImageFallback(name: product.name),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Text(
        name,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.inStock,
    required this.onPressed,
  });

  final bool inStock;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: inStock
              ? Theme.of(context).colorScheme.primary.withOpacity(0.16)
              : Theme.of(context).disabledColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: inStock
                ? Theme.of(context).colorScheme.primary.withOpacity(0.45)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Icon(
          inStock ? Icons.add_shopping_cart_rounded : Icons.block_rounded,
          size: AppSizes.iconSm,
          color: inStock
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}