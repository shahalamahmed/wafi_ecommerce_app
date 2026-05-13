import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/colors.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_details_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/shared/layout/main_layout.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_snackbar.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

import 'wishlist_provider.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const WafiAppBar(
        title: AppStrings.myWishlist,
        subtitle: 'Saved products you want to revisit',
      ),
      body: const WishlistScreen(),
    );
  }
}

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistProvider);
    final notifier = ref.read(wishlistProvider.notifier);
    ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          AppSizes.md,
          AppSizes.screenPaddingH,
          AppSizes.screenPaddingH,
        ),
        children: [
          _WishlistSummaryCard(itemCount: state.itemCount),
          const SizedBox(height: AppSizes.lg),
          _WishlistEmptyState(
            onContinueShopping: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const MainLayout(initialIndex: 0),
                ),
                (route) => false,
              );
            },
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          AppSizes.lg,
          AppSizes.screenPaddingH,
          120,
        ),
        itemCount: state.items.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _WishlistSummaryCard(itemCount: state.itemCount);
          }

          final item = state.items[index - 1];

          return _WishlistRow(
            productId: item.productId,
            productName: item.productName,
            imageUrl: item.imageUrl,
            price: item.price,
            stock: item.stock,
            inStock: item.inStock,
            quantityInCart: cartNotifier.quantityForProduct(item.productId),
            onTap: () {
              final productState = ref.read(productProvider);
              final match = productState.products.where(
                (p) => p.id == item.productId,
              );
              if (match.isEmpty) {
                GlassSnackbar.warning(
                  context,
                  AppStrings.errProductUnavailable,
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailsScreen(product: match.first),
                ),
              );
            },
            onRemove: () => notifier.remove(item.productId),
            onAddToCart: item.inStock
                ? () async {
                    final productState = ref.read(productProvider);
                    final match = productState.products.where(
                      (p) => p.id == item.productId,
                    );
                    if (match.isEmpty) return;

                    await ref
                        .read(cartProvider.notifier)
                        .addProduct(match.first);
                    if (!context.mounted) return;
                    GlassSnackbar.success(
                      context,
                      '${item.productName} added to cart',
                    );
                  }
                : null,
            onIncrement: item.inStock
                ? () {
                    cartNotifier.increment(item.productId);
                  }
                : null,
            onDecrement: () {
              cartNotifier.decrement(item.productId);
            },
          );
        },
      ),
    );
  }
}

class _WishlistRow extends StatelessWidget {
  const _WishlistRow({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.inStock,
    required this.quantityInCart,
    required this.onTap,
    required this.onRemove,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int stock;
  final bool inStock;
  final int quantityInCart;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockColor = inStock
        ? AppColors.success(context)
        : theme.colorScheme.error;
    final favoriteColor = theme.colorScheme.error;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(AppSizes.md),
      onTap: onTap,
      child: Row(
        children: [
          _WishlistImage(imageUrl: imageUrl, productName: productName),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  '${AppStrings.currencySymbol}${price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  inStock ? AppStrings.inStock : AppStrings.outOfStock,
                  style: theme.textTheme.bodySmall?.copyWith(color: stockColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.favorite_rounded, color: favoriteColor),
              ),
              const SizedBox(height: AppSizes.xs),
              _WishlistCartAction(
                quantity: quantityInCart,
                inStock: inStock,
                stock: stock,
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
    );
  }
}

class _WishlistImage extends StatelessWidget {
  const _WishlistImage({required this.imageUrl, required this.productName});

  final String imageUrl;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.trim().isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _WishlistImageFallback(name: productName),
            )
          : _WishlistImageFallback(name: productName),
    );
  }
}

class _WishlistImageFallback extends StatelessWidget {
  const _WishlistImageFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xs),
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _WishlistSummaryCard extends StatelessWidget {
  const _WishlistSummaryCard({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.myWishlist,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  itemCount == 1
                      ? '1 saved product'
                      : '$itemCount saved products',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistEmptyState extends StatelessWidget {
  const _WishlistEmptyState({required this.onContinueShopping});

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: AppSizes.iconXl,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  AppStrings.emptyWishlist,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  AppStrings.emptyWishlistSub,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                GlassButton(
                  label: AppStrings.continueShopping,
                  isFullWidth: false,
                  onPressed: onContinueShopping,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WishlistCartAction extends StatelessWidget {
  const _WishlistCartAction({
    required this.quantity,
    required this.inStock,
    required this.stock,
    required this.primary,
    required this.textStyle,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool inStock;
  final int stock;
  final Color primary;
  final TextStyle? textStyle;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WishlistQtyIconButton(
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
          _WishlistQtyIconButton(
            icon: Icons.add_rounded,
            color: foregroundColor,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _WishlistQtyIconButton extends StatelessWidget {
  const _WishlistQtyIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

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
