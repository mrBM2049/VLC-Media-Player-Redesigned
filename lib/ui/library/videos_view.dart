import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/media_library_models.dart';
import '../../services/media_library_service.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Categorization filter for the Videos library view.
enum VideoCategoryFilter {
  all,
  movies,
  tvShows,
  clips,
}

/// Dedicated Videos View for VLC Modern Redesign.
///
/// Features:
/// - Category segmentation tabs: **All Videos**, **Movies**, **TV Shows (Series & Seasons)**, and **Clips**.
/// - Sorting controls (Watched first, Unwatched first, Title A-Z, Date Added, Duration).
/// - Season/Episode grouping view for TV Shows with collapsible series cards and episode queues.
/// - Fast batch actions: "Play All", "Enqueue All".
/// - Quick search filter.
class VideosView extends StatefulWidget {
  final MediaLibraryService mediaLibraryService;
  final ValueChanged<MediaItem>? onPlayItem;
  final ValueChanged<MediaItem>? onAddToQueue;
  final ValueChanged<List<MediaItem>>? onPlayAll;
  final ValueChanged<List<MediaItem>>? onEnqueueAll;
  final VoidCallback? onAddFolder;

  const VideosView({
    super.key,
    required this.mediaLibraryService,
    this.onPlayItem,
    this.onAddToQueue,
    this.onPlayAll,
    this.onEnqueueAll,
    this.onAddFolder,
  });

  @override
  State<VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends State<VideosView> {
  VideoCategoryFilter _category = VideoCategoryFilter.all;
  MediaSortOrder _sortOrder = MediaSortOrder.unwatchedFirst;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _collapsedSeries = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isTvShow(MediaItem item) {
    return item.season != null || item.episode != null;
  }

  bool _isMovie(MediaItem item) {
    // If not a TV episode and duration >= 40 minutes (2,400,000 ms)
    return !_isTvShow(item) && item.durationMs >= 2400000;
  }

  bool _isClip(MediaItem item) {
    return !_isTvShow(item) && item.durationMs < 2400000;
  }

  List<MediaItem> _filterVideos(List<MediaItem> allVideos) {
    var result = allVideos;

    // 1. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((item) =>
          item.title.toLowerCase().contains(q) ||
          item.folderName.toLowerCase().contains(q)).toList();
    }

    // 2. Category Filter
    switch (_category) {
      case VideoCategoryFilter.all:
        break;
      case VideoCategoryFilter.movies:
        result = result.where(_isMovie).toList();
        break;
      case VideoCategoryFilter.tvShows:
        result = result.where(_isTvShow).toList();
        break;
      case VideoCategoryFilter.clips:
        result = result.where(_isClip).toList();
        break;
    }

    return result;
  }

  Map<String, List<MediaItem>> _groupBySeries(List<MediaItem> tvItems) {
    final Map<String, List<MediaItem>> grouped = {};
    for (final item in tvItems) {
      final seriesName = item.folderName.isNotEmpty ? item.folderName : 'General Series';
      grouped.putIfAbsent(seriesName, () => []).add(item);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final sA = a.season ?? 0;
        final sB = b.season ?? 0;
        if (sA != sB) return sA.compareTo(sB);
        final epA = a.episode ?? 0;
        final epB = b.episode ?? 0;
        return epA.compareTo(epB);
      });
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return AnimatedBuilder(
      animation: widget.mediaLibraryService,
      builder: (context, _) {
        final allVideos = widget.mediaLibraryService.getMediaItems(
          filter: MediaFilter.videoOnly,
          sortOrder: _sortOrder,
        );
        final filteredVideos = _filterVideos(allVideos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Category Pills, Search & Stats
            _buildHeader(context, colors, vlcTheme, allVideos.length, filteredVideos.length),

            Divider(height: 1.0, color: colors.border),

            // Main Video Workspace
            Expanded(
              child: filteredVideos.isEmpty
                  ? _buildEmptyState(context, colors, vlcTheme)
                  : (_category == VideoCategoryFilter.tvShows
                      ? _buildTvShowsWorkspace(context, colors, vlcTheme, filteredVideos)
                      : _buildVideoGrid(context, colors, vlcTheme, filteredVideos)),
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
    int totalCount,
    int filteredCount,
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
                VlcIconGlyph.video,
                size: 26.0,
              ),
              const SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Videos Library',
                    style: vlcTheme.typography.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$filteredCount items ($totalCount total indexed)',
                    style: vlcTheme.typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Batch actions
              if (filteredCount > 0) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    final items = widget.mediaLibraryService.getMediaItems(
                      filter: MediaFilter.videoOnly,
                      sortOrder: _sortOrder,
                    );
                    final filtered = _filterVideos(items);
                    widget.onPlayAll?.call(filtered);
                  },
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
                const SizedBox(width: 10.0),
                OutlinedButton.icon(
                  onPressed: () {
                    final items = widget.mediaLibraryService.getMediaItems(
                      filter: MediaFilter.videoOnly,
                      sortOrder: _sortOrder,
                    );
                    final filtered = _filterVideos(items);
                    widget.onEnqueueAll?.call(filtered);
                  },
                  icon: VlcMonochromeIcon(VlcIconGlyph.queue, size: 14.0, color: colors.textPrimary),
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
          const SizedBox(height: 14.0),

          // Category Segmentation & Search Filter Bar
          Row(
            children: [
              _buildCategoryPill('All Videos', VideoCategoryFilter.all, colors, vlcTheme),
              const SizedBox(width: 8.0),
              _buildCategoryPill('Movies', VideoCategoryFilter.movies, colors, vlcTheme),
              const SizedBox(width: 8.0),
              _buildCategoryPill('TV Shows', VideoCategoryFilter.tvShows, colors, vlcTheme),
              const SizedBox(width: 8.0),
              _buildCategoryPill('Clips', VideoCategoryFilter.clips, colors, vlcTheme),

              const Spacer(),

              // Quick Search Input
              Container(
                width: 240.0,
                height: 34.0,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search videos...',
                    hintStyle: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: VlcMonochromeIcon(VlcIconGlyph.search, size: 14.0, color: colors.textSecondary),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14.0),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(width: 12.0),

              // Sort Dropdown
              PopupMenuButton<MediaSortOrder>(
                tooltip: 'Sort Videos',
                initialValue: _sortOrder,
                onSelected: (order) => setState(() => _sortOrder = order),
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  side: BorderSide(color: colors.border),
                ),
                itemBuilder: (context) => [
                  _buildSortMenuItem(MediaSortOrder.unwatchedFirst, 'Unwatched First', vlcTheme),
                  _buildSortMenuItem(MediaSortOrder.watchedFirst, 'Watched First', vlcTheme),
                  _buildSortMenuItem(MediaSortOrder.titleAz, 'Title (A → Z)', vlcTheme),
                  _buildSortMenuItem(MediaSortOrder.titleZa, 'Title (Z → A)', vlcTheme),
                  _buildSortMenuItem(MediaSortOrder.durationDesc, 'Longest Duration', vlcTheme),
                  _buildSortMenuItem(MediaSortOrder.durationAsc, 'Shortest Duration', vlcTheme),
                  _buildSortMenuItem(MediaSortOrder.dateAddedDesc, 'Recently Added', vlcTheme),
                ],
                child: Container(
                  height: 34.0,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: VlcGeometry.borderRadiusMedium,
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      VlcMonochromeIcon(VlcIconGlyph.menu, size: 14.0, color: colors.textSecondary),
                      const SizedBox(width: 6.0),
                      Text(
                        _sortOrderLabel(_sortOrder),
                        style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(width: 4.0),
                      VlcMonochromeIcon(VlcIconGlyph.chevronDown, size: 12.0, color: colors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<MediaSortOrder> _buildSortMenuItem(MediaSortOrder order, String label, VlcThemeData vlcTheme) {
    final isSelected = _sortOrder == order;
    return PopupMenuItem(
      value: order,
      height: 36.0,
      child: Row(
        children: [
          if (isSelected)
            const VlcMonochromeIcon(VlcIconGlyph.play, size: 12.0, color: VlcColors.coneOrange)
          else
            const SizedBox(width: 12.0),
          const SizedBox(width: 8.0),
          Text(
            label,
            style: vlcTheme.typography.bodySmall.copyWith(
              color: isSelected ? VlcColors.coneOrange : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _sortOrderLabel(MediaSortOrder order) {
    switch (order) {
      case MediaSortOrder.unwatchedFirst:
        return 'Unwatched';
      case MediaSortOrder.watchedFirst:
        return 'Watched';
      case MediaSortOrder.titleAz:
        return 'A → Z';
      case MediaSortOrder.titleZa:
        return 'Z → A';
      case MediaSortOrder.durationDesc:
        return 'Longest';
      case MediaSortOrder.durationAsc:
        return 'Shortest';
      case MediaSortOrder.dateAddedDesc:
        return 'Newest';
      default:
        return 'Sort';
    }
  }

  Widget _buildCategoryPill(String label, VideoCategoryFilter filter, VlcColors colors, VlcThemeData vlcTheme) {
    final isSelected = _category == filter;
    return InkWell(
      onTap: () => setState(() => _category = filter),
      borderRadius: VlcGeometry.borderRadiusMedium,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? VlcColors.coneOrange : colors.surfaceVariant,
          borderRadius: VlcGeometry.borderRadiusMedium,
          border: Border.all(
            color: isSelected ? VlcColors.coneOrange : colors.border,
          ),
        ),
        child: Text(
          label,
          style: vlcTheme.typography.bodySmall.copyWith(
            color: isSelected ? Colors.black : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260.0,
        mainAxisSpacing: 20.0,
        crossAxisSpacing: 20.0,
        childAspectRatio: 16 / 13,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildVideoCard(context, item, colors, vlcTheme);
      },
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    MediaItem item,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 16:9 Thumbnail / Placeholder
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFF141414),
                  child: Center(
                    child: VlcTwoToneIcon(
                      item.isWatched ? VlcIconGlyph.chapters : VlcIconGlyph.video,
                      size: 38.0,
                      baseColor: colors.textSecondary.withValues(alpha: 0.3),
                      accentColor: VlcColors.coneOrange.withValues(alpha: 0.8),
                    ),
                  ),
                ),

                // Hover / Click to play overlay
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onPlayItem?.call(item),
                    child: Center(
                      child: Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                        ),
                        child: const Center(
                          child: VlcMonochromeIcon(
                            VlcIconGlyph.play,
                            size: 20.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Duration badge bottom right
                Positioned(
                  bottom: 6.0,
                  right: 6.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: VlcGeometry.borderRadiusSmall,
                    ),
                    child: Text(
                      item.formattedDuration,
                      style: vlcTheme.typography.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 10.0,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),

                // Watched badge top right
                if (item.isWatched)
                  Positioned(
                    top: 6.0,
                    right: 6.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.85),
                        borderRadius: VlcGeometry.borderRadiusSmall,
                      ),
                      child: Text(
                        'WATCHED',
                        style: vlcTheme.typography.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Resume progress bar if in progress
                if (item.resumeProgress > 0 && item.resumeProgress < 0.90)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: item.resumeProgress,
                      minHeight: 3.0,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(VlcColors.coneOrange),
                    ),
                  ),
              ],
            ),
          ),

          // Metadata bottom bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: vlcTheme.typography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${item.folderName} • ${item.formattedFileSize}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: vlcTheme.typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const VlcMonochromeIcon(VlcIconGlyph.queue, size: 16.0),
                  tooltip: 'Add to Queue',
                  onPressed: () => widget.onAddToQueue?.call(item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvShowsWorkspace(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> tvItems,
  ) {
    final grouped = _groupBySeries(tvItems);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: grouped.entries.map((entry) {
        final seriesName = entry.key;
        final episodes = entry.value;
        final isCollapsed = _collapsedSeries.contains(seriesName);

        return Container(
          margin: const EdgeInsets.only(bottom: 20.0),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Series Header Row
              InkWell(
                onTap: () {
                  setState(() {
                    if (isCollapsed) {
                      _collapsedSeries.remove(seriesName);
                    } else {
                      _collapsedSeries.add(seriesName);
                    }
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(VlcGeometry.radiusMedium)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      VlcMonochromeIcon(
                        isCollapsed ? VlcIconGlyph.chevronRight : VlcIconGlyph.chevronDown,
                        size: 16.0,
                        color: VlcColors.coneOrange,
                      ),
                      const SizedBox(width: 10.0),
                      const VlcTwoToneIcon(VlcIconGlyph.playlist, size: 20.0),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          seriesName,
                          style: vlcTheme.typography.titleMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${episodes.length} Episodes',
                        style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(width: 12.0),
                      IconButton(
                        icon: const VlcMonochromeIcon(VlcIconGlyph.play, size: 14.0, color: VlcColors.coneOrange),
                        tooltip: 'Play Series',
                        onPressed: () => widget.onPlayAll?.call(episodes),
                      ),
                      IconButton(
                        icon: const VlcMonochromeIcon(VlcIconGlyph.queue, size: 14.0),
                        tooltip: 'Enqueue Series',
                        onPressed: () => widget.onEnqueueAll?.call(episodes),
                      ),
                    ],
                  ),
                ),
              ),

              // Episodes List (if expanded)
              if (!isCollapsed) ...[
                Divider(height: 1.0, color: colors.border),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => Divider(height: 1.0, color: colors.borderSubtle),
                  itemBuilder: (context, idx) {
                    final ep = episodes[idx];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                      leading: Container(
                        width: 32.0,
                        height: 32.0,
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: VlcGeometry.borderRadiusSmall,
                        ),
                        child: Center(
                          child: Text(
                            ep.episode != null ? 'E${ep.episode}' : '${idx + 1}',
                            style: vlcTheme.typography.bodySmall.copyWith(
                              color: VlcColors.coneOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        ep.displayName,
                        style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textPrimary),
                      ),
                      subtitle: Text(
                        '${ep.formattedDuration} • ${ep.formattedFileSize}',
                        style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ep.isWatched)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                              margin: const EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: VlcGeometry.borderRadiusSmall,
                              ),
                              child: Text(
                                'WATCHED',
                                style: vlcTheme.typography.bodySmall.copyWith(
                                  color: Colors.green,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const VlcMonochromeIcon(VlcIconGlyph.play, size: 14.0),
                            onPressed: () => widget.onPlayItem?.call(ep),
                          ),
                          IconButton(
                            icon: const VlcMonochromeIcon(VlcIconGlyph.queue, size: 14.0),
                            onPressed: () => widget.onAddToQueue?.call(ep),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      }).toList(),
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
          VlcTwoToneIcon(
            VlcIconGlyph.video,
            size: 64.0,
            baseColor: colors.textSecondary.withValues(alpha: 0.3),
            accentColor: VlcColors.coneOrange,
          ),
          const SizedBox(height: 16.0),
          Text(
            _searchQuery.isNotEmpty ? 'No videos matching "$_searchQuery"' : 'No videos found in library',
            style: vlcTheme.typography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 8.0),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term or clear the filter'
                : 'Index a folder with movies, series or video clips to get started',
            style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 20.0),
          if (_searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VlcColors.coneOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                ),
              ),
              child: const Text('Clear Search'),
            )
          else if (widget.onAddFolder != null)
            ElevatedButton.icon(
              onPressed: widget.onAddFolder,
              icon: const VlcMonochromeIcon(VlcIconGlyph.folder, size: 16.0, color: Colors.black),
              label: const Text('Add Videos Folder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VlcColors.coneOrange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

