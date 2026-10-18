import 'package:flutter/material.dart';
import '../../models/video_models.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Video & Aspect Tab (Tab 2) for the 4-Tab InspectorSidebar.
/// Provides aspect ratio selection, crop geometry, orientation/rotation,
/// visual video filter preset cards, brightness/contrast/saturation color sliders,
/// HDR tone-mapping, and hardware acceleration toggles.
class VideoInspectorTab extends StatefulWidget {
  final VideoAdjustState adjustState;
  final ValueChanged<VideoAdjustState> onAdjustStateChanged;
  final VoidCallback? onTakeSnapshot;

  const VideoInspectorTab({
    super.key,
    required this.adjustState,
    required this.onAdjustStateChanged,
    this.onTakeSnapshot,
  });

  @override
  State<VideoInspectorTab> createState() => _VideoInspectorTabState();
}

class _VideoInspectorTabState extends State<VideoInspectorTab> {
  bool _isColorSlidersExpanded = true;

  IconData _getPresetIcon(String iconKey) {
    switch (iconKey) {
      case 'film':
        return Icons.movie_filter;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'movie':
        return Icons.theaters;
      case 'contrast':
        return Icons.monochrome_photos;
      case 'sun':
        return Icons.wb_sunny;
      case 'snowflake':
        return Icons.ac_unit;
      default:
        return Icons.palette;
    }
  }

  LinearGradient _getPresetGradient(String id) {
    switch (id) {
      case 'vivid':
        return const LinearGradient(
          colors: [Color(0xFFFF2A6D), Color(0xFF05D9E8), Color(0xFFFFDB00)],
        );
      case 'cinematic':
        return const LinearGradient(
          colors: [Color(0xFF005F73), Color(0xFF0A9396), Color(0xFFEE9B00), Color(0xFFCA6702)],
        );
      case 'noir':
        return const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF404040), Color(0xFF808080), Color(0xFFFFFFFF)],
        );
      case 'golden':
        return const LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFFDAA520), Color(0xFFFFD700)],
        );
      case 'cool':
        return const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B4965), Color(0xFF62B6CB), Color(0xFFBEE9E8)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF4A4E69), Color(0xFF9A8C98), Color(0xFFF2E9E4)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final state = widget.adjustState;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      children: [
        // -------------------------------------------------------------
        // 1. Aspect Ratio Selector
        // -------------------------------------------------------------
        Text(
          'ASPECT RATIO',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<VlcAspectRatio>(
              value: state.aspectRatio,
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              onChanged: (newRatio) {
                if (newRatio != null) {
                  widget.onAdjustStateChanged(state.copyWith(aspectRatio: newRatio));
                }
              },
              items: [
                for (final r in VlcAspectRatio.values)
                  DropdownMenuItem<VlcAspectRatio>(
                    value: r,
                    child: Text(r.label),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 2. Crop Geometry & Deinterlacing
        // -------------------------------------------------------------
        Row(
          children: [
            // Crop Geometry
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CROP GEOMETRY',
                    style: vlcTheme.typography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: colors.surfaceHover,
                      borderRadius: VlcGeometry.borderRadiusMedium,
                      border: Border.all(color: colors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VlcCropGeometry>(
                        value: state.cropGeometry,
                        isExpanded: true,
                        dropdownColor: colors.surface,
                        icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                        style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                        onChanged: (newCrop) {
                          if (newCrop != null) {
                            widget.onAdjustStateChanged(state.copyWith(cropGeometry: newCrop));
                          }
                        },
                        items: [
                          for (final c in VlcCropGeometry.values)
                            DropdownMenuItem<VlcCropGeometry>(
                              value: c,
                              child: Text(
                                c.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),

            // Deinterlacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEINTERLACE',
                    style: vlcTheme.typography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: colors.surfaceHover,
                      borderRadius: VlcGeometry.borderRadiusMedium,
                      border: Border.all(color: colors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VlcDeinterlaceMode>(
                        value: state.deinterlaceMode,
                        isExpanded: true,
                        dropdownColor: colors.surface,
                        icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                        style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                        onChanged: (newMode) {
                          if (newMode != null) {
                            widget.onAdjustStateChanged(state.copyWith(deinterlaceMode: newMode));
                          }
                        },
                        items: [
                          for (final m in VlcDeinterlaceMode.values)
                            DropdownMenuItem<VlcDeinterlaceMode>(
                              value: m,
                              child: Text(
                                m.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 3. Orientation & Video Rotation
        // -------------------------------------------------------------
        Text(
          'ORIENTATION & ROTATION',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        Row(
          children: [
            for (final rot in VlcVideoRotation.values) ...[
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.onAdjustStateChanged(state.copyWith(rotation: rot));
                  },
                  borderRadius: VlcGeometry.borderRadiusSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    decoration: BoxDecoration(
                      color: state.rotation == rot
                          ? colors.accent.subtleBackground
                          : colors.surfaceHover,
                      borderRadius: VlcGeometry.borderRadiusSmall,
                      border: Border.all(
                        color: state.rotation == rot
                            ? colors.accent.primary
                            : colors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rotate_right,
                          size: 13.0,
                          color: state.rotation == rot
                              ? colors.accent.primary
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          rot.label,
                          style: vlcTheme.typography.monospaceTime.copyWith(
                            fontSize: 10.5,
                            fontWeight: state.rotation == rot ? FontWeight.w700 : FontWeight.w500,
                            color: state.rotation == rot
                                ? colors.accent.primary
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
            ],
          ],
        ),

        const SizedBox(height: 18.0),

        // -------------------------------------------------------------
        // 4. Visual Video Filter Preset Cards
        // -------------------------------------------------------------
        Text(
          'VIDEO SHADER & COLOR PRESETS',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1.85,
          ),
          itemCount: VideoFilterPreset.standardPresets.length,
          itemBuilder: (context, idx) {
            final preset = VideoFilterPreset.standardPresets[idx];
            final isSelected = state.activePresetId == preset.id;

            return InkWell(
              onTap: () {
                widget.onAdjustStateChanged(
                  state.copyWith(
                    activePresetId: preset.id,
                    brightness: preset.brightness,
                    contrast: preset.contrast,
                    saturation: preset.saturation,
                    gamma: preset.gamma,
                    hue: preset.hue,
                    isAdjustEnabled: preset.id != 'standard',
                  ),
                );
              },
              borderRadius: VlcGeometry.borderRadiusMedium,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accent.subtleBackground : colors.surfaceHover,
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  border: Border.all(
                    color: isSelected ? colors.accent.primary : colors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPresetIcon(preset.iconKey),
                          size: 14.0,
                          color: isSelected ? colors.accent.primary : colors.textSecondary,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            preset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: vlcTheme.typography.bodySmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? colors.accent.primary : colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      preset.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: vlcTheme.typography.labelSmall.copyWith(
                        fontSize: 9.0,
                        color: colors.textTertiary,
                      ),
                    ),
                    // Mini Gradient Spectrum Bar
                    Container(
                      height: 4.0,
                      decoration: BoxDecoration(
                        gradient: _getPresetGradient(preset.id),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 18.0),

        // -------------------------------------------------------------
        // 5. Expandable Color & Image Adjustments
        // -------------------------------------------------------------
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isColorSlidersExpanded = !_isColorSlidersExpanded),
                borderRadius: VlcGeometry.borderRadiusMedium,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Icon(
                        _isColorSlidersExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 18.0,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          'Color Adjustments (Fine-Tuning)',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.onAdjustStateChanged(
                            state.copyWith(
                              activePresetId: 'standard',
                              brightness: 1.0,
                              contrast: 1.0,
                              saturation: 1.0,
                              gamma: 1.0,
                              hue: 0.0,
                              isAdjustEnabled: false,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          child: Text(
                            'Reset',
                            style: vlcTheme.typography.labelSmall.copyWith(
                              color: colors.accent.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isColorSlidersExpanded) ...[
                const Divider(height: 1.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Column(
                    children: [
                      // Brightness
                      _buildSliderRow(
                        label: 'BRIGHTNESS',
                        value: state.brightness,
                        displayValue: '${(state.brightness * 100).round()}%',
                        min: 0.0,
                        max: 2.0,
                        colors: colors,
                        vlcTheme: vlcTheme,
                        onChanged: (val) {
                          widget.onAdjustStateChanged(
                            state.copyWith(brightness: val, isAdjustEnabled: true),
                          );
                        },
                      ),
                      const SizedBox(height: 8.0),

                      // Contrast
                      _buildSliderRow(
                        label: 'CONTRAST',
                        value: state.contrast,
                        displayValue: '${(state.contrast * 100).round()}%',
                        min: 0.0,
                        max: 2.0,
                        colors: colors,
                        vlcTheme: vlcTheme,
                        onChanged: (val) {
                          widget.onAdjustStateChanged(
                            state.copyWith(contrast: val, isAdjustEnabled: true),
                          );
                        },
                      ),
                      const SizedBox(height: 8.0),

                      // Saturation
                      _buildSliderRow(
                        label: 'SATURATION',
                        value: state.saturation,
                        displayValue: '${(state.saturation * 100).round()}%',
                        min: 0.0,
                        max: 3.0,
                        colors: colors,
                        vlcTheme: vlcTheme,
                        onChanged: (val) {
                          widget.onAdjustStateChanged(
                            state.copyWith(saturation: val, isAdjustEnabled: true),
                          );
                        },
                      ),
                      const SizedBox(height: 8.0),

                      // Gamma
                      _buildSliderRow(
                        label: 'GAMMA',
                        value: state.gamma,
                        displayValue: state.gamma.toStringAsFixed(2),
                        min: 0.1,
                        max: 3.0,
                        colors: colors,
                        vlcTheme: vlcTheme,
                        onChanged: (val) {
                          widget.onAdjustStateChanged(
                            state.copyWith(gamma: val, isAdjustEnabled: true),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18.0),

        // -------------------------------------------------------------
        // 6. HDR & Hardware Acceleration
        // -------------------------------------------------------------
        Text(
          'HARDWARE & ENGINE RENDERING',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              // HDR Tone Mapping
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HDR Tone Mapping',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Perceptual color mapping for SDR/HDR displays',
                          style: vlcTheme.typography.labelSmall.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Switch(
                    value: state.hdrToneMapping,
                    activeColor: colors.accent.primary,
                    onChanged: (val) {
                      widget.onAdjustStateChanged(state.copyWith(hdrToneMapping: val));
                    },
                  ),
                ],
              ),
              const Divider(height: 14.0),
              // Hardware Acceleration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hardware GPU Decoding',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Zero-copy Metal / D3D11 / SurfaceTexture',
                          style: vlcTheme.typography.labelSmall.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Switch(
                    value: state.hardwareAcceleration,
                    activeColor: colors.accent.primary,
                    onChanged: (val) {
                      widget.onAdjustStateChanged(state.copyWith(hardwareAcceleration: val));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 7. Take Snapshot Action
        // -------------------------------------------------------------
        if (widget.onTakeSnapshot != null) ...[
          InkWell(
            onTap: widget.onTakeSnapshot,
            borderRadius: VlcGeometry.borderRadiusMedium,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9.0),
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: VlcGeometry.borderRadiusMedium,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 16.0, color: colors.accent.primary),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      'Capture Video Snapshot (PNG)',
                      style: vlcTheme.typography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required String displayValue,
    required double min,
    required double max,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: vlcTheme.typography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              displayValue,
              style: vlcTheme.typography.monospaceTime.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: (value - 1.0).abs() > 0.05 ? colors.accent.primary : colors.textSecondary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.accent.primary,
            inactiveTrackColor: colors.surfaceVariant,
            thumbColor: colors.accent.primary,
            overlayColor: colors.accent.glow,
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
