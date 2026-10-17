import 'dart:ui';
import 'package:flutter/material.dart';

/// Typography tokens for VLC Modern Redesign.
/// Designed for crystal clarity across desktop monitors (macOS/Win) and mobile screens (iOS/Android).
class VlcTypography {
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelSmall;
  final TextStyle monospaceTime;

  const VlcTypography({
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelSmall,
    required this.monospaceTime,
  });

  factory VlcTypography.create({
    required Color primaryColor,
    required Color secondaryColor,
    required Color mutedColor,
    String? fontFamily,
  }) {
    return VlcTypography(
      // 18sp Semi-Bold: Modal titles, Media title in full player
      titleLarge: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        fontFamily: fontFamily,
        letterSpacing: -0.2,
        height: 1.25,
      ),

      // 16sp Semi-Bold: Card titles, drawer headers
      titleMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        fontFamily: fontFamily,
        letterSpacing: -0.1,
        height: 1.3,
      ),

      // 14sp Semi-Bold: Section titles, Inspector Tab titles
      titleSmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        fontFamily: fontFamily,
        height: 1.35,
      ),

      // 14sp Medium: Primary menu items, breadcrumb parent items
      bodyLarge: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        fontFamily: fontFamily,
        height: 1.4,
      ),

      // 13sp Regular: Standard UI text, list item subtitles
      bodyMedium: TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        fontFamily: fontFamily,
        height: 1.4,
      ),

      // 12sp Regular: Metadata, helper text, secondary properties
      bodySmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        fontFamily: fontFamily,
        height: 1.35,
      ),

      // 13sp Semi-Bold: Action buttons, dropdown labels
      labelLarge: TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),

      // 10sp Semi-Bold: Badge pills, OSD tags, format indicators (4K, HDR, 1080p)
      labelSmall: TextStyle(
        fontSize: 10.0,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        fontFamily: fontFamily,
        letterSpacing: 0.5,
      ),

      // 12sp Monospace / Tabular Figures: Prevents UI jitter during video playback time updates
      monospaceTime: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontFamily: 'monospace',
        letterSpacing: 0.3,
      ),
    );
  }

  VlcTypography copyWith({
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelSmall,
    TextStyle? monospaceTime,
  }) {
    return VlcTypography(
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelSmall: labelSmall ?? this.labelSmall,
      monospaceTime: monospaceTime ?? this.monospaceTime,
    );
  }

  static VlcTypography lerp(VlcTypography a, VlcTypography b, double t) {
    return VlcTypography(
      titleLarge: TextStyle.lerp(a.titleLarge, b.titleLarge, t) ?? a.titleLarge,
      titleMedium: TextStyle.lerp(a.titleMedium, b.titleMedium, t) ?? a.titleMedium,
      titleSmall: TextStyle.lerp(a.titleSmall, b.titleSmall, t) ?? a.titleSmall,
      bodyLarge: TextStyle.lerp(a.bodyLarge, b.bodyLarge, t) ?? a.bodyLarge,
      bodyMedium: TextStyle.lerp(a.bodyMedium, b.bodyMedium, t) ?? a.bodyMedium,
      bodySmall: TextStyle.lerp(a.bodySmall, b.bodySmall, t) ?? a.bodySmall,
      labelLarge: TextStyle.lerp(a.labelLarge, b.labelLarge, t) ?? a.labelLarge,
      labelSmall: TextStyle.lerp(a.labelSmall, b.labelSmall, t) ?? a.labelSmall,
      monospaceTime: TextStyle.lerp(a.monospaceTime, b.monospaceTime, t) ?? a.monospaceTime,
    );
  }
}
