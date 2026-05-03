import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color lightBackground = Color(0xFFF5F5F7);

  static const Color glassCardDark = Color(0x1624272B);
  static const Color glassElevatedDark = Color(0x242A2C31);
  static const Color glassPressedDark = Color(0x30303339);

  static const Color glassCardLight = Color(0xCCFFFFFF);
  static const Color glassElevatedLight = Color(0xE6FFFFFF);
  static const Color glassPressedLight = Color(0xF2FFFFFF);

  static const Color glassBorderDark = Color(0x33FFFFFF);
  static const Color glassBorderLight = Color(0x14FFFFFF);

  static const Color primaryDark = Color(0xFFFFA94D);
  static const Color primaryLight = Color(0xFFF28C28);

  static const Color primaryGlassDark = Color(0x33FFA94D);
  static const Color primaryGlassLight = Color(0x1FF28C28);

  static const Color primaryBorderDark = Color(0x66FFA94D);
  static const Color primaryBorderLight = Color(0x33F28C28);

  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondaryDark = Color(0xFF7A7A7A);
  static const Color secondaryLight = Color(0xFF333333);

  static const Color secondaryGlassDark = Color(0x1FFFFFFF);
  static const Color secondaryGlassLight = Color(0x14333333);

  static const Color successDark = Color(0xFF34D399);
  static const Color successLight = Color(0xFF10B981);

  static const Color successGlassDark = Color(0x2634D399);
  static const Color successGlassLight = Color(0x1A10B981);

  static const Color successBorderDark = Color(0x5934D399);
  static const Color successBorderLight = Color(0x4D10B981);

  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFF59E0B);

  static const Color warningGlassDark = Color(0x26FBBF24);
  static const Color warningGlassLight = Color(0x1AF59E0B);

  static const Color warningBorderDark = Color(0x4DFBBF24);
  static const Color warningBorderLight = Color(0x4DF59E0B);

  static const Color errorDark = Color(0xFFF87171);
  static const Color errorLight = Color(0xFFEF4444);

  static const Color errorGlassDark = Color(0x26F87171);
  static const Color errorGlassLight = Color(0x1AEF4444);

  static const Color errorBorderDark = Color(0x4DF87171);
  static const Color errorBorderLight = Color(0x40EF4444);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFCCCCCC);
  static const Color textTertiaryDark = Color(0x99FFFFFF);
  static const Color textDisabledDark = Color(0x52FFFFFF);

  static const Color textPrimaryLight = Color(0xFF1D1D1F);
  static const Color textSecondaryLight = Color(0xFF6E6E73);
  static const Color textTertiaryLight = Color(0xFF86868B);
  static const Color textDisabledLight = Color(0x807A7A7A);

  static const Color dividerDark = Color(0x1FFFFFFF);
  static const Color dividerLight = Color(0xFFE0E0E0);

  static const Color shimmerBaseDark = Color(0x1624272B);
  static const Color shimmerHighDark = Color(0x26FFFFFF);
  static const Color shimmerBaseLight = Color(0x14FFFFFF);
  static const Color shimmerHighLight = Color(0x66FFFFFF);

  static const Color overlayDark = Color(0xCC000000);
  static const Color overlayLight = Color(0x73000000);

  static const Color bkashPink = Color(0xFFE2136E);
  static const Color bkashGlassDark = Color(0x26E2136E);
  static const Color bkashGlassLight = Color(0x1AE2136E);

  static const Color codGreen = Color(0xFF16A34A);

  static Color glassCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? glassCardDark
      : glassCardLight;

  static Color glassBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? glassBorderDark
      : glassBorderLight;

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? primaryDark
      : primaryLight;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textPrimaryDark
      : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textSecondaryDark
      : textSecondaryLight;

  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? successDark
      : successLight;

  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? errorDark : errorLight;

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? warningDark
      : warningLight;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? dividerDark
      : dividerLight;
}
