import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/colors.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';

enum GlassChipVariant { primary, success, warning, error, neutral }

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.variant    = GlassChipVariant.primary,
    this.prefixIcon,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
  });

  final String           label;
  final GlassChipVariant variant;
  final IconData?        prefixIcon;
  final VoidCallback?    onTap;
  final VoidCallback?    onDelete;
  final bool             isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color border, Color fg) = switch (variant) {
      GlassChipVariant.primary => isDark
          ? (AppColors.primaryGlassDark,  AppColors.primaryBorderDark,  AppColors.primaryDark)
          : (AppColors.primaryGlassLight, AppColors.primaryBorderLight, AppColors.primaryLight),
      GlassChipVariant.success => isDark
          ? (AppColors.successGlassDark,  AppColors.successBorderDark,  AppColors.successDark)
          : (AppColors.successGlassLight, AppColors.successBorderLight, AppColors.successLight),
      GlassChipVariant.warning => isDark
          ? (AppColors.warningGlassDark,  AppColors.warningBorderDark,  AppColors.warningDark)
          : (AppColors.warningGlassLight, AppColors.warningBorderLight, AppColors.warningLight),
      GlassChipVariant.error => isDark
          ? (AppColors.errorGlassDark,  AppColors.errorBorderDark,  AppColors.errorDark)
          : (AppColors.errorGlassLight, AppColors.errorBorderLight, AppColors.errorLight),
      GlassChipVariant.neutral => isDark
          ? (AppColors.glassCardDark,  AppColors.glassBorderDark,  AppColors.textSecondaryDark)
          : (AppColors.glassCardLight, AppColors.glassBorderLight, AppColors.textSecondaryLight),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: AppSizes.animNormal),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical:   AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color:        isSelected ? bg.withOpacity(bg.opacity * 1.5) : bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: AppSizes.iconXs, color: fg),
              const SizedBox(width: AppSizes.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color:       fg,
                fontSize:    AppSizes.labelMd,
                fontWeight:  FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: AppSizes.xs),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, size: 12, color: fg.withOpacity(.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}