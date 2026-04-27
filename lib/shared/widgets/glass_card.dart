import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';

enum GlassCardVariant { normal, elevated, pressed }

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.variant = GlassCardVariant.normal,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final GlassCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    final radius = borderRadius ?? BorderRadius.circular(AppSizes.cardRadius);

    final bgColor = switch (variant) {
      GlassCardVariant.normal => glass.cardColor,
      GlassCardVariant.elevated => glass.elevatedColor,
      GlassCardVariant.pressed => glass.pressedColor,
    };

    Widget card = ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: glass.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: glass.shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glass.highlightColor,
                bgColor,
                glass.cardColor,
              ],
              stops: const [0, 0.25, 1],
            ),
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSizes.cardPaddingH,
                  vertical: AppSizes.cardPaddingV,
                ),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null || onLongPress != null) {
      card = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      );
    }

    return card;
  }
}

class GlassTappableCard extends StatefulWidget {
  const GlassTappableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.variant = GlassCardVariant.normal,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
  });

  final Widget child;
  final VoidCallback onTap;
  final GlassCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final double? height;

  @override
  State<GlassTappableCard> createState() => _GlassTappableCardState();
}

class _GlassTappableCardState extends State<GlassTappableCard>
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
    _scale = Tween<double>(begin: 1, end: 0.975).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: GlassCard(
          variant: widget.variant,
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: widget.borderRadius,
          width: widget.width,
          height: widget.height,
          child: widget.child,
        ),
      ),
    );
  }
}
