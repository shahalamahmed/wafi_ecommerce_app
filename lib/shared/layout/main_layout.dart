import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_screen.dart';
import 'package:wafi_ecommerce_app/features/dashboard/dashboard_screen.dart';
import 'package:wafi_ecommerce_app/features/home/home_screen.dart';
import 'package:wafi_ecommerce_app/features/offers/offers_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/order_management_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_catalog_screen.dart';
import 'package:wafi_ecommerce_app/features/orders/order_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/features/profile/profile_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/app_drawer.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_bottom_nav.dart';
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
          scrollUnderAppBar: false,
          topInset: null,
          body: OwnerDashboardScreen(user: user),
        ),
        const _ShellPage(
          title: AppStrings.products,
          subtitle: 'Category and product catalog controls',
          icon: Icons.inventory_2_outlined,
          scrollUnderAppBar: false,
          topInset: null,
          body: OwnerCatalogScreen(),
        ),
        const _ShellPage(
          title: AppStrings.manageOrders,
          subtitle: 'Order processing workspace',
          icon: Icons.receipt_long_outlined,
          scrollUnderAppBar: false,
          topInset: null,
          body: OrderManagementScreen(),
        ),
        _ShellPage(
          title: 'Analytics',
          subtitle: 'Sales and fulfillment overview',
          icon: Icons.bar_chart_rounded,
          scrollUnderAppBar: false,
          topInset: null,
          body: const OwnerAnalyticsScreen(),
        ),
      ];
    }

    return const [
      _ShellPage(
        title: AppStrings.home,
        subtitle: null,
        icon: Icons.home_outlined,
        scrollUnderAppBar: true,
        topInset: 0,
        body: HomeScreen(),
      ),
      _ShellPage(
        title: AppStrings.categories,
        subtitle: null,
        icon: Icons.grid_view_rounded,
        scrollUnderAppBar: true,
        topInset: 0,
        body: ProductScreen(immersiveShell: true),
      ),
      _ShellPage(
        title: 'Offers',
        subtitle: null,
        icon: Icons.local_offer_outlined,
        scrollUnderAppBar: true,
        topInset: 0,
        body: OffersScreen(immersiveShell: true),
      ),
      _ShellPage(
        title: AppStrings.myOrders,
        subtitle: null,
        icon: Icons.receipt_long_outlined,
        scrollUnderAppBar: true,
        topInset: 0,
        body: OrderScreen(immersiveShell: true),
      ),
      _ShellPage(
        title: AppStrings.profile,
        subtitle: null,
        icon: Icons.person_outline_rounded,
        scrollUnderAppBar: true,
        topInset: 0,
        body: ProfileScreen(immersiveShell: true),
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
      extendBodyBehindAppBar: true,
      appBar: WafiAppBar(
        title: activePage.title,
        subtitle: activePage.subtitle,
        leading: const _DrawerLogoButton(),
        showNotificationAction: !isOwner,
        showCartAction: !isOwner,
        cartBadgeCount: cartState.itemCount,
        onCartTap: !isOwner
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _StandaloneCartScreen(),
                ),
              )
            : null,
        scrollUnderBody: activePage.scrollUnderAppBar,
        compactTitle: !isOwner,
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top:
                    activePage.topInset ??
                    WafiAppBar.overlayTopInset(
                      context,
                      hasSubtitle:
                          activePage.subtitle?.trim().isNotEmpty ?? false,
                    ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: AppSizes.animNormal),
                child: KeyedSubtree(
                  key: ValueKey(safeIndex),
                  child: activePage.body,
                ),
              ),
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
                return GlassBottomNavItem(label: page.title, icon: page.icon);
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
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/wafi_solution_logo.png',
                fit: BoxFit.contain,
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
    required this.scrollUnderAppBar,
    required this.topInset,
    required this.body,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool scrollUnderAppBar;
  final double? topInset;
  final Widget body;
}

class _StandaloneCartScreen extends StatelessWidget {
  const _StandaloneCartScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WafiAppBar(
        title: AppStrings.cart,
        subtitle: 'Review selected products before checkout',
      ),
      body: CartScreen(),
    );
  }
}
