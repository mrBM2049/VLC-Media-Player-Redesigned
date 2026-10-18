import 'package:flutter/material.dart';
import '../../models/subtitle_models.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Subtitles Tab (Tab 0) for the 4-Tab InspectorSidebar.
/// Provides track selection, fine-grained SPU sync stepper/slider,
/// font and color customizer, relative vs precise sizing, and real-time dialogue preview box.
class SubtitleInspectorTab extends StatefulWidget {
  final List<VlcSubtitleTrack> tracks;
  final int selectedTrackId;
  final Duration currentDelay;
  final SubtitleAppearance appearance;
  final bool isTimelineOverlayEnabled;
  final ValueChanged<int> onSelectTrack;
  final ValueChanged<Duration> onDelayChanged;
  final ValueChanged<SubtitleAppearance> onAppearanceChanged;
  final ValueChanged<bool> onToggleTimelineOverlay;
  final VoidCallback onAddSubtitle;

  const SubtitleInspectorTab({
    super.key,
    required this.tracks,
    required this.selectedTrackId,
    required this.currentDelay,
    required this.appearance,
    required this.isTimelineOverlayEnabled,
    required this.onSelectTrack,
    required this.onDelayChanged,
    required this.onAppearanceChanged,
    required this.onToggleTimelineOverlay,
    required this.onAddSubtitle,
  });

  @override
  State<SubtitleInspectorTab> createState() => _SubtitleInspectorTabState();
}

class _SubtitleInspectorTabState extends State<SubtitleInspectorTab> {
  static const List<int> _quickColors = [
    0xFFFFFFFF, // Pure White
    0xFFFFF176, // Soft Yellow
    0xFF80D8FF, // Cyan
    0xFFCCFF90, // Mint Green
    0xFFFFB74D, // Orange
  ];

  static const List<String> _fontFamilies = [
    'Inter',
    'Trebuchet MS',
    'Roboto',
    'Courier New',
    'Times New Roman',
  ];

  String _formatDelay(Duration d) {
    final ms = d.inMilliseconds;
    if (ms == 0) return '0.0 s (In Sync)';
    final sign = ms > 0 ? '+' : '';
    final seconds = (ms / 1000.0).toStringAsFixed(2);
    return '$sign${seconds}s ($sign$ms ms)';
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final delayMs = widget.currentDelay.inMilliseconds.toDouble();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      children: [
        // -------------------------------------------------------------
        // 1. Active Subtitle Track Selector
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'ACTIVE TRACK',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: vlcTheme.typography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: widget.onAddSubtitle,
              borderRadius: VlcGeometry.borderRadiusSmall,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14.0, color: colors.accent.primary),
                    const SizedBox(width: 4.0),
                    Text(
                      'Add Subtitle...',
                      style: vlcTheme.typography.labelSmall.copyWith(
                        color: colors.accent.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            child: DropdownButton<int>(
              value: widget.tracks.any((t) => t.id == widget.selectedTrackId)
                  ? widget.selectedTrackId
                  : (widget.tracks.isNotEmpty ? widget.tracks.first.id : -1),
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              onChanged: (newId) {
                if (newId != null) widget.onSelectTrack(newId);
              },
              items: [
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text('Disable Subtitles'),
                ),
                for (final track in widget.tracks)
                  DropdownMenuItem<int>(
                    value: track.id,
                    child: Text(
                      track.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 2. Subtitle Delay / Synchronization Stepper & Slider
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'SUBTITLE SYNC (DELAY)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: vlcTheme.typography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: delayMs != 0 ? colors.accent.subtleBackground : colors.surfaceHover,
                borderRadius: VlcGeometry.borderRadiusSmall,
                border: Border.all(
                  color: delayMs != 0 ? colors.accent.subtleBorder : colors.border,
                ),
              ),
              child: Text(
                _formatDelay(widget.currentDelay),
                style: vlcTheme.typography.monospaceTime.copyWith(
                  color: delayMs != 0 ? colors.accent.primary : colors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),

        // Slider from -10.0s to +10.0s (-10000ms to +10000ms)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.accent.primary,
            inactiveTrackColor: colors.surfaceVariant,
            thumbColor: colors.accent.primary,
            overlayColor: colors.accent.glow,
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            value: delayMs.clamp(-10000.0, 10000.0),
            min: -10000.0,
            max: 10000.0,
            divisions: 400, // 50ms steps
            onChanged: (val) {
              widget.onDelayChanged(Duration(milliseconds: val.round()));
            },
          ),
        ),

        // Quick Stepper Buttons: -500ms, -50ms, Reset (0ms), +50ms, +500ms
        Row(
          children: [
            Expanded(
              child: _buildStepperButton('-500ms', () {
                widget.onDelayChanged(widget.currentDelay - const Duration(milliseconds: 500));
              }, colors, vlcTheme),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: _buildStepperButton('-50ms', () {
                widget.onDelayChanged(widget.currentDelay - const Duration(milliseconds: 50));
              }, colors, vlcTheme),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: _buildStepperButton(
                '0.0s',
                () => widget.onDelayChanged(Duration.zero),
                colors,
                vlcTheme,
                isHighlight: delayMs != 0,
              ),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: _buildStepperButton('+50ms', () {
                widget.onDelayChanged(widget.currentDelay + const Duration(milliseconds: 50));
              }, colors, vlcTheme),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: _buildStepperButton('+500ms', () {
                widget.onDelayChanged(widget.currentDelay + const Duration(milliseconds: 500));
              }, colors, vlcTheme),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 3. Interactive Subtitle Timeline Switch
        // -------------------------------------------------------------
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              VlcMonochromeIcon(
                VlcIconGlyph.subtitles,
                size: 16.0,
                color: widget.isTimelineOverlayEnabled ? colors.accent.primary : colors.textTertiary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Timeline Bar',
                      style: vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Drag dialogue block above seek bar to sync',
                      style: vlcTheme.typography.labelSmall.copyWith(
                        color: colors.textTertiary,
                        fontSize: 10.0,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isTimelineOverlayEnabled,
                activeColor: colors.accent.primary,
                onChanged: widget.onToggleTimelineOverlay,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18.0),

        // -------------------------------------------------------------
        // 4. Real-time Dialogue Live Preview Box
        // -------------------------------------------------------------
        Text(
          'LIVE PREVIEW',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        _buildLivePreviewBox(colors, vlcTheme),

        const SizedBox(height: 18.0),

        // -------------------------------------------------------------
        // 5. Typography & Font Styling
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FONT SCALE',
              style: vlcTheme.typography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${(widget.appearance.fontScale * 100).round()}%',
              style: vlcTheme.typography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.accent.primary,
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
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            value: widget.appearance.fontScale.clamp(0.5, 2.0),
            min: 0.5,
            max: 2.0,
            divisions: 30, // 5% increments
            onChanged: (val) {
              widget.onAppearanceChanged(widget.appearance.copyWith(fontScale: val));
            },
          ),
        ),

        const SizedBox(height: 10.0),

        // Font Family Selector Dropdown
        Text(
          'FONT FAMILY',
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
            child: DropdownButton<String>(
              value: _fontFamilies.contains(widget.appearance.fontFamily)
                  ? widget.appearance.fontFamily
                  : _fontFamilies.first,
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              onChanged: (newFont) {
                if (newFont != null) {
                  widget.onAppearanceChanged(widget.appearance.copyWith(fontFamily: newFont));
                }
              },
              items: [
                for (final f in _fontFamilies)
                  DropdownMenuItem<String>(
                    value: f,
                    child: Text(f),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 6. Text Color & Stroke Outline
        // -------------------------------------------------------------
        Text(
          'TEXT COLOR',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            for (final col in _quickColors) ...[
              InkWell(
                onTap: () {
                  widget.onAppearanceChanged(widget.appearance.copyWith(textColorValue: col));
                },
                borderRadius: BorderRadius.circular(4.0),
                child: Container(
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: Color(col),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: widget.appearance.textColorValue == col
                          ? colors.accent.primary
                          : Colors.grey.shade700,
                      width: widget.appearance.textColorValue == col ? 2.5 : 1.0,
                    ),
                  ),
                  child: widget.appearance.textColorValue == col
                      ? Icon(
                          Icons.check,
                          size: 16.0,
                          color: col == 0xFFFFFFFF || col == 0xFFFFF176 ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8.0),
            ],
          ],
        ),

        const SizedBox(height: 16.0),

        // Outline / Stroke Width
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OUTLINE / STROKE',
              style: vlcTheme.typography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              widget.appearance.outlineWidth == 0.0
                  ? 'None'
                  : '${widget.appearance.outlineWidth.toStringAsFixed(1)} dp',
              style: vlcTheme.typography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.accent.primary,
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
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            value: widget.appearance.outlineWidth.clamp(0.0, 4.0),
            min: 0.0,
            max: 4.0,
            divisions: 8,
            onChanged: (val) {
              widget.onAppearanceChanged(widget.appearance.copyWith(outlineWidth: val));
            },
          ),
        ),

        const SizedBox(height: 12.0),

        // -------------------------------------------------------------
        // 7. Background Shading Style
        // -------------------------------------------------------------
        Text(
          'BACKGROUND SHADING',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        Row(
          children: [
            for (final bg in SubtitleBackgroundStyle.values) ...[
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.onAppearanceChanged(widget.appearance.copyWith(backgroundStyle: bg));
                  },
                  borderRadius: VlcGeometry.borderRadiusSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    decoration: BoxDecoration(
                      color: widget.appearance.backgroundStyle == bg
                          ? colors.accent.subtleBackground
                          : colors.surfaceHover,
                      borderRadius: VlcGeometry.borderRadiusSmall,
                      border: Border.all(
                        color: widget.appearance.backgroundStyle == bg
                            ? colors.accent.primary
                            : colors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bg.name.toUpperCase(),
                      style: vlcTheme.typography.labelSmall.copyWith(
                        fontSize: 9.5,
                        fontWeight: widget.appearance.backgroundStyle == bg
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: widget.appearance.backgroundStyle == bg
                            ? colors.accent.primary
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
            ],
          ],
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 8. Relative vs Precise Sizing Mode Toggle
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relative Auto-Scaling',
                    style: vlcTheme.typography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.appearance.isRelativeSizing
                        ? 'Font scales proportionally with video window'
                        : 'Fixed pixel sizing across all screen sizes',
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
              value: widget.appearance.isRelativeSizing,
              activeColor: colors.accent.primary,
              onChanged: (val) {
                widget.onAppearanceChanged(widget.appearance.copyWith(isRelativeSizing: val));
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildStepperButton(
    String label,
    VoidCallback onTap,
    VlcColors colors,
    VlcThemeData vlcTheme, {
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: VlcGeometry.borderRadiusSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: isHighlight ? colors.accent.subtleBackground : colors.surfaceHover,
          borderRadius: VlcGeometry.borderRadiusSmall,
          border: Border.all(
            color: isHighlight ? colors.accent.primary : colors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: vlcTheme.typography.monospaceTime.copyWith(
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
            color: isHighlight ? colors.accent.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewBox(VlcColors colors, VlcThemeData vlcTheme) {
    final textColor = Color(widget.appearance.textColorValue)
        .withValues(alpha: widget.appearance.textOpacity);
    final outlineColor = Color(widget.appearance.outlineColorValue);
    final fontSize = 14.0 * widget.appearance.fontScale;

    BoxDecoration bgDeco = const BoxDecoration();
    if (widget.appearance.backgroundStyle == SubtitleBackgroundStyle.semiTransparent) {
      bgDeco = BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2.0),
      );
    } else if (widget.appearance.backgroundStyle == SubtitleBackgroundStyle.solidBlack) {
      bgDeco = const BoxDecoration(color: Colors.black);
    } else if (widget.appearance.backgroundStyle == SubtitleBackgroundStyle.roundedBox) {
      bgDeco = BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.white24, width: 0.5),
      );
    }

    return Container(
      height: 90.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF101418), // Simulated 16:9 video letterbox
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          // Simulated scene background
          Positioned.fill(
            child: Opacity(
              opacity: 0.20,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Sample dialogue centered/positioned
          Align(
            alignment: widget.appearance.alignment == SubtitleAlignment.top
                ? Alignment.topCenter
                : (widget.appearance.alignment == SubtitleAlignment.center
                    ? Alignment.center
                    : Alignment.bottomCenter),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Container(
                padding: widget.appearance.backgroundStyle != SubtitleBackgroundStyle.none
                    ? const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0)
                    : EdgeInsets.zero,
                decoration: bgDeco,
                child: Stack(
                  children: [
                    // Outline stroke layer
                    if (widget.appearance.outlineWidth > 0.0)
                      Text(
                        '“Look at that rabbit... It’s dynamite!”',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: widget.appearance.fontFamily,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = widget.appearance.outlineWidth
                            ..color = outlineColor,
                        ),
                      ),
                    // Main fill text layer
                    Text(
                      '“Look at that rabbit... It’s dynamite!”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: widget.appearance.fontFamily,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
