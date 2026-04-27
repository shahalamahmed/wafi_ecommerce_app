import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/theme/theme_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/settings/settings_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/profile_avatar.dart';

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
            // ── Profile header ──────────────────────────────────────────
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

            // ── Settings ────────────────────────────────────────────────
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

            // ── Theme switcher ──────────────────────────────────────────
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

            // ── Logout ──────────────────────────────────────────────────
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