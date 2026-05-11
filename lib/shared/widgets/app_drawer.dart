import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/core/theme/theme_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_catalog_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/order_management_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/user_management_screen.dart';
import 'package:wafi_ecommerce_app/features/settings/settings_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/profile_avatar.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final productState = ref.watch(productProvider);
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final user = authState.user;
    final isOwner = user?.isOwner == true;
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCategories = productState.activeCategories;
    final topLevelCategories =
        activeCategories.where((category) => category.isTopLevel).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final childCategoryMap = <String, List<ProductCategory>>{
      for (final parent in topLevelCategories)
        parent.id:
            activeCategories
                .where((category) => category.parentId == parent.id)
                .toList()
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
    };

    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.70),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.lg),
              children: [
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileAvatar(user: user, isGuest: isGuest, radius: 26),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        user?.displayName ?? 'Guest session',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        user?.email.isNotEmpty == true
                            ? user!.email
                            : AppStrings.guestBannerMsg,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          GlassChip(
                            label: isOwner ? 'Shop Owner' : 'Customer',
                            variant: isOwner
                                ? GlassChipVariant.warning
                                : GlassChipVariant.primary,
                          ),
                          GlassChip(
                            label: themeState.mode.label,
                            variant: GlassChipVariant.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl2),
                _DrawerCategorySection(
                  categories: topLevelCategories,
                  childCategoryMap: childCategoryMap,
                ),
                const SizedBox(height: AppSizes.xl2),
                if (isOwner) ...[
                  GlassButton(
                    label: 'Catalog Management',
                    prefixIcon: Icons.inventory_2_outlined,
                    isFullWidth: true,
                    variant: GlassButtonVariant.ghost,
                    onPressed: () {
                      Navigator.of(context)
                        ..pop()
                        ..push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _DrawerScreen(
                              title: 'Catalog Management',
                              subtitle:
                                  'Category, product, and inventory controls',
                              child: OwnerCatalogScreen(),
                            ),
                          ),
                        );
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                  GlassButton(
                    label: 'Order Management',
                    prefixIcon: Icons.receipt_long_outlined,
                    isFullWidth: true,
                    variant: GlassButtonVariant.ghost,
                    onPressed: () {
                      Navigator.of(context)
                        ..pop()
                        ..push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _DrawerScreen(
                              title: 'Order Management',
                              subtitle:
                                  'Queue, fulfillment, and status updates',
                              child: OrderManagementScreen(),
                            ),
                          ),
                        );
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),
                  GlassButton(
                    label: 'User Management',
                    prefixIcon: Icons.manage_accounts_outlined,
                    isFullWidth: true,
                    variant: GlassButtonVariant.ghost,
                    onPressed: () {
                      Navigator.of(context)
                        ..pop()
                        ..push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _DrawerScreen(
                              title: 'User Management',
                              subtitle:
                                  'Assign owner access and review user roles',
                              child: UserManagementScreen(),
                            ),
                          ),
                        );
                    },
                  ),
                  const SizedBox(height: AppSizes.xl2),
                ],
                GlassButton(
                  label: AppStrings.settings,
                  prefixIcon: Icons.settings_outlined,
                  isFullWidth: true,
                  variant: GlassButtonVariant.ghost,
                  onPressed: () {
                    Navigator.of(context)
                      ..pop()
                      ..push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                  },
                ),
                const SizedBox(height: AppSizes.xl2),
                Text(
                  'Theme Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.md),
                GlassButton(
                  label: 'System',
                  isFullWidth: true,
                  variant: themeState.mode == AppThemeMode.system
                      ? GlassButtonVariant.primary
                      : GlassButtonVariant.ghost,
                  onPressed: () => themeNotifier.setTheme(AppThemeMode.system),
                ),
                const SizedBox(height: AppSizes.sm),
                GlassButton(
                  label: 'Light',
                  isFullWidth: true,
                  variant: themeState.mode == AppThemeMode.light
                      ? GlassButtonVariant.primary
                      : GlassButtonVariant.ghost,
                  onPressed: () => themeNotifier.setTheme(AppThemeMode.light),
                ),
                const SizedBox(height: AppSizes.sm),
                GlassButton(
                  label: 'Dark',
                  isFullWidth: true,
                  variant: themeState.mode == AppThemeMode.dark
                      ? GlassButtonVariant.primary
                      : GlassButtonVariant.ghost,
                  onPressed: () => themeNotifier.setTheme(AppThemeMode.dark),
                ),
                const SizedBox(height: AppSizes.xl2),
                GlassButton(
                  label: authState.isAnonymous
                      ? 'Back to Sign In'
                      : AppStrings.logout,
                  prefixIcon: Icons.logout_rounded,
                  variant: GlassButtonVariant.danger,
                  isFullWidth: true,
                  onPressed: authState.isAnonymous
                      ? authNotifier.exitGuestMode
                      : authNotifier.logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerCategorySection extends StatelessWidget {
  const _DrawerCategorySection({
    required this.categories,
    required this.childCategoryMap,
  });

  final List<ProductCategory> categories;
  final Map<String, List<ProductCategory>> childCategoryMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.categories,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        if (categories.isEmpty)
          GlassCard(
            variant: GlassCardVariant.elevated,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.lg,
            ),
            child: Text(
              'No active categories available right now.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: _DrawerCategoryTile(
                category: category,
                children: childCategoryMap[category.id] ?? const [],
              ),
            ),
          ),
      ],
    );
  }
}

class _DrawerCategoryTile extends StatelessWidget {
  const _DrawerCategoryTile({required this.category, required this.children});

  final ProductCategory category;
  final List<ProductCategory> children;

  bool get _hasChildren => children.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface.withValues(alpha: 0.72);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.32,
    );

    if (!_hasChildren) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          onTap: () => _openCategory(context, category),
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: AppSizes.iconXs,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSizes.xl,
            0,
            AppSizes.lg,
            AppSizes.md,
          ),
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.primary,
          title: Text(
            category.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            ...children.map(
              (child) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                title: Text(child.name, style: theme.textTheme.bodyLarge),
                onTap: () => _openCategory(context, child),
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openCategory(context, category),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text('View all'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, ProductCategory selectedCategory) {
    Navigator.of(context)
      ..pop()
      ..push(
        MaterialPageRoute<void>(
          builder: (_) => ProductCatalogPage(
            title: selectedCategory.name,
            subtitle: selectedCategory.description.trim().isNotEmpty
                ? selectedCategory.description
                : 'Browse products from this category',
            initialCategoryId: selectedCategory.id,
          ),
        ),
      );
  }
}

class _DrawerScreen extends StatelessWidget {
  const _DrawerScreen({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WafiAppBar(title: title, subtitle: subtitle),
      body: child,
    );
  }
}
