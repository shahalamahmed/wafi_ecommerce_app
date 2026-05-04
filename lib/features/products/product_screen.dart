import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_details_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/products/widgets/product_list.dart';
import 'package:wafi_ecommerce_app/features/wishlist/wishlist_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class ProductCatalogPage extends StatelessWidget {
  const ProductCatalogPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.initialCategoryId,
  });

  final String title;
  final String subtitle;
  final String? initialCategoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WafiAppBar(title: title, subtitle: subtitle),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: ProductScreen(
          initialCategoryId: initialCategoryId,
          resetFiltersOnOpen: true,
          resetFiltersOnDispose: true,
        ),
      ),
    );
  }
}

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({
    super.key,
    this.initialCategoryId,
    this.resetFiltersOnOpen = false,
    this.resetFiltersOnDispose = false,
  });

  final String? initialCategoryId;
  final bool resetFiltersOnOpen;
  final bool resetFiltersOnDispose;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(productProvider.notifier);

      if (widget.resetFiltersOnOpen) {
        notifier.resetFilters();
      }

      if ((widget.initialCategoryId ?? '').isNotEmpty) {
        notifier.selectCategory(widget.initialCategoryId);
      }
    });
  }

  @override
  void dispose() {
    if (widget.resetFiltersOnDispose) {
      ref.read(productProvider.notifier).resetFilters();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final notifier = ref.read(productProvider.notifier);
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final wishlistState = ref.watch(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);

    final categoryLookup = <String, String>{
      for (final category in state.categories) category.id: category.name,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;

        return Column(
          children: [
            GlassInput(
              hint: 'Search products',
              prefixIcon: Icons.search_rounded,
              onChanged: notifier.setSearchQuery,
            ),
            const SizedBox(height: AppSizes.xl2),
            Expanded(
              child: RefreshIndicator(
                onRefresh: notifier.load,
                child: Builder(
                  builder: (context) {
                    if (state.isLoading) {
                      return const _ProductLoadingState();
                    }
                    if (state.hasError) {
                      return _ProductErrorState(
                        message: state.errorMessage!,
                        onRetry: notifier.load,
                      );
                    }
                    if (state.visibleProducts.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          _ProductEmptyState(),
                          SizedBox(height: 100),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: isCompact ? 86 : 110,
                          child: _CategoryRail(
                            categories: state.activeCategories,
                            selectedCategoryId: state.selectedCategoryId,
                            onSelect: notifier.selectCategory,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.selectedCategory != null) ...[
                                GlassChip(
                                  label: state.selectedCategory!.name,
                                  variant: GlassChipVariant.primary,
                                  isSelected: true,
                                  onTap: () => notifier.selectCategory(null),
                                ),
                                const SizedBox(height: AppSizes.md),
                              ],
                              Row(
                                children: [
                                  Text(
                                    '${state.visibleProducts.length} items',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Saved ${wishlistState.itemCount} | Cart ${cartState.itemCount}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.lg),
                              Expanded(
                                child: ProductList(
                                  products: state.visibleProducts,
                                  viewMode: state.viewMode,
                                  categoryLookup: categoryLookup,
                                  onTap: (product) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductDetailsScreen(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  },
                                  onAddToCart: (product) async {
                                    await cartNotifier.addProduct(product);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.name} added to cart',
                                        ),
                                      ),
                                    );
                                  },
                                  isWishlisted:
                                      wishlistNotifier.containsProduct,
                                  onToggleWishlist: (product) async {
                                    final wasWishlisted = wishlistNotifier
                                        .containsProduct(product.id);
                                    await wishlistNotifier.toggleProduct(
                                      product,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          wasWishlisted
                                              ? '${product.name} removed from wishlist'
                                              : '${product.name} added to wishlist',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductLoadingState extends StatelessWidget {
  const _ProductLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        Padding(
          padding: EdgeInsets.all(AppSizes.xl3),
          child: Center(child: CircularProgressIndicator()),
        ),
        SizedBox(height: 100),
      ],
    );
  }
}

class _ProductErrorState extends StatelessWidget {
  const _ProductErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppSizes.iconXl,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Failed to load products',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.lg),
              GlassButton(
                label: AppStrings.retry,
                prefixIcon: Icons.refresh_rounded,
                isFullWidth: false,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _ProductEmptyState extends StatelessWidget {
  const _ProductEmptyState();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: AppSizes.iconXl),
          const SizedBox(height: AppSizes.md),
          Text(
            AppStrings.emptyProducts,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Try a different search or category filter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <ProductCategory?>[null, ...categories];

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final category = items[index];
        final isSelected = category == null
            ? selectedCategoryId == null
            : selectedCategoryId == category.id;
        final imageUrl = category?.image.trim() ?? '';
        final hasImage = imageUrl.isNotEmpty;
        final primary = Theme.of(context).colorScheme.primary;

        return InkWell(
          onTap: () => onSelect(category?.id),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            height: 120,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xs,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primary.withOpacity(0.08),
                  child: category == null
                      ? Icon(_iconFor(category?.name), color: primary)
                      : ClipOval(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: hasImage
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      _iconFor(category.name),
                                      color: primary,
                                    ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Icon(
                                            _iconFor(category.name),
                                            color: primary,
                                          );
                                        },
                                  )
                                : Icon(_iconFor(category.name), color: primary),
                          ),
                        ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  category?.name ?? 'All Products',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String? name) {
    final value = (name ?? '').toLowerCase();
    if (value.contains('rice') || value.contains('grain')) {
      return Icons.inventory_2_outlined;
    }
    if (value.contains('meat') || value.contains('poultry')) {
      return Icons.set_meal_outlined;
    }
    if (value.contains('honey')) return Icons.water_drop_outlined;
    if (value.contains('spice')) return Icons.ramen_dining_outlined;
    if (value.contains('oil')) return Icons.local_drink_outlined;
    return Icons.shopping_bag_outlined;
  }
}
