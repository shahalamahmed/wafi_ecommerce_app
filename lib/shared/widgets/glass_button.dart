import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/colors.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
enum GlassButtonVariant { primary, ghost, success, danger, warning, bkash }

enum GlassButtonSize { sm, md, lg }

class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant       = GlassButtonVariant.primary,
    this.size          = GlassButtonSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading     = false,
    this.isFullWidth   = true,
    this.borderRadius,
  });

  final String              label;
  final VoidCallback?       onPressed;
  final GlassButtonVariant  variant;
  final GlassButtonSize     size;
  final IconData?           prefixIcon;
  final IconData?           suffixIcon;
  final bool                isLoading;
  final bool                isFullWidth;
  final double?             borderRadius;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: AppSizes.animFast),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _ButtonStyle _resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (widget.variant) {
      GlassButtonVariant.primary => _ButtonStyle(
        bg:     isDark ? AppColors.primaryDark     : AppColors.primaryLight,
        border: isDark ? AppColors.primaryDark.withOpacity(.4)
            : AppColors.primaryLight.withOpacity(.4),
        fg:     Colors.white,
        bgGlass: null,
      ),
      GlassButtonVariant.ghost => _ButtonStyle(
        bg:     null,
        bgGlass: isDark ? AppColors.glassCardDark  : AppColors.glassCardLight,
        border: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        fg:     isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      GlassButtonVariant.success => _ButtonStyle(
        bg:     null,
        bgGlass: isDark ? AppColors.successGlassDark  : AppColors.successGlassLight,
        border: isDark ? AppColors.successBorderDark  : AppColors.successBorderLight,
        fg:     isDark ? AppColors.successDark         : AppColors.successLight,
      ),
      GlassButtonVariant.danger => _ButtonStyle(
        bg:     null,
        bgGlass: isDark ? AppColors.errorGlassDark  : AppColors.errorGlassLight,
        border: isDark ? AppColors.errorBorderDark  : AppColors.errorBorderLight,
        fg:     isDark ? AppColors.errorDark         : AppColors.errorLight,
      ),
      GlassButtonVariant.warning => _ButtonStyle(
        bg:     null,
        bgGlass: isDark ? AppColors.warningGlassDark  : AppColors.warningGlassLight,
        border: isDark ? AppColors.warningBorderDark  : AppColors.warningBorderLight,
        fg:     isDark ? AppColors.warningDark         : AppColors.warningLight,
      ),
      GlassButtonVariant.bkash => _ButtonStyle(
        bg:     null,
        bgGlass: isDark ? AppColors.bkashGlassDark : AppColors.bkashGlassLight,
        border: AppColors.bkashPink.withOpacity(.3),
        fg:     AppColors.bkashPink,
      ),
    };
  }

  double get _height => switch (widget.size) {
    GlassButtonSize.sm => AppSizes.buttonHeightSm,
    GlassButtonSize.md => AppSizes.buttonHeightMd,
    GlassButtonSize.lg => AppSizes.buttonHeightLg,
  };

  double get _fontSize => switch (widget.size) {
    GlassButtonSize.sm => AppSizes.bodyMd,
    GlassButtonSize.md => AppSizes.bodyLg,
    GlassButtonSize.lg => AppSizes.headingSm,
  };

  @override
  Widget build(BuildContext context) {
    final style    = _resolve(context);
    final radius   = widget.borderRadius ?? AppSizes.buttonRadius;
    final disabled = widget.onPressed == null || widget.isLoading;

    Widget content = Row(
      mainAxisSize:     widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null && !widget.isLoading) ...[
          Icon(widget.prefixIcon, size: AppSizes.iconSm, color: style.fg),
          const SizedBox(width: AppSizes.sm),
        ],
        if (widget.isLoading)
          SizedBox(
            width:  16,
            height: 16,
            child:  CircularProgressIndicator(
              strokeWidth: 2,
              color:       style.fg,
            ),
          )
        else
          Text(
            widget.label,
            style: TextStyle(
              color:       style.fg,
              fontSize:    _fontSize,
              fontWeight:  FontWeight.w600,
              letterSpacing: AppSizes.trackingNormal,
            ),
          ),
        if (widget.suffixIcon != null && !widget.isLoading) ...[
          const SizedBox(width: AppSizes.sm),
          Icon(widget.suffixIcon, size: AppSizes.iconSm, color: style.fg),
        ],
      ],
    );

    Widget button = AnimatedOpacity(
      opacity:  disabled ? AppSizes.opacityDisabled : 1.0,
      duration: const Duration(milliseconds: AppSizes.animFast),
      child: Container(
        width:  widget.isFullWidth ? double.infinity : null,
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl2),
        decoration: BoxDecoration(
          color:        style.bg ?? style.bgGlass,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: style.border, width: AppSizes.buttonBorderWidth),
        ),
        child: Center(child: content),
      ),
    );

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap:       disabled ? null : widget.onPressed,
        onTapDown:   disabled ? null : (_) => _ctrl.forward(),
        onTapUp:     disabled ? null : (_) => _ctrl.reverse(),
        onTapCancel: disabled ? null :  ()  => _ctrl.reverse(),
        child: button,
      ),
    );
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.fg,
    required this.border,
    this.bg,
    this.bgGlass,
  });
  final Color  fg;
  final Color  border;
  final Color? bg;
  final Color? bgGlass;
}