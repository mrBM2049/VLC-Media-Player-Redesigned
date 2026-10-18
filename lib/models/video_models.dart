import 'package:flutter/foundation.dart';

/// Aspect Ratio options for video frame rendering
enum VlcAspectRatio {
  original('Original / Auto', null),
  r16_9('16:9 (Widescreen)', '16:9'),
  r4_3('4:3 (Classic TV)', '4:3'),
  r21_9('2.39:1 (Cinema / 21:9)', '21:9'),
  r1_1('1:1 (Square)', '1:1'),
  r16_10('16:10 (Monitor)', '16:10'),
  fitScreen('Fit to Screen', 'fit'),
  fillScreen('Fill & Crop', 'fill');

  final String label;
  final String? ratioString;
  const VlcAspectRatio(this.label, this.ratioString);
}

/// Crop geometry presets
enum VlcCropGeometry {
  none('None (Original)', null),
  c16_9('16:9', '16:9'),
  c16_10('16:10', '16:10'),
  c1_85('1.85:1 (Theatrical)', '1.85:1'),
  c2_21('2.21:1', '2.21:1'),
  c2_35('2.35:1', '2.35:1'),
  c2_39('2.39:1 (Anamorphic)', '2.39:1'),
  c4_3('4:3', '4:3');

  final String label;
  final String? cropString;
  const VlcCropGeometry(this.label, this.cropString);
}

/// Video rotation orientation
enum VlcVideoRotation {
  rot0('0°', 0),
  rot90('90°', 90),
  rot180('180°', 180),
  rot270('270°', 270);

  final String label;
  final int degrees;
  const VlcVideoRotation(this.label, this.degrees);
}

/// Deinterlacing modes
enum VlcDeinterlaceMode {
  off('Off'),
  auto('Automatic'),
  yadif('Yadif (2x)'),
  blend('Blend'),
  bob('Bob'),
  linear('Linear');

  final String label;
  const VlcDeinterlaceMode(this.label);
}

/// Visual video filter preset card profile
class VideoFilterPreset {
  final String id;
  final String name;
  final String subtitle;
  final String iconKey;
  final double brightness; // 0.0 to 2.0 (1.0 = normal)
  final double contrast;   // 0.0 to 2.0 (1.0 = normal)
  final double saturation; // 0.0 to 3.0 (1.0 = normal)
  final double gamma;      // 0.01 to 10.0 (1.0 = normal)
  final double hue;        // -180 to +180 (0 = normal)

  const VideoFilterPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconKey,
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.gamma = 1.0,
    this.hue = 0.0,
  });

  static const VideoFilterPreset standard = VideoFilterPreset(
    id: 'standard',
    name: 'Standard / Neutral',
    subtitle: 'True-to-source studio master',
    iconKey: 'film',
    brightness: 1.0,
    contrast: 1.0,
    saturation: 1.0,
    gamma: 1.0,
    hue: 0.0,
  );

  static const VideoFilterPreset vivid = VideoFilterPreset(
    id: 'vivid',
    name: 'Vivid Cinema',
    subtitle: 'Lush colors • Rich dynamic contrast',
    iconKey: 'sparkles',
    brightness: 1.05,
    contrast: 1.25,
    saturation: 1.40,
    gamma: 0.95,
    hue: 0.0,
  );

  static const VideoFilterPreset cinematic = VideoFilterPreset(
    id: 'cinematic',
    name: 'Teal & Orange',
    subtitle: 'Blockbuster movie color grade',
    iconKey: 'movie',
    brightness: 1.0,
    contrast: 1.20,
    saturation: 1.20,
    gamma: 0.90,
    hue: -12.0,
  );

  static const VideoFilterPreset noir = VideoFilterPreset(
    id: 'noir',
    name: 'Noir / Monochrome',
    subtitle: 'High contrast black & white',
    iconKey: 'contrast',
    brightness: 0.98,
    contrast: 1.40,
    saturation: 0.0,
    gamma: 1.05,
    hue: 0.0,
  );

  static const VideoFilterPreset golden = VideoFilterPreset(
    id: 'golden',
    name: 'Warm Golden Hour',
    subtitle: 'Amber highlights • Soft warmth',
    iconKey: 'sun',
    brightness: 1.02,
    contrast: 1.10,
    saturation: 1.15,
    gamma: 1.0,
    hue: 15.0,
  );

  static const VideoFilterPreset cool = VideoFilterPreset(
    id: 'cool',
    name: 'Cool Frost / Sci-Fi',
    subtitle: 'Crisp cold tones • Sharp clarity',
    iconKey: 'snowflake',
    brightness: 1.0,
    contrast: 1.15,
    saturation: 1.05,
    gamma: 0.95,
    hue: -25.0,
  );

  static const List<VideoFilterPreset> standardPresets = [
    standard,
    vivid,
    cinematic,
    noir,
    golden,
    cool,
  ];
}

/// Reactive State for Video Geometry, Color Adjustments, and Post-Processing
class VideoAdjustState {
  final VlcAspectRatio aspectRatio;
  final VlcCropGeometry cropGeometry;
  final VlcVideoRotation rotation;
  final VlcDeinterlaceMode deinterlaceMode;
  final String activePresetId;
  final double brightness; // 0.0 to 2.0
  final double contrast;   // 0.0 to 2.0
  final double saturation; // 0.0 to 3.0
  final double gamma;      // 0.01 to 10.0
  final double hue;        // -180 to +180
  final bool isAdjustEnabled;
  final bool hdrToneMapping;
  final bool hardwareAcceleration;

  const VideoAdjustState({
    this.aspectRatio = VlcAspectRatio.original,
    this.cropGeometry = VlcCropGeometry.none,
    this.rotation = VlcVideoRotation.rot0,
    this.deinterlaceMode = VlcDeinterlaceMode.auto,
    this.activePresetId = 'standard',
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.gamma = 1.0,
    this.hue = 0.0,
    this.isAdjustEnabled = false,
    this.hdrToneMapping = true,
    this.hardwareAcceleration = true,
  });

  VideoAdjustState copyWith({
    VlcAspectRatio? aspectRatio,
    VlcCropGeometry? cropGeometry,
    VlcVideoRotation? rotation,
    VlcDeinterlaceMode? deinterlaceMode,
    String? activePresetId,
    double? brightness,
    double? contrast,
    double? saturation,
    double? gamma,
    double? hue,
    bool? isAdjustEnabled,
    bool? hdrToneMapping,
    bool? hardwareAcceleration,
  }) {
    return VideoAdjustState(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      cropGeometry: cropGeometry ?? this.cropGeometry,
      rotation: rotation ?? this.rotation,
      deinterlaceMode: deinterlaceMode ?? this.deinterlaceMode,
      activePresetId: activePresetId ?? this.activePresetId,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      gamma: gamma ?? this.gamma,
      hue: hue ?? this.hue,
      isAdjustEnabled: isAdjustEnabled ?? this.isAdjustEnabled,
      hdrToneMapping: hdrToneMapping ?? this.hdrToneMapping,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
    );
  }
}

