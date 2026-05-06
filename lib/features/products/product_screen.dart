import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';
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
      extendBodyBehindAppBar: true,
      appBar: WafiAppBar(title: title, subtitle: subtitle),
      body: ProductScreen(
        initialCategoryId: initialCategoryId,
        resetFiltersOnOpen: true,
        resetFiltersOnDispose: true,
        immersiveShell: true,
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
    this.immersiveShell = false,
  });

  final String? initialCategoryId;
  final bool resetFiltersOnOpen;
  final bool resetFiltersOnDispose;
  final bool immersiveShell;

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
    ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    ref.watch(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);

    final categoryLookup = <String, String>{
      for (final category in state.categories) category.id: category.name,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final topInset = widget.immersiveShell
            ? WafiAppBar.compactOverlayTopInset(
                context,
                hasSubtitle: false,
                revealAmount: AppSizes.xl5,
              )
            : 0.0;
        const searchSpacing = AppSizes.md;
        final searchHeight = AppSizes.inputHeight + searchSpacing;
        const horizontalPadding = 0.0;
        final contentTopPadding = topInset + searchHeight;

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  0,
                ),
                child: RefreshIndicator(
                  onRefresh: notifier.load,
                  child: Builder(
                    builder: (context) {
                      if (state.isLoading) {
                        return _ProductLoadingState(
                          topPadding: contentTopPadding,
                        );
                      }
                      if (state.hasError) {
                        return _ProductErrorState(
                          message: state.errorMessage!,
                          onRetry: notifier.load,
                          topPadding: contentTopPadding,
                        );
                      }
                      if (state.visibleProducts.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            0,
                            contentTopPadding,
                            0,
                            100,
                          ),
                          children: const [_ProductEmptyState()],
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(top: contentTopPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: isCompact ? 72 : 86,
                              child: _CategoryRail(
                                categories: state.activeCategories,
                                selectedCategoryId: state.selectedCategoryId,
                                onSelect: notifier.selectCategory,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (state.selectedCategory != null) ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: GlassChip(
                                        label: state.selectedCategory!.name,
                                        variant: GlassChipVariant.primary,
                                        isSelected: true,
                                        onTap: () =>
                                            notifier.selectCategory(null),
                                      ),
                                    ),
                                    const SizedBox(height: AppSizes.sm),
                                  ],
                                  Expanded(
                                    child: ProductList(
                                      products: state.visibleProducts,
                                      viewMode: state.viewMode,
                                      categoryLookup: categoryLookup,
                                      onTap: (product) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                ProductDetailsScreen(
                                                  product: product,
                                                ),
                                          ),
                                        );
                                      },
                                      onAddToCart: (product) async {
                                        await cartNotifier.addProduct(product);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: topInset,
              left: horizontalPadding,
              right: horizontalPadding,
              child: _PinnedSearchField(onChanged: notifier.setSearchQuery),
            ),
          ],
        );
      },
    );
  }
}

class _ProductLoadingState extends StatelessWidget {
  const _ProductLoadingState({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(0, topPadding, 0, 100),
      children: const [
        Padding(
          padding: EdgeInsets.all(AppSizes.xl2),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _ProductErrorState extends StatelessWidget {
  const _ProductErrorState({
    required this.message,
    required this.onRetry,
    required this.topPadding,
  });

  final String message;
  final Future<void> Function() onRetry;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(0, topPadding, 0, 100),
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
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (context, index) {
        final category = items[index];
        final isSelected = category == null
            ? selectedCategoryId == null
            : selectedCategoryId == category.id;
        final imageUrl = category?.image.trim() ?? '';
        final hasImage = imageUrl.isNotEmpty;
        final primary = theme.colorScheme.primary;

        return InkWell(
          onTap: () => onSelect(category?.id),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Container(
            height: 84,
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.14)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isSelected
                    ? primary.withValues(alpha: 0.38)
                    : theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: primary.withValues(alpha: 0.10),
                  child: category == null
                      ? Icon(_iconFor(category?.name), color: primary, size: 16)
                      : ClipOval(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: hasImage
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          _iconFor(category.name),
                                          color: primary,
                                          size: 16,
                                        ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Icon(
                                            _iconFor(category.name),
                                            color: primary,
                                            size: 16,
                                          );
                                        },
                                  )
                                : Icon(
                                    _iconFor(category.name),
                                    color: primary,
                                    size: 16,
                                  ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  category?.name ?? 'All Products',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
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

class _PinnedSearchField extends StatelessWidget {
  const _PinnedSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        border: Border.all(color: glass.borderColor.withValues(alpha: 0.24)),
      ),
      child: GlassInput(
        hint: 'Search products',
        prefixIcon: Icons.search_rounded,
        onChanged: onChanged,
        backgroundColor: Colors.transparent,
        unfocusedBorderColor: Colors.transparent,
        blurSigma: AppSizes.blurMd,
      ),
    );
  }
}
