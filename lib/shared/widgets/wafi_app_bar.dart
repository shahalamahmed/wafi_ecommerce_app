import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/profile/profile_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/profile_avatar.dart';

class WafiAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const WafiAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showProfileAction = true,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showProfileAction;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(
        (subtitle?.trim().isNotEmpty ?? false) ? 92 : 68,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isGuest = authState.isAnonymous || !authState.isAuthenticated;
    final hasSubtitle = subtitle?.trim().isNotEmpty ?? false;
    final glass = Theme.of(context).extension<GlassTheme>()!;

    return AppBar(
      toolbarHeight: hasSubtitle ? 92 : 68,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: AppSizes.lg,
      title: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSizes.blurMd,
            sigmaY: AppSizes.blurMd,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: glass.borderColor, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glass.highlightColor,
                  glass.cardColor,
                ],
              ),
            ),
            child: hasSubtitle
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title),
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                : Text(title),
          ),
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        if (showProfileAction)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.lg),
            child: _ProfileActionButton(user: user, isGuest: isGuest),
          ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.user,
    required this.isGuest,
  });

  final dynamic user;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      ),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSizes.blurMd,
            sigmaY: AppSizes.blurMd,
          ),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: glass.borderColor, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glass.highlightColor,
                  glass.elevatedColor,
                ],
              ),
            ),
            child: ProfileAvatar(
              user: user,
              isGuest: isGuest,
              radius: 21,
            ),
          ),
        ),
      ),
    );
  }
}
