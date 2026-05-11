import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_details_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/features/wishlist/wishlist_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider);
    ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    ref.watch(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);

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

    final categories = productState.activeCategories;
    final products = productState.products.where((p) => p.isActive).toList();
    final topLevelCategories = categories.where((category) {
      return category.isTopLevel;
    }).toList()..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final popularItems = [...products]
      ..sort((a, b) {
        final scoreA = (a.rating * 1000) + a.reviewCount;
        final scoreB = (b.rating * 1000) + b.reviewCount;
        return scoreB.compareTo(scoreA);
      });

    final newArrivals = [...products]
      ..sort((a, b) => _productTimestamp(b).compareTo(_productTimestamp(a)));

    final specialOffers = products.where((p) => p.hasDiscount).toList()
      ..sort((a, b) {
        final discountCompare = b.discountPercent.compareTo(a.discountPercent);
        if (discountCompare != 0) return discountCompare;
        return _productTimestamp(b).compareTo(_productTimestamp(a));
      });

    final topCategorySection = _resolveTopCategorySection(
      categories: categories,
      topLevelCategories: topLevelCategories,
      products: products,
    );

    void openProductDetails(ProductModel product) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      );
    }

    Future<void> addToCart(ProductModel product) async {
      await cartNotifier.addProduct(product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
    }

    Future<void> toggleWishlist(ProductModel product) async {
      final wasWishlisted = wishlistNotifier.containsProduct(product.id);
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
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          WafiAppBar.compactOverlayTopInset(
            context,
            hasSubtitle: false,
            revealAmount: AppSizes.xl5 + AppSizes.sm,
          ),
          AppSizes.screenPaddingH,
          100,
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
              title: 'Browse by category',
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
                  quantityForProduct: cartNotifier.quantityForProduct,
                  isWishlisted: wishlistNotifier.containsProduct,
                  onTap: openProductDetails,
                  onAddToCart: addToCart,
                  onIncrement: (p) => cartNotifier.increment(p.id),
                  onDecrement: (p) => cartNotifier.decrement(p.id),
                  onToggleWishlist: toggleWishlist,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),
          _SectionWrapper(
            dark: true,
            child: _SectionHeader(
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
                  quantityForProduct: cartNotifier.quantityForProduct,
                  isWishlisted: wishlistNotifier.containsProduct,
                  onTap: openProductDetails,
                  onAddToCart: addToCart,
                  onIncrement: (p) => cartNotifier.increment(p.id),
                  onDecrement: (p) => cartNotifier.decrement(p.id),
                  onToggleWishlist: toggleWishlist,
                ),
              ],
            ),
          ),
          if (specialOffers.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            _SectionWrapper(
              child: _SectionHeader(
                title: 'Special Offer',
                actionLabel: AppStrings.seeAll,
                onActionTap: () => _openCatalog(
                  context,
                  title: 'Special Offer',
                  subtitle: 'Discounted products available now',
                  initialOffersOnly: true,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _SectionWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HorizontalProductStrip(
                    products: specialOffers.take(6).toList(),
                    quantityForProduct: cartNotifier.quantityForProduct,
                    isWishlisted: wishlistNotifier.containsProduct,
                    onTap: openProductDetails,
                    onAddToCart: addToCart,
                    onIncrement: (p) => cartNotifier.increment(p.id),
                    onDecrement: (p) => cartNotifier.decrement(p.id),
                    onToggleWishlist: toggleWishlist,
                  ),
                ],
              ),
            ),
          ],
          if (topCategorySection != null &&
              topCategorySection.products.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            _SectionWrapper(
              dark: true,
              child: _SectionHeader(
                title: '${topCategorySection.category.name} picks',
                actionLabel: AppStrings.seeAll,
                onActionTap: () => _openCatalog(
                  context,
                  title: topCategorySection.category.name,
                  subtitle: topCategorySection.category.description.isNotEmpty
                      ? topCategorySection.category.description
                      : 'Most stocked category right now',
                  categoryId: topCategorySection.category.id,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _SectionWrapper(
              dark: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HorizontalProductStrip(
                    products: topCategorySection.products.take(6).toList(),
                    quantityForProduct: cartNotifier.quantityForProduct,
                    isWishlisted: wishlistNotifier.containsProduct,
                    onTap: openProductDetails,
                    onAddToCart: addToCart,
                    onIncrement: (p) => cartNotifier.increment(p.id),
                    onDecrement: (p) => cartNotifier.decrement(p.id),
                    onToggleWishlist: toggleWishlist,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _openCatalog(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? categoryId,
    bool initialOffersOnly = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductCatalogPage(
          title: title,
          subtitle: subtitle,
          initialCategoryId: categoryId,
          initialOffersOnly: initialOffersOnly,
        ),
      ),
    );
  }
}

// ─── Banner data model ───────────────────────────────────────────────────────

DateTime _productTimestamp(ProductModel product) {
  return product.updatedAt ??
      product.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

double _homeStripCardWidth(double availableWidth) {
  const spacing = AppSizes.sm;
  const cardsInViewport = 2.18;
  final reservedSpacing = spacing * 2;
  return (availableWidth - reservedSpacing) / cardsInViewport;
}

_TopCategorySection? _resolveTopCategorySection({
  required List<ProductCategory> categories,
  required List<ProductCategory> topLevelCategories,
  required List<ProductModel> products,
}) {
  if (topLevelCategories.isEmpty || products.isEmpty) {
    return null;
  }

  _TopCategorySection? winner;

  for (final category in topLevelCategories) {
    final descendantIds = _descendantCategoryIds(
      parentId: category.id,
      categories: categories,
    );
    final matchingProducts = products.where((product) {
      return product.categoryId == category.id ||
          descendantIds.contains(product.categoryId) ||
          (product.subCategoryId != null &&
              descendantIds.contains(product.subCategoryId));
    }).toList()
      ..sort((a, b) => _productTimestamp(b).compareTo(_productTimestamp(a)));

    if (matchingProducts.isEmpty) {
      continue;
    }

    final current = _TopCategorySection(
      category: category,
      products: matchingProducts,
    );

    if (winner == null || current.products.length > winner.products.length) {
      winner = current;
    }
  }

  return winner;
}

Set<String> _descendantCategoryIds({
  required String parentId,
  required List<ProductCategory> categories,
}) {
  final descendants = <String>{};
  final pending = <String>[parentId];

  while (pending.isNotEmpty) {
    final currentId = pending.removeLast();
    for (final category in categories) {
      if (!category.isActive || category.parentId != currentId) continue;
      if (descendants.add(category.id)) {
        pending.add(category.id);
      }
    }
  }

  return descendants;
}

class _TopCategorySection {
  const _TopCategorySection({required this.category, required this.products});

  final ProductCategory category;
  final List<ProductModel> products;
}

class _BannerItem {
  const _BannerItem({
    required this.imageUrl,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String imageUrl;
  final String eyebrow;
  final String title;
  final String subtitle;
}

// ─── Hero Banner (auto-sliding carousel) ─────────────────────────────────────

class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.onShopTap});

  final VoidCallback onShopTap;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  static const _banners = [
    _BannerItem(
      imageUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
      eyebrow: 'Fresh Grocery Delivery',
      title: 'A cleaner way\nto shop daily\nessentials.',
      subtitle:
          'Fresh picks, daily essentials, and pantry staples — delivered.',
    ),
    _BannerItem(
      imageUrl:
          'https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=800&q=80',
      eyebrow: 'Farm Fresh Produce',
      title: 'Straight from\nthe farm to\nyour table.',
      subtitle:
          'Organic vegetables and fruits, sourced daily from local farms.',
    ),
    _BannerItem(
      imageUrl:
          'https://images.unsplash.com/photo-1579113800032-c38bd7635818?w=800&q=80',
      eyebrow: 'Premium Quality',
      title: 'The finest\nspices and\ndry goods.',
      subtitle: 'Authentic flavors from across the region, at your doorstep.',
    ),
  ];

  late final PageController _controller;
  late Timer _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetTimer() {
    _timer.cancel();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            // ── PageView ──────────────────────────────────────────────────
            PageView.builder(
              controller: _controller,
              itemCount: _banners.length,
              onPageChanged: (i) {
                setState(() => _current = i);
                _resetTimer();
              },
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return _BannerSlide(
                  banner: banner,
                  onShopTap: widget.onShopTap,
                );
              },
            ),

            // ── Dot indicators ────────────────────────────────────────────
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
                  final isActive = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive ? primary : primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single banner slide ──────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner, required this.onShopTap});

  final _BannerItem banner;
  final VoidCallback onShopTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = Colors.white;
    final subtitleColor = Colors.white.withValues(alpha: isDark ? 0.88 : 0.92);
    final chipBackground = Colors.white.withValues(alpha: isDark ? 0.12 : 0.16);
    final chipBorder = Colors.white.withValues(alpha: isDark ? 0.24 : 0.32);
    final textShadow = [
      Shadow(
        color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.28),
        blurRadius: 18,
        offset: const Offset(0, 4),
      ),
    ];

    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ─────────────────────────────────────────
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),

          // ── Dark gradient overlay so text is readable ────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: isDark ? 0.42 : 0.54),
                  Colors.black.withValues(alpha: isDark ? 0.24 : 0.34),
                  Colors.black.withValues(alpha: isDark ? 0.08 : 0.14),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.34, 0.62, 1.0],
              ),
            ),
          ),

          // ── Text content ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.xl2,
              AppSizes.xl2,
              AppSizes.xl2,
              36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _EyebrowChip(
                  label: banner.eyebrow,
                  textColor: titleColor,
                  backgroundColor: chipBackground,
                  borderColor: chipBorder,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  banner.title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: titleColor,
                    shadows: textShadow,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  banner.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    height: 1.35,
                    shadows: textShadow,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.lg),
              ],
            ),
          ),
        ],
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
    final primary = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.onTap});

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
        separatorBuilder: (context, index) => const SizedBox(width: AppSizes.sm),
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
    final imageUrl = category.image.trim();
    final hasImage = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          _iconFor(category.image),
                          color: primary,
                          size: 22,
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Icon(
                            _iconFor(category.name),
                            color: primary,
                            size: 22,
                          );
                        },
                      )
                    : Icon(_iconFor(category.name), color: primary, size: 22),
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
    required this.quantityForProduct,
    required this.isWishlisted,
    required this.onTap,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggleWishlist,
  });

  final List<ProductModel> products;
  final int Function(String productId) quantityForProduct;
  final bool Function(String productId) isWishlisted;
  final ValueChanged<ProductModel> onTap;
  final ValueChanged<ProductModel> onAddToCart;
  final ValueChanged<ProductModel> onIncrement;
  final ValueChanged<ProductModel> onDecrement;
  final ValueChanged<ProductModel> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const GlassCard(child: Text('No products available.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSizes.sm;
        final cardWidth = _homeStripCardWidth(constraints.maxWidth);

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: cardWidth,
                child: _ProductCard(
                  product: product,
                  quantityInCart: quantityForProduct(product.id),
                  isWishlisted: isWishlisted(product.id),
                  onTap: () => onTap(product),
                  onAddToCart: () => onAddToCart(product),
                  onIncrement: () => onIncrement(product),
                  onDecrement: () => onDecrement(product),
                  onToggleWishlist: () => onToggleWishlist(product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantityInCart,
    required this.isWishlisted,
    required this.onTap,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggleWishlist,
  });

  final ProductModel product;
  final int quantityInCart;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onToggleWishlist;

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
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
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
                  Positioned(
                    top: AppSizes.sm,
                    right: AppSizes.sm,
                    child: _HomeWishlistButton(
                      isSelected: isWishlisted,
                      onTap: onToggleWishlist,
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: AppSizes.sm,
                      left: AppSizes.sm,
                      child: _HomeImageOfferBadge(
                        label: '${product.discountPercent}% OFF',
                        backgroundColor: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSizes.sm),
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
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.hasDiscount)
                              Text(
                                '${AppStrings.currencySymbol}${product.originalPrice.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      _HomeCartAction(
                        quantity: quantityInCart,
                        inStock: product.inStock,
                        primary: primary,
                        textStyle: theme.textTheme.labelSmall,
                        onAdd: onAddToCart,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
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

class _HomeImageOfferBadge extends StatelessWidget {
  const _HomeImageOfferBadge({
    required this.label,
    required this.backgroundColor,
  });

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _NewArrivalStrip extends StatelessWidget {
  const _NewArrivalStrip({
    required this.products,
    required this.quantityForProduct,
    required this.isWishlisted,
    required this.onTap,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggleWishlist,
  });

  final List<ProductModel> products;
  final int Function(String productId) quantityForProduct;
  final bool Function(String productId) isWishlisted;
  final ValueChanged<ProductModel> onTap;
  final ValueChanged<ProductModel> onAddToCart;
  final ValueChanged<ProductModel> onIncrement;
  final ValueChanged<ProductModel> onDecrement;
  final ValueChanged<ProductModel> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const GlassCard(child: Text('No new arrivals.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSizes.sm;
        final cardWidth = _homeStripCardWidth(constraints.maxWidth);

        return SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: cardWidth,
                child: _NewArrivalCard(
                  product: product,
                  quantityInCart: quantityForProduct(product.id),
                  isWishlisted: isWishlisted(product.id),
                  onTap: () => onTap(product),
                  onAddToCart: () => onAddToCart(product),
                  onIncrement: () => onIncrement(product),
                  onDecrement: () => onDecrement(product),
                  onToggleWishlist: () => onToggleWishlist(product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NewArrivalCard extends StatelessWidget {
  const _NewArrivalCard({
    required this.product,
    required this.quantityInCart,
    required this.isWishlisted,
    required this.onTap,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggleWishlist,
  });

  final ProductModel product;
  final int quantityInCart;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final hasImage = product.primaryImage.trim().isNotEmpty;
    final cardBg = theme.colorScheme.surfaceContainerHighest;
    final imgBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
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
                  Positioned(
                    top: AppSizes.sm,
                    right: AppSizes.sm,
                    child: _HomeWishlistButton(
                      isSelected: isWishlisted,
                      onTap: onToggleWishlist,
                    ),
                  ),
                  Positioned(
                    top: AppSizes.sm,
                    left: AppSizes.sm,
                    child: _HomeImageOfferBadge(
                      label: product.hasDiscount
                          ? '${product.discountPercent}% OFF'
                          : 'NEW',
                      backgroundColor: product.hasDiscount
                          ? theme.colorScheme.error
                          : primary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.currencySymbol}${product.price.toStringAsFixed(0)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.hasDiscount)
                              Text(
                                '${AppStrings.currencySymbol}${product.originalPrice.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      _HomeCartAction(
                        quantity: quantityInCart,
                        inStock: product.inStock,
                        primary: primary,
                        filled: true,
                        textStyle: theme.textTheme.labelSmall,
                        onAdd: onAddToCart,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
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
  const _EyebrowChip({
    required this.label,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

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
        color: backgroundColor ?? primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: borderColor ?? primary.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor ?? primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HomeWishlistButton extends StatelessWidget {
  const _HomeWishlistButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isSelected
        ? Colors.redAccent
        : theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.82)
        : theme.colorScheme.primary.withValues(alpha: 0.82);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            isSelected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: iconColor,
            size: AppSizes.iconSm,
          ),
        ),
      ),
    );
  }
}

class _HomeCartAction extends StatelessWidget {
  const _HomeCartAction({
    required this.quantity,
    required this.inStock,
    required this.primary,
    required this.textStyle,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.filled = false,
  });

  final int quantity;
  final bool inStock;
  final Color primary;
  final TextStyle? textStyle;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final disabledColor = Colors.grey;
    final borderColor = filled
        ? Colors.transparent
        : inStock
        ? primary.withValues(alpha: 0.4)
        : disabledColor.withValues(alpha: 0.3);
    final backgroundColor = filled
        ? (inStock ? primary : disabledColor.withValues(alpha: 0.3))
        : (inStock
            ? primary.withValues(alpha: 0.1)
            : disabledColor.withValues(alpha: 0.1));
    final foregroundColor = filled
        ? Colors.white
        : (inStock ? primary : disabledColor);

    if (quantity <= 0) {
      return GestureDetector(
        onTap: inStock ? onAdd : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            inStock ? 'ADD' : 'OUT',
            style: textStyle?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyIconButton(
            icon: Icons.remove_rounded,
            color: foregroundColor,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            child: Text(
              '$quantity',
              style: textStyle?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QtyIconButton(
            icon: Icons.add_rounded,
            color: foregroundColor,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  const _QtyIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

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
