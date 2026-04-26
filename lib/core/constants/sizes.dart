/// Wafi Design System — Spacing, Radius, Typography, Elevation Tokens
abstract class AppSizes {
  // ─── Base Spacing Grid (4px) ────────────────────────────────
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xl2  = 24.0;
  static const double xl3  = 32.0;
  static const double xl4  = 40.0;
  static const double xl5  = 48.0;
  static const double xl6  = 64.0;

  // ─── Screen Padding ─────────────────────────────────────────
  static const double screenPaddingH = 20.0;
  static const double screenPaddingV = 24.0;

  // ─── Border Radius ──────────────────────────────────────────
  static const double radiusXs  = 6.0;
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radiusXxl = 28.0;
  static const double radiusFull = 999.0; // pill shape

  // ─── Glass Card ─────────────────────────────────────────────
  static const double cardRadius     = radiusLg;
  static const double cardPaddingH   = 20.0;
  static const double cardPaddingV   = 16.0;
  static const double cardBorderWidth = 1.0;

  // ─── Blur Sigma (BackdropFilter) ────────────────────────────
  /// Subtle blur — chips, badges
  static const double blurSm  = 8.0;
  /// Default glass card blur
  static const double blurMd  = 20.0;
  /// Heavy blur — bottom sheet, modal
  static const double blurLg  = 40.0;
  /// Max blur — full screen overlay
  static const double blurXl  = 60.0;

  // ─── Typography ─────────────────────────────────────────────
  // Display
  static const double displayLg   = 36.0;
  static const double displayMd   = 30.0;
  static const double displaySm   = 24.0;

  // Heading
  static const double headingXl   = 22.0;
  static const double headingLg   = 20.0;
  static const double headingMd   = 18.0;
  static const double headingSm   = 16.0;

  // Body
  static const double bodyLg      = 16.0;
  static const double bodyMd      = 14.0;
  static const double bodySm      = 13.0;
  static const double bodyXs      = 12.0;

  // Caption / Label
  static const double labelMd     = 12.0;
  static const double labelSm     = 11.0;
  static const double labelXs     = 10.0;

  // ─── Line Height ────────────────────────────────────────────
  static const double lineHeightTight   = 1.2;
  static const double lineHeightNormal  = 1.5;
  static const double lineHeightRelaxed = 1.7;

  // ─── Letter Spacing ─────────────────────────────────────────
  static const double trackingTight  = -0.5;
  static const double trackingNormal = 0.0;
  static const double trackingWide   = 0.5;
  static const double trackingWidest = 1.2; // uppercase labels

  // ─── Icon Sizes ─────────────────────────────────────────────
  static const double iconXs  = 16.0;
  static const double iconSm  = 20.0;
  static const double iconMd  = 24.0;
  static const double iconLg  = 28.0;
  static const double iconXl  = 32.0;

  // ─── Avatar / Profile Picture ───────────────────────────────
  static const double avatarXs  = 28.0;
  static const double avatarSm  = 36.0;
  static const double avatarMd  = 48.0;
  static const double avatarLg  = 64.0;
  static const double avatarXl  = 96.0;

  // ─── Button ─────────────────────────────────────────────────
  static const double buttonHeightSm  = 36.0;
  static const double buttonHeightMd  = 48.0;
  static const double buttonHeightLg  = 56.0;
  static const double buttonRadius    = radiusMd;
  static const double buttonBorderWidth = 1.0;

  // ─── Input Field ────────────────────────────────────────────
  static const double inputHeight      = 52.0;
  static const double inputRadius      = radiusMd;
  static const double inputBorderWidth = 1.0;
  static const double inputPaddingH    = 16.0;

  // ─── Bottom Navigation ──────────────────────────────────────
  static const double bottomNavHeight = 72.0;
  static const double bottomNavRadius = radiusXxl;

  // ─── App Bar ────────────────────────────────────────────────
  static const double appBarHeight    = 56.0;

  // ─── Product Card ───────────────────────────────────────────
  static const double productCardWidth   = 160.0;
  static const double productImageHeight = 160.0;
  static const double productCardRadius  = radiusLg;

  // ─── Image Aspect Ratios ────────────────────────────────────
  static const double aspectSquare    = 1.0;
  static const double aspectProduct   = 0.8;   // 4:5
  static const double aspectBanner    = 0.4;   // 5:2
  static const double aspectCategory  = 0.75;  // 4:3

  // ─── Animation Durations (ms) ───────────────────────────────
  static const int animFast    = 150;
  static const int animNormal  = 250;
  static const int animSlow    = 400;
  static const int animVerySlow = 600;

  // ─── Opacity Tokens ─────────────────────────────────────────
  static const double opacityDisabled = 0.38;
  static const double opacityMedium   = 0.60;
  static const double opacityHigh     = 0.87;

  // ─── Z-Index Layers ─────────────────────────────────────────
  static const double zBase    = 0.0;
  static const double zCard    = 1.0;
  static const double zHeader  = 10.0;
  static const double zModal   = 100.0;
  static const double zToast   = 200.0;
}