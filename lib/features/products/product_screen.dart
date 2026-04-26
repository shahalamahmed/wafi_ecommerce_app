import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_details_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/products/widgets/product_list.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    final notifier = ref.read(productProvider.notifier);
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final categoryLookup = <String, String>{
      for (final category in state.categories) category.id: category.name,
    };

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    GlassInput(
                      label: AppStrings.search,
                      hint: 'Search',
                      prefixIcon: Icons.search_rounded,
                      onChanged: notifier.setSearchQuery,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl2),
              if (state.isLoading)
                const _ProductLoadingState()
              else if (state.hasError)
                _ProductErrorState(
                  message: state.errorMessage!,
                  onRetry: notifier.load,
                )
              else if (state.visibleProducts.isEmpty)
                const _ProductEmptyState()
              else
                SizedBox(
                  height: isCompact ? 860 : 900,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: isCompact ? 116 : 148,
                        child: _CategoryRail(
                          categories: state.topLevelCategories,
                          selectedCategoryId: state.selectedCategoryId,
                          onSelect: notifier.selectCategory,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...state.subCategories.expand(
                                    (category) => [
                                      GlassChip(
                                        label: category.name.toUpperCase(),
                                        variant: GlassChipVariant.primary,
                                        isSelected: state.selectedSubCategoryId == category.id,
                                        onTap: () => notifier.selectSubCategory(category.id),
                                      ),
                                      const SizedBox(width: AppSizes.sm),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSizes.lg),
                            Row(
                              children: [
                                Text(
                                  '${state.visibleProducts.length} items',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                Text(
                                  'Cart ${cartState.itemCount}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.lg),
                            Expanded(
                              child: SingleChildScrollView(
                                child: ProductList(
                                  products: state.visibleProducts,
                                  viewMode: state.viewMode,
                                  categoryLookup: categoryLookup,
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductLoadingState extends StatelessWidget {
  const _ProductLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.xl3),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ProductErrorState extends StatelessWidget {
  const _ProductErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final category = items[index];
        final isSelected = category == null
            ? selectedCategoryId == null
            : selectedCategoryId == category.id;

        return InkWell(
          onTap: () => onSelect(category?.id),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
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
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  child: Icon(
                    _iconFor(category?.name),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  category?.name ?? 'All Products',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
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
    if (value.contains('rice') || value.contains('grain')) return Icons.inventory_2_outlined;
    if (value.contains('meat') || value.contains('poultry')) return Icons.set_meal_outlined;
    if (value.contains('honey')) return Icons.water_drop_outlined;
    if (value.contains('spice')) return Icons.ramen_dining_outlined;
    if (value.contains('oil')) return Icons.local_drink_outlined;
    return Icons.shopping_bag_outlined;
  }
}
