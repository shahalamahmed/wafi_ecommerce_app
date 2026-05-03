import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';
import 'package:wafi_ecommerce_app/features/notifications/notifications_screen.dart';

class WafiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WafiAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showNotificationAction = false,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showNotificationAction;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize =>
      Size.fromHeight((subtitle?.trim().isNotEmpty ?? false) ? 92 : 68);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                colors: isDark
                    ? [glass.elevatedColor, glass.cardColor]
                    : [glass.highlightColor, glass.cardColor],
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
        if (showNotificationAction)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.lg),
            child: const _NotificationActionButton(),
          ),
      ],
    );
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = Theme.of(context).extension<GlassTheme>()!;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      ),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
                colors: isDark
                    ? [glass.cardColor, glass.elevatedColor]
                    : [glass.highlightColor, glass.elevatedColor],
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: AppSizes.iconMd,
            ),
          ),
        ),
      ),
    );
  }
}
