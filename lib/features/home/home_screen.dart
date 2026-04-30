import 'dart:ui';

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
    final products =
    productState.products.where((p) => p.isActive).toList();

    final popularItems = [...products]
      ..sort((a, b) {
        final scoreA = (a.rating * 1000) + a.reviewCount;
        final scoreB = (b.rating * 1000) + b.reviewCount;
        return scoreB.compareTo(scoreA);
      });

    final newArrivals = [...products]
      ..sort((a, b) {
        final dateA =
            a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    return RefreshIndicator(
      onRefresh: () => ref.read(productProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          AppSizes.md,
          AppSizes.screenPaddingH,
          AppSizes.xl4,
        ),
        children: [
          _HeroBanner(
            onShopTap: () => _openCatalog(
              context,
              title: 'All Products',
              subtitle: 'Fresh picks, daily essentials, and pantry staples',
            ),
          ),

          const SizedBox(height: AppSizes.lg),
          _SectionWrapper(
            dark: true,
            child: _SectionHeader(
              eyebrow: 'Collections',
              title: 'Browse by category.',
              actionLabel: AppStrings.seeAll,
              onActionTap: () => _openCatalog(
                context,
                title: 'All Products',
                subtitle: 'Browse every active category',
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionWrapper(
            dark: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.lg),
                _CategoryGrid(
                  categories: categories,
                  onTap: (cat) => _openCatalog(
                    context,
                    title: cat.name,
                    subtitle: cat.description.isNotEmpty
                        ? cat.description
                        : 'Selected collection',
                    categoryId: cat.id,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),
          _SectionWrapper(
            child: _SectionHeader(
              eyebrow: 'Popular Now',
              title: 'Most popular items.',
              actionLabel: AppStrings.seeAll,
              onActionTap: () => _openCatalog(
                context,
                title: 'Popular Picks',
                subtitle: 'Top rated products',
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HorizontalProductStrip(
                  products: popularItems.take(6).toList(),
                  onTap: (p) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailsScreen(product: p),
                    ),
                  ),
                  onAddToCart: (p) async {
                    await cartNotifier.addProduct(p);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${p.name} added to cart')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),
          _SectionWrapper(
            dark: true,
            child: _SectionHeader(
              eyebrow: 'New This Week',
              title: 'Fresh arrivals.',
              actionLabel: AppStrings.seeAll,
              onActionTap: () => _openCatalog(
                context,
                title: 'New Arrivals',
                subtitle: 'Recently stocked products',
              ),
            ),
          ),
          _SectionWrapper(
            dark: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.lg),
                _NewArrivalStrip(
                  products: newArrivals.take(6).toList(),
                  onTap: (p) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailsScreen(product: p),
                    ),
                  ),
                  onAddToCart: (p) async {
                    await cartNotifier.addProduct(p);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${p.name} added to cart')),
                    );
                  },
                ),
              ],
            ),
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onShopTap});

  final VoidCallback onShopTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;


    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
      child: Container(
        color: theme.colorScheme.surface,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: _Orb(size: 150, color: primary.withOpacity(0.11)),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: _Orb(size: 110, color: primary.withOpacity(0.07)),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSizes.xl2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EyebrowChip(label: 'Fresh Grocery Delivery'),
                  const SizedBox(height: AppSizes.lg),

                  Text(
                    'A cleaner way\nto shop daily\nessentials.',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.md),

                  Text(
                    'Fresh picks, daily essentials, and pantry staples — delivered.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xl),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onShopTap,
                          child: const Text('Shop now'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onShopTap,
                          child: const Text('Learn more'),
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

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.md),
        GestureDetector(
          onTap: onActionTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(color: primary.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: primary,
                ),
              ],
            ),
          ),
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
      return const GlassCard(child: Text('No categories found.'));
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryCard(category: cat, onTap: () => onTap(cat));
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  _iconFor(category.name),
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                category.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    final v = name.toLowerCase();
    if (v.contains('rice') || v.contains('grain') || v.contains('pulse')) {
      return Icons.inventory_2_outlined;
    }
    if (v.contains('meat') || v.contains('poultry') || v.contains('chicken')) {
      return Icons.set_meal_outlined;
    }
    if (v.contains('fish') || v.contains('seafood')) {
      return Icons.phishing_outlined;
    }
    if (v.contains('spice') || v.contains('masala')) {
      return Icons.ramen_dining_outlined;
    }
    if (v.contains('honey')) return Icons.hive_outlined;
    if (v.contains('oil')) return Icons.opacity_outlined;
    if (v.contains('vegetable') || v.contains('fruit') || v.contains('fresh')) {
      return Icons.eco_outlined;
    }
    if (v.contains('dairy') || v.contains('milk')) {
      return Icons.water_drop_outlined;
    }
    if (v.contains('snack') || v.contains('biscuit')) {
      return Icons.cookie_outlined;
    }
    if (v.contains('super') || v.contains('health')) {
      return Icons.spa_outlined;
    }
    return Icons.shopping_bag_outlined;
  }
}


class _HorizontalProductStrip extends StatelessWidget {
  const _HorizontalProductStrip({
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
      return const GlassCard(child: Text('No products available.'));
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 180,
            child: _ProductCard(
              product: product,
              onTap: () => onTap(product),
              onAddToCart: () => onAddToCart(product),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
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
    final primary = theme.colorScheme.primary;
    final hasImage = product.primaryImage.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: Center(
                  child: hasImage
                      ? Image.network(
                    product.primaryImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.shopping_basket_outlined,
                      size: 36,
                      color: primary,
                    ),
                  )
                      : Icon(
                    Icons.shopping_basket_outlined,
                    size: 36,
                    color: primary,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    product.shortDescription.isNotEmpty
                        ? product.shortDescription
                        : product.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: product.inStock ? onAddToCart : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.xs,
                          ),
                          decoration: BoxDecoration(
                            color: product.inStock
                                ? primary.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                            border: Border.all(
                              color: product.inStock
                                  ? primary.withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            product.inStock ? 'ADD' : 'OUT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: product.inStock ? primary : Colors.grey,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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

class _NewArrivalStrip extends StatelessWidget {
  const _NewArrivalStrip({
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
      return const GlassCard(child: Text('No new arrivals.'));
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 200,
            child: _NewArrivalCard(
              product: product,
              onTap: () => onTap(product),
              onAddToCart: () => onAddToCart(product),
            ),
          );
        },
      ),
    );
  }
}

class _NewArrivalCard extends StatelessWidget {
  const _NewArrivalCard({
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
    final primary = theme.colorScheme.primary;
    final hasImage = product.primaryImage.trim().isNotEmpty;
    final cardBg = theme.colorScheme.surfaceContainerHighest;
    final imgBg  = theme.colorScheme.surfaceContainerHighest.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: imgBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: Center(
                  child: hasImage
                      ? Image.network(
                    product.primaryImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_mall_outlined,
                      size: 36,
                      color: primary,
                    ),
                  )
                      : Icon(
                    Icons.local_mall_outlined,
                    size: 36,
                    color: primary,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'NEW',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    product.shortDescription.isNotEmpty
                        ? product.shortDescription
                        : product.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      GestureDetector(
                        onTap: product.inStock ? onAddToCart : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.xs,
                          ),
                          decoration: BoxDecoration(
                            color: product.inStock
                                ? primary
                                : Colors.grey.withOpacity(0.3),
                            borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            product.inStock ? 'ADD' : 'OUT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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

class _EyebrowChip extends StatelessWidget {
  const _EyebrowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: primary.withOpacity(0.20)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}