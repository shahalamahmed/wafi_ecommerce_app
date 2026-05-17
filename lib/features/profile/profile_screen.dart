import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wafi_ecommerce_app/core/constants/file_upload.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_provider.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_screen.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_screen.dart';
import 'package:wafi_ecommerce_app/features/profile/contact_support_service.dart';
import 'package:wafi_ecommerce_app/features/settings/settings_screen.dart';
import 'package:wafi_ecommerce_app/features/wishlist/wishlist_provider.dart';
import 'package:wafi_ecommerce_app/features/wishlist/wishlist_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_snackbar.dart';
import 'package:wafi_ecommerce_app/shared/widgets/profile_avatar.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.immersiveShell = false});

  final bool immersiveShell;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _pickAndUpload() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _showSnack('Sign in first to update your profile picture.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: FileUpload.imageExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final path = result.files.single.path;
    if (path == null || path.trim().isEmpty || !File(path).existsSync()) {
      _showSnack('Selected file could not be opened from device storage.');
      return;
    }

    await ref.read(authProvider.notifier).updateProfilePhoto(path);
    if (!mounted) return;

    final nextState = ref.read(authProvider);
    _showSnack(
      nextState.hasError
          ? nextState.errorMessage ?? 'Profile update failed.'
          : 'Profile picture updated successfully.',
    );
  }

  void _showSnack(String message) {
    GlassSnackbar.info(context, message);
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openPlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    _openPage(_PlaceholderScreen(title: title, subtitle: subtitle, icon: icon));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.watch(addressProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final wishlistState = ref.watch(wishlistProvider);
    final user = authState.user;
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;
    final primary = Theme.of(context).colorScheme.primary;
    final topInset = widget.immersiveShell
        ? WafiAppBar.compactOverlayTopInset(
            context,
            hasSubtitle: false,
            revealAmount: AppSizes.xl5,
          )
        : AppSizes.md;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        topInset,
        AppSizes.screenPaddingH,
        120,
      ),
      children: [
        _ProfileHeroCard(
          user: user,
          isGuest: isGuest,
          isLoading: authState.isLoading,
          onPickPhoto: _pickAndUpload,
          onPrimaryAction: isGuest
              ? authNotifier.exitGuestMode
              : () => _openPage(const _ProfileDetailsScreen()),
        ),
        const SizedBox(height: AppSizes.lg),
        _SectionCard(
          title: 'Quick Actions',
          child: Column(
            children: [
              Row(
                children: [
                  _QuickActionTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    onTap: () => _openPage(const _StandaloneOrdersScreen()),
                  ),
                  const SizedBox(width: AppSizes.md),
                  _QuickActionTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'Wishlist',
                    badgeText: wishlistState.itemCount > 0
                        ? '${wishlistState.itemCount}'
                        : null,
                    onTap: () => _openPage(const WishlistPage()),
                  ),
                  const SizedBox(width: AppSizes.md),
                  _QuickActionTile(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    onTap: () => _openPage(const AddressScreen()),
                  ),
                  const SizedBox(width: AppSizes.md),
                  _QuickActionTile(
                    icon: Icons.local_offer_outlined,
                    label: 'Coupon',
                    onTap: () => _openPlaceholder(
                      title: 'Coupons',
                      subtitle: 'Coupon management is not wired up yet.',
                      icon: Icons.local_offer_outlined,
                    ),
                  ),
                ].map((w) => w is SizedBox ? w : Expanded(child: w)).toList(),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  _QuickActionTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Track',
                    onTap: () => _openPage(const _TrackingOrdersScreen()),
                  ),
                  const SizedBox(width: AppSizes.md),
                  _QuickActionTile(
                    icon: Icons.support_agent_outlined,
                    label: 'Support',
                    onTap: () => _openPage(const _ContactSupportScreen()),
                  ),
                  const SizedBox(width: AppSizes.md),
                  _QuickActionTile(
                    icon: Icons.credit_card_outlined,
                    label: 'Payments',
                    onTap: () => _openPage(const _PaymentHistoryScreen()),
                  ),
                  const SizedBox(width: AppSizes.md),
                  _QuickActionTile(
                    icon: Icons.question_answer_outlined,
                    label: 'Faqs',
                    onTap: () => _openPlaceholder(
                      title: 'FAQs',
                      subtitle:
                          'Frequently asked questions will be published here.',
                      icon: Icons.question_answer_outlined,
                    ),
                  ),
                ].map((w) => w is SizedBox ? w : Expanded(child: w)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _SectionCard(
          title: 'Account & Security',
          child: Column(
            children: [
              _ProfileMenuRow(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle: isGuest
                    ? 'Open sign in to manage your personal details'
                    : 'Manage your profile details and account photo',
                onTap: () {
                  if (isGuest) {
                    authNotifier.exitGuestMode();
                    return;
                  }
                  _openPage(const _ProfileDetailsScreen());
                },
              ),
              const SizedBox(height: AppSizes.md),
              _ProfileMenuRow(
                icon: Icons.shield_outlined,
                title: 'Session Status',
                subtitle: isGuest
                    ? 'Browsing as guest'
                    : 'Signed in as ${user?.email ?? 'Wafi user'}',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    isGuest ? 'Guest' : 'Active',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _SectionCard(
          title: 'App Settings',
          child: Column(
            children: [
              _ProfileMenuRow(
                icon: Icons.settings_outlined,
                title: AppStrings.settings,
                subtitle: 'Theme, notifications, and app preferences',
                onTap: () => _openPage(const SettingsScreen()),
              ),
              const SizedBox(height: AppSizes.md),
              _ProfileMenuRow(
                icon: Icons.star_outline_rounded,
                title: 'Rate Us',
                subtitle: 'App store rating flow will be added later',
                onTap: () => _openPlaceholder(
                  title: 'Rate Us',
                  subtitle: 'App store rating integration is not ready yet.',
                  icon: Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _SectionCard(
          title: 'Support',
          child: Column(
            children: [
              _ProfileMenuRow(
                icon: Icons.mail_outline_rounded,
                title: 'Contact Us',
                subtitle: 'Phone, email, WhatsApp, LinkedIn, and feedback',
                onTap: () => _openPage(const _ContactSupportScreen()),
              ),
              const SizedBox(height: AppSizes.md),
              _ProfileMenuRow(
                icon: isGuest ? Icons.login_rounded : Icons.logout_rounded,
                title: isGuest ? 'Back to Sign In' : AppStrings.logout,
                subtitle: isGuest
                    ? 'Open the sign in screen to access your account'
                    : 'Sign out and continue browsing as guest',
                onTap: isGuest
                    ? authNotifier.exitGuestMode
                    : authNotifier.logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.isGuest,
    required this.isLoading,
    required this.onPickPhoto,
    required this.onPrimaryAction,
  });

  final AppUser? user;
  final bool isGuest;
  final bool isLoading;
  final VoidCallback onPickPhoto;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final heroTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final heroSubtleTextColor = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : const Color(0xFF334155);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? 'Hello there!' : 'Welcome back!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: heroTextColor,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                if (isGuest)
                  Text(
                    'Sign in to get the best experience',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: heroTextColor,
                      height: 1.08,
                    ),
                  )
                else
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(
                            user: user,
                            isGuest: isGuest,
                            radius: 34,
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: InkWell(
                              onTap: isLoading ? null : onPickPhoto,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primary, width: 2),
                                ),
                                child: isLoading
                                    ? Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.add_rounded,
                                        color: primary,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName.isNotEmpty == true
                                  ? user!.displayName
                                  : 'Wafi User',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: heroTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              user?.email.isNotEmpty == true
                                  ? user!.email
                                  : 'No email available',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: heroSubtleTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSizes.lg),
                GlassButton(
                  label: isGuest ? 'Sign In' : 'Manage Account',
                  prefixIcon: isGuest
                      ? Icons.login_rounded
                      : Icons.manage_accounts_outlined,
                  isFullWidth: false,
                  onPressed: onPrimaryAction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).cardColor.withValues(alpha: 0.35),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(icon, color: primary, size: 20),
                ),
                if ((badgeText ?? '').isNotEmpty)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontSize: 10, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSizes.xs),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        ],
      ),
    );
  }
}

class _ProfileDetailsScreen extends ConsumerWidget {
  const _ProfileDetailsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [_InfoCard(user: user, isGuest: isGuest)],
      ),
    );
  }
}

class _StandaloneOrdersScreen extends StatelessWidget {
  const _StandaloneOrdersScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myOrders),
        centerTitle: false,
      ),
      body: const OrderScreen(),
    );
  }
}

class _TrackingOrdersScreen extends ConsumerWidget {
  const _TrackingOrdersScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final orderNotifier = ref.read(orderProvider.notifier);

    if (orderState.isLoading && orderState.orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Orders'), centerTitle: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sortedOrders = [...orderState.orders]..sort(_compareTrackingOrders);

    return Scaffold(
      appBar: AppBar(title: const Text('Track Orders'), centerTitle: false),
      body: sortedOrders.isEmpty
          ? RefreshIndicator(
              onRefresh: orderNotifier.loadOrders,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                children: const [SizedBox(height: 140), _TrackingEmptyState()],
              ),
            )
          : RefreshIndicator(
              onRefresh: orderNotifier.loadOrders,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPaddingH,
                  AppSizes.lg,
                  AppSizes.screenPaddingH,
                  120,
                ),
                itemCount: sortedOrders.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
                itemBuilder: (context, index) {
                  final order = sortedOrders[index];
                  return _TrackingOrderCard(order: order);
                },
              ),
            ),
    );
  }
}

int _compareTrackingOrders(CustomerOrder a, CustomerOrder b) {
  final statusScore = <String, int>{
    'pending': 0,
    'confirmed': 1,
    'shipped': 2,
    'delivered': 3,
    'cancelled': 4,
  };

  final aScore = statusScore[a.status.trim().toLowerCase()] ?? 99;
  final bScore = statusScore[b.status.trim().toLowerCase()] ?? 99;
  if (aScore != bScore) return aScore.compareTo(bScore);

  final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  return bDate.compareTo(aDate);
}

class _TrackingOrderCard extends StatelessWidget {
  const _TrackingOrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final createdLabel = order.createdAt == null
        ? 'Recent order'
        : DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailsScreen(order: order),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: GlassCard(
        variant: GlassCardVariant.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderId,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        createdLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _TrackingStatusBadge(status: order.statusLabel),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                GlassChip(
                  label: '${order.items.length} items',
                  variant: GlassChipVariant.primary,
                ),
                GlassChip(
                  label: order.paymentSummaryLabel,
                  variant: GlassChipVariant.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Tracking Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.sm),
            _TrackingProgressLine(status: order.status),
            const SizedBox(height: AppSizes.md),
            Text(
              'Current status: ${order.statusLabel}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingEmptyState extends StatelessWidget {
  const _TrackingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        variant: GlassCardVariant.elevated,
        child: Column(
          children: [
            const Icon(Icons.local_shipping_outlined, size: AppSizes.iconXl),
            const SizedBox(height: AppSizes.md),
            Text(
              'No orders to track',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Your pending, shipped, and delivered orders will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingStatusBadge extends StatelessWidget {
  const _TrackingStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.trim().toLowerCase()) {
      'confirmed' => const Color(0xFF2563EB),
      'shipped' => const Color(0xFF0F766E),
      'delivered' => const Color(0xFF16A34A),
      'cancelled' => Theme.of(context).colorScheme.error,
      _ => const Color(0xFFD97706),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrackingProgressLine extends StatelessWidget {
  const _TrackingProgressLine({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = ['Pending', 'Confirmed', 'Shipped', 'Delivered'];
    final currentIndex = switch (status.trim().toLowerCase()) {
      'confirmed' => 1,
      'shipped' => 2,
      'delivered' => 3,
      _ => 0,
    };
    final isCancelled = status.trim().toLowerCase() == 'cancelled';

    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _TrackingMiniNode(
            label: steps[index],
            isActive: !isCancelled && index <= currentIndex,
          ),
          if (index < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                color: !isCancelled && index < currentIndex
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
        ],
      ],
    );
  }
}

class _TrackingMiniNode extends StatelessWidget {
  const _TrackingMiniNode({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).dividerColor;

    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: AppSizes.xs),
        SizedBox(
          width: 58,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _PaymentHistoryScreen extends ConsumerWidget {
  const _PaymentHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final orderState = ref.watch(orderProvider);
    final orderNotifier = ref.read(orderProvider.notifier);
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History'), centerTitle: false),
      body: Builder(
        builder: (context) {
          if (orderState.isLoading && orderState.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderState.hasError && orderState.orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                child: GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: AppSizes.iconXl,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        orderState.errorMessage ?? 'Failed to load payments.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      GlassButton(
                        label: AppStrings.retry,
                        prefixIcon: Icons.refresh_rounded,
                        isFullWidth: false,
                        onPressed: orderNotifier.loadOrders,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (orderState.orders.isEmpty) {
            return _PaymentHistoryEmptyState(isGuest: isGuest);
          }

          return RefreshIndicator(
            onRefresh: orderNotifier.loadOrders,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPaddingH,
                AppSizes.lg,
                AppSizes.screenPaddingH,
                120,
              ),
              itemCount: orderState.orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, index) {
                final order = orderState.orders[index];
                return _PaymentHistoryCard(order: order);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PaymentHistoryEmptyState extends ConsumerWidget {
  const _PaymentHistoryEmptyState({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payments_outlined, size: AppSizes.iconXl),
              const SizedBox(height: AppSizes.md),
              Text(
                isGuest
                    ? 'Sign in to view your payments'
                    : 'No payment history yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                isGuest
                    ? 'Your payment history is linked to your account orders. Sign in to see all payment records.'
                    : 'Your order payment records will appear here once you place an order.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isGuest) ...[
                const SizedBox(height: AppSizes.lg),
                GlassButton(
                  label: 'Back to Sign In',
                  prefixIcon: Icons.login_rounded,
                  isFullWidth: false,
                  onPressed: () {
                    ref.read(authProvider.notifier).exitGuestMode();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentMoment = order.paymentCollectedAt ?? order.createdAt;
    final paymentMomentLabel = order.paymentCollectedAt != null
        ? 'Collected'
        : 'Order Date';

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      order.paymentSummaryLabel,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              _PaymentStatusBadge(status: order.paymentStatusLabel),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              GlassChip(
                label:
                    '${AppStrings.currencySymbol}${order.total.toStringAsFixed(0)}',
                variant: GlassChipVariant.success,
              ),
              GlassChip(
                label: order.isCashOnDelivery ? 'COD' : 'Online',
                variant: GlassChipVariant.primary,
              ),
              if (order.paymentChannelLabel.isNotEmpty)
                GlassChip(
                  label: order.paymentChannelLabel,
                  variant: GlassChipVariant.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (paymentMoment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Text(
                '$paymentMomentLabel: ${DateFormat('dd MMM yyyy, hh:mm a').format(paymentMoment)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          Text(
            'Status: ${order.paymentStatusLabel}',
            style: theme.textTheme.bodyMedium,
          ),
          if (order.gatewayTransactionId.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'Txn ID: ${order.gatewayTransactionId}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (order.paymentCollectedAt != null && order.isCashOnDelivery) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'COD paid at ${DateFormat('dd MMM yyyy, hh:mm a').format(order.paymentCollectedAt!)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (order.paymentCollectedBy.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'Collected by: ${order.paymentCollectedBy}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'paid' => const Color(0xFF16A34A),
      'failed' => Theme.of(context).colorScheme.error,
      'cancelled' => const Color(0xFFDC2626),
      'invalid' => const Color(0xFFB45309),
      'unpaid' => const Color(0xFFB45309),
      _ => const Color(0xFF2563EB),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ContactSupportScreen extends ConsumerStatefulWidget {
  const _ContactSupportScreen();

  @override
  ConsumerState<_ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<_ContactSupportScreen> {
  static const _phoneNumber = '01758344572';
  static const _supportEmail = 'shahalamahemd21@gmail.com';
  static const _linkedinUrl = 'https://www.linkedin.com/in/shah-alam-app/';
  static const _whatsAppNumber = '8801758344572';
  static const _issueTypes = <String>[
    'Order Issue',
    'Payment Issue',
    'Refund',
    'Account',
    'Other',
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _messageController = TextEditingController();

  final Map<String, String?> _errors = {};
  bool _isSubmitting = false;
  String? _successMessage;
  String _selectedIssueType = _issueTypes.first;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user != null) {
      _nameController.text = user.displayName;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orderIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchExternal(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showSnack('Could not open the selected contact option.');
    }
  }

  Future<void> _submit() async {
    final nextErrors = <String, String?>{
      'name': AppValidators.name(_nameController.text),
      'email': AppValidators.email(_emailController.text),
      'phone': AppValidators.phone(_phoneController.text),
      'orderId': _validateOrderId(_orderIdController.text),
      'message': _validateMessage(_messageController.text),
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
      _successMessage = null;
    });

    if (nextErrors.values.any((value) => value != null)) {
      return;
    }

    final authState = ref.read(authProvider);
    final user = authState.user;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(contactSupportServiceProvider)
          .submitContactRequest(
            ContactSupportRequest(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              message: _messageController.text.trim(),
              userId: user?.uid,
              isGuest: authState.isAnonymous || !authState.isAuthenticated,
              issueType: _selectedIssueType,
              orderId: _orderIdController.text.trim(),
            ),
          );

      _messageController.clear();
      _orderIdController.clear();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _successMessage =
            'Support request sent successfully. We will review it and contact you soon.';
      });
      _showSnack('Support request submitted successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Failed to send your message. Please try again.');
    }
  }

  String? _validateMessage(String? value) {
    final requiredError = AppValidators.required(
      value,
      message: 'Please enter your message or feedback.',
    );
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 10) {
      return 'Please provide a bit more detail in your message.';
    }
    return null;
  }

  String? _validateOrderId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim().length < 6 ? 'Enter a valid order ID.' : null;
  }

  void _showSnack(String message) {
    GlassSnackbar.info(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: isDark ? 0.22 : 0.16),
                    theme.colorScheme.surface.withValues(
                      alpha: isDark ? 0.92 : 0.84,
                    ),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Support Desk',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Reach our team instantly or send detailed feedback.',
                    style: theme.textTheme.headlineSmall?.copyWith(height: 1.2),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Choose the fastest channel for your issue, or leave a message and we will follow up with you professionally.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.72,
                      ),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionCard(
            title: 'Direct Contact',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ContactActionCard(
                        icon: Icons.call_outlined,
                        title: 'Phone',
                        value: _phoneNumber,
                        accentColor: primary,
                        onTap: () => _launchExternal(
                          Uri(scheme: 'tel', path: _phoneNumber),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _ContactActionCard(
                        icon: Icons.mail_outline_rounded,
                        title: 'Email',
                        value: _supportEmail,
                        accentColor: const Color(0xFF0EA5E9),
                        onTap: () => _launchExternal(
                          Uri(
                            scheme: 'mailto',
                            path: _supportEmail,
                            queryParameters: {
                              'subject': 'Wafi App Support Request',
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: _ContactActionCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'WhatsApp',
                        value: _phoneNumber,
                        accentColor: const Color(0xFF16A34A),
                        onTap: () => _launchExternal(
                          Uri.parse(
                            'https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent('Hello, I need help with Wafi app.')}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _ContactActionCard(
                        icon: Icons.work_outline_rounded,
                        title: 'LinkedIn',
                        value: 'Open profile',
                        accentColor: const Color(0xFF2563EB),
                        onTap: () => _launchExternal(Uri.parse(_linkedinUrl)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionCard(
            title: 'Message / Feedback',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send us your issue, suggestion, or partnership inquiry.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                if ((_successMessage ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: primary,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.md),
                Text('Issue Type', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    for (final issueType in _issueTypes)
                      GlassChip(
                        label: issueType,
                        variant: GlassChipVariant.primary,
                        isSelected: _selectedIssueType == issueType,
                        onTap: () {
                          setState(() {
                            _selectedIssueType = issueType;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Use Order Issue for tracking, delivery, or missing item problems.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                GlassInput(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Your name',
                  prefixIcon: Icons.person_outline_rounded,
                  errorText: _errors['name'],
                  onChanged: (_) => setState(() => _errors['name'] = null),
                ),
                const SizedBox(height: AppSizes.md),
                GlassInput(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _errors['email'],
                  onChanged: (_) => setState(() => _errors['email'] = null),
                ),
                const SizedBox(height: AppSizes.md),
                GlassInput(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '01XXXXXXXXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  errorText: _errors['phone'],
                  onChanged: (_) => setState(() => _errors['phone'] = null),
                ),
                const SizedBox(height: AppSizes.md),
                GlassInput(
                  controller: _orderIdController,
                  label: 'Order ID (Optional)',
                  hint: 'WAFI-20260512-883911',
                  prefixIcon: Icons.receipt_long_outlined,
                  errorText: _errors['orderId'],
                  onChanged: (_) => setState(() => _errors['orderId'] = null),
                ),
                const SizedBox(height: AppSizes.md),
                GlassInput(
                  controller: _messageController,
                  label: 'Message',
                  hint: 'Write your feedback or support request here',
                  prefixIcon: Icons.edit_note_rounded,
                  maxLines: 6,
                  errorText: _errors['message'],
                  onChanged: (_) => setState(() => _errors['message'] = null),
                ),
                const SizedBox(height: AppSizes.lg),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Send Message',
                        prefixIcon: Icons.send_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactActionCard extends StatelessWidget {
  const _ContactActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.72,
                ),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Text(
                  'Open',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.iconXs,
                  color: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPaddingH),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppSizes.iconXl),
                const SizedBox(height: AppSizes.md),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSizes.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user, required this.isGuest});

  final AppUser? user;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (
        label: 'Name',
        value: user?.displayName.isNotEmpty == true
            ? user!.displayName
            : 'Guest User',
      ),
      (
        label: 'Email',
        value: user?.email.isNotEmpty == true
            ? user!.email
            : 'guest@local.session',
      ),
      (label: 'Role', value: user?.isOwner == true ? 'Shop Owner' : 'Customer'),
      (
        label: 'Phone',
        value: user?.phone.isNotEmpty == true ? user!.phone : 'Not added yet',
      ),
    ];

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(user: user, isGuest: isGuest, radius: 28),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName
                          : 'Guest User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      isGuest ? 'Guest session' : 'Customer account details',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          for (final row in rows)
            _ProfileInfoRow(label: row.label, value: row.value),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

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
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
