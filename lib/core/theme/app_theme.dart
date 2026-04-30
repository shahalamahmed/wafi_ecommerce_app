import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';

@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.cardColor,
    required this.elevatedColor,
    required this.pressedColor,
    required this.borderColor,
    required this.highlightColor,
    required this.shadowColor,
    required this.blurSigma,
    required this.primaryGlass,
    required this.primaryBorder,
    required this.successGlass,
    required this.successBorder,
    required this.errorGlass,
    required this.errorBorder,
    required this.warningGlass,
    required this.warningBorder,
    required this.bkashGlass,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color cardColor;
  final Color elevatedColor;
  final Color pressedColor;
  final Color borderColor;
  final Color highlightColor;
  final Color shadowColor;
  final double blurSigma;
  final Color primaryGlass;
  final Color primaryBorder;
  final Color successGlass;
  final Color successBorder;
  final Color errorGlass;
  final Color errorBorder;
  final Color warningGlass;
  final Color warningBorder;
  final Color bkashGlass;
  final Color shimmerBase;
  final Color shimmerHighlight;

  @override
  GlassTheme copyWith({
    Color? cardColor,
    Color? elevatedColor,
    Color? pressedColor,
    Color? borderColor,
    Color? highlightColor,
    Color? shadowColor,
    double? blurSigma,
    Color? primaryGlass,
    Color? primaryBorder,
    Color? successGlass,
    Color? successBorder,
    Color? errorGlass,
    Color? errorBorder,
    Color? warningGlass,
    Color? warningBorder,
    Color? bkashGlass,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return GlassTheme(
      cardColor: cardColor ?? this.cardColor,
      elevatedColor: elevatedColor ?? this.elevatedColor,
      pressedColor: pressedColor ?? this.pressedColor,
      borderColor: borderColor ?? this.borderColor,
      highlightColor: highlightColor ?? this.highlightColor,
      shadowColor: shadowColor ?? this.shadowColor,
      blurSigma: blurSigma ?? this.blurSigma,
      primaryGlass: primaryGlass ?? this.primaryGlass,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      successGlass: successGlass ?? this.successGlass,
      successBorder: successBorder ?? this.successBorder,
      errorGlass: errorGlass ?? this.errorGlass,
      errorBorder: errorBorder ?? this.errorBorder,
      warningGlass: warningGlass ?? this.warningGlass,
      warningBorder: warningBorder ?? this.warningBorder,
      bkashGlass: bkashGlass ?? this.bkashGlass,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      elevatedColor: Color.lerp(elevatedColor, other.elevatedColor, t)!,
      pressedColor: Color.lerp(pressedColor, other.pressedColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      primaryGlass: Color.lerp(primaryGlass, other.primaryGlass, t)!,
      primaryBorder: Color.lerp(primaryBorder, other.primaryBorder, t)!,
      successGlass: Color.lerp(successGlass, other.successGlass, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      errorGlass: Color.lerp(errorGlass, other.errorGlass, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      warningGlass: Color.lerp(warningGlass, other.warningGlass, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      bkashGlass: Color.lerp(bkashGlass, other.bkashGlass, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }

  static const dark = GlassTheme(
    cardColor: AppColors.glassCardDark,
    elevatedColor: AppColors.glassElevatedDark,
    pressedColor: AppColors.glassPressedDark,
    borderColor: AppColors.glassBorderDark,
    highlightColor: Color(0x0DFFFFFF),
    shadowColor: Color(0x4D000000),
    blurSigma: AppSizes.blurMd,
    primaryGlass: AppColors.primaryGlassDark,
    primaryBorder: AppColors.primaryBorderDark,
    successGlass: AppColors.successGlassDark,
    successBorder: AppColors.successBorderDark,
    errorGlass: AppColors.errorGlassDark,
    errorBorder: AppColors.errorBorderDark,
    warningGlass: AppColors.warningGlassDark,
    warningBorder: AppColors.warningBorderDark,
    bkashGlass: AppColors.bkashGlassDark,
    shimmerBase: AppColors.shimmerBaseDark,
    shimmerHighlight: AppColors.shimmerHighDark,
  );

  static const light = GlassTheme(
    cardColor: AppColors.glassCardLight,
    elevatedColor: AppColors.glassElevatedLight,
    pressedColor: AppColors.glassPressedLight,
    borderColor: AppColors.glassBorderLight,
    highlightColor: Color(0x99FFFFFF),
    shadowColor: Color(0x14000000),
    blurSigma: AppSizes.blurMd,
    primaryGlass: AppColors.primaryGlassLight,
    primaryBorder: AppColors.primaryBorderLight,
    successGlass: AppColors.successGlassLight,
    successBorder: AppColors.successBorderLight,
    errorGlass: AppColors.errorGlassLight,
    errorBorder: AppColors.errorBorderLight,
    warningGlass: AppColors.warningGlassLight,
    warningBorder: AppColors.warningBorderLight,
    bkashGlass: AppColors.bkashGlassLight,
    shimmerBase: AppColors.shimmerBaseLight,
    shimmerHighlight: AppColors.shimmerHighLight,
  );
}

abstract class AppTheme {
  static ThemeData get dark => _buildTheme(isDark: true);
  static ThemeData get light => _buildTheme(isDark: false);

  static ThemeData _buildTheme({required bool isDark}) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final errorColor = isDark ? AppColors.errorDark : AppColors.errorLight;
    final glassCard =
        isDark ? AppColors.glassCardDark : AppColors.glassCardLight;
    final glassBorder =
        isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;
    final systemOverlay = isDark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xFFF5F5F7),
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer:
          isDark ? AppColors.primaryGlassDark : AppColors.primaryGlassLight,
      onPrimaryContainer: primary,
      secondary:
          isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
      onSecondary: textPrimary,
      secondaryContainer: isDark
          ? AppColors.secondaryGlassDark
          : AppColors.secondaryGlassLight,
      onSecondaryContainer: textPrimary,
      error: errorColor,
      onError: Colors.white,
      errorContainer:
          isDark ? AppColors.errorGlassDark : AppColors.errorGlassLight,
      onErrorContainer: errorColor,
      surface: glassCard,
      onSurface: textPrimary,
      surfaceContainerHighest: isDark
          ? AppColors.glassElevatedDark
          : AppColors.glassElevatedLight,
      outline: glassBorder,
      outlineVariant: divider,
      scrim: isDark ? AppColors.overlayDark : AppColors.overlayLight,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: glassCard,
      dividerColor: divider,
      splashFactory: InkRipple.splashFactory,
      extensions: [isDark ? GlassTheme.dark : GlassTheme.light],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: AppSizes.headingLg,
          fontWeight: FontWeight.w600,
          letterSpacing: AppSizes.trackingTight,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: AppSizes.iconMd),
        actionsIconTheme:
            IconThemeData(color: textSecondary, size: AppSizes.iconMd),
      ),
      cardTheme: CardThemeData(
        color: glassCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: BorderSide(color: glassBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.bodyLg,
            fontWeight: FontWeight.w400,
            letterSpacing: AppSizes.trackingNormal,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          side: BorderSide(color: primary, width: 1),
          textStyle: const TextStyle(
            fontSize: AppSizes.bodyLg,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: AppSizes.bodyLg,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.inputPaddingH,
          vertical: AppSizes.md,
        ),
        hintStyle: TextStyle(
          color: textSecondary,
          fontSize: AppSizes.bodyLg,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: AppSizes.bodyLg,
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontSize: AppSizes.labelMd,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        errorStyle: TextStyle(color: errorColor, fontSize: AppSizes.labelMd),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: AppSizes.labelSm,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppSizes.labelSm,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glassCard,
        selectedColor:
            isDark ? AppColors.primaryGlassDark : AppColors.primaryGlassLight,
        disabledColor: divider,
        labelStyle: TextStyle(
          color: textPrimary,
          fontSize: AppSizes.bodyXs,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: primary,
          fontSize: AppSizes.bodyXs,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        side: BorderSide(color: glassBorder, width: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.xs,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF111214) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: AppSizes.headingLg,
          fontWeight: FontWeight.w600,
          letterSpacing: AppSizes.trackingTight,
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: AppSizes.bodyLg,
          height: AppSizes.lineHeightNormal,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF111214) : Colors.white,
        modalBackgroundColor: isDark ? const Color(0xFF111214) : Colors.white,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXxl),
          ),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        dragHandleColor: divider,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF111214) : const Color(0xFF1D1D1F),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: AppSizes.bodyMd,
          fontWeight: FontWeight.w400,
        ),
        actionTextColor: primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        insetPadding: const EdgeInsets.all(AppSizes.lg),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor:
            isDark ? AppColors.primaryGlassDark : AppColors.primaryGlassLight,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: AppSizes.bodyLg,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: AppSizes.bodySm,
        ),
        iconColor: textSecondary,
        selectedColor: primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.xs,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? AppColors.primaryGlassDark
                : AppColors.primaryGlassLight;
          }
          return glassCard;
        }),
        trackOutlineColor: WidgetStateProperty.all(glassBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: glassBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : textSecondary;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: glassCard,
        circularTrackColor: glassCard,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: glassCard,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        labelStyle: const TextStyle(
          fontSize: AppSizes.bodyLg,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppSizes.bodyLg,
          fontWeight: FontWeight.w400,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      iconTheme: IconThemeData(
        color: textPrimary,
        size: AppSizes.iconMd,
      ),
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      useMaterial3: true,
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: _text(AppSizes.displayLg, FontWeight.w600, primary,
          height: 1.1, letterSpacing: -0.28),
      displayMedium: _text(AppSizes.displayMd, FontWeight.w600, primary,
          height: 1.18, letterSpacing: -0.28),
      displaySmall: _text(AppSizes.displaySm, FontWeight.w600, primary,
          height: 1.18, letterSpacing: -0.2),
      headlineLarge: _text(AppSizes.headingXl, FontWeight.w600, primary,
          height: AppSizes.lineHeightTight, letterSpacing: -0.24),
      headlineMedium: _text(AppSizes.headingLg, FontWeight.w600, primary,
          height: 1.2, letterSpacing: -0.18),
      headlineSmall: _text(AppSizes.headingMd, FontWeight.w600, primary,
          height: 1.24, letterSpacing: -0.12),
      titleLarge: _text(AppSizes.headingSm, FontWeight.w600, primary,
          height: 1.24, letterSpacing: -0.12),
      titleMedium: _text(AppSizes.bodyLg, FontWeight.w600, primary,
          height: 1.24, letterSpacing: -0.12),
      titleSmall: _text(AppSizes.bodyMd, FontWeight.w600, primary,
          height: 1.24),
      bodyLarge: _text(AppSizes.bodyLg, FontWeight.w400, primary,
          height: AppSizes.lineHeightNormal, letterSpacing: -0.12),
      bodyMedium: _text(AppSizes.bodyMd, FontWeight.w400, primary,
          height: 1.5),
      bodySmall: _text(AppSizes.bodySm, FontWeight.w400, secondary,
          height: 1.43),
      labelLarge: _text(AppSizes.labelMd, FontWeight.w400, primary,
          height: 1.29),
      labelMedium: _text(AppSizes.labelSm, FontWeight.w400, secondary,
          height: 1.2),
      labelSmall: _text(AppSizes.labelXs, FontWeight.w400, secondary,
          height: 1.1, letterSpacing: AppSizes.trackingWide),
    );
  }

  static TextStyle _text(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double letterSpacing = AppSizes.trackingNormal,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
