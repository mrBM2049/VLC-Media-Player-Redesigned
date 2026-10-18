import 'package:flutter/material.dart';

import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Dedicated Capture Device Modal for VLC Modern Redesign.
///
/// Implements Juxtopposed 25-Year Redesign Task 4.6:
/// - Select webcam, HDMI capture cards, and virtual video devices.
/// - Select microphone / audio interface inputs.
/// - Configure capture standard & resolution (1080p60, 1080p30, 720p60).
class CaptureDeviceModal extends StatefulWidget {
  final void Function(String videoDevice, String audioDevice, String resolution)? onOpenCapture;
  final VoidCallback? onClose;

  const CaptureDeviceModal({
    super.key,
    this.onOpenCapture,
    this.onClose,
  });

  @override
  State<CaptureDeviceModal> createState() => _CaptureDeviceModalState();
}

class _CaptureDeviceModalState extends State<CaptureDeviceModal> {
  String _selectedVideoDevice = 'FaceTime HD Camera';
  String _selectedAudioDevice = 'Built-in Microphone (CoreAudio)';
  String _selectedResolution = '1920x1080 @ 60 FPS';

  static const List<String> _videoDevices = [
    'FaceTime HD Camera',
    'Elgato Cam Link 4K',
    'OBS Virtual Camera',
    'Blackmagic UltraStudio Mini',
  ];

  static const List<String> _audioDevices = [
    'Built-in Microphone (CoreAudio)',
    'Focusrite Scarlett 2i2 USB',
    'Elgato Wave:3 Digital',
    'System Audio Loopback',
  ];

  static const List<String> _resolutions = [
    '1920x1080 @ 60 FPS',
    '1920x1080 @ 30 FPS',
    '1280x720 @ 60 FPS',
    '3840x2160 @ 30 FPS (4K)',
  ];

  void _handleOpen() {
    widget.onOpenCapture?.call(
      _selectedVideoDevice,
      _selectedAudioDevice,
      _selectedResolution,
    );
    widget.onClose?.call();
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Container(
        width: 540.0,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusLarge,
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 28.0, offset: Offset(0, 14)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              color: colors.surfaceVariant.withOpacity(0.4),
              child: Row(
                children: [
                  const Icon(Icons.videocam, size: 22.0, color: VlcColors.coneOrange),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Open Capture Device',
                      style: vlcTheme.typography.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: VlcMonochromeIcon(VlcIconGlyph.close, size: 16.0, color: colors.textSecondary),
                    onPressed: () {
                      widget.onClose?.call();
                      if (Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    tooltip: 'Close [Esc]',
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video Device Dropdown
                  Text(
                    'Video Device Name:',
                    style: vlcTheme.typography.labelSmall.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  _buildDropdown(
                    value: _selectedVideoDevice,
                    items: _videoDevices,
                    onChanged: (val) => setState(() => _selectedVideoDevice = val!),
                    colors: colors,
                    vlcTheme: vlcTheme,
                    icon: Icons.camera_alt_outlined,
                  ),

                  const SizedBox(height: 16.0),

                  // Audio Device Dropdown
                  Text(
                    'Audio Device Name:',
                    style: vlcTheme.typography.labelSmall.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  _buildDropdown(
                    value: _selectedAudioDevice,
                    items: _audioDevices,
                    onChanged: (val) => setState(() => _selectedAudioDevice = val!),
                    colors: colors,
                    vlcTheme: vlcTheme,
                    icon: Icons.mic_none_outlined,
                  ),

                  const SizedBox(height: 16.0),

                  // Resolution & Framerate Dropdown
                  Text(
                    'Standard & Resolution:',
                    style: vlcTheme.typography.labelSmall.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  _buildDropdown(
                    value: _selectedResolution,
                    items: _resolutions,
                    onChanged: (val) => setState(() => _selectedResolution = val!),
                    colors: colors,
                    vlcTheme: vlcTheme,
                    icon: Icons.high_quality_outlined,
                  ),

                  const SizedBox(height: 24.0),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          widget.onClose?.call();
                          if (Navigator.of(context, rootNavigator: true).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                      ),
                      const SizedBox(width: 12.0),
                      ElevatedButton.icon(
                        onPressed: _handleOpen,
                        icon: const Icon(Icons.play_arrow, size: 18.0),
                        label: const Text('Open Device'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down, size: 18.0, color: colors.textSecondary),
          style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textPrimary),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 16.0, color: colors.accent.primary),
                  const SizedBox(width: 10.0),
                  Text(item),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
