import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/colors.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_details_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
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
          _WishlistEmptyState(onRefresh: notifier.load),
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
            inStock: item.inStock,
            onTap: () {
              final productState = ref.read(productProvider);
              final match = productState.products.where(
                (p) => p.id == item.productId,
              );
              if (match.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product details are unavailable.'),
                  ),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.productName} added to cart'),
                      ),
                    );
                  }
                : null,
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
    required this.inStock,
    required this.onTap,
    required this.onRemove,
    required this.onAddToCart,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final bool inStock;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onAddToCart;

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
            children: [
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.favorite_rounded, color: favoriteColor),
              ),
              const SizedBox(height: AppSizes.xs),
              IconButton(
                onPressed: onAddToCart,
                icon: Icon(
                  Icons.add_shopping_cart_rounded,
                  color: onAddToCart == null
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
                ),
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
  const _WishlistEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

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
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
