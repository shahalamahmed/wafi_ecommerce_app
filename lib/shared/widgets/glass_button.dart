import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/colors.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';

enum GlassButtonVariant { primary, ghost, success, danger, warning, bkash }

enum GlassButtonSize { sm, md, lg }

class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.size = GlassButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final GlassButtonSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? borderRadius;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppSizes.animFast),
    );
    _scale = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _ButtonStyle _resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = Theme.of(context).extension<GlassTheme>()!;

    return switch (widget.variant) {
      GlassButtonVariant.primary => _ButtonStyle(
          bg: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          border: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          fg: Colors.white,
        ),
      GlassButtonVariant.ghost => _ButtonStyle(
          bg: glass.cardColor,
          border: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          fg: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
      GlassButtonVariant.success => _ButtonStyle(
          bg: glass.successGlass,
          border: glass.successBorder,
          fg: isDark ? AppColors.successDark : AppColors.successLight,
        ),
      GlassButtonVariant.danger => _ButtonStyle(
          bg: glass.errorGlass,
          border: glass.errorBorder,
          fg: isDark ? AppColors.errorDark : AppColors.errorLight,
        ),
      GlassButtonVariant.warning => _ButtonStyle(
          bg: glass.warningGlass,
          border: glass.warningBorder,
          fg: isDark ? AppColors.warningDark : AppColors.warningLight,
        ),
      GlassButtonVariant.bkash => _ButtonStyle(
          bg: AppColors.bkashPink.withOpacity(0.10),
          border: AppColors.bkashPink.withOpacity(0.25),
          fg: AppColors.bkashPink,
        ),
    };
  }

  double get _height => switch (widget.size) {
        GlassButtonSize.sm => AppSizes.buttonHeightSm,
        GlassButtonSize.md => AppSizes.buttonHeightMd,
        GlassButtonSize.lg => AppSizes.buttonHeightLg,
      };

  double get _fontSize => switch (widget.size) {
        GlassButtonSize.sm => AppSizes.bodySm,
        GlassButtonSize.md => AppSizes.bodyLg,
        GlassButtonSize.lg => AppSizes.headingSm,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _resolve(context);
    final disabled = widget.onPressed == null || widget.isLoading;
    final radius = widget.borderRadius ?? AppSizes.buttonRadius;

    final content = Row(
      mainAxisSize:
          widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null && !widget.isLoading) ...[
          Icon(widget.prefixIcon, size: AppSizes.iconSm, color: style.fg),
          const SizedBox(width: AppSizes.sm),
        ],
        if (widget.isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style.fg,
            ),
          )
        else
          Text(
            widget.label,
            style: TextStyle(
              color: style.fg,
              fontSize: _fontSize,
              fontWeight: FontWeight.w400,
              letterSpacing: AppSizes.trackingNormal,
            ),
          ),
        if (widget.suffixIcon != null && !widget.isLoading) ...[
          const SizedBox(width: AppSizes.sm),
          Icon(widget.suffixIcon, size: AppSizes.iconSm, color: style.fg),
        ],
      ],
    );

    return ScaleTransition(
      scale: _scale,
      child: AnimatedOpacity(
        opacity: disabled ? AppSizes.opacityDisabled : 1,
        duration: const Duration(milliseconds: AppSizes.animFast),
        child: GestureDetector(
          onTap: disabled ? null : widget.onPressed,
          onTapDown: disabled ? null : (_) => _ctrl.forward(),
          onTapUp: disabled ? null : (_) => _ctrl.reverse(),
          onTapCancel: disabled ? null : _ctrl.reverse,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: AppSizes.animNormal),
            curve: Curves.easeOutCubic,
            width: widget.isFullWidth ? double.infinity : null,
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: style.border, width: 1),
              boxShadow: widget.variant == GlassButtonVariant.primary
                  ? [
                      BoxShadow(
                        color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                            .withOpacity(isDark ? 0.08 : 0.18),
                        blurRadius: isDark ? 12 : 24,
                        offset: Offset(0, isDark ? 5 : 10),
                      ),
                    ]
                  : null,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        style.bg,
                        style.bg.withOpacity(0.92),
                      ]
                    : [
                        Colors.white.withOpacity(0.14),
                        style.bg,
                      ],
              ),
            ),
            child: ColoredBox(
              color: Colors.transparent,
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.bg,
    required this.border,
    required this.fg,
  });

  final Color bg;
  final Color border;
  final Color fg;
}
