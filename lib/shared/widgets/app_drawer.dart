import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/theme/theme_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/owner/order_management_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/product_management_screen.dart';
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
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final user = authState.user;
    final isOwner = user?.isOwner == true;
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;

    return Drawer(
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
            if (isOwner) ...[
              GlassButton(
                label: 'Product Management',
                prefixIcon: Icons.inventory_2_outlined,
                isFullWidth: true,
                variant: GlassButtonVariant.ghost,
                onPressed: () {
                  Navigator.of(context)
                    ..pop()
                    ..push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _DrawerScreen(
                          title: 'Product Management',
                          subtitle: 'Catalog operations and inventory controls',
                          child: ProductManagementScreen(),
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
                          subtitle: 'Queue, fulfillment, and status updates',
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
                          subtitle: 'Assign owner access and review user roles',
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
            Text('Theme Mode', style: Theme.of(context).textTheme.titleMedium),
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
