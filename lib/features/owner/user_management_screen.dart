import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/owner/owner_management_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';
import 'package:wafi_ecommerce_app/shared/widgets/profile_avatar.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    ref.listen(ownerUserManagementProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.errorMessage != previous?.errorMessage && next.hasError) {
        messenger.showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.successMessage != previous?.successMessage &&
          (next.successMessage?.isNotEmpty ?? false)) {
        messenger.showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    if (currentUser?.isOwner != true) {
      return const _AccessDeniedState();
    }

    final state = ref.watch(ownerUserManagementProvider);
    final notifier = ref.read(ownerUserManagementProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        children: [
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Role Management',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Promote customers to owners and manage existing owner access.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                GlassInput(
                  hint: 'Search by name, email, or phone',
                  prefixIcon: Icons.search_rounded,
                  onChanged: notifier.setSearchQuery,
                ),
                const SizedBox(height: AppSizes.lg),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    GlassChip(
                      label: '${state.users.length} users',
                      variant: GlassChipVariant.primary,
                    ),
                    GlassChip(
                      label:
                          '${state.users.where((user) => user.isOwner).length} owners',
                      variant: GlassChipVariant.warning,
                    ),
                    GlassChip(
                      label:
                          '${state.users.where((user) => user.isCustomer).length} customers',
                      variant: GlassChipVariant.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xl3),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.filteredUsers.isEmpty)
            GlassCard(
              variant: GlassCardVariant.elevated,
              child: Column(
                children: [
                  const Icon(Icons.group_outlined, size: AppSizes.iconXl),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No users found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            ...state.filteredUsers.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _UserManagementCard(
                  user: user,
                  currentUserId: currentUser!.uid,
                  isSaving: state.isSaving,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserManagementCard extends ConsumerWidget {
  const _UserManagementCard({
    required this.user,
    required this.currentUserId,
    required this.isSaving,
  });

  final AppUser user;
  final String currentUserId;
  final bool isSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = user.uid == currentUserId;
    final targetRole = user.isOwner ? UserRole.customer : UserRole.owner;
    final actionLabel = user.isOwner ? 'Make Customer' : 'Make Owner';

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(user: user, isGuest: false, radius: 24),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        user.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              GlassChip(
                label: user.isOwner ? 'Owner' : 'Customer',
                variant: user.isOwner
                    ? GlassChipVariant.warning
                    : GlassChipVariant.primary,
              ),
              GlassChip(
                label: user.isShopOwner
                    ? 'Shop access enabled'
                    : 'Shop access off',
                variant: user.isShopOwner
                    ? GlassChipVariant.success
                    : GlassChipVariant.neutral,
              ),
              if (isSelf)
                const GlassChip(
                  label: 'Current session',
                  variant: GlassChipVariant.neutral,
                ),
            ],
          ),
          if (user.shopName.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            Text(
              'Shop: ${user.shopName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Text(
            isSelf
                ? 'You cannot change your own role from this device.'
                : 'Role change will update access immediately after next profile refresh.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.md),
          GlassButton(
            label: actionLabel,
            variant: user.isOwner
                ? GlassButtonVariant.danger
                : GlassButtonVariant.primary,
            prefixIcon: user.isOwner
                ? Icons.person_off_outlined
                : Icons.verified_user_outlined,
            isLoading: isSaving,
            onPressed: isSelf
                ? null
                : () => _confirmRoleChange(
              context,
              ref,
              user: user,
              targetRole: targetRole,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRoleChange(
    BuildContext context,
    WidgetRef ref, {
    required AppUser user,
    required UserRole targetRole,
  }) async {
    final nextRoleLabel = targetRole == UserRole.owner ? 'owner' : 'customer';
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm role update'),
          content: Text('Change ${user.displayName} to $nextRoleLabel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldUpdate == true) {
      await ref
          .read(ownerUserManagementProvider.notifier)
          .updateUserRole(userId: user.uid, role: targetRole);
    }
  }
}

class _AccessDeniedState extends StatelessWidget {
  const _AccessDeniedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: AppSizes.iconXl,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Access denied',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Only owners can manage user roles.',
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
