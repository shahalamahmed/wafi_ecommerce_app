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
import 'package:wafi_ecommerce_app/features/profile/profile_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/profile_avatar.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

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
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    onTap: () => _openProfile(context),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ProfileAvatar(
                                user: user,
                                isGuest: isGuest,
                                radius: 26,
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.displayName ?? 'Guest session',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: AppSizes.xs),
                                    Text(
                                      user?.email.isNotEmpty == true
                                          ? user!.email
                                          : AppStrings.guestBannerMsg,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: AppSizes.iconXs,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
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

                const SizedBox(height: AppSizes.xl2),
                _ThemeModePicker(
                  selectedMode: themeState.mode,
                  onChanged: themeNotifier.setTheme,
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

  void _openProfile(BuildContext context) {
    Navigator.of(context).pop();
    if (onProfileTap != null) {
      onProfileTap!();
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }
}

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker({required this.selectedMode, required this.onChanged});

  final AppThemeMode selectedMode;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.24,
    );
    final shellColor = theme.colorScheme.surface.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          padding: const EdgeInsets.all(AppSizes.xs),
          decoration: BoxDecoration(
            color: shellColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _ThemeModeOption(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: selectedMode == AppThemeMode.system,
                  onTap: () => onChanged(AppThemeMode.system),
                ),
              ),
              _ThemeModeDivider(color: borderColor),
              Expanded(
                child: _ThemeModeOption(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: selectedMode == AppThemeMode.light,
                  onTap: () => onChanged(AppThemeMode.light),
                ),
              ),
              _ThemeModeDivider(color: borderColor),
              Expanded(
                child: _ThemeModeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: selectedMode == AppThemeMode.dark,
                  onTap: () => onChanged(AppThemeMode.dark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeDivider extends StatelessWidget {
  const _ThemeModeDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
      color: color,
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final selectedFill = primary.withValues(alpha: 0.12);
    final selectedBorder = primary.withValues(alpha: 0.24);
    final idleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xs,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: isSelected ? Border.all(color: selectedBorder) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? primary : idleColor, size: 18),
              const SizedBox(height: AppSizes.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? primary : idleColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
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
                vertical: AppSizes.md,
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
          minTileHeight: 0,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSizes.xl,
            0,
            AppSizes.lg,
            AppSizes.md,
          ),
          visualDensity: const VisualDensity(vertical: -3),
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
