import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/theme/theme_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/settings/settings_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: const WafiAppBar(
        title: AppStrings.settings,
        subtitle: 'Control theme, language, and account preferences',
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPaddingH),
              children: [
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          for (final mode in AppThemeMode.values)
                            GlassChip(
                              label: mode.label,
                              variant: GlassChipVariant.primary,
                              isSelected: themeState.mode == mode,
                              onTap: () => themeNotifier.setTheme(mode),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(AppStrings.notifications),
                        subtitle: const Text(
                          'Receive order updates and delivery alerts.',
                        ),
                        value: settingsState.notificationsEnabled,
                        onChanged: settingsNotifier.setNotificationsEnabled,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Promotions'),
                        subtitle: const Text(
                          'Allow discount offers and marketing messages.',
                        ),
                        value: settingsState.marketingEnabled,
                        onChanged: settingsNotifier.setMarketingEnabled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          _LanguageChip(
                            label: 'English',
                            code: 'en',
                            selectedCode: settingsState.languageCode,
                            onTap: settingsNotifier.setLanguageCode,
                          ),
                          _LanguageChip(
                            label: 'Bangla',
                            code: 'bn',
                            selectedCode: settingsState.languageCode,
                            onTap: settingsNotifier.setLanguageCode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.md),
                      const _SettingsInfoRow(
                        title: AppStrings.privacy,
                        subtitle: 'Privacy details will be published here.',
                      ),
                      const SizedBox(height: AppSizes.md),
                      const _SettingsInfoRow(
                        title: AppStrings.terms,
                        subtitle: 'Terms and service summary placeholder.',
                      ),
                      const SizedBox(height: AppSizes.md),
                      const _SettingsInfoRow(
                        title: AppStrings.about,
                        subtitle: '${AppStrings.appName} grocery shopping experience.',
                      ),
                      const SizedBox(height: AppSizes.md),
                      const _SettingsInfoRow(
                        title: AppStrings.version,
                        subtitle: AppStrings.appVersion,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        authState.isAnonymous
                            ? 'You are browsing as a guest.'
                            : 'Signed in as ${authState.user?.email ?? 'Wafi user'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSizes.lg),
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
              ],
            ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.code,
    required this.selectedCode,
    required this.onTap,
  });

  final String label;
  final String code;
  final String selectedCode;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GlassChip(
      label: label,
      variant: GlassChipVariant.primary,
      isSelected: selectedCode == code,
      onTap: () => onTap(code),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
