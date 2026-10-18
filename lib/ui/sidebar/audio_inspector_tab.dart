import 'package:flutter/material.dart';
import '../../models/audio_models.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Audio & Equalizer Tab (Tab 1) for the 4-Tab InspectorSidebar.
/// Provides track selection, hardware output device picker,
/// audio delay stepper/slider, visual audio preset cards,
/// preamp slider, 10-band ISO graphic equalizer, and spatial toggles.
class AudioInspectorTab extends StatefulWidget {
  final List<VlcAudioTrack> tracks;
  final int selectedTrackId;
  final List<VlcAudioOutputDevice> devices;
  final String selectedDeviceId;
  final Duration currentDelay;
  final AudioFilterState filterState;
  final ValueChanged<int> onSelectTrack;
  final ValueChanged<String> onSelectDevice;
  final ValueChanged<Duration> onDelayChanged;
  final ValueChanged<AudioFilterState> onFilterStateChanged;

  const AudioInspectorTab({
    super.key,
    required this.tracks,
    required this.selectedTrackId,
    required this.devices,
    required this.selectedDeviceId,
    required this.currentDelay,
    required this.filterState,
    required this.onSelectTrack,
    required this.onSelectDevice,
    required this.onDelayChanged,
    required this.onFilterStateChanged,
  });

  @override
  State<AudioInspectorTab> createState() => _AudioInspectorTabState();
}

class _AudioInspectorTabState extends State<AudioInspectorTab> {
  bool _isEqExpanded = true;

  String _formatDelay(Duration d) {
    final ms = d.inMilliseconds;
    if (ms == 0) return '0.0 s (In Sync)';
    final sign = ms > 0 ? '+' : '';
    final seconds = (ms / 1000.0).toStringAsFixed(2);
    return '$sign${seconds}s ($sign$ms ms)';
  }

  IconData _getPresetIcon(String iconKey) {
    switch (iconKey) {
      case 'flat':
        return Icons.graphic_eq;
      case 'bass':
        return Icons.speaker;
      case 'vocal':
        return Icons.record_voice_over;
      case 'moon':
        return Icons.nightlight_round;
      case 'rock':
        return Icons.music_note;
      case 'classical':
        return Icons.album;
      default:
        return Icons.equalizer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final delayMs = widget.currentDelay.inMilliseconds.toDouble();
    final filter = widget.filterState;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      children: [
        // -------------------------------------------------------------
        // 1. Audio Track Selector
        // -------------------------------------------------------------
        Text(
          'AUDIO TRACK',
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
                  child: Text('Disable Audio'),
                ),
                for (final track in widget.tracks)
                  DropdownMenuItem<int>(
                    value: track.id,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(3.0),
                          ),
                          child: Text(
                            track.codec,
                            style: vlcTheme.typography.labelSmall.copyWith(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w600,
                              color: colors.accent.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 2. Hardware Output Device Selector
        // -------------------------------------------------------------
        Text(
          'OUTPUT DEVICE',
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
              value: widget.devices.any((d) => d.id == widget.selectedDeviceId)
                  ? widget.selectedDeviceId
                  : (widget.devices.isNotEmpty ? widget.devices.first.id : 'default'),
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              onChanged: (newId) {
                if (newId != null) widget.onSelectDevice(newId);
              },
              items: [
                for (final dev in widget.devices)
                  DropdownMenuItem<String>(
                    value: dev.id,
                    child: Row(
                      children: [
                        Icon(
                          _getDeviceIcon(dev.type),
                          size: 15.0,
                          color: dev.id == widget.selectedDeviceId
                              ? colors.accent.primary
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            dev.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 3. Audio Delay / Sync Stepper & Slider
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'AUDIO SYNC (DELAY)',
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

        // Slider from -5000ms to +5000ms
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
            value: delayMs.clamp(-5000.0, 5000.0),
            min: -5000.0,
            max: 5000.0,
            divisions: 200, // 50ms steps
            onChanged: (val) {
              widget.onDelayChanged(Duration(milliseconds: val.round()));
            },
          ),
        ),

        // Quick Stepper Buttons: -500ms, -50ms, 0.0s, +50ms, +500ms
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

        const SizedBox(height: 20.0),

        // -------------------------------------------------------------
        // 4. Equalizer Toggle & Preamp
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  VlcMonochromeIcon(
                    VlcIconGlyph.equalizer,
                    size: 16.0,
                    color: filter.isEqEnabled ? colors.accent.primary : colors.textTertiary,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      '10-Band Graphic Equalizer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Switch(
              value: filter.isEqEnabled,
              activeColor: colors.accent.primary,
              onChanged: (enabled) {
                widget.onFilterStateChanged(filter.copyWith(isEqEnabled: enabled));
              },
            ),
          ],
        ),

        // Preamp Slider
        if (filter.isEqEnabled) ...[
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PREAMP GAIN',
                style: vlcTheme.typography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${filter.preamp >= 0 ? '+' : ''}${filter.preamp.toStringAsFixed(1)} dB',
                style: vlcTheme.typography.monospaceTime.copyWith(
                  color: filter.preamp != 0.0 ? colors.accent.primary : colors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
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
              value: filter.preamp.clamp(-20.0, 20.0),
              min: -20.0,
              max: 20.0,
              divisions: 80,
              onChanged: (val) {
                widget.onFilterStateChanged(filter.copyWith(preamp: val));
              },
            ),
          ),
        ],

        const SizedBox(height: 14.0),

        // -------------------------------------------------------------
        // 5. Visual Audio Filter Preset Cards
        // -------------------------------------------------------------
        Text(
          'AUDIO FILTER PRESETS',
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
          itemCount: AudioEqualizerPreset.standardPresets.length,
          itemBuilder: (context, idx) {
            final preset = AudioEqualizerPreset.standardPresets[idx];
            final isSelected = filter.activePresetId == preset.id;

            return InkWell(
              onTap: () {
                widget.onFilterStateChanged(
                  filter.copyWith(
                    activePresetId: preset.id,
                    preamp: preset.preamp,
                    bands: List<double>.from(preset.bands),
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
                    // Mini EQ Curve Bar visualization
                    _buildMiniEqCurve(preset.bands, isSelected, colors),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 18.0),

        // -------------------------------------------------------------
        // 6. Expandable 10-Band ISO Frequency Sliders
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
                onTap: () => setState(() => _isEqExpanded = !_isEqExpanded),
                borderRadius: VlcGeometry.borderRadiusMedium,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Icon(
                        _isEqExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 18.0,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          '10-Band Frequency Sliders (ISO)',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.onFilterStateChanged(
                            filter.copyWith(
                              activePresetId: 'flat',
                              preamp: 0.0,
                              bands: List.filled(10, 0.0),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          child: Text(
                            'Reset All',
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
              if (_isEqExpanded) ...[
                const Divider(height: 1.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: SizedBox(
                    height: 140.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int i = 0; i < 10; i++) ...[
                          _buildVerticalBandSlider(
                            index: i,
                            band: AudioEqualizerBand.standardBands[i],
                            amplitude: filter.bands[i],
                            colors: colors,
                            vlcTheme: vlcTheme,
                            onChanged: (newAmp) {
                              final updatedBands = List<double>.from(filter.bands);
                              updatedBands[i] = newAmp;
                              widget.onFilterStateChanged(
                                filter.copyWith(
                                  activePresetId: 'custom',
                                  bands: updatedBands,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18.0),

        // -------------------------------------------------------------
        // 7. Spatial & Dynamic Processing Features
        // -------------------------------------------------------------
        Text(
          'SPATIAL & DYNAMIC ENHANCEMENTS',
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
              // Spatial Audio Virtualizer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spatial Audio Virtualizer',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Expands stereo soundfield for headphones',
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
                    value: filter.spatialAudio,
                    activeColor: colors.accent.primary,
                    onChanged: (val) {
                      widget.onFilterStateChanged(filter.copyWith(spatialAudio: val));
                    },
                  ),
                ],
              ),
              const Divider(height: 14.0),
              // Loudness Normalization
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loudness Normalization',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Balances sudden dynamic loudness spikes',
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
                    value: filter.loudnessNormalization,
                    activeColor: colors.accent.primary,
                    onChanged: (val) {
                      widget.onFilterStateChanged(filter.copyWith(loudnessNormalization: val));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildVerticalBandSlider({
    required int index,
    required AudioEqualizerBand band,
    required double amplitude,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
    required ValueChanged<double> onChanged,
  }) {
    final isNonZero = amplitude.abs() > 0.1;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amplitude text
          Text(
            amplitude == 0.0 ? '0' : '${amplitude > 0 ? '+' : ''}${amplitude.round()}',
            style: vlcTheme.typography.monospaceTime.copyWith(
              fontSize: 8.5,
              fontWeight: isNonZero ? FontWeight.w700 : FontWeight.w400,
              color: isNonZero ? colors.accent.primary : colors.textTertiary,
            ),
          ),
          const SizedBox(height: 2.0),
          // Vertical Slider
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colors.accent.primary,
                  inactiveTrackColor: colors.surfaceVariant,
                  thumbColor: isNonZero ? colors.accent.primary : colors.textSecondary,
                  overlayColor: colors.accent.glow,
                  trackHeight: 2.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                ),
                child: Slider(
                  value: amplitude.clamp(-20.0, 20.0),
                  min: -20.0,
                  max: 20.0,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2.0),
          // Band frequency label
          Text(
            band.label.replaceAll(' ', ''),
            style: vlcTheme.typography.labelSmall.copyWith(
              fontSize: 7.8,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniEqCurve(List<double> bands, bool isSelected, VlcColors colors) {
    return SizedBox(
      height: 14.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final amp in bands) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                // Height normalized between 2dp and 14dp
                height: (((amp + 20.0) / 40.0) * 12.0 + 2.0).clamp(2.0, 14.0),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accent.primary : colors.textTertiary,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ),
          ],
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
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

  IconData _getDeviceIcon(VlcAudioDeviceType type) {
    switch (type) {
      case VlcAudioDeviceType.speakers:
        return Icons.volume_up;
      case VlcAudioDeviceType.headphones:
        return Icons.headphones;
      case VlcAudioDeviceType.bluetooth:
        return Icons.bluetooth_audio;
      case VlcAudioDeviceType.hdmi:
        return Icons.tv;
      case VlcAudioDeviceType.usb:
        return Icons.usb;
      case VlcAudioDeviceType.systemDefault:
        return Icons.settings_suggest;
    }
  }
}
