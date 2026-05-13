import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/colors.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';

enum GlassSnackbarVariant { success, error, warning, info }

class GlassSnackbar {
  const GlassSnackbar._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    String message, {
    GlassSnackbarVariant variant = GlassSnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        0,
        AppSizes.screenPaddingH,
        AppSizes.lg,
      ),
      padding: EdgeInsets.zero,
      content: _GlassSnackbarContent(
        message: message,
        variant: variant,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );

    return messenger.showSnackBar(snackBar);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    return show(
      context,
      message,
      variant: GlassSnackbarVariant.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    return show(
      context,
      message,
      variant: GlassSnackbarVariant.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    return show(
      context,
      message,
      variant: GlassSnackbarVariant.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    return show(
      context,
      message,
      variant: GlassSnackbarVariant.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }
}

class _GlassSnackbarContent extends StatelessWidget {
  const _GlassSnackbarContent({
    required this.message,
    required this.variant,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final GlassSnackbarVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;
    final scheme = theme.colorScheme;
    final spec = _specFor(context, variant);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: spec.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: glass.shadowColor.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glass.highlightColor.withValues(alpha: 0.30),
            spec.background,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: spec.foreground.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(spec.icon, color: spec.foreground, size: 20),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            if ((actionLabel ?? '').trim().isNotEmpty && onAction != null) ...[
              const SizedBox(width: AppSizes.sm),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: spec.foreground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: spec.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _SnackbarVisualSpec _specFor(
    BuildContext context,
    GlassSnackbarVariant variant,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return switch (variant) {
      GlassSnackbarVariant.success => _SnackbarVisualSpec(
        icon: Icons.check_circle_rounded,
        foreground: AppColors.success(context),
        background: isDark
            ? AppColors.successGlassDark.withValues(alpha: 0.72)
            : AppColors.successGlassLight.withValues(alpha: 0.96),
        border: isDark
            ? AppColors.successBorderDark
            : AppColors.successBorderLight,
      ),
      GlassSnackbarVariant.error => _SnackbarVisualSpec(
        icon: Icons.error_rounded,
        foreground: AppColors.error(context),
        background: isDark
            ? AppColors.errorGlassDark.withValues(alpha: 0.74)
            : AppColors.errorGlassLight.withValues(alpha: 0.96),
        border: isDark ? AppColors.errorBorderDark : AppColors.errorBorderLight,
      ),
      GlassSnackbarVariant.warning => _SnackbarVisualSpec(
        icon: Icons.warning_amber_rounded,
        foreground: AppColors.warning(context),
        background: isDark
            ? AppColors.warningGlassDark.withValues(alpha: 0.74)
            : AppColors.warningGlassLight.withValues(alpha: 0.96),
        border: isDark
            ? AppColors.warningBorderDark
            : AppColors.warningBorderLight,
      ),
      GlassSnackbarVariant.info => _SnackbarVisualSpec(
        icon: Icons.info_rounded,
        foreground: AppColors.primary(context),
        background: isDark
            ? AppColors.primaryGlassDark.withValues(alpha: 0.72)
            : AppColors.primaryGlassLight.withValues(alpha: 0.96),
        border: isDark
            ? AppColors.primaryBorderDark
            : AppColors.primaryBorderLight,
      ),
    };
  }
}

class _SnackbarVisualSpec {
  const _SnackbarVisualSpec({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
}
