import 'package:flutter/material.dart';


abstract class AppColors {

  static const Color darkBackground     = Color(0xFF000000);

  static const Color lightBackground    = Color(0xFFFFFFFF);

  static const Color glassCardDark      = Color(0x0FFFFFFF); // 6% white
  /// Elevated glass — dark (nav bar, bottom sheet)
  static const Color glassElevatedDark  = Color(0x1AFFFFFF); // 10% white
  static const Color glassPressedDark   = Color(0x26FFFFFF); // 15% white

  static const Color glassCardLight     = Color(0x8CFFFFFF); // 55% white
  static const Color glassElevatedLight = Color(0xB3FFFFFF); // 70% white
  static const Color glassPressedLight  = Color(0xCCFFFFFF); // 80% white

  static const Color glassBorderDark    = Color(0x1AFFFFFF); // 10%
  static const Color glassBorderLight   = Color(0x26000000); // 15% black for visible light borders

  static const Color primaryDark        = Color(0xFF6366F1); // indigo-500
  static const Color primaryLight       = Color(0xFF4F46E5); // indigo-600

  static const Color primaryGlassDark   = Color(0x406366F1); // 25% indigo
  static const Color primaryGlassLight  = Color(0x1F4F46E5); // 12% indigo

  static const Color primaryBorderDark  = Color(0x736366F1); // 45% indigo
  static const Color primaryBorderLight = Color(0x4D4F46E5); // 30% indigo

  static const Color onPrimary          = Color(0xFFFFFFFF);

  static const Color secondaryDark      = Color(0xFFA855F7); // violet-500
  static const Color secondaryLight     = Color(0xFF8B5CF6); // violet-500

  static const Color secondaryGlassDark  = Color(0x33A855F7);
  static const Color secondaryGlassLight = Color(0x1A8B5CF6);

  static const Color successDark        = Color(0xFF34D399); // emerald-400
  static const Color successLight       = Color(0xFF10B981); // emerald-500

  static const Color successGlassDark   = Color(0x2634D399);
  static const Color successGlassLight  = Color(0x1A10B981);

  static const Color successBorderDark  = Color(0x5934D399);
  static const Color successBorderLight = Color(0x4D10B981);

  static const Color warningDark        = Color(0xFFFBBF24); // amber-400
  static const Color warningLight       = Color(0xFFF59E0B); // amber-500

  static const Color warningGlassDark   = Color(0x26FBBF24);
  static const Color warningGlassLight  = Color(0x1AF59E0B);

  static const Color warningBorderDark  = Color(0x4DFBBF24);
  static const Color warningBorderLight = Color(0x4DF59E0B);

  static const Color errorDark          = Color(0xFFF87171); // red-400
  static const Color errorLight         = Color(0xFFEF4444); // red-500

  static const Color errorGlassDark     = Color(0x26F87171);
  static const Color errorGlassLight    = Color(0x1AEF4444);

  static const Color errorBorderDark    = Color(0x4DF87171);
  static const Color errorBorderLight   = Color(0x40EF4444);

  static const Color textPrimaryDark    = Color(0xFFFFFFFF);
  static const Color textSecondaryDark  = Color(0x80FFFFFF); // 50%
  static const Color textTertiaryDark   = Color(0x4DFFFFFF); // 30%
  static const Color textDisabledDark   = Color(0x26FFFFFF); // 15%

  static const Color textPrimaryLight   = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0x80000000); // 50%
  static const Color textTertiaryLight  = Color(0x4D000000); // 30%
  static const Color textDisabledLight  = Color(0x26000000); // 15%

  static const Color dividerDark        = Color(0x14FFFFFF); // 8%
  static const Color dividerLight       = Color(0x12000000); // 7%

  static const Color shimmerBaseDark    = Color(0x0FFFFFFF);
  static const Color shimmerHighDark    = Color(0x26FFFFFF);
  static const Color shimmerBaseLight   = Color(0x0F000000);
  static const Color shimmerHighLight   = Color(0x1A000000);

  // ─── Overlay ───────────────────────────────────────────────
  static const Color overlayDark        = Color(0xCC000000); // 80% black
  static const Color overlayLight       = Color(0x80000000); // 50% black

  // ─── bKash Brand ───────────────────────────────────────────
  static const Color bkashPink          = Color(0xFFE2136E);
  static const Color bkashGlassDark     = Color(0x26E2136E);
  static const Color bkashGlassLight    = Color(0x1AE2136E);

  // ─── CoD Brand ─────────────────────────────────────────────
  static const Color codGreen           = Color(0xFF16A34A);

  // ─── Helper — context-aware getters ────────────────────────
  /// Returns the correct color based on current theme brightness
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
      Theme.of(context).brightness == Brightness.dark
          ? errorDark
          : errorLight;

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? warningDark
          : warningLight;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? dividerDark
          : dividerLight;
}
