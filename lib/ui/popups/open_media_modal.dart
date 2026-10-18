import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../services/file_picker_service.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';
import '../shell/top_player_bar.dart'; // for VlcTopBarButton

/// Open Media Modal allowing user to:
/// 1. Browse local video/audio via OS native file picker or path entry
/// 2. Stream online video/audio via URL (http, https, rtsp, m3u8)
/// 3. Pick from bundled demo media
class OpenMediaModal extends StatefulWidget {
  final ValueChanged<String> onOpenMedia;
  final VoidCallback? onClose;

  const OpenMediaModal({
    super.key,
    required this.onOpenMedia,
    this.onClose,
  });

  @override
  State<OpenMediaModal> createState() => _OpenMediaModalState();
}

class _OpenMediaModalState extends State<OpenMediaModal> {
  int _activeTab = 0; // 0: Local File, 1: Network Stream, 2: Sample Media
  final TextEditingController _filePathController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  static const List<Map<String, String>> _sampleClips = [
    {
      'title': 'Big Buck Bunny (4K 60fps)',
      'desc': 'Blender Open Movie • Animation Master',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    },
    {
      'title': 'Elephants Dream',
      'desc': 'Orange Open Movie Project • Sci-Fi Animation',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    },
    {
      'title': 'Sintel (4K HDR)',
      'desc': 'Blender Animation Studio • Fantasy Short Film',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    },
    {
      'title': 'Tears of Steel (VFX Remaster)',
      'desc': 'Mango Open Movie Project • Live Action VFX',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    },
  ];

  @override
  void dispose() {
    _filePathController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleBrowseFile() async {
    final path = await FilePickerService.pickMediaFile();
    if (path != null && mounted) {
      _filePathController.text = path;
      widget.onOpenMedia(path);
      widget.onClose?.call();
    }
  }

  void _handleOpenFilePath() {
    final path = _filePathController.text.trim();
    if (path.isNotEmpty) {
      widget.onOpenMedia(path);
      widget.onClose?.call();
    }
  }

  void _handleOpenUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      widget.onOpenMedia(url);
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 520, maxWidth: 560),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: VlcGeometry.borderRadiusLarge,
            border: Border.all(
              color: colors.border,
              width: VlcGeometry.strokeWidthBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.40),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.border.withOpacity(0.50),
                      width: VlcGeometry.strokeWidthBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    VlcMonochromeIcon(
                      VlcIconGlyph.folder,
                      size: 20.0,
                      color: colors.accent.primary,
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      'Open Media',
                      style: vlcTheme.typography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onClose != null)
                      VlcTopBarButton(
                        width: 28.0,
                        height: 28.0,
                        tooltip: 'Close',
                        onPressed: widget.onClose,
                        child: Icon(
                          Icons.close,
                          size: 16.0,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // Tab Selector (Local File | Network Stream | Sample Clips)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.40),
                  border: Border(
                    bottom: BorderSide(
                      color: colors.border.withOpacity(0.30),
                      width: VlcGeometry.strokeWidthBorder,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Local File', VlcIconGlyph.folder, colors, vlcTheme),
                      const SizedBox(width: 8.0),
                      _buildTabButton(1, 'Network Stream', VlcIconGlyph.speed, colors, vlcTheme),
                      const SizedBox(width: 8.0),
                      _buildTabButton(2, 'Demo Clips', VlcIconGlyph.play, colors, vlcTheme),
                    ],
                  ),
                ),
              ),

              // Tab Content Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: switch (_activeTab) {
                    0 => _buildLocalFileTab(colors, vlcTheme),
                    1 => _buildNetworkStreamTab(colors, vlcTheme),
                    _ => _buildSampleClipsTab(colors, vlcTheme),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    int index,
    String label,
    VlcIconGlyph icon,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isActive = _activeTab == index;

    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: VlcGeometry.borderRadiusSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isActive ? colors.accent.subtleBackground : Colors.transparent,
          borderRadius: VlcGeometry.borderRadiusSmall,
          border: Border.all(
            color: isActive ? colors.accent.subtleBorder : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VlcMonochromeIcon(
              icon,
              size: 14.0,
              color: isActive ? colors.accent.primary : colors.textTertiary,
            ),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: vlcTheme.typography.labelSmall.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? colors.accent.primary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalFileTab(VlcColors colors, VlcThemeData vlcTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select a video or audio file from your computer:',
          style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 14.0),
        // Primary Native Browse Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent.primary,
            foregroundColor: Colors.white,
            shape: VlcGeometry.buttonShape,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
          ),
          onPressed: _handleBrowseFile,
          icon: const Icon(Icons.folder_open, size: 20.0),
          label: Text(
            'Browse Computer (Native File Picker)...',
            style: vlcTheme.typography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(child: Divider(color: colors.border.withOpacity(0.50))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'OR ENTER PATH MANUALLY',
                style: vlcTheme.typography.labelSmall.copyWith(
                  color: colors.textTertiary,
                  fontSize: 10.0,
                ),
              ),
            ),
            Expanded(child: Divider(color: colors.border.withOpacity(0.50))),
          ],
        ),
        const SizedBox(height: 14.0),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _filePathController,
                  style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '/path/to/movie.mp4 or C:\\Movies\\video.mkv',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _handleOpenFilePath(),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surfaceHover,
                foregroundColor: colors.textPrimary,
                shape: VlcGeometry.buttonShape,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              onPressed: _handleOpenFilePath,
              child: const Text('Open'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkStreamTab(VlcColors colors, VlcThemeData vlcTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter a network URL (HTTP, HTTPS, RTSP, RTMP, or HLS .m3u8):',
          style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 14.0),
        Container(
          height: 42.0,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _urlController,
            style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'https://example.com/stream.m3u8 or rtsp://...',
              border: InputBorder.none,
              isDense: true,
            ),
            onSubmitted: (_) => _handleOpenUrl(),
          ),
        ),
        const SizedBox(height: 14.0),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent.primary,
            foregroundColor: Colors.white,
            shape: VlcGeometry.buttonShape,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
          onPressed: _handleOpenUrl,
          icon: const Icon(Icons.play_arrow, size: 20.0),
          label: Text(
            'Play Network Stream',
            style: vlcTheme.typography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSampleClipsTab(VlcColors colors, VlcThemeData vlcTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Instant demo media to test VLC Modern video decoding:',
          style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 10.0),
        for (final clip in _sampleClips)
          Container(
            margin: const EdgeInsets.only(bottom: 6.0),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(0.40),
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.border.withOpacity(0.50)),
            ),
            child: ListTile(
              dense: true,
              leading: VlcMonochromeIcon(
                VlcIconGlyph.play,
                size: 16.0,
                color: colors.accent.primary,
              ),
              title: Text(
                clip['title']!,
                style: vlcTheme.typography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                clip['desc']!,
                style: vlcTheme.typography.labelSmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent.subtleBackground,
                  foregroundColor: colors.accent.primary,
                  elevation: 0,
                  shape: VlcGeometry.buttonShape,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                ),
                onPressed: () {
                  widget.onOpenMedia(clip['url']!);
                  widget.onClose?.call();
                },
                child: const Text('Play'),
              ),
            ),
          ),
      ],
    );
  }
}
