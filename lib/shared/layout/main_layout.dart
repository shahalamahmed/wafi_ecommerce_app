import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_screen.dart';
import 'package:wafi_ecommerce_app/features/home/home_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/order_management_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_catalog_screen.dart';
import 'package:wafi_ecommerce_app/features/orders/order_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/features/profile/profile_screen.dart';
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

  List<_ShellPage> _pagesFor(AppUser? user) {
    final isOwner = user?.isOwner == true;

    if (isOwner) {
      return [
        _ShellPage(
          title: AppStrings.dashboard,
          subtitle: 'Operations workspace',
          icon: Icons.dashboard_outlined,
          body: _OverviewPage(user: user),
        ),
        const _ShellPage(
          title: AppStrings.products,
          subtitle: 'Category and product catalog controls',
          icon: Icons.inventory_2_outlined,
          body: OwnerCatalogScreen(),
        ),
        const _ShellPage(
          title: AppStrings.manageOrders,
          subtitle: 'Order processing workspace',
          icon: Icons.receipt_long_outlined,
          body: OrderManagementScreen(),
        ),
        const _ShellPage(
          title: 'Analytics',
          subtitle: 'Sales and fulfillment overview',
          icon: Icons.bar_chart_rounded,
          body: _PlaceholderPage(
            title: 'Analytics Workspace',
            subtitle: 'Sales charts and fulfillment data will connect here.',
          ),
        ),
      ];
    }

    return const [
      _ShellPage(
        title: AppStrings.home,
        subtitle: 'Fresh grocery picks, categories, and daily essentials',
        icon: Icons.home_outlined,
        body: HomeScreen(),
      ),
      _ShellPage(
        title: AppStrings.categories,
        subtitle: 'Browse all grocery collections',
        icon: Icons.grid_view_rounded,
        body: ProductScreen(),
      ),
      _ShellPage(
        title: AppStrings.cart,
        subtitle: 'Review selected products before checkout',
        icon: Icons.shopping_bag_outlined,
        body: CartScreen(),
      ),
      _ShellPage(
        title: AppStrings.myOrders,
        subtitle: 'Track your placed orders and history',
        icon: Icons.receipt_long_outlined,
        body: OrderScreen(),
      ),
      _ShellPage(
        title: AppStrings.profile,
        subtitle: 'Account shortcuts, settings, and support',
        icon: Icons.person_outline_rounded,
        body: ProfileScreen(),
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
    final safeIndex = _currentIndex >= pages.length
        ? pages.length - 1
        : _currentIndex;

    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentIndex = safeIndex);
        }
      });
    }

    final activePage = pages[safeIndex];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: WafiAppBar(
        title: activePage.title,
        subtitle: activePage.subtitle,
        leading: const _DrawerLogoButton(),
        showNotificationAction: !isOwner,
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: AppSizes.animNormal),
            child: KeyedSubtree(
              key: ValueKey(safeIndex),
              child: activePage.body,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              currentIndex: safeIndex,
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
        return Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: Image.asset(
                'assets/wafi_solution_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
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
                'Owner shell is ready for dashboard, product, and order integrations.',
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
