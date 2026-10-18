import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../models/media_library_models.dart';
import '../../services/media_library_service.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';
import '../shell/top_player_bar.dart'; // for VlcTopBarButton

/// Filter categories for the Compact Library Drawer.
enum CompactLibraryTab {
  all,
  unwatched,
  watched,
  inProgress,
}

/// Compact Media Library Drawer for VLC Modern Redesign.
///
/// Slides in alongside playing video (Desktop 340dp width) triggered by the
/// top folder breadcrumb (`TopPlayerBar.onFolderBreadcrumbTap`) or shortcut (`Ctrl+L`).
/// Allows users to browse episodes/media, see watched vs unwatched states, and
/// drag-and-drop items directly into the Queue without stopping video playback.
class CompactLibraryDrawer extends StatefulWidget {
  final MediaLibraryService mediaLibraryService;
  final VoidCallback? onClose;
  final ValueChanged<MediaItem>? onPlayItem;
  final ValueChanged<MediaItem>? onAddToQueue;
  final ValueChanged<List<MediaItem>>? onPlayAll;
  final ValueChanged<List<MediaItem>>? onEnqueueAll;
  final VoidCallback? onAddFolder;
  final String? currentMrl;
  final String? activeFolderPath;

  const CompactLibraryDrawer({
    super.key,
    required this.mediaLibraryService,
    this.onClose,
    this.onPlayItem,
    this.onAddToQueue,
    this.onPlayAll,
    this.onEnqueueAll,
    this.onAddFolder,
    this.currentMrl,
    this.activeFolderPath,
  });

  @override
  State<CompactLibraryDrawer> createState() => _CompactLibraryDrawerState();
}

class _CompactLibraryDrawerState extends State<CompactLibraryDrawer> {
  final TextEditingController _searchController = TextEditingController();
  CompactLibraryTab _activeTab = CompactLibraryTab.all;
  MediaSortOrder _sortOrder = MediaSortOrder.unwatchedFirst;
  String? _selectedFolderPath;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFolderPath = widget.activeFolderPath;
    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CompactLibraryDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeFolderPath != oldWidget.activeFolderPath && widget.activeFolderPath != null) {
      _selectedFolderPath = widget.activeFolderPath;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MediaItem> _getFilteredItems() {
    List<MediaItem> items;
    if (_activeTab == CompactLibraryTab.inProgress) {
      items = widget.mediaLibraryService.getContinueWatching(limit: 50);
      if (_selectedFolderPath != null && _selectedFolderPath!.isNotEmpty) {
        items = items.where((it) => it.folderPath.startsWith(_selectedFolderPath!)).toList();
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        items = items.where((it) => it.title.toLowerCase().contains(q) || it.mrl.toLowerCase().contains(q)).toList();
      }
    } else {
      MediaFilter filter = MediaFilter.all;
      if (_activeTab == CompactLibraryTab.unwatched) {
        filter = MediaFilter.unwatchedOnly;
      } else if (_activeTab == CompactLibraryTab.watched) {
        filter = MediaFilter.watchedOnly;
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

  String _formatTotalDuration(List<MediaItem> items) {
    int totalMs = 0;
    for (final it in items) {
      totalMs += it.durationMs;
    }
    if (totalMs <= 0) return '';
    final totalSec = totalMs ~/ 1000;
    final hours = totalSec ~/ 3600;
    final minutes = (totalSec % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return AnimatedBuilder(
      animation: widget.mediaLibraryService,
      builder: (context, _) {
        final folders = widget.mediaLibraryService.getFolders();
        final items = _getFilteredItems();
        final unwatchedCount = widget.mediaLibraryService
            .getMediaItems(
              filter: MediaFilter.unwatchedOnly,
              folderPath: _selectedFolderPath,
            )
            .length;

        return Container(
          width: VlcGeometry.inspectorDrawerWidth,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              right: BorderSide(
                color: colors.border,
                width: VlcGeometry.strokeWidthBorder,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------------------
                // 1. Header: Folder Selector, Add Folder, Sort, Close
                // -------------------------------------------------------------
                _buildHeader(context, colors, vlcTheme, folders),

                // -------------------------------------------------------------
                // 2. Search & Segment Tabs (All, Unwatched, Watched, In Progress)
                // -------------------------------------------------------------
                _buildSearchAndFilters(context, colors, vlcTheme, unwatchedCount),

                // -------------------------------------------------------------
                // 3. Media Items List (Draggable Cards)
                // -------------------------------------------------------------
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState(context, colors, vlcTheme)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return _buildMediaCard(context, colors, vlcTheme, items[index]);
                          },
                        ),
                ),

                // -------------------------------------------------------------
                // 4. Footer Summary & Quick Action Buttons
                // -------------------------------------------------------------
                if (items.isNotEmpty)
                  _buildFooter(context, colors, vlcTheme, items),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaFolder> folders,
  ) {
    String folderLabel = 'All Media Folders';
    if (_selectedFolderPath != null && _selectedFolderPath!.isNotEmpty) {
      final match = folders.firstWhere(
        (f) => f.path == _selectedFolderPath,
        orElse: () => MediaFolder(
          id: 0,
          path: _selectedFolderPath!,
          name: p.basename(_selectedFolderPath!),
          lastIndexed: DateTime.now(),
        ),
      );
      folderLabel = match.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: VlcGeometry.strokeWidthBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Folder Cone-Orange Icon
          VlcMonochromeIcon(
            VlcIconGlyph.folder,
            size: 18.0,
            color: colors.accent.primary,
          ),
          const SizedBox(width: 8.0),

          // Folder Dropdown Switcher
          Expanded(
            child: PopupMenuButton<String?>(
              tooltip: 'Switch Folder',
              offset: const Offset(0, 32),
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: VlcGeometry.borderRadiusMedium,
                side: BorderSide(color: colors.border),
              ),
              onSelected: (path) {
                setState(() => _selectedFolderPath = path);
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String?>(
                    value: null,
                    child: Text(
                      '📁 All Media Folders',
                      style: vlcTheme.typography.bodyMedium.copyWith(
                        color: _selectedFolderPath == null ? colors.accent.primary : colors.textPrimary,
                        fontWeight: _selectedFolderPath == null ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...folders.map(
                    (f) => PopupMenuItem<String?>(
                      value: f.path,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.name,
                              overflow: TextOverflow.ellipsis,
                              style: vlcTheme.typography.bodyMedium.copyWith(
                                color: _selectedFolderPath == f.path
                                    ? colors.accent.primary
                                    : colors.textPrimary,
                                fontWeight: _selectedFolderPath == f.path
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surfaceHover,
                              borderRadius: VlcGeometry.borderRadiusSmall,
                            ),
                            child: Text(
                              '${f.itemCount}',
                              style: vlcTheme.typography.monospaceTime.copyWith(
                                fontSize: 10,
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      folderLabel,
                      overflow: TextOverflow.ellipsis,
                      style: vlcTheme.typography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18.0,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Add Folder Button
          if (widget.onAddFolder != null)
            VlcTopBarButton(
              tooltip: 'Index New Folder',
              width: 28.0,
              height: 28.0,
              onPressed: widget.onAddFolder,
              child: const Icon(Icons.create_new_folder_outlined, size: 16.0),
            ),

          // Sort Menu
          PopupMenuButton<MediaSortOrder>(
            tooltip: 'Sort Items',
            offset: const Offset(0, 32),
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: VlcGeometry.borderRadiusMedium,
              side: BorderSide(color: colors.border),
            ),
            icon: VlcMonochromeIcon(
              VlcIconGlyph.settings,
              size: 16.0,
              color: colors.textSecondary,
            ),
            onSelected: (sort) {
              setState(() => _sortOrder = sort);
            },
            itemBuilder: (context) => [
              _buildSortItem('Unwatched First', MediaSortOrder.unwatchedFirst, colors, vlcTheme),
              _buildSortItem('Watched First', MediaSortOrder.watchedFirst, colors, vlcTheme),
              _buildSortItem('Recently Played', MediaSortOrder.recentlyPlayed, colors, vlcTheme),
              _buildSortItem('Title (A-Z)', MediaSortOrder.titleAz, colors, vlcTheme),
              _buildSortItem('Duration (Longest)', MediaSortOrder.durationDesc, colors, vlcTheme),
            ],
          ),

          // Close Drawer Button
          if (widget.onClose != null)
            VlcTopBarButton(
              tooltip: 'Close Library',
              width: 28.0,
              height: 28.0,
              onPressed: widget.onClose,
              child: const Icon(Icons.close, size: 16.0),
            ),
        ],
      ),
    );
  }

  PopupMenuItem<MediaSortOrder> _buildSortItem(
    String label,
    MediaSortOrder order,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isSelected = _sortOrder == order;
    return PopupMenuItem<MediaSortOrder>(
      value: order,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 15.0,
            color: isSelected ? colors.accent.primary : colors.textTertiary,
          ),
          const SizedBox(width: 8.0),
          Text(
            label,
            style: vlcTheme.typography.bodySmall.copyWith(
              color: isSelected ? colors.accent.primary : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    int unwatchedCount,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.border.withOpacity(0.5),
            width: VlcGeometry.strokeWidthBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search input box
          Container(
            height: 32.0,
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(0.50),
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(
                color: colors.border.withOpacity(0.60),
                width: 1.0,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search episodes, movies...',
                hintStyle: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: VlcMonochromeIcon(
                    VlcIconGlyph.search,
                    size: 14.0,
                    color: colors.textTertiary,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14.0),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 7.0),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Filter Segment Pills
          Row(
            children: [
              _buildSegmentPill('All', CompactLibraryTab.all, colors, vlcTheme),
              const SizedBox(width: 4.0),
              _buildSegmentPill(
                'Unwatched',
                CompactLibraryTab.unwatched,
                colors,
                vlcTheme,
                badge: unwatchedCount > 0 ? '$unwatchedCount' : null,
              ),
              const SizedBox(width: 4.0),
              _buildSegmentPill('Watched', CompactLibraryTab.watched, colors, vlcTheme),
              const SizedBox(width: 4.0),
              _buildSegmentPill('In Progress', CompactLibraryTab.inProgress, colors, vlcTheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPill(
    String label,
    CompactLibraryTab tab,
    VlcColors colors,
    VlcThemeData vlcTheme, {
    String? badge,
  }) {
    final isSelected = _activeTab == tab;

    return Expanded(
      child: GestureDetector(
        key: ValueKey('tab_${tab.name}'),
        onTap: () => setState(() => _activeTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          decoration: BoxDecoration(
            color: isSelected ? colors.accent.primary : colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusSmall,
            border: Border.all(
              color: isSelected ? colors.accent.primary : colors.border.withOpacity(0.40),
            ),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Center(
              child: Text(
                badge != null ? '$label ($badge)' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: vlcTheme.typography.bodySmall.copyWith(
                  fontSize: 10.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCard(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    MediaItem item,
  ) {
    final isCurrent = widget.currentMrl == item.mrl;

    // Draggable wrapper to enable dragging media into QueueDrawer
    return Draggable<MediaItem>(
      data: item,
      feedback: Material(
        elevation: 8.0,
        color: colors.surfaceVariant,
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Container(
          width: 260.0,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.accent.primary, width: 1.5),
          ),
          child: Row(
            children: [
              VlcMonochromeIcon(
                item.mediaType == MediaType.audio ? VlcIconGlyph.audioTrack : VlcIconGlyph.play,
                size: 16.0,
                color: colors.accent.primary,
              ),
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
        child: _buildCardContent(context, colors, vlcTheme, item, isCurrent),
      ),
      child: _buildCardContent(context, colors, vlcTheme, item, isCurrent),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    MediaItem item,
    bool isCurrent,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        color: isCurrent
            ? colors.accent.subtleBackground
            : colors.surfaceVariant.withOpacity(0.35),
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(
          color: isCurrent
              ? colors.accent.primary
              : colors.border.withOpacity(0.50),
          width: isCurrent ? 1.5 : VlcGeometry.strokeWidthBorder,
        ),
      ),
      child: InkWell(
        borderRadius: VlcGeometry.borderRadiusMedium,
        onTap: () => widget.onPlayItem?.call(item),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail / Media Glyph Preview Box
                  Container(
                    width: 44.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: colors.surfaceHover,
                      borderRadius: VlcGeometry.borderRadiusSmall,
                      border: Border.all(color: colors.border.withOpacity(0.60)),
                    ),
                    alignment: Alignment.center,
                    child: VlcMonochromeIcon(
                      item.mediaType == MediaType.audio
                          ? VlcIconGlyph.audioTrack
                          : VlcIconGlyph.play,
                      size: 20.0,
                      color: isCurrent ? colors.accent.primary : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8.0),

                  // Title and Subtitle Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Episode Tag + Title
                        Row(
                          children: [
                            if (item.season != null && item.episode != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                decoration: BoxDecoration(
                                  color: colors.accent.primary.withOpacity(0.18),
                                  borderRadius: VlcGeometry.borderRadiusSmall,
                                  border: Border.all(color: colors.accent.primary.withOpacity(0.40)),
                                ),
                                child: Text(
                                  'S${item.season!.toString().padLeft(2, '0')}E${item.episode!.toString().padLeft(2, '0')}',
                                  style: vlcTheme.typography.monospaceTime.copyWith(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accent.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6.0),
                            ],
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: vlcTheme.typography.bodyMedium.copyWith(
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                  color: isCurrent ? colors.accent.primary : colors.textPrimary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4.0),

                        // Metadata: Duration • File Size • Watched Status
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 2.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              item.formattedDuration,
                              style: vlcTheme.typography.monospaceTime.copyWith(
                                fontSize: 10.5,
                                color: colors.textSecondary,
                              ),
                            ),
                            if (item.fileSizeBytes > 0)
                              Text(
                                item.formattedFileSize,
                                style: vlcTheme.typography.monospaceTime.copyWith(
                                  fontSize: 10.5,
                                  color: colors.textTertiary,
                                ),
                              ),
                            if (item.isWatched)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: VlcGeometry.borderRadiusSmall,
                                  border: Border.all(color: Colors.green.withOpacity(0.40)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, size: 10.0, color: Colors.green),
                                    const SizedBox(width: 3.0),
                                    Text(
                                      'Watched',
                                      style: vlcTheme.typography.bodySmall.copyWith(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (item.resumePositionMs > 2000)
                              Text(
                                '${(item.resumeProgress * 100).toInt()}% watched',
                                style: vlcTheme.typography.monospaceTime.copyWith(
                                  fontSize: 10.0,
                                  color: colors.accent.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hover Action Buttons: Play, Add to Queue, Toggle Watched
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play action
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 18.0),
                        tooltip: 'Play Now',
                        color: colors.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: () => widget.onPlayItem?.call(item),
                      ),

                      // Add to Queue action
                      IconButton(
                        icon: const Icon(Icons.add, size: 18.0),
                        tooltip: 'Add to Queue',
                        color: colors.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: () => widget.onAddToQueue?.call(item),
                      ),

                      // Mark Watched Toggle
                      IconButton(
                        icon: Icon(
                          item.isWatched ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16.0,
                        ),
                        tooltip: item.isWatched ? 'Mark as Unwatched' : 'Mark as Watched',
                        color: item.isWatched ? colors.accent.primary : colors.textTertiary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: () {
                          widget.mediaLibraryService.markAsWatched(item.mrl, watched: !item.isWatched);
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Resume Progress Bar (if in progress)
              if (!item.isWatched && item.resumeProgress > 0.02) ...[
                const SizedBox(height: 6.0),
                ClipRRect(
                  borderRadius: VlcGeometry.borderRadiusSmall,
                  child: LinearProgressIndicator(
                    value: item.resumeProgress,
                    minHeight: 3.0,
                    backgroundColor: colors.surfaceHover,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accent.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52.0,
              height: 52.0,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: VlcGeometry.borderRadiusLarge,
              ),
              alignment: Alignment.center,
              child: VlcMonochromeIcon(
                VlcIconGlyph.folder,
                size: 26.0,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              'No Media Found',
              style: vlcTheme.typography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results matching "$_searchQuery".'
                  : 'No files indexed in this folder. Click "+ Add Folder" to scan a media directory.',
              textAlign: TextAlign.center,
              style: vlcTheme.typography.bodySmall.copyWith(
                color: colors.textTertiary,
                fontSize: 12.0,
                height: 1.4,
              ),
            ),
            if (widget.onAddFolder != null && _searchQuery.isEmpty) ...[
              const SizedBox(height: 14.0),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent.primary,
                  foregroundColor: Colors.white,
                  shape: VlcGeometry.buttonShape,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                ),
                onPressed: widget.onAddFolder,
                icon: const Icon(Icons.folder_open, size: 16.0),
                label: Text(
                  'Add Media Folder',
                  style: vlcTheme.typography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<MediaItem> items,
  ) {
    final dur = _formatTotalDuration(items);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.20),
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: VlcGeometry.strokeWidthBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Item count & duration
          Expanded(
            child: Text(
              '${items.length} items${dur.isNotEmpty ? ' • $dur' : ''}',
              style: vlcTheme.typography.monospaceTime.copyWith(
                fontSize: 11.0,
                color: colors.textSecondary,
              ),
            ),
          ),

          // Play All
          if (widget.onPlayAll != null)
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => widget.onPlayAll?.call(items),
              icon: Icon(Icons.play_arrow, size: 14.0, color: colors.accent.primary),
              label: Text(
                'Play All',
                style: vlcTheme.typography.bodySmall.copyWith(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: colors.accent.primary,
                ),
              ),
            ),
          const SizedBox(width: 6.0),

          // Enqueue All
          if (widget.onEnqueueAll != null)
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => widget.onEnqueueAll?.call(items),
              icon: Icon(Icons.playlist_add, size: 14.0, color: colors.textSecondary),
              label: Text(
                'Enqueue All',
                style: vlcTheme.typography.bodySmall.copyWith(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
