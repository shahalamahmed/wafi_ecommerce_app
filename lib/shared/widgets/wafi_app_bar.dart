import 'dart:ui';
import 'dart:math' as math;

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
    this.scrollUnderBody = false,
    this.compactTitle = false,
    this.showCartAction = false,
    this.cartBadgeCount = 0,
    this.onCartTap,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showNotificationAction;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool scrollUnderBody;
  final bool compactTitle;
  final bool showCartAction;
  final int cartBadgeCount;
  final VoidCallback? onCartTap;

  static double toolbarHeightFor({required bool hasSubtitle}) {
    return hasSubtitle ? 92 : 68;
  }

  static double overlayTopInset(
    BuildContext context, {
    required bool hasSubtitle,
    double extraSpacing = AppSizes.md,
  }) {
    return MediaQuery.paddingOf(context).top +
        toolbarHeightFor(hasSubtitle: hasSubtitle) +
        extraSpacing;
  }

  static double immersiveTopInset(
    BuildContext context, {
    required bool hasSubtitle,
    double revealAmount = AppSizes.xl3,
  }) {
    return math.max(
      AppSizes.lg,
      overlayTopInset(context, hasSubtitle: hasSubtitle) - revealAmount,
    );
  }

  static double compactOverlayTopInset(
    BuildContext context, {
    required bool hasSubtitle,
    double revealAmount = AppSizes.xl5,
  }) {
    return math.max(
      AppSizes.md,
      overlayTopInset(context, hasSubtitle: hasSubtitle) - revealAmount,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeightFor(hasSubtitle: subtitle?.trim().isNotEmpty ?? false),
  );

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle?.trim().isNotEmpty ?? false;
    final toolbarHeight = toolbarHeightFor(hasSubtitle: hasSubtitle);
    final resolvedLeading = _resolveLeading(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      centerTitle: compactTitle && !hasSubtitle,
      leadingWidth: compactTitle
          ? 68
          : resolvedLeading != null
          ? 56
          : null,
      leading: resolvedLeading,
      automaticallyImplyLeading: false,
      titleSpacing: AppSizes.lg,
      title: hasSubtitle
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : compactTitle
          ? _CompactTitleChip(title: title)
          : Text(title),
      actions: [
        if (actions != null) ...actions!,
        if (showCartAction)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: _GlassActionButton(
              icon: Icons.shopping_cart_outlined,
              badgeCount: cartBadgeCount,
              onTap: onCartTap,
            ),
          ),
        if (showNotificationAction)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.lg),
            child: const _NotificationActionButton(),
          ),
      ],
    );
  }

  Widget? _resolveLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!automaticallyImplyLeading) return null;

    final route = ModalRoute.of(context);
    final canPop =
        Navigator.of(context).canPop() ||
        (route?.impliesAppBarDismissal ?? false);
    if (!canPop) return null;

    return const _MinimalBackButton();
  }
}

class _CompactTitleChip extends StatelessWidget {
  const _CompactTitleChip({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = theme.extension<GlassTheme>()!;
    final baseColor = isDark
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFFDFDFF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.blurMd,
          sigmaY: AppSizes.blurMd,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: glass.borderColor, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withValues(alpha: isDark ? 0.72 : 0.82),
                baseColor.withValues(alpha: isDark ? 0.58 : 0.66),
              ],
            ),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton();

  @override
  Widget build(BuildContext context) {
    return _GlassActionButton(
      icon: Icons.notifications_none_rounded,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      ),
    );
  }
}

class _MinimalBackButton extends StatelessWidget {
  const _MinimalBackButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.sm),
      child: IconButton(
        onPressed: () => Navigator.maybePop(context),
        splashRadius: 22,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 22,
          color: iconColor,
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = theme.extension<GlassTheme>()!;
    final baseColor = isDark
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFFDFDFF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
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
                    colors: [
                      baseColor.withValues(alpha: isDark ? 0.72 : 0.82),
                      baseColor.withValues(alpha: isDark ? 0.58 : 0.66),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: AppSizes.iconMd,
                ),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '$badgeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
