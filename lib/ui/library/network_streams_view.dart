import 'package:flutter/material.dart';

import '../../services/file_picker_service.dart';
import '../../services/m3u_stream_parser.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';
import '../popups/stream_modal.dart';

/// Modern Network Streams & IPTV Channel Browser for VLC Modern Redesign.
///
/// Implements Juxtopposed 25-Year Redesign Task 4.6:
/// - Category segmentation pills (All, News, Sports, Music, Movies & TV, Science & Tech).
/// - Responsive channel cards with live badge, stream quality tag, and instant playback.
/// - Integrated M3U/M3U8 parser import and custom URL entry.
/// - Fast real-time channel search.
class NetworkStreamsView extends StatefulWidget {
  final ValueChanged<NetworkStreamChannel>? onPlayStream;
  final ValueChanged<NetworkStreamChannel>? onAddToQueue;
  final ValueChanged<List<NetworkStreamChannel>>? onPlayAll;
  final ValueChanged<List<NetworkStreamChannel>>? onEnqueueAll;

  const NetworkStreamsView({
    super.key,
    this.onPlayStream,
    this.onAddToQueue,
    this.onPlayAll,
    this.onEnqueueAll,
  });

  @override
  State<NetworkStreamsView> createState() => _NetworkStreamsViewState();
}

class _NetworkStreamsViewState extends State<NetworkStreamsView> {
  final List<NetworkStreamChannel> _channels = List.from(M3uStreamParser.defaultCuratedStreams);
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final Set<String> groups = {'All'};
    for (final ch in _channels) {
      groups.add(ch.group);
    }
    return groups.toList();
  }

  List<NetworkStreamChannel> get _filteredChannels {
    return _channels.where((ch) {
      final matchesCategory = _selectedCategory == 'All' || ch.group == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          ch.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ch.group.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ch.country.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _handleImportM3u() async {
    final path = await FilePickerService.pickMediaFile();
    if (path != null && (path.endsWith('.m3u') || path.endsWith('.m3u8'))) {
      final imported = await M3uStreamParser.parseFile(path);
      if (imported.isNotEmpty && mounted) {
        setState(() {
          _channels.addAll(imported);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported ${imported.length} IPTV channels')),
        );
      }
    }
  }

  void _showAddStreamModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => StreamModal(
        onOpenStream: (url) {
          final newChannel = NetworkStreamChannel(
            id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
            name: url.split('/').last.split('?').first.isEmpty ? 'Custom Stream' : url.split('/').last.split('?').first,
            streamUrl: url,
            group: 'Custom',
            resolution: 'Live',
          );
          setState(() {
            _channels.insert(0, newChannel);
          });
          widget.onPlayStream?.call(newChannel);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final channels = _filteredChannels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header
        _buildHeader(context, colors, vlcTheme),

        Divider(height: 1.0, color: colors.border),

        // Main Channel Grid
        Expanded(
          child: channels.isEmpty
              ? _buildEmptyState(context, colors, vlcTheme)
              : GridView.builder(
                  padding: const EdgeInsets.all(24.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280.0,
                    mainAxisSpacing: 18.0,
                    crossAxisSpacing: 18.0,
                    childAspectRatio: 1.22,
                  ),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return _StreamChannelCard(
                      channel: channel,
                      colors: colors,
                      vlcTheme: vlcTheme,
                      onPlay: () => widget.onPlayStream?.call(channel),
                      onEnqueue: () => widget.onAddToQueue?.call(channel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const VlcTwoToneIcon(
                VlcIconGlyph.stream,
                size: 26.0,
              ),
              const SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Streams & IPTV',
                    style: vlcTheme.typography.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_channels.length} channels available • HLS, RTSP & HTTP Multicast',
                    style: vlcTheme.typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Import M3U Button
              OutlinedButton.icon(
                onPressed: _handleImportM3u,
                icon: const Icon(Icons.file_upload_outlined, size: 16.0),
                label: const Text('Import .m3u'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
                ),
              ),
              const SizedBox(width: 8.0),

              // Add Stream URL Button
              ElevatedButton.icon(
                onPressed: _showAddStreamModal,
                icon: const Icon(Icons.add_link, size: 16.0),
                label: const Text('Add Stream URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Category Pills and Search Input Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isActive = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = category),
                          borderRadius: VlcGeometry.borderRadiusMedium,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: isActive ? colors.accent.primary.withOpacity(0.18) : Colors.transparent,
                              borderRadius: VlcGeometry.borderRadiusMedium,
                              border: Border.all(
                                color: isActive ? colors.accent.primary : colors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              category,
                              style: vlcTheme.typography.labelSmall.copyWith(
                                color: isActive ? colors.accent.primary : colors.textSecondary,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 12.0),

              // Search Bar
              SizedBox(
                width: 220.0,
                height: 34.0,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search channels...',
                    hintStyle: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: VlcMonochromeIcon(VlcIconGlyph.search, size: 14.0, color: colors.textTertiary),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: VlcMonochromeIcon(VlcIconGlyph.close, size: 12.0, color: colors.textTertiary),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    border: OutlineInputBorder(
                      borderRadius: VlcGeometry.borderRadiusSmall,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16.0),
            ),
            alignment: Alignment.center,
            child: const VlcTwoToneIcon(VlcIconGlyph.stream, size: 36.0),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No Stream Channels Found',
            style: vlcTheme.typography.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Try clearing your search query or add a custom IPTV stream URL.',
            style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Stream Channel Card Component
// -----------------------------------------------------------------------------

class _StreamChannelCard extends StatefulWidget {
  final NetworkStreamChannel channel;
  final VlcColors colors;
  final VlcThemeData vlcTheme;
  final VoidCallback onPlay;
  final VoidCallback onEnqueue;

  const _StreamChannelCard({
    required this.channel,
    required this.colors,
    required this.vlcTheme,
    required this.onPlay,
    required this.onEnqueue,
  });

  @override
  State<_StreamChannelCard> createState() => _StreamChannelCardState();
}

class _StreamChannelCardState extends State<_StreamChannelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final vlcTheme = widget.vlcTheme;
    final channel = widget.channel;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusMedium,
          border: Border.all(
            color: _isHovered ? colors.accent.primary : colors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Preview Slate (16:9)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: colors.surfaceVariant,
                    alignment: Alignment.center,
                    child: const VlcTwoToneIcon(VlcIconGlyph.stream, size: 44.0),
                  ),

                  // LIVE red badge in top-left
                  Positioned(
                    top: 8.0,
                    left: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.0,
                            height: 5.0,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quality Badge in top-right
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        channel.resolution,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Hover Play and Queue Overlay Buttons
                  if (_isHovered)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: widget.onPlay,
                              child: Container(
                                width: 44.0,
                                height: 44.0,
                                decoration: BoxDecoration(
                                  color: colors.accent.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 8.0, offset: Offset(0, 4)),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.play_arrow, size: 26.0, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            GestureDetector(
                              onTap: widget.onEnqueue,
                              child: Container(
                                width: 36.0,
                                height: 36.0,
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.border),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.playlist_add, size: 18.0, color: colors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Metadata Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vlcTheme.typography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '${channel.group} • ${channel.country}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vlcTheme.typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

