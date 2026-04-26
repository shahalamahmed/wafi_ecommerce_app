import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/theme/theme_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_bottom_nav.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  List<_ShellPage> _pagesFor(AppUser? user) {
    return [
      _ShellPage(
        title: user?.isOwner == true ? AppStrings.dashboard : 'Categories',
        subtitle: user?.isOwner == true
            ? 'Operations workspace'
            : 'Grocery collections and daily essentials',
        icon: user?.isOwner == true ? Icons.dashboard_outlined : Icons.storefront_outlined,
        body: user?.isOwner == true
            ? _OverviewPage(user: user)
            : const ProductScreen(),
      ),
      _ShellPage(
        title: user?.isOwner == true ? AppStrings.products : 'Overview',
        subtitle: user?.isOwner == true
            ? 'Product catalog controls'
            : 'Session, theme, and account snapshot',
        icon: user?.isOwner == true ? Icons.inventory_2_outlined : Icons.home_outlined,
        body: user?.isOwner == true
            ? const ProductScreen()
            : _OverviewPage(user: user),
      ),
      _ShellPage(
        title: user?.isOwner == true ? AppStrings.orders : AppStrings.cart,
        subtitle: user?.isOwner == true
            ? 'Order processing workspace'
            : 'Review selected products before checkout',
        icon: user?.isOwner == true ? Icons.receipt_long_outlined : Icons.shopping_bag_outlined,
        body: user?.isOwner == true
            ? const _PlaceholderPage(
                title: 'Order Workspace',
                subtitle: 'Order history, fulfillment pipeline, and timeline data will connect here.',
              )
            : const CartScreen(),
      ),
      _ShellPage(
        title: AppStrings.settings,
        subtitle: 'Preferences and account controls',
        icon: Icons.settings_outlined,
        body: const _PlaceholderPage(
          title: 'Settings Workspace',
          subtitle: 'Theme, notifications, language, and account preferences will live here.',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final cartState = ref.watch(cartProvider);
    final user = authState.user;
    final pages = _pagesFor(user);
    final activePage = pages[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: AppSizes.lg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(activePage.title),
            const SizedBox(height: 2),
            Text(
              activePage.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.lg),
            child: _ProfileAction(
              user: user,
              isGuest: authState.isAnonymous || !authState.isAuthenticated,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              GlassCard(
                variant: GlassCardVariant.elevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                      child: Text(
                        user == null
                            ? 'G'
                            : user.displayName.trim().isEmpty
                                ? 'U'
                                : user.displayName.trim().characters.first.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      user?.displayName ?? 'Guest session',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      user?.email.isNotEmpty == true ? user!.email : AppStrings.guestBannerMsg,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      children: [
                        GlassChip(
                          label: user?.isOwner == true ? 'Shop Owner' : 'Customer',
                          variant: user?.isOwner == true
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
                label: authState.isAnonymous ? 'Back to Sign In' : AppStrings.logout,
                prefixIcon: Icons.logout_rounded,
                variant: GlassButtonVariant.danger,
                onPressed: authState.isAnonymous
                    ? authNotifier.exitGuestMode
                    : authNotifier.logout,
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: activePage.body,
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: pages
            .map(
              (page) => GlassBottomNavItem(
                label: page.title,
                icon: page.icon,
                badgeCount: user?.isOwner == true || page.title != AppStrings.cart
                    ? 0
                    : cartState.itemCount,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.user,
    required this.isGuest,
  });

  final AppUser? user;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _ProfileSheet(),
        );
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.24),
          ),
        ),
        child: _ProfileAvatar(
          user: user,
          isGuest: isGuest,
          radius: 22,
        ),
      ),
    );
  }
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet();

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to update your profile picture.')),
      );
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );

    if (file == null || !mounted) return;

    await ref.read(authProvider.notifier).updateProfilePhoto(file.path);
    if (!mounted) return;

    final nextState = ref.read(authProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextState.hasError
              ? nextState.errorMessage ?? 'Profile update failed.'
              : 'Profile picture updated successfully.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.xl2,
        ),
        child: GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppStrings.profile,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _ProfileAvatar(
                      user: user,
                      isGuest: isGuest,
                      radius: 52,
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: InkWell(
                        onTap: authState.isLoading ? null : _pickAndUpload,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: authState.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              _ProfileInfoRow(
                label: 'Name',
                value: user?.displayName.isNotEmpty == true ? user!.displayName : 'Guest User',
              ),
              _ProfileInfoRow(
                label: 'Email',
                value: user?.email.isNotEmpty == true ? user!.email : 'guest@local.session',
              ),
              _ProfileInfoRow(
                label: 'Role',
                value: user?.isOwner == true ? 'Shop Owner' : 'Customer',
              ),
              _ProfileInfoRow(
                label: 'Phone',
                value: user?.phone.isNotEmpty == true ? user!.phone : 'Not added yet',
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                isGuest
                    ? 'Guest users can browse products and view the profile panel. Sign in to upload a real profile picture.'
                    : 'Tap the plus icon on the avatar to choose a photo from the device and update your account picture.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.isGuest,
    required this.radius,
  });

  final AppUser? user;
  final bool isGuest;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.profilePicture.trim() ?? '';
    final initials = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim().characters.first.toUpperCase()
        : isGuest
            ? 'G'
            : 'U';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isNotEmpty
          ? null
          : Text(
              initials,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
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
      (title: 'Session', value: user == null ? 'Guest' : 'Active', icon: Icons.shield_outlined),
      (title: 'Role', value: user?.isOwner == true ? 'Owner' : 'Customer', icon: Icons.badge_outlined),
      (title: 'Theme', value: Theme.of(context).brightness == Brightness.dark ? 'Pure Black' : 'Pure White', icon: Icons.contrast_rounded),
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
                      Text(card.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSizes.xs),
                      Text(card.value, style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.subtitle,
  });

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
