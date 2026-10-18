import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/media_library_models.dart';
import '../../services/media_library_service.dart';
import '../../theme/vlc_theme.dart';
import '../drawer/compact_library_drawer.dart';

/// Navigation sections available in the Full Library sidebar.
enum LibrarySection {
  home,
  videos,
  music,
  streams,
  playlists,
  folders,
}

/// Content layout mode within the main media display.
enum LibraryLayoutMode {
  grid,
  list,
  details,
}

/// Fullscreen Media Library View with Draggable Bottom-Right MiniPlayerOverlay.
///
/// Implements Juxtopposed 25-Year Redesign Task 4.3:
/// - Pinned Left Sidebar (Home, Videos, Music, Streams, Playlists, Folders)
/// - Top Breadcrumb Address Bar (e.g., Home › Videos › Movies) with live search and View Switcher
/// - Multi-mode layout (Grid with 16:9 thumbnails, List with quick actions, Details with technical specs)
/// - Sorting switcher (Unwatched First, Watched First, Title A-Z, Date Added, Duration)
/// - Filter segment tabs (All, Unwatched, Watched, In Progress)
/// - Draggable, floating MiniPlayerOverlay (16:9 card) pinned in bottom-right corner with mini transport controls
///   and one-click maximize button to return to fullscreen video playback.
class FullLibraryView extends StatefulWidget {
  final MediaLibraryService mediaLibraryService;
  final String? currentMrl;
  final String currentTitle;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final int volume;
  final bool isMuted;
  final VoidCallback? onReturnToPlayer;
  final ValueChanged<MediaItem>? onPlayItem;
  final ValueChanged<MediaItem>? onAddToQueue;
  final ValueChanged<List<MediaItem>>? onPlayAll;
  final ValueChanged<List<MediaItem>>? onEnqueueAll;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ValueChanged<int>? onVolumeChanged;
  final VoidCallback? onToggleMute;
  final VoidCallback? onAddFolder;

  const FullLibraryView({
    super.key,
    required this.mediaLibraryService,
    this.currentMrl,
    required this.currentTitle,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100,
    this.isMuted = false,
    this.onReturnToPlayer,
    this.onPlayItem,
    this.onAddToQueue,
    this.onPlayAll,
    this.onEnqueueAll,
    this.onTogglePlayPause,
    this.onNext,
    this.onPrevious,
    this.onVolumeChanged,
    this.onToggleMute,
    this.onAddFolder,
  });

  @override
  State<FullLibraryView> createState() => _FullLibraryViewState();
}

class _FullLibraryViewState extends State<FullLibraryView> {
  final TextEditingController _searchController = TextEditingController();
  LibrarySection _activeSection = LibrarySection.videos;
  LibraryLayoutMode _layoutMode = LibraryLayoutMode.grid;
  CompactLibraryTab _filterTab = CompactLibraryTab.all;
  MediaSortOrder _sortOrder = MediaSortOrder.unwatchedFirst;

  String? _selectedFolderPath;
  String _searchQuery = '';

  // Draggable MiniPlayer position offset (relative to bottom-right resting place)
  Offset _miniPlayerOffset = Offset.zero;
  bool _isMiniPlayerVisible = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MediaItem> _getFilteredItems() {
    List<MediaItem> items;
    if (_filterTab == CompactLibraryTab.inProgress) {
      items = widget.mediaLibraryService.getContinueWatching(limit: 100);
      if (_selectedFolderPath != null && _selectedFolderPath!.isNotEmpty) {
        items = items.where((it) => it.folderPath.startsWith(_selectedFolderPath!)).toList();
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        items = items.where((it) => it.title.toLowerCase().contains(q) || it.mrl.toLowerCase().contains(q)).toList();
      }
    } else {
      MediaFilter filter = MediaFilter.all;
      if (_activeSection == LibrarySection.videos) {
        if (_filterTab == CompactLibraryTab.unwatched) {
          filter = MediaFilter.unwatchedOnly;
        } else if (_filterTab == CompactLibraryTab.watched) {
          filter = MediaFilter.watchedOnly;
        } else {
          filter = MediaFilter.videoOnly;
        }
      } else if (_activeSection == LibrarySection.music) {
        filter = MediaFilter.audioOnly;
      } else {
        if (_filterTab == CompactLibraryTab.unwatched) {
          filter = MediaFilter.unwatchedOnly;
        } else if (_filterTab == CompactLibraryTab.watched) {
          filter = MediaFilter.watchedOnly;
        }
      }

      items = widget.mediaLibraryService.getMediaItems(
        sortOrder: _sortOrder,
        filter: filter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        folderPath: _selectedFolderPath,
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return AnimatedBuilder(
      animation: widget.mediaLibraryService,
      builder: (context, _) {
        final items = _getFilteredItems();
        final folders = widget.mediaLibraryService.getFolders();

        return Scaffold(
          backgroundColor: colors.background,
          body: Stack(
            children: [
              // -------------------------------------------------------------
              // 1. Full Library Main Layout (Sidebar + Content Workspace)
              // -------------------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pinned Left Sidebar (220dp)
                  _buildSidebar(context, colors, vlcTheme, folders),

                  // Main Content Area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Breadcrumb Address Bar & Action Row
                        _buildAddressBar(context, colors, vlcTheme, items),

                        // Filter Pills & View Layout Mode Switcher Bar
                        _buildControlsBar(context, colors, vlcTheme, items),

                        // Main Media Display (Grid / List / Details)
                        Expanded(
                          child: items.isEmpty
                              ? _buildEmptyState(context, colors, vlcTheme)
                              : _buildContentArea(context, colors, vlcTheme, items),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // -------------------------------------------------------------
              // 2. Draggable Bottom-Right MiniPlayerOverlay
              // -------------------------------------------------------------
              if (_isMiniPlayerVisible && widget.currentMrl != null)
                Positioned(
                  right: 24.0 - _miniPlayerOffset.dx,
                  bottom: 24.0 - _miniPlayerOffset.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _miniPlayerOffset += details.delta;
                      });
                    },
                    child: MiniPlayerOverlay(
                      title: widget.currentTitle,
                      mrl: widget.currentMrl!,
                      isPlaying: widget.isPlaying,
                      position: widget.position,
                      duration: widget.duration,
                      volume: widget.volume,
                      isMuted: widget.isMuted,
                      onMaximize: widget.onReturnToPlayer,
                      onTogglePlayPause: widget.onTogglePlayPause,
                      onNext: widget.onNext,
                      onPrevious: widget.onPrevious,
                      onVolumeChanged: widget.onVolumeChanged,
                      onToggleMute: widget.onToggleMute,
                      onClose: () => setState(() => _isMiniPlayerVisible = false),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  Widget _buildSidebar(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaFolder> folders,
  ) {
    return Container(
      width: 240.0,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(
            color: colors.border,
            width: VlcGeometry.strokeWidthBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.border.withOpacity(0.5),
                  width: VlcGeometry.strokeWidthBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                // Cone emblem
                CustomPaint(
                  size: const Size(20.0, 20.0),
                  painter: _MiniConePainter(coneColor: colors.accent.primary),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'VLC Media',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vlcTheme.typography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onReturnToPlayer != null)
                  Tooltip(
                    message: 'Back to Player [Esc]',
                    child: InkWell(
                      onTap: widget.onReturnToPlayer,
                      borderRadius: BorderRadius.circular(4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: VlcMonochromeIcon(
                          VlcIconGlyph.close,
                          size: 16.0,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _buildSidebarSectionHeader('LIBRARY', colors, vlcTheme),
                _buildSidebarItem(
                  section: LibrarySection.home,
                  label: 'Home',
                  icon: VlcIconGlyph.home,
                  colors: colors,
                  vlcTheme: vlcTheme,
                ),
                _buildSidebarItem(
                  section: LibrarySection.videos,
                  label: 'Videos',
                  icon: VlcIconGlyph.video,
                  colors: colors,
                  vlcTheme: vlcTheme,
                ),
                _buildSidebarItem(
                  section: LibrarySection.music,
                  label: 'Music',
                  icon: VlcIconGlyph.music,
                  colors: colors,
                  vlcTheme: vlcTheme,
                ),
                _buildSidebarItem(
                  section: LibrarySection.streams,
                  label: 'Streams',
                  icon: VlcIconGlyph.stream,
                  colors: colors,
                  vlcTheme: vlcTheme,
                ),
                _buildSidebarItem(
                  section: LibrarySection.playlists,
                  label: 'Playlists',
                  icon: VlcIconGlyph.playlist,
                  colors: colors,
                  vlcTheme: vlcTheme,
                ),

                const SizedBox(height: 12.0),
                _buildSidebarSectionHeader('INDEXED FOLDERS', colors, vlcTheme),
                ...folders.map((f) => _buildFolderSidebarItem(f, colors, vlcTheme)),

                // Add Folder Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: InkWell(
                    onTap: widget.onAddFolder,
                    borderRadius: VlcGeometry.borderRadiusMedium,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16.0, color: colors.accent.primary),
                          const SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              'Add Folder...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: vlcTheme.typography.bodySmall.copyWith(
                                color: colors.accent.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Return to Video Player Footer Button
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.border.withOpacity(0.5),
                  width: VlcGeometry.strokeWidthBorder,
                ),
              ),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.surfaceHover,
                foregroundColor: colors.textPrimary,
                shape: VlcGeometry.buttonShape,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
              onPressed: widget.onReturnToPlayer ?? () {},
              icon: VlcMonochromeIcon(
                VlcIconGlyph.play,
                size: 14.0,
                color: colors.accent.primary,
              ),
              label: Text(
                'Return to Player',
                style: vlcTheme.typography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title, VlcColors colors, VlcThemeData vlcTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
      child: Text(
        title,
        style: vlcTheme.typography.labelSmall.copyWith(
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          color: colors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required LibrarySection section,
    required String label,
    required VlcIconGlyph icon,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
  }) {
    final isSelected = _activeSection == section && _selectedFolderPath == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.5),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeSection = section;
            _selectedFolderPath = null;
          });
        },
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: isSelected ? colors.accent.subtleBackground : Colors.transparent,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: isSelected ? colors.accent.subtleBorder : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              VlcMonochromeIcon(
                icon,
                size: 16.0,
                color: isSelected ? colors.accent.primary : colors.textSecondary,
              ),
              const SizedBox(width: 10.0),
              Text(
                label,
                style: vlcTheme.typography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.accent.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderSidebarItem(
    MediaFolder folder,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isSelected = _selectedFolderPath == folder.path;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.5),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFolderPath = folder.path;
            _activeSection = LibrarySection.folders;
          });
        },
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: isSelected ? colors.accent.subtleBackground : Colors.transparent,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: isSelected ? colors.accent.subtleBorder : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              VlcMonochromeIcon(
                VlcIconGlyph.folder,
                size: 15.0,
                color: isSelected ? colors.accent.primary : colors.textSecondary,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vlcTheme.typography.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? colors.accent.primary : colors.textPrimary,
                  ),
                ),
              ),
              if (folder.itemCount > 0)
                Text(
                  '${folder.itemCount}',
                  style: vlcTheme.typography.monospaceTime.copyWith(
                    fontSize: 10.0,
                    color: colors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Address Bar (Breadcrumb + Search + View Layout Switcher)
  // ---------------------------------------------------------------------------

  Widget _buildAddressBar(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    return Container(
      height: 52.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: VlcGeometry.strokeWidthBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb Trail (e.g., Home › Videos › Movies)
          Expanded(
            child: Row(
              children: [
                _buildBreadcrumbPill('Home', () {
                  setState(() {
                    _activeSection = LibrarySection.home;
                    _selectedFolderPath = null;
                  });
                }, colors, vlcTheme),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: VlcMonochromeIcon(VlcIconGlyph.chevronRight, size: 12.0, color: colors.textTertiary),
                ),
                _buildBreadcrumbPill(_activeSection.name.toUpperCase(), () {}, colors, vlcTheme, isActive: _selectedFolderPath == null),
                if (_selectedFolderPath != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: VlcMonochromeIcon(VlcIconGlyph.chevronRight, size: 12.0, color: colors.textTertiary),
                  ),
                  _buildBreadcrumbPill(
                    _selectedFolderPath!.split(RegExp(r'[\\/]')).last,
                    () {},
                    colors,
                    vlcTheme,
                    isActive: true,
                  ),
                ],
              ],
            ),
          ),

          // Real-time Search Input
          SizedBox(
            width: 200.0,
            height: 32.0,
            child: TextField(
              controller: _searchController,
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: VlcMonochromeIcon(VlcIconGlyph.search, size: 14.0, color: colors.textSecondary),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14.0),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: colors.surfaceHover,
                border: OutlineInputBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  borderSide: BorderSide(color: colors.border.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  borderSide: BorderSide(color: colors.accent.primary),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12.0),

          // Layout Mode Switcher (Grid / List / Details)
          Container(
            height: 32.0,
            decoration: BoxDecoration(
              color: colors.surfaceHover,
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLayoutButton(LibraryLayoutMode.grid, VlcIconGlyph.viewGrid, 'Grid View', colors),
                _buildLayoutButton(LibraryLayoutMode.list, VlcIconGlyph.viewList, 'List View', colors),
                _buildLayoutButton(LibraryLayoutMode.details, VlcIconGlyph.viewDetails, 'Details View', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbPill(
    String label,
    VoidCallback onTap,
    VlcColors colors,
    VlcThemeData vlcTheme, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: VlcGeometry.borderRadiusSmall,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Text(
          label,
          style: vlcTheme.typography.bodySmall.copyWith(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? colors.accent.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutButton(
    LibraryLayoutMode mode,
    VlcIconGlyph glyph,
    String tooltip,
    VlcColors colors,
  ) {
    final isSelected = _layoutMode == mode;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _layoutMode = mode),
        child: Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: isSelected ? colors.accent.primary : Colors.transparent,
            borderRadius: VlcGeometry.borderRadiusSmall,
          ),
          alignment: Alignment.center,
          child: VlcMonochromeIcon(
            glyph,
            size: 15.0,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Controls Bar (Segment Pills + Sort Order Dropdown + Batch Actions)
  // ---------------------------------------------------------------------------

  Widget _buildControlsBar(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withOpacity(0.4),
            width: VlcGeometry.strokeWidthBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Filter Tabs (All, Unwatched, Watched, In Progress)
          _buildFilterPill(CompactLibraryTab.all, 'All', colors, vlcTheme),
          const SizedBox(width: 6.0),
          _buildFilterPill(CompactLibraryTab.unwatched, 'Unwatched', colors, vlcTheme),
          const SizedBox(width: 6.0),
          _buildFilterPill(CompactLibraryTab.watched, 'Watched', colors, vlcTheme),
          const SizedBox(width: 6.0),
          _buildFilterPill(CompactLibraryTab.inProgress, 'In Progress', colors, vlcTheme),

          const SizedBox(width: 12.0),

          // Batch Action: Play All
          if (items.isNotEmpty && widget.onPlayAll != null)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.accent.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              ),
              onPressed: () => widget.onPlayAll!(items),
              icon: VlcMonochromeIcon(VlcIconGlyph.play, size: 14.0, color: colors.accent.primary),
              label: Text('Play All (${items.length})', style: vlcTheme.typography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ),

          // Batch Action: Enqueue All
          if (items.isNotEmpty && widget.onEnqueueAll != null)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              ),
              onPressed: () => widget.onEnqueueAll!(items),
              icon: VlcMonochromeIcon(VlcIconGlyph.queue, size: 14.0, color: colors.textSecondary),
              label: Text('Enqueue All', style: vlcTheme.typography.bodySmall),
            ),

          const SizedBox(width: 8.0),

          // Sorting Dropdown
          PopupMenuButton<MediaSortOrder>(
            tooltip: 'Sort Order',
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: VlcGeometry.borderRadiusMedium,
              side: BorderSide(color: colors.border),
            ),
            onSelected: (order) => setState(() => _sortOrder = order),
            itemBuilder: (context) => [
              _buildSortMenuItem(MediaSortOrder.unwatchedFirst, 'Unwatched First', colors, vlcTheme),
              _buildSortMenuItem(MediaSortOrder.watchedFirst, 'Watched First', colors, vlcTheme),
              _buildSortMenuItem(MediaSortOrder.titleAz, 'Title (A → Z)', colors, vlcTheme),
              _buildSortMenuItem(MediaSortOrder.titleZa, 'Title (Z → A)', colors, vlcTheme),
              _buildSortMenuItem(MediaSortOrder.dateAddedDesc, 'Date Added (Newest)', colors, vlcTheme),
              _buildSortMenuItem(MediaSortOrder.durationDesc, 'Duration (Longest)', colors, vlcTheme),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: VlcGeometry.borderRadiusMedium,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortLabel(_sortOrder),
                    style: vlcTheme.typography.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  VlcMonochromeIcon(VlcIconGlyph.chevronDown, size: 12.0, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
    CompactLibraryTab tab,
    String label,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isSelected = _filterTab == tab;

    return InkWell(
      onTap: () => setState(() => _filterTab = tab),
      borderRadius: VlcGeometry.borderRadiusSmall,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent.primary : colors.surfaceHover,
          borderRadius: VlcGeometry.borderRadiusSmall,
          border: Border.all(
            color: isSelected ? colors.accent.primary : colors.border.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: vlcTheme.typography.bodySmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<MediaSortOrder> _buildSortMenuItem(
    MediaSortOrder order,
    String label,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isSelected = _sortOrder == order;
    return PopupMenuItem<MediaSortOrder>(
      value: order,
      height: 34.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: vlcTheme.typography.bodySmall.copyWith(
              color: isSelected ? colors.accent.primary : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (isSelected)
            Icon(Icons.check, size: 14.0, color: colors.accent.primary),
        ],
      ),
    );
  }

  String _sortLabel(MediaSortOrder order) {
    switch (order) {
      case MediaSortOrder.unwatchedFirst:
        return 'Unwatched First';
      case MediaSortOrder.watchedFirst:
        return 'Watched First';
      case MediaSortOrder.titleAz:
        return 'Title (A → Z)';
      case MediaSortOrder.titleZa:
        return 'Title (Z → A)';
      case MediaSortOrder.dateAddedDesc:
        return 'Newest First';
      case MediaSortOrder.durationDesc:
        return 'Duration';
      default:
        return 'Sort';
    }
  }

  // ---------------------------------------------------------------------------
  // Content Display: Grid / List / Details Views
  // ---------------------------------------------------------------------------

  Widget _buildContentArea(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    switch (_layoutMode) {
      case LibraryLayoutMode.grid:
        return _buildGridView(context, colors, vlcTheme, items);
      case LibraryLayoutMode.list:
        return _buildListView(context, colors, vlcTheme, items);
      case LibraryLayoutMode.details:
        return _buildDetailsView(context, colors, vlcTheme, items);
    }
  }

  Widget _buildGridView(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive column count: cards are ~220dp wide
        final crossAxisCount = math.max(2, (constraints.maxWidth / 220.0).floor());

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.15, // 16:9 thumbnail preview + info section
            crossAxisSpacing: 14.0,
            mainAxisSpacing: 14.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildGridCard(context, colors, vlcTheme, items[index]);
          },
        );
      },
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    MediaItem item,
  ) {
    final isCurrent = widget.currentMrl == item.mrl;

    return Draggable<MediaItem>(
      data: item,
      feedback: Material(
        elevation: 8.0,
        color: colors.surfaceVariant,
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Container(
          width: 220.0,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.accent.primary, width: 1.5),
          ),
          child: Row(
            children: [
              VlcMonochromeIcon(VlcIconGlyph.play, size: 16.0, color: colors.accent.primary),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  item.displayName,
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
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildGridCardContent(context, colors, vlcTheme, item, isCurrent),
      ),
      child: _buildGridCardContent(context, colors, vlcTheme, item, isCurrent),
    );
  }

  Widget _buildGridCardContent(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    MediaItem item,
    bool isCurrent,
  ) {
    return _GridCardHoverContainer(
      item: item,
      colors: colors,
      vlcTheme: vlcTheme,
      isCurrent: isCurrent,
      onPlay: () => widget.onPlayItem?.call(item),
      onAddToQueue: () => widget.onAddToQueue?.call(item),
      onToggleWatched: () {
        widget.mediaLibraryService.markAsWatched(item.mrl, watched: !item.isWatched);
      },
    );
  }

  Widget _buildListView(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCurrent = widget.currentMrl == item.mrl;

        return Draggable<MediaItem>(
          data: item,
          feedback: Material(
            elevation: 8.0,
            color: colors.surfaceVariant,
            borderRadius: VlcGeometry.borderRadiusMedium,
            child: Container(
              width: 240.0,
              padding: const EdgeInsets.all(8.0),
              child: Text(item.displayName, style: vlcTheme.typography.bodySmall),
            ),
          ),
          child: _ListCardHoverContainer(
            item: item,
            colors: colors,
            vlcTheme: vlcTheme,
            isCurrent: isCurrent,
            onPlay: () => widget.onPlayItem?.call(item),
            onAddToQueue: () => widget.onAddToQueue?.call(item),
            onToggleWatched: () {
              widget.mediaLibraryService.markAsWatched(item.mrl, watched: !item.isWatched);
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailsView(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(4), // Title
          1: FlexColumnWidth(2), // Progress / Watched
          2: FlexColumnWidth(1.5), // Duration
          3: FlexColumnWidth(1.5), // Size
          4: FlexColumnWidth(2), // Folder
          5: FixedColumnWidth(80), // Actions
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Table Header
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            children: [
              _tableHeader('NAME', colors, vlcTheme),
              _tableHeader('STATUS', colors, vlcTheme),
              _tableHeader('DURATION', colors, vlcTheme),
              _tableHeader('SIZE', colors, vlcTheme),
              _tableHeader('FOLDER', colors, vlcTheme),
              _tableHeader('ACTIONS', colors, vlcTheme),
            ],
          ),
          ...items.map((it) => _buildTableRow(it, colors, vlcTheme)),
        ],
      ),
    );
  }

  Widget _tableHeader(String label, VlcColors colors, VlcThemeData vlcTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        label,
        style: vlcTheme.typography.labelSmall.copyWith(
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          color: colors.textTertiary,
        ),
      ),
    );
  }

  TableRow _buildTableRow(MediaItem item, VlcColors colors, VlcThemeData vlcTheme) {
    final isCurrent = widget.currentMrl == item.mrl;

    return TableRow(
      decoration: BoxDecoration(
        color: isCurrent ? colors.accent.subtleBackground : Colors.transparent,
        border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.3))),
      ),
      children: [
        // Name
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              VlcMonochromeIcon(
                item.mediaType == MediaType.audio ? VlcIconGlyph.audioTrack : VlcIconGlyph.video,
                size: 16.0,
                color: isCurrent ? colors.accent.primary : colors.textSecondary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vlcTheme.typography.bodySmall.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? colors.accent.primary : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 7.0,
                height: 7.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isWatched
                      ? Colors.greenAccent
                      : item.resumeProgress > 0
                          ? colors.accent.primary
                          : colors.textTertiary.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                item.isWatched
                    ? 'Watched'
                    : item.resumeProgress > 0
                        ? '${(item.resumeProgress * 100).toInt()}%'
                        : 'Unwatched',
                style: vlcTheme.typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
        ),

        // Duration
        Text(
          item.formattedDuration,
          style: vlcTheme.typography.monospaceTime.copyWith(
            color: colors.textSecondary,
            fontSize: 11.0,
          ),
        ),

        // Size
        Text(
          item.formattedFileSize,
          style: vlcTheme.typography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 11.0,
          ),
        ),

        // Folder
        Text(
          item.folderName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: vlcTheme.typography.bodySmall.copyWith(
            color: colors.textTertiary,
            fontSize: 11.0,
          ),
        ),

        // Quick Actions
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => widget.onPlayItem?.call(item),
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: VlcMonochromeIcon(VlcIconGlyph.play, size: 14.0, color: colors.accent.primary),
              ),
            ),
            const SizedBox(width: 4.0),
            InkWell(
              onTap: () => widget.onAddToQueue?.call(item),
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: VlcMonochromeIcon(VlcIconGlyph.queue, size: 14.0, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, VlcColors colors, VlcThemeData vlcTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VlcMonochromeIcon(
            VlcIconGlyph.folder,
            size: 48.0,
            color: colors.textTertiary.withOpacity(0.4),
          ),
          const SizedBox(height: 16.0),
          Text(
            _searchQuery.isNotEmpty ? 'No media found matching "$_searchQuery"' : 'No media items in this section',
            style: vlcTheme.typography.titleMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Add folders to your indexed library to browse videos and music',
            style: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: 16.0),
          if (widget.onAddFolder != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent.primary,
                foregroundColor: Colors.white,
                shape: VlcGeometry.buttonShape,
              ),
              onPressed: widget.onAddFolder,
              icon: const Icon(Icons.add, size: 18.0),
              label: const Text('Add Media Folder'),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Grid Card with Hover Previews and Overlay Actions
// -----------------------------------------------------------------------------

class _GridCardHoverContainer extends StatefulWidget {
  final MediaItem item;
  final VlcColors colors;
  final VlcThemeData vlcTheme;
  final bool isCurrent;
  final VoidCallback onPlay;
  final VoidCallback onAddToQueue;
  final VoidCallback onToggleWatched;

  const _GridCardHoverContainer({
    required this.item,
    required this.colors,
    required this.vlcTheme,
    required this.isCurrent,
    required this.onPlay,
    required this.onAddToQueue,
    required this.onToggleWatched,
  });

  @override
  State<_GridCardHoverContainer> createState() => _GridCardHoverContainerState();
}

class _GridCardHoverContainerState extends State<_GridCardHoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? colors.accent.subtleBackground
                : _isHovered
                    ? colors.surfaceHover
                    : colors.surface,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: widget.isCurrent
                  ? colors.accent.primary
                  : _isHovered
                      ? colors.border
                      : colors.border.withOpacity(0.5),
              width: widget.isCurrent ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 16:9 Thumbnail Canvas with Overlay Badges
              Expanded(
                child: Stack(
                  children: [
                    // Simulated 16:9 media slate
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5.0)),
                      ),
                      alignment: Alignment.center,
                      child: VlcMonochromeIcon(
                        item.mediaType == MediaType.audio ? VlcIconGlyph.music : VlcIconGlyph.video,
                        size: 32.0,
                        color: colors.textTertiary.withOpacity(0.5),
                      ),
                    ),

                    // Progress Bar along bottom of thumbnail
                    if (item.resumeProgress > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.5,
                          color: Colors.black45,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: item.resumeProgress.clamp(0.0, 1.0),
                            child: Container(
                              color: item.isWatched ? Colors.greenAccent : colors.accent.primary,
                            ),
                          ),
                        ),
                      ),

                    // Duration badge (bottom right)
                    Positioned(
                      bottom: 6.0,
                      right: 6.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: VlcGeometry.borderRadiusSmall,
                        ),
                        child: Text(
                          item.formattedDuration,
                          style: widget.vlcTheme.typography.monospaceTime.copyWith(
                            fontSize: 10.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Hover Action Overlay Bar
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5.0)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _hoverCircleButton(
                                  icon: VlcIconGlyph.play,
                                  tooltip: 'Play Now',
                                  onTap: widget.onPlay,
                                  isAccent: true,
                                ),
                                const SizedBox(width: 8.0),
                                _hoverCircleButton(
                                  icon: VlcIconGlyph.queue,
                                  tooltip: 'Enqueue',
                                  onTap: widget.onAddToQueue,
                                ),
                                const SizedBox(width: 8.0),
                                _hoverCircleButton(
                                  icon: item.isWatched ? Icons.remove_done : Icons.done,
                                  tooltip: item.isWatched ? 'Mark Unwatched' : 'Mark Watched',
                                  onTap: widget.onToggleWatched,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title & Metadata area
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isCurrent ? colors.accent.primary : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Row(
                      children: [
                        if (item.season != null && item.episode != null)
                          Text(
                            'S${item.season!.toString().padLeft(2, '0')}E${item.episode!.toString().padLeft(2, '0')} • ',
                            style: widget.vlcTheme.typography.labelSmall.copyWith(
                              color: colors.accent.primary,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            item.folderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: widget.vlcTheme.typography.labelSmall.copyWith(
                              color: colors.textTertiary,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                        if (item.isWatched)
                          const Icon(Icons.check_circle, size: 12.0, color: Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hoverCircleButton({
    dynamic icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            color: isAccent ? widget.colors.accent.primary : Colors.black87,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: icon is VlcIconGlyph
              ? VlcMonochromeIcon(icon, size: 14.0, color: Colors.white)
              : Icon(icon as IconData, size: 14.0, color: Colors.white),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// List Card Hover Container
// -----------------------------------------------------------------------------

class _ListCardHoverContainer extends StatefulWidget {
  final MediaItem item;
  final VlcColors colors;
  final VlcThemeData vlcTheme;
  final bool isCurrent;
  final VoidCallback onPlay;
  final VoidCallback onAddToQueue;
  final VoidCallback onToggleWatched;

  const _ListCardHoverContainer({
    required this.item,
    required this.colors,
    required this.vlcTheme,
    required this.isCurrent,
    required this.onPlay,
    required this.onAddToQueue,
    required this.onToggleWatched,
  });

  @override
  State<_ListCardHoverContainer> createState() => _ListCardHoverContainerState();
}

class _ListCardHoverContainerState extends State<_ListCardHoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2.5),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? colors.accent.subtleBackground
                : _isHovered
                    ? colors.surfaceHover
                    : colors.surface,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: widget.isCurrent
                  ? colors.accent.primary
                  : _isHovered
                      ? colors.border
                      : colors.border.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              // Icon or thumbnail indicator
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: VlcGeometry.borderRadiusSmall,
                ),
                alignment: Alignment.center,
                child: VlcMonochromeIcon(
                  item.mediaType == MediaType.audio ? VlcIconGlyph.audioTrack : VlcIconGlyph.play,
                  size: 16.0,
                  color: widget.isCurrent ? colors.accent.primary : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12.0),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isCurrent ? colors.accent.primary : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Row(
                      children: [
                        Text(
                          '${item.formattedDuration} • ${item.formattedFileSize}',
                          style: widget.vlcTheme.typography.labelSmall.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10.0,
                          ),
                        ),
                        if (item.resumeProgress > 0 && !item.isWatched) ...[
                          const SizedBox(width: 8.0),
                          Container(
                            width: 50.0,
                            height: 3.0,
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: item.resumeProgress.clamp(0.0, 1.0),
                              child: Container(color: colors.accent.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Watched checkmark
              if (item.isWatched)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.check_circle, size: 14.0, color: Colors.greenAccent),
                ),

              // Hover quick actions
              if (_isHovered)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: VlcMonochromeIcon(VlcIconGlyph.play, size: 14.0, color: colors.accent.primary),
                      onPressed: widget.onPlay,
                      tooltip: 'Play',
                      splashRadius: 16.0,
                    ),
                    IconButton(
                      icon: VlcMonochromeIcon(VlcIconGlyph.queue, size: 14.0, color: colors.textSecondary),
                      onPressed: widget.onAddToQueue,
                      tooltip: 'Add to Queue',
                      splashRadius: 16.0,
                    ),
                    IconButton(
                      icon: Icon(item.isWatched ? Icons.remove_done : Icons.done, size: 14.0, color: colors.textSecondary),
                      onPressed: widget.onToggleWatched,
                      tooltip: item.isWatched ? 'Mark Unwatched' : 'Mark Watched',
                      splashRadius: 16.0,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Draggable Bottom-Right MiniPlayerOverlay (Task 4.3)
// -----------------------------------------------------------------------------

/// Floating mini player card pinned in the bottom-right of the FullLibraryView.
/// Allows full playback control while browsing the media library.
class MiniPlayerOverlay extends StatelessWidget {
  final String title;
  final String mrl;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final int volume;
  final bool isMuted;
  final VoidCallback? onMaximize;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ValueChanged<int>? onVolumeChanged;
  final VoidCallback? onToggleMute;
  final VoidCallback? onClose;

  const MiniPlayerOverlay({
    super.key,
    required this.title,
    required this.mrl,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100,
    this.isMuted = false,
    this.onMaximize,
    this.onTogglePlayPause,
    this.onNext,
    this.onPrevious,
    this.onVolumeChanged,
    this.onToggleMute,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      elevation: 12.0,
      shadowColor: Colors.black87,
      borderRadius: VlcGeometry.borderRadiusMedium,
      child: Container(
        width: 320.0,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusMedium,
          border: Border.all(color: colors.accent.primary, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mini 16:9 Simulated Canvas / Title Header
            Stack(
              children: [
                // Top Simulated 16:9 aspect display
                Container(
                  height: 140.0,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(5.0)),
                  ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size(40.0, 40.0),
                    painter: _MiniConePainter(coneColor: colors.accent.primary),
                  ),
                ),

                // Top Right Action Icons (Maximize to return to video player, Close)
                Positioned(
                  top: 6.0,
                  right: 6.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _miniIconButton(
                        icon: VlcIconGlyph.maximize,
                        tooltip: 'Maximize to Fullscreen [Esc]',
                        onTap: onMaximize,
                        colors: colors,
                      ),
                      const SizedBox(width: 4.0),
                      if (onClose != null)
                        _miniIconButton(
                          icon: VlcIconGlyph.close,
                          tooltip: 'Hide Mini Player',
                          onTap: onClose,
                          colors: colors,
                        ),
                    ],
                  ),
                ),

                // Title overlay bar (bottom of video slate)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: vlcTheme.typography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Mini Seek Bar Progress
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent.primary),
              minHeight: 3.0,
            ),

            // Controls & Timers Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                children: [
                  // Current Time / Duration
                  Text(
                    '${_fmt(position)} / ${_fmt(duration)}',
                    style: vlcTheme.typography.monospaceTime.copyWith(
                      fontSize: 10.0,
                      color: colors.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  // Transport Buttons (Prev, Play/Pause, Next)
                  _miniTransportButton(
                    icon: VlcMonochromeIcon(VlcIconGlyph.previous, size: 14.0, color: colors.textPrimary),
                    onTap: onPrevious,
                    tooltip: 'Previous',
                  ),
                  const SizedBox(width: 2.0),
                  _miniTransportButton(
                    icon: VlcMonochromeIcon(
                      isPlaying ? VlcIconGlyph.pause : VlcIconGlyph.play,
                      size: 16.0,
                      color: colors.accent.primary,
                    ),
                    onTap: onTogglePlayPause,
                    tooltip: isPlaying ? 'Pause [Space]' : 'Play [Space]',
                  ),
                  const SizedBox(width: 2.0),
                  _miniTransportButton(
                    icon: VlcMonochromeIcon(VlcIconGlyph.next, size: 14.0, color: colors.textPrimary),
                    onTap: onNext,
                    tooltip: 'Next',
                  ),
                  const SizedBox(width: 4.0),

                  // Mute / Volume icon
                  _miniTransportButton(
                    icon: VlcMonochromeIcon(
                      isMuted ? VlcIconGlyph.volumeMute : VlcIconGlyph.volumeHigh,
                      size: 14.0,
                      color: colors.textSecondary,
                    ),
                    onTap: onToggleMute,
                    tooltip: isMuted ? 'Unmute' : 'Mute',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _miniIconButton({
    required VlcIconGlyph icon,
    required String tooltip,
    required VoidCallback? onTap,
    required VlcColors colors,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26.0,
          height: 26.0,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: VlcGeometry.borderRadiusSmall,
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: VlcMonochromeIcon(icon, size: 13.0, color: Colors.white),
        ),
      ),
    );
  }

  Widget _miniTransportButton({
    required Widget icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: icon,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Vector Cone Painter for Mini Player & Sidebar
// -----------------------------------------------------------------------------

class _MiniConePainter extends CustomPainter {
  final Color coneColor;
  _MiniConePainter({required this.coneColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintOrange = Paint()..color = coneColor..style = PaintingStyle.fill;
    final paintWhite = Paint()..color = Colors.white.withOpacity(0.92)..style = PaintingStyle.fill;
    final paintBase = Paint()..color = coneColor.withOpacity(0.80)..style = PaintingStyle.fill;

    // Base rectangular plate
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.84, w * 0.80, h * 0.12),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(baseRect, paintBase);

    // Main cone body
    final conePath = Path()
      ..moveTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.78, h * 0.84)
      ..lineTo(w * 0.22, h * 0.84)
      ..close();
    canvas.drawPath(conePath, paintOrange);

    // Reflective white stripe 1
    final stripe1 = Path()
      ..moveTo(w * 0.32, h * 0.60)
      ..lineTo(w * 0.68, h * 0.60)
      ..lineTo(w * 0.72, h * 0.73)
      ..lineTo(w * 0.28, h * 0.73)
      ..close();
    canvas.drawPath(stripe1, paintWhite);

    // Reflective white stripe 2
    final stripe2 = Path()
      ..moveTo(w * 0.40, h * 0.32)
      ..lineTo(w * 0.60, h * 0.32)
      ..lineTo(w * 0.64, h * 0.45)
      ..lineTo(w * 0.36, h * 0.45)
      ..close();
    canvas.drawPath(stripe2, paintWhite);
  }

  @override
  bool shouldRepaint(covariant _MiniConePainter oldDelegate) => oldDelegate.coneColor != coneColor;
}
