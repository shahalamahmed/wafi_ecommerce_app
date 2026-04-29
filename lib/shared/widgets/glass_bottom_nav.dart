import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';

class GlassBottomNavItem {
  const GlassBottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final int badgeCount;
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = Theme.of(context).extension<GlassTheme>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.sm,
        AppSizes.lg,
        AppSizes.lg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.bottomNavRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSizes.blurLg,
            sigmaY: AppSizes.blurLg,
          ),
          child: Container(
            height: AppSizes.bottomNavHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.bottomNavRadius),
              border: Border.all(color: glass.borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: glass.shadowColor,
                  blurRadius: isDark ? 16 : 28,
                  offset: Offset(0, isDark ? 8 : 16),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        glass.cardColor,
                        glass.elevatedColor,
                      ]
                    : [
                        glass.highlightColor,
                        glass.elevatedColor,
                      ],
              ),
            ),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _GlassBottomNavTile(
                      item: items[index],
                      isSelected: index == currentIndex,
                      onTap: () => onTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBottomNavTile extends StatelessWidget {
  const _GlassBottomNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final GlassBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg =
        isSelected ? theme.colorScheme.primary : theme.textTheme.labelMedium?.color;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.xs,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.10)
              : Colors.transparent,
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.16),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  color: fg,
                  size: AppSizes.iconMd,
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              item.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
