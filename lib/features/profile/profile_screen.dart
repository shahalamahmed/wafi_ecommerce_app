import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_model.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_provider.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_screen.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/profile_avatar.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

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
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final addressState = ref.watch(addressProvider);
    final user = authState.user;
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;

    return Scaffold(
      appBar: WafiAppBar(
        title: AppStrings.profile,
        subtitle: 'Account details and preferences',
        showProfileAction: false,
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          _AvatarCard(
            user: user,
            isGuest: isGuest,
            isLoading: authState.isLoading,
            onPickPhoto: _pickAndUpload,
          ),

          const SizedBox(height: AppSizes.lg),

          _InfoCard(user: user, isGuest: isGuest),

          const SizedBox(height: AppSizes.lg),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
            child: Text(
              isGuest
                  ? 'Guest users can browse products and view the profile panel. '
                        'Sign in to upload a real profile picture.'
                  : 'Tap the plus icon on the avatar to choose a photo from '
                        'the device and update your account picture.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          if (!isGuest && addressState.items.isEmpty)
            GlassCard(
              variant: GlassCardVariant.elevated,
              child: GlassButton(
                label: AppStrings.addresses,
                prefixIcon: Icons.location_on_outlined,
                onPressed: () => showAddressSheet(context, ref),
              ),
            ),
          if (!isGuest && addressState.items.isNotEmpty)
            _ProfileAddressSection(
              items: addressState.items,
              onEdit: (address) =>
                  showAddressSheet(context, ref, initial: address),
              onDelete: (addressId) =>
                  ref.read(addressProvider.notifier).remove(addressId),
            ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.user,
    required this.isGuest,
    required this.isLoading,
    required this.onPickPhoto,
  });

  final AppUser? user;
  final bool isGuest;
  final bool isLoading;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(user: user, isGuest: isGuest, radius: 52),
              Positioned(
                right: -4,
                bottom: -4,
                child: InkWell(
                  onTap: isLoading ? null : onPickPhoto,
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
                    child: isLoading
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
          const SizedBox(height: AppSizes.lg),
          Text(
            user?.displayName.isNotEmpty == true
                ? user!.firstName
                : 'Guest User',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            user?.email.isNotEmpty == true
                ? user!.email
                : 'guest@local.session',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            children: [
              GlassChip(
                label: user?.isOwner == true ? 'Shop Owner' : 'Customer',
                variant: user?.isOwner == true
                    ? GlassChipVariant.warning
                    : GlassChipVariant.primary,
              ),
            ],
          ),
        ],
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
        value: user?.firstName.isNotEmpty == true
            ? user!.firstName
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
        children: [
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

class _ProfileAddressSection extends StatelessWidget {
  const _ProfileAddressSection({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AddressModel> items;
  final ValueChanged<AddressModel> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.addresses,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.md),
          for (var index = 0; index < items.length; index++) ...[
            _ProfileAddressRow(
              address: items[index],
              onEdit: () => onEdit(items[index]),
              onDelete: () => onDelete(items[index].id),
            ),
            if (index != items.length - 1) const SizedBox(height: AppSizes.md),
          ],
        ],
      ),
    );
  }
}

class _ProfileAddressRow extends StatelessWidget {
  const _ProfileAddressRow({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassChip(
                label: address.typeLabel,
                variant: GlassChipVariant.primary,
              ),
              const SizedBox(width: AppSizes.sm),
              if (address.isDefault)
                const GlassChip(
                  label: AppStrings.defaultAddress,
                  variant: GlassChipVariant.success,
                ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(address.formatted, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
