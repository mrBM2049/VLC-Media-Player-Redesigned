import 'package:flutter/material.dart';
import '../../models/audio_models.dart';
import '../../theme/vlc_theme.dart';

/// AudioQuickPopup — Desktop flyout and mobile sheet combining embedded audio tracks,
/// live OS hardware output device selection, and microsecond-precise audio sync delay.
class AudioQuickPopup extends StatelessWidget {
  final List<VlcAudioTrack> tracks;
  final int selectedTrackId;
  final List<VlcAudioOutputDevice> devices;
  final String selectedDeviceId;
  final Duration currentDelay;
  final ValueChanged<int> onSelectTrack;
  final ValueChanged<String> onSelectDevice;
  final ValueChanged<Duration> onDelayChanged;
  final VoidCallback? onOpenEqualizer;
  final VoidCallback? onClose;

  const AudioQuickPopup({
    super.key,
    required this.tracks,
    required this.selectedTrackId,
    required this.devices,
    required this.selectedDeviceId,
    required this.currentDelay,
    required this.onSelectTrack,
    required this.onSelectDevice,
    required this.onDelayChanged,
    this.onOpenEqualizer,
    this.onClose,
  });

  IconData _getDeviceIcon(VlcAudioDeviceType type) {
    switch (type) {
      case VlcAudioDeviceType.headphones:
        return Icons.headphones_outlined;
      case VlcAudioDeviceType.bluetooth:
        return Icons.bluetooth_audio;
      case VlcAudioDeviceType.hdmi:
        return Icons.tv;
      case VlcAudioDeviceType.usb:
        return Icons.usb;
      case VlcAudioDeviceType.speakers:
      case VlcAudioDeviceType.systemDefault:
        return Icons.speaker_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final typography = vlcTheme.typography;
    final accent = colors.accent.primary;
    final delayMs = currentDelay.inMilliseconds;

    final allTracks = [
      VlcAudioTrack.disabled,
      ...tracks,
    ];

    return Container(
      width: 380.0,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(VlcGeometry.radiusMedium),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  VlcMonochromeIcon(
                    VlcIconGlyph.audioTrack,
                    size: 16.0,
                    color: accent,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'AUDIO & OUTPUT',
                    style: typography.titleSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  if (onClose != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                      onTap: onClose,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: VlcMonochromeIcon(
                          VlcIconGlyph.close,
                          size: 14.0,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1.0, thickness: 1.0),

            // Section 1: Embedded Audio Tracks
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'AUDIO TRACKS',
                style: typography.labelSmall.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140.0),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                itemCount: allTracks.length,
                itemBuilder: (context, index) {
                  final track = allTracks[index];
                  final isSelected = track.id == selectedTrackId;

                  return InkWell(
                    onTap: () => onSelectTrack(track.id),
                    child: Container(
                      height: 32.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      color: isSelected ? colors.accent.subtleBackground : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 14.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: isSelected ? accent : colors.textDisabled,
                                width: 1.5,
                              ),
                              color: isSelected ? accent : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check, size: 10.0, color: Colors.black),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              track.name,
                              style: typography.bodyMedium.copyWith(
                                color: isSelected ? accent : colors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (track.codec != 'None') ...[
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(3.0),
                                border: Border.all(color: colors.border, width: 0.5),
                              ),
                              child: Text(
                                track.codec,
                                style: typography.labelSmall.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 9.0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1.0, thickness: 1.0),

            // Section 2: Live OS Hardware Output Devices
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'HARDWARE OUTPUT DEVICE',
                style: typography.labelSmall.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140.0),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final dev = devices[index];
                  final isSelected = dev.id == selectedDeviceId;

                  return InkWell(
                    onTap: () => onSelectDevice(dev.id),
                    child: Container(
                      height: 32.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      color: isSelected ? colors.accent.subtleBackground : Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            _getDeviceIcon(dev.type),
                            size: 15.0,
                            color: isSelected ? accent : colors.textSecondary,
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              dev.name,
                              style: typography.bodyMedium.copyWith(
                                color: isSelected ? accent : colors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(3.0),
                                border: Border.all(color: accent, width: 0.5),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1.0, thickness: 1.0),

            // Section 3: Audio Sync Delay Stepper
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Audio Delay / Lip-Sync',
                          style: typography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ),
                      Text(
                        '${delayMs >= 0 ? '+' : ''}$delayMs ms',
                        style: typography.monospaceTime.copyWith(
                          color: delayMs == 0 ? colors.textPrimary : accent,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildStepButton(
                        label: '-100ms',
                        onTap: () => onDelayChanged(currentDelay - const Duration(milliseconds: 100)),
                        colors: colors,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: '-50ms',
                        onTap: () => onDelayChanged(currentDelay - const Duration(milliseconds: 50)),
                        colors: colors,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: 'Reset',
                        onTap: () => onDelayChanged(Duration.zero),
                        colors: colors,
                        isAccent: delayMs != 0,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: '+50ms',
                        onTap: () => onDelayChanged(currentDelay + const Duration(milliseconds: 50)),
                        colors: colors,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: '+100ms',
                        onTap: () => onDelayChanged(currentDelay + const Duration(milliseconds: 100)),
                        colors: colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (onOpenEqualizer != null) ...[
              const Divider(height: 1.0, thickness: 1.0),
              // Section 4: Action to Equalizer
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: colors.surface,
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  onPressed: onOpenEqualizer,
                  icon: VlcMonochromeIcon(VlcIconGlyph.equalizer, size: 16.0, color: accent),
                  label: const Text('10-Band Equalizer & Effects...', style: TextStyle(fontSize: 12.0)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required String label,
    required VoidCallback onTap,
    required VlcColors colors,
    bool isAccent = false,
  }) {
    final accent = colors.accent.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
        child: Container(
          height: 26.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isAccent ? colors.accent.subtleBackground : colors.surface,
            borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
            border: Border.all(
              color: isAccent ? accent : colors.border,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: isAccent ? FontWeight.w700 : FontWeight.w500,
              color: isAccent ? accent : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
