import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/offers/offer_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_details_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/products/widgets/product_list.dart';
import 'package:wafi_ecommerce_app/features/wishlist/wishlist_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key, this.immersiveShell = false});

  final bool immersiveShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerState = ref.watch(offerProvider);
    final productState = ref.watch(productProvider);
    ref.watch(cartProvider);
    ref.watch(wishlistProvider);

    final cartNotifier = ref.read(cartProvider.notifier);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final offerNotifier = ref.read(offerProvider.notifier);
    final productNotifier = ref.read(productProvider.notifier);

    final activeProducts = <String, ProductModel>{
      for (final product in productState.products)
        if (product.isActive) product.id: product,
    };

    final activeOfferIds = <String>{};
    final offeredProducts = offerState.offers
        .where((offer) {
          final product = activeProducts[offer.productId];
          if (product == null) return false;
          if (!offer.hasValidDiscount || !product.hasDiscount) return false;
          if (product.price != offer.offerPrice) return false;
          if (product.originalPrice != offer.originalPrice) return false;
          return activeOfferIds.add(offer.productId);
        })
        .map((offer) => activeProducts[offer.productId]!)
        .toList();

    final categoryLookup = <String, String>{
      for (final category in productState.categories) category.id: category.name,
    };

    final topInset = immersiveShell
        ? WafiAppBar.compactOverlayTopInset(
            context,
            hasSubtitle: false,
            revealAmount: AppSizes.xl5,
          )
        : 0.0;

    Future<void> refresh() async {
      await productNotifier.load();
      await offerNotifier.load();
    }

    if ((offerState.isLoading || productState.isLoading) &&
        offeredProducts.isEmpty &&
        !offerState.hasError) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          topInset,
          AppSizes.screenPaddingH,
          120,
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(AppSizes.xl2),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (offerState.hasError && offeredProducts.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          topInset,
          AppSizes.screenPaddingH,
          120,
        ),
        children: [
          GlassCard(
            child: Column(
              children: [
                const Icon(Icons.local_offer_outlined, size: AppSizes.iconXl),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Failed to load offers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  offerState.errorMessage ?? AppStrings.errGeneral,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                GlassButton(
                  label: AppStrings.retry,
                  prefixIcon: Icons.refresh_rounded,
                  isFullWidth: false,
                  onPressed: refresh,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (offeredProducts.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSizes.screenPaddingH,
            topInset,
            AppSizes.screenPaddingH,
            120,
          ),
          children: [
            GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.local_offer_outlined, size: AppSizes.iconXl),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No active offers right now',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Discounted products will appear here when the owner adds them.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          topInset,
          AppSizes.screenPaddingH,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Offers',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '${offeredProducts.length} discounted products are available now.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Expanded(
              child: ProductList(
                products: offeredProducts,
                viewMode: productState.viewMode,
                categoryLookup: categoryLookup,
                quantityForProduct: cartNotifier.quantityForProduct,
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
                onIncrement: (product) => cartNotifier.increment(product.id),
                onDecrement: (product) => cartNotifier.decrement(product.id),
                isWishlisted: wishlistNotifier.containsProduct,
                onToggleWishlist: (product) async {
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
            ),
          ],
        ),
      ),
    );
  }
}
