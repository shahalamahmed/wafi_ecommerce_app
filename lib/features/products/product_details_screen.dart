import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_model.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_provider.dart';
import 'package:wafi_ecommerce_app/features/wishlist/wishlist_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_snackbar.dart';
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
  int _activeImageIndex = 0;
  late final PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final wishlistState = ref.watch(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    ProductModel product = widget.product;
    for (final candidate in ref.watch(productProvider).products) {
      if (candidate.id == widget.product.id) {
        product = candidate;
        break;
      }
    }
    final productImages = product.images
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList();
    final isWishlisted = wishlistNotifier.containsProduct(product.id);
    final cartQuantity = cartNotifier.quantityForProduct(product.id);
    final effectiveQuantity = cartQuantity > 0 ? cartQuantity : _quantity;
    final canIncreaseDraft =
        _quantity < 20 && (_quantity < product.stock || product.stock <= 0);
    final canIncreaseCart =
        cartQuantity > 0 &&
        cartQuantity < 20 &&
        (cartQuantity < product.stock || product.stock <= 0);

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
              GlassSnackbar.info(
                context,
                wasWishlisted
                    ? '${product.name} removed from wishlist'
                    : '${product.name} added to wishlist',
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
                padding: EdgeInsets.zero,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppSizes.productCardRadius,
                    ), // ← -4 বাদ
                    child: productImages.isNotEmpty
                        ? PageView.builder(
                            controller: _imagePageController,
                            itemCount: productImages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _activeImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) => Image.network(
                              productImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _DetailsImageFallback(name: product.name),
                            ),
                          )
                        : _DetailsImageFallback(name: product.name),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  productImages.isEmpty ? 1 : productImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _activeImageIndex ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _activeImageIndex
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
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
                  quantity: effectiveQuantity,
                  onDecrease: cartQuantity > 0
                      ? () => cartNotifier.decrement(product.id)
                      : _quantity > 1
                      ? () {
                          setState(() {
                            _quantity--;
                          });
                        }
                      : null,
                  onIncrease: cartQuantity > 0
                      ? (canIncreaseCart
                            ? () => cartNotifier.increment(product.id)
                            : null)
                      : canIncreaseDraft
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
                  GlassSnackbar.info(
                    context,
                    wasWishlisted
                        ? '${product.name} removed from wishlist'
                        : '${product.name} added to wishlist',
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
            _ReviewsSection(product: product),
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
              _CartCountBadge(
                count: cartState.itemCount,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _StandaloneCartDetailsScreen(),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: cartQuantity <= 0
                    ? GlassButton(
                        label: AppStrings.addToCart,
                        variant: GlassButtonVariant.success,
                        onPressed: product.inStock
                            ? () async {
                                await cartNotifier.addProduct(
                                  product,
                                  quantity: _quantity,
                                );
                                if (!context.mounted) return;
                                GlassSnackbar.success(
                                  context,
                                  '${product.name} added to cart',
                                );
                              }
                            : null,
                      )
                    : _DetailsCartAction(
                        quantity: cartQuantity,
                        inStock: product.inStock,
                        primary: Theme.of(context).colorScheme.primary,
                        textStyle: Theme.of(context).textTheme.labelLarge,
                        onIncrement: canIncreaseCart
                            ? () => cartNotifier.increment(product.id)
                            : null,
                        onDecrement: () => cartNotifier.decrement(product.id),
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
                  '${AppStrings.currencySymbol}${(product.price * effectiveQuantity).toStringAsFixed(0)}',
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

class _StandaloneCartDetailsScreen extends StatelessWidget {
  const _StandaloneCartDetailsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WafiAppBar(title: AppStrings.cart, subtitle: null),
      body: const CartScreen(),
    );
  }
}

class _DetailsCartAction extends StatelessWidget {
  const _DetailsCartAction({
    required this.quantity,
    required this.inStock,
    required this.primary,
    required this.textStyle,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool inStock;
  final Color primary;
  final TextStyle? textStyle;
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

    return Container(
      height: AppSizes.buttonHeightMd,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DetailsQtyIconButton(
            icon: Icons.remove_rounded,
            color: foregroundColor,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Text(
              '$quantity',
              style: textStyle?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _DetailsQtyIconButton(
            icon: Icons.add_rounded,
            color: foregroundColor,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _DetailsQtyIconButton extends StatelessWidget {
  const _DetailsQtyIconButton({
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
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: AppSizes.iconSm, color: color),
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
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
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
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
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

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));
    final myReviewAsync = ref.watch(myProductReviewProvider(product.id));
    final eligibilityAsync = ref.watch(reviewEligibilityProvider(product.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.rating > 0
                              ? product.rating.toStringAsFixed(1)
                              : '0.0',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        _StarRatingRow(rating: product.rating),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          product.reviewCount > 0
                              ? '${product.reviewCount} review${product.reviewCount == 1 ? '' : 's'}'
                              : AppStrings.noReviews,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  myReviewAsync.when(
                    data: (myReview) {
                      return eligibilityAsync.when(
                        data: (eligibility) {
                          final canEdit = myReview != null;
                          final canWrite = eligibility.canReview;
                          final canOpenSheet = canEdit || canWrite;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GlassButton(
                                label: canEdit
                                    ? AppStrings.editReview
                                    : AppStrings.writeReview,
                                variant: canEdit
                                    ? GlassButtonVariant.ghost
                                    : GlassButtonVariant.primary,
                                isFullWidth: false,
                                onPressed: canOpenSheet
                                    ? () => _openReviewComposer(
                                        context,
                                        ref,
                                        product: product,
                                        existingReview: myReview,
                                      )
                                    : null,
                              ),
                              if (!canOpenSheet) ...[
                                const SizedBox(height: AppSizes.sm),
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    authState.user == null
                                        ? 'Sign in to write a review.'
                                        : eligibility.message ??
                                              'Only delivered buyers can review this product.',
                                    textAlign: TextAlign.right,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      );
                    },
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              myReviewAsync.when(
                data: (myReview) {
                  if (myReview == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSizes.md),
                    child: GlassChip(
                      label: 'Your review is live',
                      variant: GlassChipVariant.success,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return GlassCard(
                child: Text(
                  AppStrings.noReviews,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return Column(
              children: [
                for (final review in reviews) ...[
                  _ReviewCard(review: review),
                  if (review != reviews.last)
                    const SizedBox(height: AppSizes.md),
                ],
              ],
            );
          },
          loading: () => const GlassCard(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => GlassCard(
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openReviewComposer(
    BuildContext context,
    WidgetRef ref, {
    required ProductModel product,
    required ReviewModel? existingReview,
  }) async {
    ref.read(reviewMutationProvider.notifier).clearMessages();

    final result = await showModalBottomSheet<_ReviewComposerResult>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.lg,
            AppSizes.lg,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSizes.xl2,
          ),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            child: _ReviewComposerSheet(
              product: product,
              existingReview: existingReview,
            ),
          ),
        );
      },
    );

    if (!context.mounted || result == null) return;
    if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
      GlassSnackbar.error(context, result.errorMessage!);
      return;
    }
    if (result.successMessage != null && result.successMessage!.isNotEmpty) {
      GlassSnackbar.success(context, result.successMessage!);
    }
  }
}

class _ReviewComposerResult {
  const _ReviewComposerResult({this.successMessage, this.errorMessage});

  final String? successMessage;
  final String? errorMessage;
}

class _ReviewComposerSheet extends ConsumerStatefulWidget {
  const _ReviewComposerSheet({
    required this.product,
    required this.existingReview,
  });

  final ProductModel product;
  final ReviewModel? existingReview;

  @override
  ConsumerState<_ReviewComposerSheet> createState() =>
      _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends ConsumerState<_ReviewComposerSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _commentController;
  late int _rating;
  final Map<String, String?> _errors = <String, String?>{};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingReview?.title ?? '',
    );
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
    _rating = widget.existingReview?.rating ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nextErrors = <String, String?>{
      'rating': _rating <= 0 ? 'Select a rating.' : null,
      'title': AppValidators.required(_titleController.text),
      'comment': AppValidators.required(_commentController.text),
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });

    if (nextErrors.values.any((error) => error != null)) return;

    await ref
        .read(reviewMutationProvider.notifier)
        .submitReview(
          product: widget.product,
          rating: _rating,
          title: _titleController.text,
          comment: _commentController.text,
        );

    final mutationState = ref.read(reviewMutationProvider);
    if (!mounted) return;

    if (mutationState.errorMessage != null &&
        mutationState.errorMessage!.isNotEmpty) {
      Navigator.of(
        context,
      ).pop(_ReviewComposerResult(errorMessage: mutationState.errorMessage));
      return;
    }

    Navigator.of(context).pop(
      _ReviewComposerResult(
        successMessage:
            mutationState.successMessage ?? 'Your review has been saved.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(reviewMutationProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existingReview == null
                ? AppStrings.writeReview
                : AppStrings.editReview,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            AppStrings.rating,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          _InteractiveStarRating(
            rating: _rating,
            onChanged: (value) {
              setState(() {
                _rating = value;
                _errors['rating'] = null;
              });
            },
          ),
          if (_errors['rating'] != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              _errors['rating']!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          GlassInput(
            controller: _titleController,
            label: AppStrings.reviewTitle,
            hint: 'Summarize your experience',
            maxLength: 80,
            errorText: _errors['title'],
            onChanged: (_) {
              if (_errors['title'] != null) {
                setState(() => _errors['title'] = null);
              }
            },
          ),
          const SizedBox(height: AppSizes.md),
          GlassInput(
            controller: _commentController,
            label: AppStrings.reviewComment,
            hint: 'What did you like or dislike?',
            maxLines: 5,
            maxLength: 400,
            errorText: _errors['comment'],
            onChanged: (_) {
              if (_errors['comment'] != null) {
                setState(() => _errors['comment'] = null);
              }
            },
          ),
          const SizedBox(height: AppSizes.lg),
          GlassButton(
            label: widget.existingReview == null
                ? AppStrings.writeReview
                : AppStrings.update,
            prefixIcon: Icons.rate_review_outlined,
            isLoading: mutationState.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final createdAt = review.updatedAt ?? review.createdAt;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      review.reviewerName.isNotEmpty
                          ? review.reviewerName
                          : 'Wafi customer',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StarPill(rating: review.rating),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              if (review.isVerifiedPurchase)
                GlassChip(
                  label: AppStrings.verifiedPurchase,
                  variant: GlassChipVariant.success,
                ),
              if (createdAt != null)
                GlassChip(
                  label: _formatReviewDate(createdAt),
                  variant: GlassChipVariant.neutral,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(review.comment, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _StarPill extends StatelessWidget {
  const _StarPill({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC857).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
          const SizedBox(width: 4),
          Text(
            '$rating',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final filled = rating >= index + 1;
        final half = !filled && rating > index && rating < index + 1;
        return Icon(
          half
              ? Icons.star_half_rounded
              : filled
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          color: const Color(0xFFFFB800),
          size: 18,
        );
      }),
    );
  }
}

class _InteractiveStarRating extends StatelessWidget {
  const _InteractiveStarRating({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final value = index + 1;
        return IconButton(
          onPressed: () => onChanged(value),
          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
          padding: EdgeInsets.zero,
          icon: Icon(
            value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFB800),
            size: 30,
          ),
        );
      }),
    );
  }
}

String _formatReviewDate(DateTime date) {
  final month = switch (date.month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    _ => 'Dec',
  };
  return '${date.day} $month ${date.year}';
}

class _CartCountBadge extends StatelessWidget {
  const _CartCountBadge({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Stack(
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
      ),
    );
  }
}
