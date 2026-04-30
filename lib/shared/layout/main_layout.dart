import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_screen.dart';
import 'package:wafi_ecommerce_app/features/home/home_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_catalog_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/order_management_screen.dart';
import 'package:wafi_ecommerce_app/features/orders/order_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/app_drawer.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_bottom_nav.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  // ── 4-tab bottom nav pages ─────────────────────────────────────────────
  List<_ShellPage> _pagesFor(AppUser? user) {
    final isOwner = user?.isOwner == true;

    return [
      // 0 — Home / Dashboard
      _ShellPage(
        title: isOwner ? AppStrings.dashboard : AppStrings.home,
        subtitle: isOwner
            ? 'Operations workspace'
            : 'Fresh grocery picks, categories, and daily essentials',
        icon: isOwner ? Icons.dashboard_outlined : Icons.home_outlined,
        body: isOwner ? _OverviewPage(user: user) : const HomeScreen(),
      ),

      // 1 — Categories / Products
      _ShellPage(
        title: isOwner ? AppStrings.products : AppStrings.categories,
        subtitle: isOwner
            ? 'Category and product catalog controls'
            : 'Browse all grocery collections',
        icon: isOwner ? Icons.inventory_2_outlined : Icons.grid_view_rounded,
        body: isOwner ? const OwnerCatalogScreen() : const ProductScreen(),
      ),

      // 2 — Cart (customer) / Orders (owner)
      _ShellPage(
        title: isOwner ? AppStrings.manageOrders : AppStrings.cart,
        subtitle: isOwner
            ? 'Order processing workspace'
            : 'Review selected products before checkout',
        icon: isOwner
            ? Icons.receipt_long_outlined
            : Icons.shopping_bag_outlined,
        body: isOwner ? const OrderManagementScreen() : const CartScreen(),
      ),

      // 3 — My Orders (customer) / Analytics (owner)
      _ShellPage(
        title: isOwner ? 'Analytics' : AppStrings.myOrders,
        subtitle: isOwner
            ? 'Sales and fulfillment overview'
            : 'Track your placed orders and history',
        icon: isOwner ? Icons.bar_chart_rounded : Icons.receipt_long_outlined,
        body: isOwner
            ? const _PlaceholderPage(
                title: 'Analytics Workspace',
                subtitle:
                    'Sales charts and fulfillment data will connect here.',
              )
            : const OrderScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);
    final user = authState.user;
    final isOwner = user?.isOwner == true;
    final pages = _pagesFor(user);
    final activePage = pages[_currentIndex];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: WafiAppBar(
        title: activePage.title,
        subtitle: activePage.subtitle,
        leading: const _DrawerLogoButton(),
      ),

      drawer: const AppDrawer(),

        body: Stack(
          children: [
            AnimatedSwitcher(
                duration: const Duration(milliseconds: AppSizes.animNormal),
                child: KeyedSubtree(
                  key: ValueKey(_currentIndex),
                  child: activePage.body,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GlassBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: pages.map((page) {
                  final isCartTab = !isOwner && page.title == AppStrings.cart;
                  return GlassBottomNavItem(
                    label: page.title,
                    icon: page.icon,
                    badgeCount: isCartTab ? cartState.itemCount : 0,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
    );
  }
}

class _DrawerLogoButton extends StatelessWidget {
  const _DrawerLogoButton();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: Image.asset(
              'assets/wafi_solution_logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

class _ShellPage {
  const _ShellPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.body,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget body;
}



class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final cards = <({String title, String value, IconData icon})>[
      (
        title: 'Session',
        value: user == null ? 'Guest' : 'Active',
        icon: Icons.shield_outlined,
      ),
      (
        title: 'Role',
        value: user?.isOwner == true ? 'Owner' : 'Customer',
        icon: Icons.badge_outlined,
      ),
      (
        title: 'Theme',
        value: Theme.of(context).brightness == Brightness.dark
            ? 'Pure Black'
            : 'Pure White',
        icon: Icons.contrast_rounded,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenPaddingH),
      children: [
        GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.firstName.isNotEmpty == true ? user!.firstName : 'Wafi user'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                user?.isOwner == true
                    ? 'Owner shell is ready for dashboard, product, and order integrations.'
                    : 'Customer shell is ready for auth-gated shopping, orders, and profile flows.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Wrap(
          spacing: AppSizes.lg,
          runSpacing: AppSizes.lg,
          children: [
            for (final card in cards)
              SizedBox(
                width: 220,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(card.icon),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        card.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        card.value,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}



class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSizes.sm),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
