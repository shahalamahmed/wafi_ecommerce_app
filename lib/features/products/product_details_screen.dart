import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/wishlist/wishlist_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ProductModel product;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final wishlistState = ref.watch(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final product = widget.product;
    final isWishlisted = wishlistNotifier.containsProduct(product.id);

    return Scaffold(
      appBar: WafiAppBar(
        title: product.name,
        subtitle: product.shortDescription.trim().isNotEmpty
            ? product.shortDescription
            : AppStrings.productDetails,
        actions: [
          IconButton(
            onPressed: () async {
              final wasWishlisted = wishlistNotifier.containsProduct(
                product.id,
              );
              await wishlistNotifier.toggleProduct(product);
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
            tooltip: isWishlisted
                ? AppStrings.removeFromWishlist
                : AppStrings.addToWishlist,
            icon: Icon(
              isWishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isWishlisted ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          AppSizes.lg,
          AppSizes.screenPaddingH,
          120,
        ),
        children: [
          Column(
            children: [
              GlassCard(
                variant: GlassCardVariant.elevated,
                padding: EdgeInsets.zero,  // ← padding শূন্য
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.productCardRadius),  // ← -4 বাদ
                    child: product.primaryImage.trim().isNotEmpty
                        ? Image.network(
                      product.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _DetailsImageFallback(name: product.name),
                    )
                        : _DetailsImageFallback(name: product.name),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  product.images.isEmpty ? 1 : product.images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == 0 ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.xl2),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: AppSizes.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${AppStrings.currencySymbol}${product.originalPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (product.hasDiscount) ...[
            const SizedBox(height: AppSizes.sm),
            GlassChip(
              label: 'Save ${product.discountPercent}% today',
              variant: GlassChipVariant.error,
            ),
          ],

          const SizedBox(height: AppSizes.lg),

          Text(
            AppStrings.quantity,
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: AppSizes.md),

          Row(
            children: [
              Expanded(
                child: _QuantitySelector(
                  quantity: _quantity,
                  onDecrease: _quantity > 1
                      ? () {
                          setState(() {
                            _quantity--;
                          });
                        }
                      : null,
                  onIncrease: _quantity < 20 && _quantity < product.stock
                      ? () {
                          setState(() {
                            _quantity++;
                          });
                        }
                      : null,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              if (product.sku.trim().isNotEmpty)
                Expanded(
                  child: _OptionTile(
                    label: product.sku,
                    isSelected: false,
                    onTap: () {},
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSizes.lg),

          Row(
            children: [
              GlassChip(
                label: product.inStock
                    ? AppStrings.inStock
                    : AppStrings.outOfStock,
                variant: product.inStock
                    ? GlassChipVariant.success
                    : GlassChipVariant.error,
              ),
              const SizedBox(width: AppSizes.sm),
              if (product.isLowStock)
                GlassChip(
                  label: 'Only ${product.stock} left',
                  variant: GlassChipVariant.warning,
                ),
              const Spacer(),
              GlassChip(
                label: wishlistState.itemCount > 0
                    ? 'Saved ${wishlistState.itemCount}'
                    : AppStrings.wishlist,
                variant: isWishlisted
                    ? GlassChipVariant.error
                    : GlassChipVariant.primary,
                onTap: () async {
                  final wasWishlisted = wishlistNotifier.containsProduct(
                    product.id,
                  );
                  await wishlistNotifier.toggleProduct(product);
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
            ],
          ),

          const SizedBox(height: AppSizes.xl2),

          _SectionTabs(
            activeIndex: _activeTab,
            onChanged: (index) => setState(() => _activeTab = index),
          ),

          const SizedBox(height: AppSizes.lg),

          if (_activeTab == 0)
            _HighlightsSection(product: product)
          else if (_activeTab == 1)
            _DetailsSection(product: product)
          else
            const _ReviewsSection(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPaddingH,
            AppSizes.md,
            AppSizes.screenPaddingH,
            AppSizes.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              _CartCountBadge(count: cartState.itemCount),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: GlassButton(
                  label: AppStrings.addToCart,
                  variant: GlassButtonVariant.success,
                  onPressed: product.inStock
                      ? () async {
                          await cartNotifier.addProduct(
                            product,
                            quantity: _quantity,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                            ),
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Text(
                  '${AppStrings.currencySymbol}${(product.price * _quantity).toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded),
            color: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: Text(
              '$quantity unit',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _DetailsImageFallback extends StatelessWidget {
  const _DetailsImageFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSizes.xl2),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.activeIndex, required this.onChanged});

  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = ['Highlights', 'Details', 'Reviews'];

    return Row(
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                decoration: BoxDecoration(
                  color: index == activeIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: index == activeIndex ? Colors.white : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final points = <String>[
      if (product.shortDescription.trim().isNotEmpty) product.shortDescription,
      if (product.description.trim().isNotEmpty) product.description,
      if (product.sku.trim().isNotEmpty) 'SKU: ${product.sku}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: Text(point, style: Theme.of(context).textTheme.bodyLarge),
            ),
          )
          .toList(),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name: ${product.name}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Category ID: ${product.categoryId}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Stock: ${product.stock}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            product.description.trim().isNotEmpty
                ? product.description
                : product.shortDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text(
        AppStrings.noReviews,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _CartCountBadge extends StatelessWidget {
  const _CartCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '$count',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
