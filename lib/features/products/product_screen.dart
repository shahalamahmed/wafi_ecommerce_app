import 'dart:ui';

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
  bool _didApplyInitialCategory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(productProvider.notifier);

      if (widget.resetFiltersOnOpen) {
        notifier.resetFilters();
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
    final shouldPreferInitialCategory =
        !_didApplyInitialCategory &&
        (widget.initialCategoryId?.trim().isNotEmpty ?? false);
    final resolvedSelection = _resolveSelection(
      state,
      preferredCategoryId: widget.initialCategoryId,
      preferInitialCategory: shouldPreferInitialCategory,
    );
    final selectedParentCategory = resolvedSelection.parent;
    final visibleSubCategories = selectedParentCategory == null
        ? const <ProductCategory>[]
        : (state.categories
              .where(
                (category) =>
                    category.isActive &&
                    category.parentId == selectedParentCategory.id,
              )
              .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)));
    final showSubCategoryBar =
        selectedParentCategory != null && visibleSubCategories.isNotEmpty;

    _applyInitialCategorySelectionIfNeeded(state);

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
                                categories: state.topLevelCategories,
                                selectedCategoryId: selectedParentCategory?.id,
                                onSelect: notifier.selectCategory,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showSubCategoryBar) ...[
                                    _SubCategorySelector(
                                      subCategories: visibleSubCategories,
                                      selectedSubCategoryId:
                                          state.selectedSubCategoryId,
                                      onSelect: notifier.selectSubCategory,
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
              child: _PinnedSearchRow(
                searchQuery: state.searchQuery,
                activeFilterCount: state.activeFilterCount,
                onChanged: notifier.setSearchQuery,
                onOpenFilters: () => _openFilterSheet(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(productProvider);
              final notifier = ref.read(productProvider.notifier);
              final theme = Theme.of(context);
              final glass = theme.extension<GlassTheme>()!;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.md,
                  MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: glass.elevatedColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                    border: Border.all(
                      color: glass.borderColor.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glass.shadowColor.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.xl,
                        AppSizes.xl,
                        AppSizes.xl,
                        AppSizes.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Filter Products',
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: AppSizes.xs),
                                    Text(
                                      'Refine the catalog by stock, and price order.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.lg),
                          _FilterSection(
                            title: 'Quick Filters',
                            child: Wrap(
                              spacing: AppSizes.sm,
                              runSpacing: AppSizes.sm,
                              children: [
                                _FilterChipButton(
                                  label: 'In Stock',
                                  icon: Icons.inventory_2_outlined,
                                  selected: state.inStockOnly,
                                  onTap: notifier.toggleInStockOnly,
                                ),
                                _FilterChipButton(
                                  label: 'Low Stock',
                                  icon: Icons.warning_amber_rounded,
                                  selected: state.lowStockOnly,
                                  onTap: notifier.toggleLowStockOnly,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          _FilterSection(
                            title: 'Sort By',
                            child: Column(
                              children: [
                                for (final option in ProductSortOption.values
                                    .where((o) => o != ProductSortOption.topRated))
                                  _SortOptionTile(
                                    label: _sortLabel(option),
                                    subtitle: _sortSubtitle(option),
                                    selected: state.sortOption == option,
                                    onTap: () => notifier.setSortOption(option),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Row(
                            children: [
                              Expanded(
                                child: GlassButton(
                                  label: 'Reset',
                                  variant: GlassButtonVariant.ghost,
                                  onPressed: notifier.resetFilters,
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: GlassButton(
                                  label: 'Done',
                                  suffixIcon: Icons.arrow_forward_rounded,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _sortLabel(ProductSortOption option) {
    return switch (option) {
      ProductSortOption.newest => 'Newest First',
      ProductSortOption.priceLowToHigh => 'Price: Low to High',
      ProductSortOption.priceHighToLow => 'Price: High to Low',
      _ => '',
    };
  }

  String _sortSubtitle(ProductSortOption option) {
    return switch (option) {
      ProductSortOption.newest => 'Show recently updated items first.',
      ProductSortOption.priceLowToHigh => 'Surface the most affordable products first.',
      ProductSortOption.priceHighToLow => 'Bring premium and higher-ticket items to the top.',
      _ => '',
    };
  }

  void _applyInitialCategorySelectionIfNeeded(ProductState state) {
    final initialCategoryId = widget.initialCategoryId?.trim() ?? '';
    if (_didApplyInitialCategory || state.isLoading || initialCategoryId.isEmpty) {
      return;
    }

    final resolved = _resolveSelection(
      state,
      preferredCategoryId: initialCategoryId,
      preferInitialCategory: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didApplyInitialCategory) return;
      final notifier = ref.read(productProvider.notifier);
      _didApplyInitialCategory = true;
      notifier.selectCategory(resolved.parent?.id);
      notifier.selectSubCategory(resolved.subCategory?.id);
    });
  }

  _ResolvedCategorySelection _resolveSelection(
    ProductState state, {
    required String? preferredCategoryId,
    required bool preferInitialCategory,
  }) {
    ProductCategory? selectedCategory;

    if (preferInitialCategory) {
      final initialCategoryId = preferredCategoryId?.trim() ?? '';
      if (initialCategoryId.isNotEmpty) {
        for (final category in state.categories) {
          if (category.id == initialCategoryId) {
            selectedCategory = category;
            break;
          }
        }
      }
    } else {
      selectedCategory = state.selectedCategory;
    }

    if (selectedCategory == null) {
      return const _ResolvedCategorySelection(parent: null, subCategory: null);
    }

    if (selectedCategory.isTopLevel) {
      final selectedSubCategoryId = preferInitialCategory
          ? null
          : state.selectedSubCategoryId;
      ProductCategory? selectedSubCategory;
      if ((selectedSubCategoryId ?? '').isNotEmpty) {
        for (final category in state.categories) {
          if (category.id == selectedSubCategoryId) {
            selectedSubCategory = category;
            break;
          }
        }
      }
      return _ResolvedCategorySelection(
        parent: selectedCategory,
        subCategory: selectedSubCategory,
      );
    }

    ProductCategory? parentCategory;
    final parentId = selectedCategory.parentId;
    if ((parentId ?? '').isNotEmpty) {
      for (final category in state.categories) {
        if (category.id == parentId) {
          parentCategory = category;
          break;
        }
      }
    }

    return _ResolvedCategorySelection(
      parent: parentCategory,
      subCategory: selectedCategory,
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

class _SubCategorySelector extends StatelessWidget {
  const _SubCategorySelector({
    required this.subCategories,
    required this.selectedSubCategoryId,
    required this.onSelect,
  });

  final List<ProductCategory> subCategories;
  final String? selectedSubCategoryId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: subCategories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: AppSizes.xs),
        itemBuilder: (context, index) {
          final isAllChip = index == 0;
          final category = isAllChip ? null : subCategories[index - 1];
          final isSelected = isAllChip
              ? (selectedSubCategoryId == null || selectedSubCategoryId!.isEmpty)
              : selectedSubCategoryId == category!.id;

          return GlassChip(
            label: category?.name ?? 'All',
            variant: GlassChipVariant.primary,
            isSelected: isSelected,
            onTap: () => onSelect(category?.id),
          );
        },
      ),
    );
  }
}

class _ResolvedCategorySelection {
  const _ResolvedCategorySelection({
    required this.parent,
    required this.subCategory,
  });

  final ProductCategory? parent;
  final ProductCategory? subCategory;
}

class _PinnedSearchRow extends StatelessWidget {
  const _PinnedSearchRow({
    required this.searchQuery,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onOpenFilters,
  });

  final String searchQuery;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;

    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              border: Border.all(
                color: glass.borderColor.withValues(alpha: 0.24),
              ),
            ),
            child: GlassInput(
              hint: 'Search products',
              prefixIcon: Icons.search_rounded,
              onChanged: onChanged,
              backgroundColor: Colors.transparent,
              unfocusedBorderColor: Colors.transparent,
              blurSigma: AppSizes.blurMd,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        _FilterActionButton(
          hasActiveFilters: activeFilterCount > 0,
          activeFilterCount: activeFilterCount,
          onTap: onOpenFilters,
        ),
      ],
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.hasActiveFilters,
    required this.activeFilterCount,
    required this.onTap,
  });

  final bool hasActiveFilters;
  final int activeFilterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        child: Ink(
          height: AppSizes.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          decoration: BoxDecoration(
            color: glass.cardColor.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            border: Border.all(
              color: hasActiveFilters
                  ? primary.withValues(alpha: 0.42)
                  : glass.borderColor.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: hasActiveFilters
                        ? primary
                        : theme.iconTheme.color?.withValues(alpha: 0.82),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSizes.sm),

            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: glass.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: glass.borderColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animFast),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.28,
                ),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.42)
                : theme.colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? primary : null),
            const SizedBox(width: AppSizes.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppSizes.animFast),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.40)
                  : theme.dividerColor.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? primary : theme.iconTheme.color,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
