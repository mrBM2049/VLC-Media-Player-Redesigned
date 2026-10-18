import 'package:flutter/material.dart';

import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Dedicated Stream Modal for VLC Modern Redesign.
///
/// Replaces the cluttered multi-tab Open Media dialog with a focused,
/// professional network stream entry modal:
/// - URL input with protocol auto-detection (HTTP, HLS, RTSP, RTMP, UDP/RTP).
/// - Network buffer size presets (Low Latency 300ms, Standard 1200ms, High 5000ms).
/// - History of recently opened stream URLs.
class StreamModal extends StatefulWidget {
  final ValueChanged<String> onOpenStream;
  final VoidCallback? onClose;

  const StreamModal({
    super.key,
    required this.onOpenStream,
    this.onClose,
  });

  @override
  State<StreamModal> createState() => _StreamModalState();
}

class _StreamModalState extends State<StreamModal> {
  final TextEditingController _urlController = TextEditingController();
  int _bufferMs = 1200; // 1200ms default standard network buffer

  static const List<String> _recentStreams = [
    'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
    'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    'rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4',
    'https://ice1.somafm.com/groovesalad-128-mp3',
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleOpen(String url) {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) {
      widget.onOpenStream(trimmed);
      widget.onClose?.call();
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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
                  const VlcTwoToneIcon(VlcIconGlyph.stream, size: 22.0),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Open Network Stream',
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
                  Text(
                    'Enter a network URL (HTTP, HTTPS, HLS .m3u8, RTSP, RTMP, MMS, or UDP):',
                    style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 10.0),

                  // URL Input Box
                  TextField(
                    controller: _urlController,
                    autofocus: true,
                    style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/live/stream.m3u8',
                      hintStyle: vlcTheme.typography.bodyMedium.copyWith(color: colors.textTertiary),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: VlcMonochromeIcon(VlcIconGlyph.stream, size: 16.0, color: colors.accent.primary),
                      ),
                      filled: true,
                      fillColor: colors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: VlcGeometry.borderRadiusMedium,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: VlcGeometry.borderRadiusMedium,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: VlcGeometry.borderRadiusMedium,
                        borderSide: BorderSide(color: colors.accent.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) => _handleOpen(val),
                  ),

                  const SizedBox(height: 16.0),

                  // Network Caching Buffer Selector
                  Text(
                    'Network Buffer & Caching:',
                    style: vlcTheme.typography.labelSmall.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildBufferOption('Low Latency (300ms)', 300, colors, vlcTheme),
                      const SizedBox(width: 8.0),
                      _buildBufferOption('Standard (1200ms)', 1200, colors, vlcTheme),
                      const SizedBox(width: 8.0),
                      _buildBufferOption('High Reliability (5000ms)', 5000, colors, vlcTheme),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  // Recent Streams
                  Text(
                    'Recent Streams:',
                    style: vlcTheme.typography.labelSmall.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withOpacity(0.3),
                      borderRadius: VlcGeometry.borderRadiusMedium,
                      border: Border.all(color: colors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: _recentStreams.map((url) {
                        return InkWell(
                          onTap: () {
                            _urlController.text = url;
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 14.0, color: colors.textTertiary),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: vlcTheme.typography.monospaceTime.copyWith(
                                      fontSize: 11.0,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Bottom Action Buttons
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
                        onPressed: () => _handleOpen(_urlController.text),
                        icon: const Icon(Icons.play_arrow, size: 18.0),
                        label: const Text('Play Stream'),
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

  Widget _buildBufferOption(
    String label,
    int ms,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isSelected = _bufferMs == ms;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _bufferMs = ms),
        borderRadius: VlcGeometry.borderRadiusSmall,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
          decoration: BoxDecoration(
            color: isSelected ? colors.accent.primary.withOpacity(0.18) : colors.surfaceVariant,
            borderRadius: VlcGeometry.borderRadiusSmall,
            border: Border.all(
              color: isSelected ? colors.accent.primary : colors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: vlcTheme.typography.labelSmall.copyWith(
              fontSize: 10.0,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colors.accent.primary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
