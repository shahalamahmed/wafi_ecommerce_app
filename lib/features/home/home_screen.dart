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
          _HeroSection(
            products: products.take(3).toList(),
            onPrimaryTap: () => _openCatalog(
              context,
              title: 'All Grocery Products',
              subtitle: 'Fresh picks, daily essentials, and pantry staples',
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionTile(
            dark: true,
            header: _SectionHeader(
              eyebrow: 'Collections',
              title: 'Browse by category.',
              subtitle:
                  'A lighter way to move through pantry, produce, protein, and household staples.',
              actionLabel: AppStrings.seeAll,
              onActionTap: () => _openCatalog(
                context,
                title: 'All Grocery Products',
                subtitle: 'Browse every active grocery category',
              ),
            ),
            child: _CategoryRailGrid(
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
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionTile(
            header: _SectionHeader(
              eyebrow: 'Popular Now',
              title: 'Most popular items.',
              subtitle:
                  'Top rated grocery picks, arranged as clean product cards with quick actions.',
              actionLabel: AppStrings.seeAll,
              onActionTap: () => _openCatalog(
                context,
                title: 'Popular Grocery Picks',
                subtitle: 'Top rated products customers are choosing most',
              ),
            ),
            child: _HorizontalProductStrip(
              products: popularItems.take(6).toList(),
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
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionTile(
            dark: true,
            header: _SectionHeader(
              eyebrow: 'New This Week',
              title: 'Fresh arrivals.',
              subtitle:
                  'Newly stocked essentials with a darker, editorial product stage.',
              actionLabel: AppStrings.seeAll,
              onActionTap: () => _openCatalog(
                context,
                title: 'New Grocery Arrivals',
                subtitle: 'Recently updated and newly stocked products',
              ),
            ),
            child: _NewArrivalStack(
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.products,
    required this.onPrimaryTap,
  });

  final List<ProductModel> products;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 18,
            right: 18,
            child: _LiquidOrb(size: 120),
          ),
          const Positioned(
            bottom: 36,
            left: 16,
            child: _LiquidOrb(size: 82, reverse: true),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassEyebrow(label: 'Fresh Grocery Delivery'),
                const SizedBox(height: AppSizes.xl),
                Text(
                  'A cleaner way to shop daily essentials.',
                  style: theme.textTheme.displayLarge,
                ),
                const SizedBox(height: AppSizes.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Text(
                    'Use the Apple-inspired layout as the base, then add liquid glass depth, frosted chips, and gentle motion across hero, cards, and nav.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    SizedBox(
                      width: 154,
                      child: GlassButton(
                        label: 'Shop now',
                        onPressed: onPrimaryTap,
                      ),
                    ),
                    SizedBox(
                      width: 154,
                      child: GlassButton(
                        label: 'Learn more',
                        variant: GlassButtonVariant.ghost,
                        onPressed: onPrimaryTap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl2),
                _HeroShowcase(products: products),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroShowcase extends StatelessWidget {
  const _HeroShowcase({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: _AnimatedProductStage(
              product: products.isNotEmpty ? products.first : null,
              dark: false,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: _HeroInfoPanel(
                    title: 'Daily offers',
                    value: 'Up to 25% off',
                    subtitle: 'Quiet blue actions, minimal chrome.',
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Expanded(
                  child: _AnimatedProductStage(
                    product: products.length > 1 ? products[1] : null,
                    dark: true,
                    compact: true,
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

class _HeroInfoPanel extends StatelessWidget {
  const _HeroInfoPanel({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: AppSizes.trackingWidest,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AnimatedProductStage extends StatelessWidget {
  const _AnimatedProductStage({
    required this.product,
    required this.dark,
    this.compact = false,
  });

  final ProductModel? product;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = product?.primaryImage.trim().isNotEmpty ?? false;
    final bg = dark ? const Color(0xFF272729) : const Color(0xFFF5F5F7);
    final fg = dark ? Colors.white : theme.colorScheme.onSurface;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: AppSizes.animVerySlow),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: EdgeInsets.all(compact ? AppSizes.lg : AppSizes.xl),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: compact ? 72 : 96,
                height: compact ? 72 : 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(dark ? 0.08 : 0.7),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? 'Curated grocery picks',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(color: fg),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  product?.shortDescription.isNotEmpty == true
                      ? product!.shortDescription
                      : 'Photography-first product staging with soft depth.',
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: dark ? const Color(0xFFCCCCCC) : null,
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: compact ? 4 : 7,
                  child: Center(
                    child: hasImage
                        ? Container(
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x38000000),
                                  blurRadius: 30,
                                  offset: Offset(3, 5),
                                ),
                              ],
                            ),
                            child: Image.network(
                              product!.primaryImage,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _FallbackStage(
                                icon: Icons.shopping_bag_outlined,
                                dark: dark,
                              ),
                            ),
                          )
                        : _FallbackStage(
                            icon: Icons.shopping_bag_outlined,
                            dark: dark,
                          ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _FrostedStatBar(
                dark: dark,
                leftLabel: 'Fresh picks',
                rightLabel: product == null
                    ? 'Gallery layout'
                    : '${AppStrings.currencySymbol}${product!.price.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackStage extends StatelessWidget {
  const _FallbackStage({
    required this.icon,
    required this.dark,
  });

  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? Colors.white.withOpacity(0.08) : Colors.white,
      ),
      child: Icon(
        icon,
        size: 44,
        color: dark ? Colors.white : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _FrostedStatBar extends StatelessWidget {
  const _FrostedStatBar({
    required this.dark,
    required this.leftLabel,
    required this.rightLabel,
  });

  final bool dark;
  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.blurMd,
          sigmaY: AppSizes.blurMd,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: Colors.white.withOpacity(dark ? 0.16 : 0.8),
            ),
          ),
          child: Row(
            children: [
              Text(
                leftLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                    ),
              ),
              const Spacer(),
              Text(
                rightLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.header,
    required this.child,
    this.dark = false,
  });

  final Widget header;
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark ? const Color(0xFF272729) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppSizes.xl2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: dark ? Colors.white : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: AppSizes.xl),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkParent = DefaultTextStyle.of(context).style.color == Colors.white;

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
                  color: darkParent
                      ? const Color(0xFF2997FF)
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppSizes.trackingWidest,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                title,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: darkParent ? Colors.white : null,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: darkParent ? const Color(0xFFCCCCCC) : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.lg),
        SizedBox(
          width: 124,
          child: GlassButton(
            label: actionLabel,
            variant: GlassButtonVariant.ghost,
            onPressed: onActionTap,
          ),
        ),
      ],
    );
  }
}

class _CategoryRailGrid extends StatelessWidget {
  const _CategoryRailGrid({
    required this.categories,
    required this.onTap,
  });

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const GlassCard(child: Text('No active categories found.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 920
            ? 4
            : width > 640
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSizes.md,
            crossAxisSpacing: AppSizes.md,
            childAspectRatio: 1.06,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return GlassTappableCard(
              onTap: () => onTap(category),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      _categoryIcon(category.name),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    category.description.isNotEmpty
                        ? category.description
                        : 'Browse category products',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFCCCCCC),
                        ),
                  ),
                ],
              ),
            );
          },
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
      return const GlassCard(child: Text('No products available right now.'));
    }

    return SizedBox(
      height: 330,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 238,
            child: _ProductGalleryCard(
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

class _ProductGalleryCard extends StatelessWidget {
  const _ProductGalleryCard({
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

    return GlassTappableCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Center(
                child: hasImage
                    ? Container(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x38000000),
                              blurRadius: 30,
                              offset: Offset(3, 5),
                            ),
                          ],
                        ),
                        child: Image.network(
                          product.primaryImage,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _FallbackStage(
                            icon: Icons.shopping_basket_outlined,
                            dark: false,
                          ),
                        ),
                      )
                    : const _FallbackStage(
                        icon: Icons.shopping_basket_outlined,
                        dark: false,
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
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
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Text(
                '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              SizedBox(
                width: 94,
                child: GlassButton(
                  label: product.inStock ? 'Buy' : 'Sold out',
                  onPressed: product.inStock ? onAddToCart : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewArrivalStack extends StatelessWidget {
  const _NewArrivalStack({
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
      return const GlassCard(child: Text('No products available right now.'));
    }

    return Column(
      children: [
        for (var i = 0; i < products.length; i++) ...[
          _EditorialRowCard(
            product: products[i],
            reverse: i.isOdd,
            onTap: () => onTap(products[i]),
            onAddToCart: () => onAddToCart(products[i]),
          ),
          if (i != products.length - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}

class _EditorialRowCard extends StatelessWidget {
  const _EditorialRowCard({
    required this.product,
    required this.reverse,
    required this.onTap,
    required this.onAddToCart,
  });

  final ProductModel product;
  final bool reverse;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = product.primaryImage.trim().isNotEmpty;
    final image = Expanded(
      flex: 5,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2C),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Center(
          child: hasImage
              ? Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x42000000),
                        blurRadius: 30,
                        offset: Offset(3, 5),
                      ),
                    ],
                  ),
                  child: Image.network(
                    product.primaryImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _FallbackStage(
                      icon: Icons.local_mall_outlined,
                      dark: true,
                    ),
                  ),
                )
              : const _FallbackStage(
                  icon: Icons.local_mall_outlined,
                  dark: true,
                ),
        ),
      ),
    );

    final copy = Expanded(
      flex: 6,
      child: GlassCard(
        variant: GlassCardVariant.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GlassEyebrow(label: 'New arrival'),
            const SizedBox(height: AppSizes.lg),
            Text(
              product.name,
              style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              product.shortDescription.isNotEmpty
                  ? product.shortDescription
                  : product.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFCCCCCC),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 108,
                  child: GlassButton(
                    label: 'Details',
                    variant: GlassButtonVariant.ghost,
                    onPressed: onTap,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                SizedBox(
                  width: 108,
                  child: GlassButton(
                    label: 'Add',
                    onPressed: product.inStock ? onAddToCart : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: reverse
            ? [copy, const SizedBox(width: AppSizes.md), image]
            : [image, const SizedBox(width: AppSizes.md), copy],
      ),
    );
  }
}

class _GlassEyebrow extends StatelessWidget {
  const _GlassEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.blurMd,
          sigmaY: AppSizes.blurMd,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _LiquidOrb extends StatefulWidget {
  const _LiquidOrb({
    required this.size,
    this.reverse = false,
  });

  final double size;
  final bool reverse;

  @override
  State<_LiquidOrb> createState() => _LiquidOrbState();
}

class _LiquidOrbState extends State<_LiquidOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        final dx = widget.reverse ? -10 + (value * 20) : 10 - (value * 20);
        final dy = widget.reverse ? 6 - (value * 12) : -6 + (value * 12);

        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSizes.blurLg,
            sigmaY: AppSizes.blurLg,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.95),
                  const Color(0x800066CC),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.55)),
            ),
          ),
        ),
      ),
    );
  }
}
