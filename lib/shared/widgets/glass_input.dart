import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';

class GlassInput extends StatefulWidget {
  const GlassInput({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.inputFormatters,
    this.autofocus = false,
    this.autocorrect = true,
    this.backgroundColor,
    this.unfocusedBorderColor,
    this.blurSigma,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool autocorrect;
  final Color? backgroundColor;
  final Color? unfocusedBorderColor;
  final double? blurSigma;

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  late FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focus.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    final borderColor = hasError
        ? Theme.of(context).colorScheme.error
        : _isFocused
        ? Theme.of(context).colorScheme.primary
        : (widget.unfocusedBorderColor ?? glass.borderColor);

    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: .3)
        : Colors.black.withValues(alpha: .3);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: .4)
        : Colors.black.withValues(alpha: .4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── Label ─────────────────────────────────────────
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: .6)
                  : Colors.black.withValues(alpha: .6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
        ],

        // ─── Input field ───────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: AppSizes.animNormal),
          height: widget.maxLines == 1 ? AppSizes.inputHeight : null,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? glass.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : AppSizes.inputBorderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma ?? AppSizes.blurSm,
                sigmaY: widget.blurSigma ?? AppSizes.blurSm,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                maxLength: widget.maxLength,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                autocorrect: widget.autocorrect,
                inputFormatters: widget.inputFormatters,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: hintColor,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.inputPaddingH,
                    vertical: AppSizes.md,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: iconColor,
                          size: AppSizes.iconSm,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? GestureDetector(
                          onTap: widget.onSuffixTap,
                          child: Icon(
                            widget.suffixIcon,
                            color: iconColor,
                            size: AppSizes.iconSm,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ),

        // ─── Helper / Error text ───────────────────────────
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            widget.errorText ?? widget.helperText!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: hasError ? Theme.of(context).colorScheme.error : hintColor,
            ),
          ),
        ],
      ],
    );
  }
}
