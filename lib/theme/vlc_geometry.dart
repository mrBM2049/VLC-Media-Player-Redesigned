import 'package:flutter/material.dart';

/// Geometry and dimension tokens enforcing the modern rectangular aesthetic
/// from Figma TKMz3UlzGRDOxFHHXq4Bln (4dp–8dp corner radii, strictly NO pill buttons).
class VlcGeometry {
  const VlcGeometry();

  // --- Strict Rectangular Corner Radii (4dp–8dp) ---
  /// Small radius for tags, badge pills, slider notches, timeline ticks (4dp)
  static const double radiusSmall = 4.0;

  /// Medium radius for toolbar buttons, interactive control tiles, menu items (6dp)
  static const double radiusMedium = 6.0;

  /// Large radius for cards, inspector drawer, modal dialogs, preview popups (8dp)
  static const double radiusLarge = 8.0;

  /// Extra-large radius for outer window containers and rounded app shell corners (12dp)
  static const double radiusXLarge = 12.0;

  // --- Pre-computed BorderRadius instances ---
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(radiusXLarge));

  // --- Pre-computed ShapeBorders ---
  static const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: borderRadiusMedium,
  );
  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: borderRadiusLarge,
  );
  static const RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: borderRadiusLarge,
  );

  // --- 4dp Baseline Spacing Grid ---
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // --- Pre-computed EdgeInsets ---
  static const EdgeInsets insetsZero = EdgeInsets.zero;
  static const EdgeInsets insetsAll4 = EdgeInsets.all(space4);
  static const EdgeInsets insetsAll8 = EdgeInsets.all(space8);
  static const EdgeInsets insetsAll12 = EdgeInsets.all(space12);
  static const EdgeInsets insetsAll16 = EdgeInsets.all(space16);
  static const EdgeInsets insetsAll24 = EdgeInsets.all(space24);

  static const EdgeInsets insetsH8V4 = EdgeInsets.symmetric(horizontal: space8, vertical: space4);
  static const EdgeInsets insetsH12V8 = EdgeInsets.symmetric(horizontal: space12, vertical: space8);
  static const EdgeInsets insetsH16V8 = EdgeInsets.symmetric(horizontal: space16, vertical: space8);
  static const EdgeInsets insetsH16V12 = EdgeInsets.symmetric(horizontal: space16, vertical: space12);

  // --- Component Heights & Fixed Dimensions ---
  /// Height of the top player bar (breadcrumbs, unified menu, window controls)
  static const double topPlayerBarHeight = 48.0;

  /// Height of the bottom transport controls bar
  static const double bottomTransportRowHeight = 60.0;

  /// Default resting height of the Thick Seek Bar (10dp)
  static const double thickSeekBarHeightNormal = 10.0;

  /// Expanded height of the Thick Seek Bar when hovered (16dp)
  static const double thickSeekBarHeightHover = 16.0;

  /// Width of the seekbar scrubber thumb handle (4dp rectangular)
  static const double thickSeekBarScrubberWidth = 4.0;

  /// Width of the right-side 4-Tab Inspector Sidebar on desktop
  static const double inspectorDrawerWidth = 340.0;

  /// Width of the horizontal volume slider in the transport row
  static const double volumeSliderWidth = 120.0;

  /// Hover frame preview popup dimensions
  static const double hoverPreviewWidth = 160.0;
  static const double hoverPreviewHeight = 90.0;

  // --- Standard Icon Sizes ---
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;

  // --- Vector Stroke Widths ---
  /// Standard 1.5dp stroke width for monochrome interactive icons
  static const double strokeWidthMonochrome = 1.5;

  /// Thicker 2.0dp stroke for active indicators and scrubber ticks
  static const double strokeWidthActive = 2.0;

  /// Subtle 1.0dp stroke for container borders and panel dividers
  static const double strokeWidthBorder = 1.0;
}

