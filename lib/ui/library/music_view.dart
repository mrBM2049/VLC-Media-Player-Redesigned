import 'package:flutter/material.dart';

import '../../models/media_library_models.dart';
import '../../services/media_library_service.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Active category tab within the Music Library.
enum MusicCategoryTab {
  songs,
  albums,
  artists,
  genres,
}

/// Modern Music Library View for VLC Modern Redesign.
///
/// Implements Juxtopposed 25-Year Redesign Task 4.5:
/// - Category segmentation tabs: **Songs**, **Albums**, **Artists**, **Genres**.
/// - Comprehensive metadata display (Title, Artist, Album, Duration, Track count).
/// - Instant batch triggers: "Play All", "Enqueue All".
/// - Fast real-time search filtering.
/// - Responsive album grid cards and artist profiles.
class MusicView extends StatefulWidget {
  final MediaLibraryService mediaLibraryService;
  final ValueChanged<MediaItem>? onPlayItem;
  final ValueChanged<MediaItem>? onAddToQueue;
  final ValueChanged<List<MediaItem>>? onPlayAll;
  final ValueChanged<List<MediaItem>>? onEnqueueAll;
  final VoidCallback? onAddFolder;

  const MusicView({
    super.key,
    required this.mediaLibraryService,
    this.onPlayItem,
    this.onAddToQueue,
    this.onPlayAll,
    this.onEnqueueAll,
    this.onAddFolder,
  });

  @override
  State<MusicView> createState() => _MusicViewState();
}

class _MusicViewState extends State<MusicView> {
  MusicCategoryTab _currentTab = MusicCategoryTab.songs;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  MusicAlbumGroup? _selectedAlbum;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return AnimatedBuilder(
      animation: widget.mediaLibraryService,
      builder: (context, _) {
        final audioItems = widget.mediaLibraryService.getMediaItems(
          filter: MediaFilter.audioOnly,
          sortOrder: MediaSortOrder.titleAz,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Stats, Search, Batch Actions & Tab Switcher
            _buildHeader(context, colors, vlcTheme, audioItems),

            Divider(height: 1.0, color: colors.border),

            // Main Content Area
            Expanded(
              child: audioItems.isEmpty && _selectedAlbum == null
                  ? _buildEmptyState(context, colors, vlcTheme)
                  : (_selectedAlbum != null
                      ? _buildAlbumDetailView(context, colors, vlcTheme)
                      : _buildTabContent(context, colors, vlcTheme, audioItems)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> audioItems,
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
                VlcIconGlyph.music,
                size: 26.0,
              ),
              const SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Music Library',
                    style: vlcTheme.typography.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${audioItems.length} tracks indexed',
                    style: vlcTheme.typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Batch actions
              if (audioItems.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => widget.onPlayAll?.call(audioItems),
                  icon: const VlcMonochromeIcon(VlcIconGlyph.play, size: 14.0, color: VlcColors.coneOrange),
                  label: const Text('Play All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: VlcGeometry.borderRadiusMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                OutlinedButton.icon(
                  onPressed: () => widget.onEnqueueAll?.call(audioItems),
                  icon: VlcMonochromeIcon(VlcIconGlyph.playlist, size: 14.0, color: colors.textSecondary),
                  label: const Text('Enqueue All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: VlcGeometry.borderRadiusMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12.0),

          // Search Bar & Tab Segment Pills Row
          Row(
            children: [
              // Category Tabs: Songs, Albums, Artists, Genres
              _buildTabPill('Songs', MusicCategoryTab.songs, colors, vlcTheme),
              const SizedBox(width: 6.0),
              _buildTabPill('Albums', MusicCategoryTab.albums, colors, vlcTheme),
              const SizedBox(width: 6.0),
              _buildTabPill('Artists', MusicCategoryTab.artists, colors, vlcTheme),
              const SizedBox(width: 6.0),
              _buildTabPill('Genres', MusicCategoryTab.genres, colors, vlcTheme),

              const Spacer(),

              // Real-time Search Box
              SizedBox(
                width: 220.0,
                height: 34.0,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search music...',
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

  Widget _buildTabPill(
    String label,
    MusicCategoryTab tab,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isActive = _currentTab == tab && _selectedAlbum == null;
    return InkWell(
      onTap: () {
        setState(() {
          _currentTab = tab;
          _selectedAlbum = null;
        });
      },
      borderRadius: VlcGeometry.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isActive ? colors.accent.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: VlcGeometry.borderRadiusMedium,
          border: Border.all(
            color: isActive ? colors.accent.primary : colors.border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: vlcTheme.typography.labelSmall.copyWith(
            color: isActive ? colors.accent.primary : colors.textSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> audioItems,
  ) {
    switch (_currentTab) {
      case MusicCategoryTab.songs:
        return _buildSongsTable(context, colors, vlcTheme, audioItems);
      case MusicCategoryTab.albums:
        return _buildAlbumsGrid(context, colors, vlcTheme);
      case MusicCategoryTab.artists:
        return _buildArtistsGrid(context, colors, vlcTheme);
      case MusicCategoryTab.genres:
        return _buildGenresGrid(context, colors, vlcTheme);
    }
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Songs Table
  // ---------------------------------------------------------------------------

  Widget _buildSongsTable(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1.0, color: colors.border.withOpacity(0.4)),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SongRow(
          index: index + 1,
          item: item,
          colors: colors,
          vlcTheme: vlcTheme,
          onPlay: () => widget.onPlayItem?.call(item),
          onEnqueue: () => widget.onAddToQueue?.call(item),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Albums Grid
  // ---------------------------------------------------------------------------

  Widget _buildAlbumsGrid(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final albums = widget.mediaLibraryService.getAlbums(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (albums.isEmpty) {
      return Center(
        child: Text('No albums found', style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220.0,
        mainAxisSpacing: 18.0,
        crossAxisSpacing: 18.0,
        childAspectRatio: 0.82,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return _AlbumCard(
          album: album,
          colors: colors,
          vlcTheme: vlcTheme,
          onTap: () => setState(() => _selectedAlbum = album),
          onPlay: () => widget.onPlayAll?.call(album.tracks),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Album Detail View
  // ---------------------------------------------------------------------------

  Widget _buildAlbumDetailView(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final album = _selectedAlbum!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Album Hero Header
        Container(
          padding: const EdgeInsets.all(24.0),
          color: colors.surfaceVariant.withOpacity(0.3),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: colors.textPrimary,
                onPressed: () => setState(() => _selectedAlbum = null),
                tooltip: 'Back to Albums',
              ),
              const SizedBox(width: 12.0),

              // Square Album Art
              Container(
                width: 90.0,
                height: 90.0,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  border: Border.all(color: colors.border),
                ),
                alignment: Alignment.center,
                child: const VlcTwoToneIcon(VlcIconGlyph.music, size: 40.0),
              ),
              const SizedBox(width: 20.0),

              // Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALBUM',
                      style: vlcTheme.typography.labelSmall.copyWith(
                        color: colors.accent.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      album.name,
                      style: vlcTheme.typography.titleLarge.copyWith(
                        fontSize: 22.0,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${album.artist} • ${album.trackCount} tracks • ${album.formattedTotalDuration}',
                      style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Play Album & Enqueue Album
              ElevatedButton.icon(
                onPressed: () => widget.onPlayAll?.call(album.tracks),
                icon: const Icon(Icons.play_arrow, size: 18.0),
                label: const Text('Play Album'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ],
          ),
        ),

        // Album Track List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            itemCount: album.tracks.length,
            separatorBuilder: (_, __) => Divider(height: 1.0, color: colors.border.withOpacity(0.3)),
            itemBuilder: (context, index) {
              final track = album.tracks[index];
              return _SongRow(
                index: index + 1,
                item: track,
                colors: colors,
                vlcTheme: vlcTheme,
                onPlay: () => widget.onPlayItem?.call(track),
                onEnqueue: () => widget.onAddToQueue?.call(track),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Artists Grid
  // ---------------------------------------------------------------------------

  Widget _buildArtistsGrid(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final artists = widget.mediaLibraryService.getArtists(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (artists.isEmpty) {
      return Center(
        child: Text('No artists found', style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        mainAxisSpacing: 18.0,
        crossAxisSpacing: 18.0,
        childAspectRatio: 0.78,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return _ArtistCard(
          artist: artist,
          colors: colors,
          vlcTheme: vlcTheme,
          onPlay: () => widget.onPlayAll?.call(artist.tracks),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 4: Genres Grid
  // ---------------------------------------------------------------------------

  Widget _buildGenresGrid(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final genres = widget.mediaLibraryService.getGenres(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (genres.isEmpty) {
      return Center(
        child: Text('No genres found', style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220.0,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 1.6,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        return _GenreCard(
          genre: genre,
          colors: colors,
          vlcTheme: vlcTheme,
          onPlay: () => widget.onPlayAll?.call(genre.tracks),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------

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
            child: const VlcTwoToneIcon(VlcIconGlyph.music, size: 36.0),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No Audio Tracks Found',
            style: vlcTheme.typography.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Add your Music folder to index and play local audio files',
            style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton.icon(
            onPressed: widget.onAddFolder,
            icon: const Icon(Icons.add, size: 16.0),
            label: const Text('Add Music Folder...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Song Row Component
// -----------------------------------------------------------------------------

class _SongRow extends StatefulWidget {
  final int index;
  final MediaItem item;
  final VlcColors colors;
  final VlcThemeData vlcTheme;
  final VoidCallback onPlay;
  final VoidCallback onEnqueue;

  const _SongRow({
    required this.index,
    required this.item,
    required this.colors,
    required this.vlcTheme,
    required this.onPlay,
    required this.onEnqueue,
  });

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 48.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: _isHovered ? widget.colors.surfaceHover : Colors.transparent,
          borderRadius: VlcGeometry.borderRadiusSmall,
        ),
        child: Row(
          children: [
            // Track Number / Hover Play Button
            SizedBox(
              width: 36.0,
              child: _isHovered
                  ? GestureDetector(
                      onTap: widget.onPlay,
                      child: Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: widget.colors.accent.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.play_arrow, size: 16.0, color: Colors.white),
                      ),
                    )
                  : Text(
                      '${widget.index}',
                      style: widget.vlcTheme.typography.bodySmall.copyWith(
                        color: widget.colors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 8.0),

            // Track Title
            Expanded(
              flex: 4,
              child: Text(
                widget.item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.vlcTheme.typography.bodyMedium.copyWith(
                  color: _isHovered ? widget.colors.accent.primary : widget.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Artist
            Expanded(
              flex: 3,
              child: Text(
                widget.item.artist ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.vlcTheme.typography.bodySmall.copyWith(color: widget.colors.textSecondary),
              ),
            ),

            // Album
            Expanded(
              flex: 3,
              child: Text(
                widget.item.album ?? widget.item.folderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.vlcTheme.typography.bodySmall.copyWith(color: widget.colors.textTertiary),
              ),
            ),

            // Duration
            Container(
              width: 60.0,
              alignment: Alignment.centerRight,
              child: Text(
                widget.item.formattedDuration,
                style: widget.vlcTheme.typography.monospaceTime.copyWith(
                  fontSize: 12.0,
                  color: widget.colors.textSecondary,
                ),
              ),
            ),

            const SizedBox(width: 12.0),

            // Enqueue Hover Button
            SizedBox(
              width: 32.0,
              child: _isHovered
                  ? IconButton(
                      icon: const Icon(Icons.playlist_add, size: 18.0),
                      color: widget.colors.textSecondary,
                      tooltip: 'Add to Queue',
                      onPressed: widget.onEnqueue,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Album Card Component
// -----------------------------------------------------------------------------

class _AlbumCard extends StatefulWidget {
  final MusicAlbumGroup album;
  final VlcColors colors;
  final VlcThemeData vlcTheme;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _AlbumCard({
    required this.album,
    required this.colors,
    required this.vlcTheme,
    required this.onTap,
    required this.onPlay,
  });

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.colors.surface,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: _isHovered ? widget.colors.accent.primary : widget.colors.border,
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square Album Cover Placeholder / Artwork
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.colors.surfaceVariant,
                        borderRadius: VlcGeometry.borderRadiusSmall,
                      ),
                      alignment: Alignment.center,
                      child: const VlcTwoToneIcon(VlcIconGlyph.music, size: 48.0),
                    ),
                    if (_isHovered)
                      Positioned(
                        right: 8.0,
                        bottom: 8.0,
                        child: GestureDetector(
                          onTap: widget.onPlay,
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: widget.colors.accent.primary,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 6.0, offset: Offset(0, 3)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.play_arrow, size: 22.0, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),

              // Title
              Text(
                widget.album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.vlcTheme.typography.bodyMedium.copyWith(
                  color: widget.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2.0),

              // Artist & Track Count
              Text(
                '${widget.album.artist} • ${widget.album.trackCount} tracks',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.vlcTheme.typography.bodySmall.copyWith(
                  color: widget.colors.textSecondary,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Artist Card Component
// -----------------------------------------------------------------------------

class _ArtistCard extends StatelessWidget {
  final MusicArtistGroup artist;
  final VlcColors colors;
  final VlcThemeData vlcTheme;
  final VoidCallback onPlay;

  const _ArtistCard({
    required this.artist,
    required this.colors,
    required this.vlcTheme,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28.0,
            backgroundColor: colors.surfaceVariant,
            child: const VlcTwoToneIcon(VlcIconGlyph.music, size: 28.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: vlcTheme.typography.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${artist.albumCount} albums • ${artist.trackCount} tracks',
            style: vlcTheme.typography.bodySmall.copyWith(
              color: colors.textSecondary,
              fontSize: 11.0,
            ),
          ),
          const SizedBox(height: 10.0),
          OutlinedButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow, size: 14.0),
            label: const Text('Play'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accent.primary,
              side: BorderSide(color: colors.accent.primary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusSmall),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Genre Card Component
// -----------------------------------------------------------------------------

class _GenreCard extends StatelessWidget {
  final MusicGenreGroup genre;
  final VlcColors colors;
  final VlcThemeData vlcTheme;
  final VoidCallback onPlay;

  const _GenreCard({
    required this.genre,
    required this.colors,
    required this.vlcTheme,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surfaceVariant,
            colors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  genre.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vlcTheme.typography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${genre.trackCount} tracks',
                  style: vlcTheme.typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, size: 32.0),
            color: colors.accent.primary,
            onPressed: onPlay,
            tooltip: 'Play Genre',
          ),
        ],
      ),
    );
  }
}
