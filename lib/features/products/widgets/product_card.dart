import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.quantityInCart,
    required this.onTap,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.isWishlisted,
    required this.onToggleWishlist,
    this.categoryName,
  });

  final ProductModel product;
  final int quantityInCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        variant: GlassCardVariant.elevated,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProductImage(product: product),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, 6, 6, 6
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((categoryName ?? '').isNotEmpty)
                        Text(
                          categoryName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 1),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.xs),
                          if (product.hasDiscount)
                            Flexible(
                              child: Text(
                                '${AppStrings.currencySymbol}${product.originalPrice.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: AppSizes.xs),
                          _WishlistButton(
                            isSelected: isWishlisted,
                            onTap: onToggleWishlist,
                          ),
                          const Spacer(),
                          _ProductCartAction(
                            quantity: quantityInCart,
                            inStock: product.inStock,
                            primary: theme.colorScheme.primary,
                            textStyle: theme.textTheme.labelSmall,
                            onAdd: onAddToCart,
                            onIncrement: onIncrement,
                            onDecrement: onDecrement,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);

    return SizedBox(
      width: 68,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMd),
                bottomLeft: Radius.circular(AppSizes.radiusMd),
              ),
              child: hasImage
                  ? Image.network(
                      product.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _ProductImageFallback(name: product.name),
                    )
                  : _ProductImageFallback(name: product.name),
            ),
          ),
          if (product.hasDiscount)
            Positioned(
              top: AppSizes.xs,
              left: AppSizes.xs,
              child: _ImageOfferBadge(
                label: '${product.discountPercent}% OFF',
                backgroundColor: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageOfferBadge extends StatelessWidget {
  const _ImageOfferBadge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
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
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
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

class _ProductCartAction extends StatelessWidget {
  const _ProductCartAction({
    required this.quantity,
    required this.inStock,
    required this.primary,
    required this.textStyle,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool inStock;
  final Color primary;
  final TextStyle? textStyle;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final disabledColor = Colors.grey;
    final borderColor = inStock
        ? primary.withValues(alpha: 0.4)
        : disabledColor.withValues(alpha: 0.3);
    final backgroundColor = inStock
        ? primary.withValues(alpha: 0.1)
        : disabledColor.withValues(alpha: 0.1);
    final foregroundColor = inStock ? primary : disabledColor;

    if (quantity <= 0) {
      return GestureDetector(
        onTap: inStock ? onAdd : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(color: borderColor),
          ),
          child: Icon(
            inStock ? Icons.add_shopping_cart_rounded : Icons.block_rounded,
            size: 16,
            color: foregroundColor,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _QtyIconButton(
          icon: Icons.remove_rounded,
          color: foregroundColor,
          onTap: onDecrement,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$quantity',
            style: textStyle?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _QtyIconButton(
          icon: Icons.add_rounded,
          color: foregroundColor,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  const _QtyIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isSelected
        ? Colors.redAccent
        : theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.82)
        : theme.colorScheme.primary.withValues(alpha: 0.82);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          isSelected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: AppSizes.iconSm,
          color: iconColor,
        ),
      ),
    );
  }
}
