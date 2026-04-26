import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

// ─── Glass Extension ──────────────────────────────────────────────────────────
// ThemeExtension দিয়ে glass-specific tokens ThemeData-এ inject করা হয়েছে
// যাতে যেকোনো widget থেকে Theme.of(context).extension<GlassTheme>() দিয়ে পাওয়া যায়

@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.cardColor,
    required this.elevatedColor,
    required this.pressedColor,
    required this.borderColor,
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
      cardColor:        cardColor        ?? this.cardColor,
      elevatedColor:    elevatedColor    ?? this.elevatedColor,
      pressedColor:     pressedColor     ?? this.pressedColor,
      borderColor:      borderColor      ?? this.borderColor,
      blurSigma:        blurSigma        ?? this.blurSigma,
      primaryGlass:     primaryGlass     ?? this.primaryGlass,
      primaryBorder:    primaryBorder    ?? this.primaryBorder,
      successGlass:     successGlass     ?? this.successGlass,
      successBorder:    successBorder    ?? this.successBorder,
      errorGlass:       errorGlass       ?? this.errorGlass,
      errorBorder:      errorBorder      ?? this.errorBorder,
      warningGlass:     warningGlass     ?? this.warningGlass,
      warningBorder:    warningBorder    ?? this.warningBorder,
      bkashGlass:       bkashGlass       ?? this.bkashGlass,
      shimmerBase:      shimmerBase      ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      cardColor:        Color.lerp(cardColor,        other.cardColor,        t)!,
      elevatedColor:    Color.lerp(elevatedColor,    other.elevatedColor,    t)!,
      pressedColor:     Color.lerp(pressedColor,     other.pressedColor,     t)!,
      borderColor:      Color.lerp(borderColor,      other.borderColor,      t)!,
      blurSigma:        lerpDouble(blurSigma,        other.blurSigma,        t),
      primaryGlass:     Color.lerp(primaryGlass,     other.primaryGlass,     t)!,
      primaryBorder:    Color.lerp(primaryBorder,    other.primaryBorder,    t)!,
      successGlass:     Color.lerp(successGlass,     other.successGlass,     t)!,
      successBorder:    Color.lerp(successBorder,    other.successBorder,    t)!,
      errorGlass:       Color.lerp(errorGlass,       other.errorGlass,       t)!,
      errorBorder:      Color.lerp(errorBorder,      other.errorBorder,      t)!,
      warningGlass:     Color.lerp(warningGlass,     other.warningGlass,     t)!,
      warningBorder:    Color.lerp(warningBorder,    other.warningBorder,    t)!,
      bkashGlass:       Color.lerp(bkashGlass,       other.bkashGlass,       t)!,
      shimmerBase:      Color.lerp(shimmerBase,      other.shimmerBase,      t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }

  // ─── Predefined instances ───────────────────────────────────
  static const dark = GlassTheme(
    cardColor:        AppColors.glassCardDark,
    elevatedColor:    AppColors.glassElevatedDark,
    pressedColor:     AppColors.glassPressedDark,
    borderColor:      AppColors.glassBorderDark,
    blurSigma:        AppSizes.blurMd,
    primaryGlass:     AppColors.primaryGlassDark,
    primaryBorder:    AppColors.primaryBorderDark,
    successGlass:     AppColors.successGlassDark,
    successBorder:    AppColors.successBorderDark,
    errorGlass:       AppColors.errorGlassDark,
    errorBorder:      AppColors.errorBorderDark,
    warningGlass:     AppColors.warningGlassDark,
    warningBorder:    AppColors.warningBorderDark,
    bkashGlass:       AppColors.bkashGlassDark,
    shimmerBase:      AppColors.shimmerBaseDark,
    shimmerHighlight: AppColors.shimmerHighDark,
  );

  static const light = GlassTheme(
    cardColor:        AppColors.glassCardLight,
    elevatedColor:    AppColors.glassElevatedLight,
    pressedColor:     AppColors.glassPressedLight,
    borderColor:      AppColors.glassBorderLight,
    blurSigma:        AppSizes.blurMd,
    primaryGlass:     AppColors.primaryGlassLight,
    primaryBorder:    AppColors.primaryBorderLight,
    successGlass:     AppColors.successGlassLight,
    successBorder:    AppColors.successBorderLight,
    errorGlass:       AppColors.errorGlassLight,
    errorBorder:      AppColors.errorBorderLight,
    warningGlass:     AppColors.warningGlassLight,
    warningBorder:    AppColors.warningBorderLight,
    bkashGlass:       AppColors.bkashGlassLight,
    shimmerBase:      AppColors.shimmerBaseLight,
    shimmerHighlight: AppColors.shimmerHighLight,
  );
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ─── AppTheme ─────────────────────────────────────────────────────────────────

abstract class AppTheme {
  // ─── Public entry points ──────────────────────────────────
  static ThemeData get dark  => _buildTheme(isDark: true);
  static ThemeData get light => _buildTheme(isDark: false);

  // ─── Core builder ─────────────────────────────────────────
  static ThemeData _buildTheme({required bool isDark}) {
    final base        = isDark ? ThemeData.dark()  : ThemeData.light();
    final bg          = isDark ? AppColors.darkBackground  : AppColors.lightBackground;
    final primary     = isDark ? AppColors.primaryDark     : AppColors.primaryLight;
    final onPrimary   = AppColors.onPrimary;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecond  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final divider     = isDark ? AppColors.dividerDark     : AppColors.dividerLight;
    final errorColor  = isDark ? AppColors.errorDark       : AppColors.errorLight;
    final glassCard   = isDark ? AppColors.glassCardDark   : AppColors.glassCardLight;
    final glassBorder = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    // System UI overlay — status bar adapts to theme
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
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    final colorScheme = ColorScheme(
      brightness:           isDark ? Brightness.dark : Brightness.light,
      primary:              primary,
      onPrimary:            onPrimary,
      primaryContainer:     isDark ? AppColors.primaryGlassDark  : AppColors.primaryGlassLight,
      onPrimaryContainer:   primary,
      secondary:            isDark ? AppColors.secondaryDark      : AppColors.secondaryLight,
      onSecondary:          onPrimary,
      secondaryContainer:   isDark ? AppColors.secondaryGlassDark : AppColors.secondaryGlassLight,
      onSecondaryContainer: isDark ? AppColors.secondaryDark      : AppColors.secondaryLight,
      error:                errorColor,
      onError:              Colors.white,
      errorContainer:       isDark ? AppColors.errorGlassDark    : AppColors.errorGlassLight,
      onErrorContainer:     errorColor,
      surface:              glassCard,
      onSurface:            textPrimary,
      surfaceContainerHighest: isDark ? AppColors.glassElevatedDark : AppColors.glassElevatedLight,
      outline:              glassBorder,
      outlineVariant:       divider,
      scrim:                isDark ? AppColors.overlayDark       : AppColors.overlayLight,
    );

    return base.copyWith(
      colorScheme:       colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor:       bg,
      cardColor:         glassCard,
      dividerColor:      divider,
      extensions:        [isDark ? GlassTheme.dark : GlassTheme.light],

      // ─── AppBar ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:    Colors.transparent,
        elevation:          0,
        scrolledUnderElevation: 0,
        centerTitle:        true,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: TextStyle(
          color:       textPrimary,
          fontSize:    AppSizes.headingSm,
          fontWeight:  FontWeight.w600,
          letterSpacing: AppSizes.trackingTight,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: AppSizes.iconMd),
        actionsIconTheme: IconThemeData(color: textSecond, size: AppSizes.iconMd),
      ),

      // ─── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:        glassCard,
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: BorderSide(color: glassBorder, width: AppSizes.cardBorderWidth),
        ),
        margin: const EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
      ),

      // ─── Elevated Button ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  primary,
          foregroundColor:  onPrimary,
          minimumSize:      const Size(double.infinity, AppSizes.buttonHeightMd),
          elevation:        0,
          shadowColor:      Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize:    AppSizes.bodyLg,
            fontWeight:  FontWeight.w600,
            letterSpacing: AppSizes.trackingNormal,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withOpacity(0.15);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),

      // ─── Outlined Button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeightMd),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          side: BorderSide(color: glassBorder, width: 1),
          textStyle: const TextStyle(
            fontSize:    AppSizes.bodyLg,
            fontWeight:  FontWeight.w600,
            letterSpacing: AppSizes.trackingNormal,
          ),
        ),
      ),

      // ─── Text Button ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize:    AppSizes.bodyMd,
            fontWeight:  FontWeight.w500,
          ),
        ),
      ),

      // ─── Input / TextField ──────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   glassCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.inputPaddingH,
          vertical:   AppSizes.md,
        ),
        hintStyle: TextStyle(
          color:    textSecond,
          fontSize: AppSizes.bodyMd,
        ),
        labelStyle: TextStyle(
          color:    textSecond,
          fontSize: AppSizes.bodyMd,
        ),
        floatingLabelStyle: TextStyle(
          color:    primary,
          fontSize: AppSizes.labelMd,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: textSecond,
        suffixIconColor: textSecond,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide:   BorderSide(color: glassBorder, width: AppSizes.inputBorderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide:   BorderSide(color: glassBorder, width: AppSizes.inputBorderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide:   BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide:   BorderSide(color: errorColor, width: AppSizes.inputBorderWidth),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide:   BorderSide(color: errorColor, width: 1.5),
        ),
        errorStyle: TextStyle(color: errorColor, fontSize: AppSizes.labelMd),
      ),

      // ─── Bottom Navigation Bar ──────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:     Colors.transparent,
        elevation:           0,
        selectedItemColor:   primary,
        unselectedItemColor: textSecond,
        selectedLabelStyle:  const TextStyle(
          fontSize:   AppSizes.labelSm,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize:   AppSizes.labelSm,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
      ),

      // ─── Navigation Bar (Material 3) ────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:    Colors.transparent,
        elevation:          0,
        indicatorColor:     isDark
            ? AppColors.primaryGlassDark
            : AppColors.primaryGlassLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: AppSizes.iconMd);
          }
          return IconThemeData(color: textSecond, size: AppSizes.iconMd);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color:      primary,
              fontSize:   AppSizes.labelSm,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color:      textSecond,
            fontSize:   AppSizes.labelSm,
            fontWeight: FontWeight.w400,
          );
        }),
      ),

      // ─── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: glassCard,
        selectedColor:   isDark ? AppColors.primaryGlassDark : AppColors.primaryGlassLight,
        disabledColor:   divider,
        labelStyle: TextStyle(
          color:      textPrimary,
          fontSize:   AppSizes.bodyXs,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color:      primary,
          fontSize:   AppSizes.bodyXs,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        side: BorderSide(color: glassBorder, width: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical:   AppSizes.xs,
        ),
      ),

      // ─── Divider ────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color:     divider,
        thickness: 0.5,
        space:     1,
      ),

      // ─── Dialog ─────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   AppSizes.headingSm,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color:    textSecond,
          fontSize: AppSizes.bodyMd,
          height:   AppSizes.lineHeightRelaxed,
        ),
      ),

      // ─── BottomSheet ────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:    isDark ? const Color(0xFF0A0A0A) : Colors.white,
        modalBackgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        elevation:           0,
        modalElevation:      0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXxl),
          ),
        ),
        dragHandleColor: divider,
        dragHandleSize:  const Size(40, 4),
        showDragHandle:  true,
      ),

      // ─── Snack Bar ──────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF111111),
        contentTextStyle: const TextStyle(
          color:      Colors.white,
          fontSize:   AppSizes.bodyMd,
          fontWeight: FontWeight.w400,
        ),
        actionTextColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior:      SnackBarBehavior.floating,
        elevation:     0,
        insetPadding:  const EdgeInsets.all(AppSizes.lg),
      ),

      // ─── List Tile ──────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        selectedTileColor: isDark ? AppColors.primaryGlassDark : AppColors.primaryGlassLight,
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   AppSizes.bodyMd,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color:    textSecond,
          fontSize: AppSizes.bodySm,
        ),
        iconColor:       textSecond,
        selectedColor:   primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical:   AppSizes.xs,
        ),
      ),

      // ─── Switch ─────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : textSecond;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.primaryGlassDark : AppColors.primaryGlassLight;
          }
          return glassCard;
        }),
        trackOutlineColor: WidgetStateProperty.all(glassBorder),
      ),

      // ─── Checkbox ───────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: glassBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        ),
      ),

      // ─── Radio ──────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : textSecond;
        }),
      ),

      // ─── Progress Indicator ─────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:             primary,
        linearTrackColor:  glassCard,
        circularTrackColor: glassCard,
      ),

      // ─── Slider ─────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor:   primary,
        inactiveTrackColor: glassCard,
        thumbColor:         primary,
        overlayColor:       primary.withOpacity(0.15),
        thumbShape:  const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
      ),

      // ─── Tab Bar ────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:         primary,
        unselectedLabelColor: textSecond,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        labelStyle: const TextStyle(
          fontSize:   AppSizes.bodyMd,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize:   AppSizes.bodyMd,
          fontWeight: FontWeight.w400,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ─── Icon ───────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: textPrimary,
        size:  AppSizes.iconMd,
      ),

      // ─── Text ───────────────────────────────────────────────
      textTheme: _buildTextTheme(textPrimary, textSecond),

      // ─── Page Transitions ────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),

      useMaterial3: true,
    );
  }

  // ─── Text Theme Builder ────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      // Display
      displayLarge:  _text(AppSizes.displayLg,  FontWeight.w700, primary),
      displayMedium: _text(AppSizes.displayMd,  FontWeight.w700, primary),
      displaySmall:  _text(AppSizes.displaySm,  FontWeight.w600, primary),
      // Heading
      headlineLarge:  _text(AppSizes.headingXl, FontWeight.w700, primary),
      headlineMedium: _text(AppSizes.headingLg, FontWeight.w600, primary),
      headlineSmall:  _text(AppSizes.headingMd, FontWeight.w600, primary),
      // Title
      titleLarge:  _text(AppSizes.headingSm, FontWeight.w600, primary),
      titleMedium: _text(AppSizes.bodyLg,    FontWeight.w500, primary),
      titleSmall:  _text(AppSizes.bodyMd,    FontWeight.w500, primary),
      // Body
      bodyLarge:   _text(AppSizes.bodyLg, FontWeight.w400, primary,
          height: AppSizes.lineHeightRelaxed),
      bodyMedium:  _text(AppSizes.bodyMd, FontWeight.w400, primary,
          height: AppSizes.lineHeightNormal),
      bodySmall:   _text(AppSizes.bodySm, FontWeight.w400, secondary,
          height: AppSizes.lineHeightNormal),
      // Label
      labelLarge:  _text(AppSizes.labelMd, FontWeight.w500, primary),
      labelMedium: _text(AppSizes.labelSm, FontWeight.w500, secondary),
      labelSmall:  _text(AppSizes.labelXs, FontWeight.w400, secondary,
          letterSpacing: AppSizes.trackingWidest),
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
      fontSize:      size,
      fontWeight:    weight,
      color:         color,
      height:        height,
      letterSpacing: letterSpacing,
    );
  }
}