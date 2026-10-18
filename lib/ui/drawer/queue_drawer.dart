import 'package:flutter/material.dart';
import '../../models/queue_models.dart';
import '../../models/media_library_models.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';
import '../shell/top_player_bar.dart'; // for VlcTopBarButton

/// Temporary drag-and-drop playback queue drawer for VLC Modern Redesign.
/// Width: 340.0dp (VlcGeometry.inspectorDrawerWidth).
/// Distinct from persistent saved Playlists in the medialibrary.
class QueueDrawer extends StatelessWidget {
  final QueueController controller;
  final VoidCallback? onClose;
  final ValueChanged<QueueItem>? onPlayItem;
  final VoidCallback? onSaveAsPlaylist;
  final VoidCallback? onAddMedia;

  const QueueDrawer({
    super.key,
    required this.controller,
    this.onClose,
    this.onPlayItem,
    this.onSaveAsPlaylist,
    this.onAddMedia,
  });

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatRemainingSummary(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    }
    return '${minutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final items = controller.items;

        return Container(
          width: VlcGeometry.inspectorDrawerWidth,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              left: BorderSide(
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
                // 1. Header: Title, Item Count Badge, Clear & Close
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VlcMonochromeIcon(
                              VlcIconGlyph.queue,
                              size: 18.0,
                              color: colors.accent.primary,
                            ),
                            const SizedBox(width: 6.0),
                            Flexible(
                              child: Text(
                                'Play Queue',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: vlcTheme.typography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius: VlcGeometry.borderRadiusSmall,
                                border: Border.all(color: colors.border.withOpacity(0.40)),
                              ),
                              child: Text(
                                '${controller.count}',
                                style: vlcTheme.typography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(width: 4.0),
                        Tooltip(
                          message: 'Clear Play Queue',
                          child: InkWell(
                            onTap: controller.clear,
                            borderRadius: VlcGeometry.borderRadiusSmall,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'Clear',
                                style: vlcTheme.typography.labelSmall.copyWith(
                                  color: colors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (onClose != null) ...[
                        const SizedBox(width: 4.0),
                        VlcTopBarButton(
                          width: 28.0,
                          height: 28.0,
                          tooltip: 'Close Queue [Q]',
                          onPressed: onClose,
                          child: Icon(
                            Icons.close,
                            size: 16.0,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // -------------------------------------------------------------
                // 2. Sub-Header: Duration Summary & Mode Toggles
                // -------------------------------------------------------------
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withOpacity(0.35),
                      border: Border(
                        bottom: BorderSide(
                          color: colors.border.withOpacity(0.30),
                          width: VlcGeometry.strokeWidthBorder,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatRemainingSummary(controller.totalRemainingDuration),
                            style: vlcTheme.typography.labelSmall.copyWith(
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Shuffle Toggle
                        Tooltip(
                          message: controller.isShuffle ? 'Shuffle: On' : 'Shuffle: Off',
                          child: InkWell(
                            onTap: controller.toggleShuffle,
                            borderRadius: VlcGeometry.borderRadiusSmall,
                            child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: controller.isShuffle
                                    ? colors.accent.subtleBackground
                                    : Colors.transparent,
                                borderRadius: VlcGeometry.borderRadiusSmall,
                              ),
                              child: VlcMonochromeIcon(
                                VlcIconGlyph.shuffle,
                                size: 14.0,
                                color: controller.isShuffle
                                    ? colors.accent.primary
                                    : colors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        // Repeat Toggle
                        Tooltip(
                          message: switch (controller.repeatMode) {
                            QueueRepeatMode.off => 'Repeat: Off',
                            QueueRepeatMode.all => 'Repeat: All',
                            QueueRepeatMode.one => 'Repeat: One',
                          },
                          child: InkWell(
                            onTap: controller.cycleRepeatMode,
                            borderRadius: VlcGeometry.borderRadiusSmall,
                            child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: controller.repeatMode != QueueRepeatMode.off
                                    ? colors.accent.subtleBackground
                                    : Colors.transparent,
                                borderRadius: VlcGeometry.borderRadiusSmall,
                              ),
                              child: VlcMonochromeIcon(
                                controller.repeatMode == QueueRepeatMode.one
                                    ? VlcIconGlyph.repeatOne
                                    : VlcIconGlyph.repeat,
                                size: 14.0,
                                color: controller.repeatMode != QueueRepeatMode.off
                                    ? colors.accent.primary
                                    : colors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // -------------------------------------------------------------
                // 3. Queue List or Empty State with DragTarget for MediaItem
                // -------------------------------------------------------------
                Expanded(
                  child: DragTarget<MediaItem>(
                    onWillAcceptWithDetails: (details) => true,
                    onAcceptWithDetails: (details) {
                      final media = details.data;
                      controller.addItem(
                        QueueItem(
                          id: 'q_${DateTime.now().millisecondsSinceEpoch}_${media.id}',
                          mrl: media.mrl,
                          title: media.displayName,
                          artist: media.formattedDuration,
                          duration: Duration(milliseconds: media.durationMs),
                        ),
                      );
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovered = candidateData.isNotEmpty;
                      return Container(
                        decoration: BoxDecoration(
                          color: isHovered
                              ? colors.accent.subtleBackground
                              : Colors.transparent,
                          border: isHovered
                              ? Border.all(color: colors.accent.primary, width: 2.0)
                              : null,
                        ),
                        child: items.isEmpty
                            ? _buildEmptyState(context, colors, vlcTheme)
                            : _buildQueueList(context, colors, vlcTheme, items),
                      );
                    },
                  ),
                ),

                // -------------------------------------------------------------
                // 4. Footer: Action Buttons (Save as Playlist, Add Media)
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.border,
                        width: VlcGeometry.strokeWidthBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (onSaveAsPlaylist != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                              side: BorderSide(color: colors.border),
                              shape: VlcGeometry.buttonShape,
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                            ),
                            onPressed: items.isEmpty ? null : onSaveAsPlaylist,
                            icon: VlcMonochromeIcon(
                              VlcIconGlyph.playlist,
                              size: 14.0,
                              color: items.isEmpty ? colors.textTertiary : colors.textSecondary,
                            ),
                            label: Text(
                              'Save Playlist',
                              style: vlcTheme.typography.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (onSaveAsPlaylist != null && onAddMedia != null)
                        const SizedBox(width: 8.0),
                      if (onAddMedia != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.surfaceVariant,
                              foregroundColor: colors.textPrimary,
                              elevation: 0,
                              shape: VlcGeometry.buttonShape,
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                            ),
                            onPressed: onAddMedia,
                            icon: const Icon(Icons.add, size: 15.0),
                            label: Text(
                              'Add Media',
                              style: vlcTheme.typography.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, VlcColors colors, VlcThemeData vlcTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.50),
                borderRadius: VlcGeometry.borderRadiusLarge,
                border: Border.all(color: colors.border.withOpacity(0.50)),
              ),
              alignment: Alignment.center,
              child: VlcMonochromeIcon(
                VlcIconGlyph.queue,
                size: 28.0,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Queue is Empty',
              style: vlcTheme.typography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Add files from the media library or drag and drop videos here for temporary playback.',
              textAlign: TextAlign.center,
              style: vlcTheme.typography.bodySmall.copyWith(
                color: colors.textTertiary,
                fontSize: 12.0,
                height: 1.4,
              ),
            ),
            if (onAddMedia != null) ...[
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent.primary,
                  foregroundColor: Colors.white,
                  shape: VlcGeometry.buttonShape,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                ),
                onPressed: onAddMedia,
                icon: const Icon(Icons.add, size: 16.0),
                label: Text(
                  'Add Media to Queue',
                  style: vlcTheme.typography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    List<QueueItem> items,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorder: controller.reorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) => Material(
            elevation: 6.0,
            color: colors.surfaceVariant,
            borderRadius: VlcGeometry.borderRadiusMedium,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: VlcGeometry.borderRadiusMedium,
                border: Border.all(
                  color: colors.accent.primary,
                  width: 1.5,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final isPlaying = item.isPlaying;

        return Material(
          key: ValueKey(item.id),
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: isPlaying
                  ? colors.accent.subtleBackground
                  : colors.surfaceVariant.withOpacity(0.30),
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(
                color: isPlaying
                    ? colors.accent.subtleBorder
                    : colors.border.withOpacity(0.40),
                width: VlcGeometry.strokeWidthBorder,
              ),
            ),
            child: InkWell(
              borderRadius: VlcGeometry.borderRadiusMedium,
              onTap: () {
                controller.playIndex(index);
                onPlayItem?.call(item);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Drag Handle
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 16.0,
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0),

                    // Playing indicator or index
                    SizedBox(
                      width: 22.0,
                      child: isPlaying
                          ? VlcMonochromeIcon(
                              VlcIconGlyph.play,
                              size: 14.0,
                              color: colors.accent.primary,
                            )
                          : Text(
                              '${index + 1}'.padLeft(2, '0'),
                              style: vlcTheme.typography.monospaceTime.copyWith(
                                fontSize: 11.0,
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    const SizedBox(width: 6.0),

                    // Thumbnail / Media type icon
                    Container(
                      width: 38.0,
                      height: 26.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: VlcGeometry.borderRadiusSmall,
                        border: Border.all(
                          color: isPlaying
                              ? colors.accent.primary.withOpacity(0.50)
                              : colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: VlcMonochromeIcon(
                        isPlaying ? VlcIconGlyph.play : VlcIconGlyph.folder,
                        size: 14.0,
                        color: isPlaying ? colors.accent.primary : colors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 10.0),

                    // Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: vlcTheme.typography.bodySmall.copyWith(
                              fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                              color: isPlaying ? colors.accent.primary : colors.textPrimary,
                              fontSize: 12.0,
                            ),
                          ),
                          if (item.artist != null) ...[
                            const SizedBox(height: 1.0),
                            Text(
                              item.artist!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: vlcTheme.typography.labelSmall.copyWith(
                                color: colors.textTertiary,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 6.0),

                    // Duration
                    Text(
                      _formatDuration(item.duration),
                      style: vlcTheme.typography.monospaceTime.copyWith(
                        fontSize: 11.0,
                        color: isPlaying ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: 4.0),

                    // Delete item from queue button
                    Tooltip(
                      message: 'Remove from Queue',
                      child: InkWell(
                        borderRadius: VlcGeometry.borderRadiusSmall,
                        onTap: () => controller.removeAt(index),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 14.0,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
