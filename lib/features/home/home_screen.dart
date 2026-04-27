import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_details_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (productState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productState.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPaddingH),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load home feed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  productState.errorMessage ?? AppStrings.errGeneral,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                GlassButton(
                  label: AppStrings.retry,
                  isFullWidth: false,
                  onPressed: () => ref.read(productProvider.notifier).load(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categories = productState.topLevelCategories;
    final products = productState.products.where((product) => product.isActive).toList();
    final popularItems = [...products]
      ..sort((a, b) {
        final scoreA = (a.rating * 1000) + a.reviewCount;
        final scoreB = (b.rating * 1000) + b.reviewCount;
        return scoreB.compareTo(scoreA);
      });
    final newArrivals = [...products]
      ..sort((a, b) {
        final dateA = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    final bannerProducts = products
        .where((product) => product.primaryImage.trim().isNotEmpty)
        .take(4)
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(productProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          _BannerSection(
            products: bannerProducts,
            onShopNow: () => _openCatalog(
              context,
              title: 'All Grocery Products',
              subtitle: 'Fresh picks, daily essentials, and pantry staples',
            ),
          ),
          const SizedBox(height: AppSizes.xl2),
          _SectionHeader(
            title: 'Categories',
            actionLabel: AppStrings.seeAll,
            onActionTap: () => _openCatalog(
              context,
              title: 'All Grocery Products',
              subtitle: 'Browse every active grocery category',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _CategoryGrid(
            categories: categories,
            onTap: (category) => _openCatalog(
              context,
              title: category.name,
              subtitle: category.description.isNotEmpty
                  ? category.description
                  : 'Selected grocery collection',
              categoryId: category.id,
            ),
          ),
          const SizedBox(height: AppSizes.xl2),
          _SectionHeader(
            title: 'Most Popular Items',
            actionLabel: AppStrings.seeAll,
            onActionTap: () => _openCatalog(
              context,
              title: 'Popular Grocery Picks',
              subtitle: 'Top rated products customers are choosing most',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _FeaturedProductList(
            products: popularItems.take(4).toList(),
            onTap: (product) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailsScreen(product: product),
                ),
              );
            },
            onAddToCart: (product) async {
              await cartNotifier.addProduct(product);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} added to cart')),
              );
            },
          ),
          const SizedBox(height: AppSizes.xl2),
          _SectionHeader(
            title: AppStrings.newArrivals,
            actionLabel: AppStrings.seeAll,
            onActionTap: () => _openCatalog(
              context,
              title: 'New Grocery Arrivals',
              subtitle: 'Recently updated and newly stocked products',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _FeaturedProductList(
            products: newArrivals.take(4).toList(),
            onTap: (product) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailsScreen(product: product),
                ),
              );
            },
            onAddToCart: (product) async {
              await cartNotifier.addProduct(product);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} added to cart')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openCatalog(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? categoryId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductCatalogPage(
          title: title,
          subtitle: subtitle,
          initialCategoryId: categoryId,
        ),
      ),
    );
  }
}

class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.products,
    required this.onShopNow,
  });

  final List<ProductModel> products;
  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BannerImageMosaic(products: products),
          const SizedBox(height: AppSizes.xl),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              'Fresh grocery delivery',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Fresh deals for your everyday shopping.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: AppSizes.lineHeightTight,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Groceries, kitchen staples, and home picks in one smooth mobile shopping flow.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              _BannerStatChip(
                icon: Icons.local_shipping_outlined,
                label: 'Fast delivery',
              ),
              _BannerStatChip(
                icon: Icons.discount_outlined,
                label: 'Daily offers',
              ),
              _BannerStatChip(
                icon: Icons.verified_outlined,
                label: 'Trusted quality',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          GlassButton(
            label: 'Shop Now',
            prefixIcon: Icons.shopping_bag_outlined,
            onPressed: onShopNow,
          ),
        ],
      ),
    );
  }
}

class _BannerImageMosaic extends StatelessWidget {
  const _BannerImageMosaic({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = products.isNotEmpty ? products.first : null;
    final secondary = products.skip(1).take(2).toList();

    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.surface.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.14),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -12,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -28,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _BannerImageTile(
                    imageUrl: primary?.primaryImage,
                    icon: Icons.shopping_basket_outlined,
                    height: double.infinity,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: _BannerImageTile(
                          imageUrl: secondary.isNotEmpty ? secondary.first.primaryImage : null,
                          icon: Icons.local_offer_outlined,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.flash_on_rounded,
                                    color: theme.colorScheme.primary,
                                    size: AppSizes.iconMd,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'UP TO',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: AppSizes.trackingWide,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '25% OFF',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                secondary.length > 1 ? 'Fresh picks in every order' : 'Top picks for your basket',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSizes.md,
            right: AppSizes.md,
            bottom: AppSizes.md,
            child: Row(
              children: [
                Expanded(
                  child: _FloatingBannerPill(
                    icon: Icons.storefront_outlined,
                    label: '1000+ products',
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _FloatingBannerPill(
                    icon: Icons.schedule_outlined,
                    label: 'Same day slots',
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

class _BannerImageTile extends StatelessWidget {
  const _BannerImageTile({
    this.imageUrl,
    required this.icon,
    this.height,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;
  final IconData icon;
  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.65),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (validImage)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                alignment: alignment,
                errorBuilder: (_, __, ___) => _BannerImageFallback(icon: icon),
              )
            else
              _BannerImageFallback(icon: icon),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.black.withOpacity(0.22),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerImageFallback extends StatelessWidget {
  const _BannerImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.24),
            theme.colorScheme.primary.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 36,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _FloatingBannerPill extends StatelessWidget {
  const _FloatingBannerPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.80),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStatChip extends StatelessWidget {
  const _BannerStatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSizes.xs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.onTap,
  });

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const GlassCard(
        child: Text('No active categories found.'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSizes.md,
        crossAxisSpacing: AppSizes.md,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final theme = Theme.of(context);

        return InkWell(
          onTap: () => onTap(category),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    _categoryIcon(category.name),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  category.description.isNotEmpty
                      ? category.description
                      : 'Browse category products',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('rice') || value.contains('grain')) {
      return Icons.inventory_2_outlined;
    }
    if (value.contains('meat') || value.contains('poultry')) {
      return Icons.set_meal_outlined;
    }
    if (value.contains('fish')) return Icons.phishing_outlined;
    if (value.contains('spice')) return Icons.ramen_dining_outlined;
    if (value.contains('vegetable') || value.contains('fruit')) {
      return Icons.eco_outlined;
    }
    return Icons.shopping_bag_outlined;
  }
}

class _FeaturedProductList extends StatelessWidget {
  const _FeaturedProductList({
    required this.products,
    required this.onTap,
    required this.onAddToCart,
  });

  final List<ProductModel> products;
  final ValueChanged<ProductModel> onTap;
  final ValueChanged<ProductModel> onAddToCart;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const GlassCard(
        child: Text('No products available right now.'),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < products.length; index++) ...[
          _FeaturedProductCard(
            product: products[index],
            onTap: () => onTap(products[index]),
            onAddToCart: () => onAddToCart(products[index]),
          ),
          if (index != products.length - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  const _FeaturedProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = product.primaryImage.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: GlassCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: SizedBox(
                width: 88,
                height: 88,
                child: hasImage
                    ? Image.network(
                        product.primaryImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _FallbackImage(name: product.name),
                      )
                    : _FallbackImage(name: product.name),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    product.shortDescription.isNotEmpty
                        ? product.shortDescription
                        : product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Text(
                        '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      if (product.hasDiscount)
                        Text(
                          '${AppStrings.currencySymbol}${product.originalPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const Spacer(),
                      InkWell(
                        onTap: product.inStock ? onAddToCart : null,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm,
                          ),
                          decoration: BoxDecoration(
                            color: product.inStock
                                ? theme.colorScheme.primary.withOpacity(0.14)
                                : theme.disabledColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(
                              color: product.inStock
                                  ? theme.colorScheme.primary.withOpacity(0.24)
                                  : theme.dividerColor,
                            ),
                          ),
                          child: Text(
                            product.inStock ? 'ADD' : 'OUT',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: product.inStock
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      padding: const EdgeInsets.all(AppSizes.sm),
      alignment: Alignment.center,
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
