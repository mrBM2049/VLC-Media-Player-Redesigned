import 'package:flutter/material.dart';

import '../../models/media_library_models.dart';
import '../../services/media_library_service.dart';
import '../../theme/vlc_theme.dart';

/// Modern Home View for VLC Modern Redesign.
///
/// Replaces the classic empty cone screen with a rich, interactive media hub:
/// - Hero Header / Quick Stats
/// - "Continue Watching" horizontal carousel with resume progress bars & remaining timestamps
/// - "Recently Played & Added" grid with quick hover playback triggers
/// - "Smart Playlists & Collections" card row
/// - "Indexed Folder Shortcuts"
/// - Prominent Open Media & Stream triggers
class HomeView extends StatelessWidget {
  final MediaLibraryService mediaLibraryService;
  final ValueChanged<MediaItem>? onPlayItem;
  final ValueChanged<MediaItem>? onAddToQueue;
  final VoidCallback? onOpenMedia;
  final VoidCallback? onOpenStream;
  final VoidCallback? onAddFolder;
  final ValueChanged<String>? onNavigateToSection;

  const HomeView({
    super.key,
    required this.mediaLibraryService,
    this.onPlayItem,
    this.onAddToQueue,
    this.onOpenMedia,
    this.onOpenStream,
    this.onAddFolder,
    this.onNavigateToSection,
  });

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return AnimatedBuilder(
      animation: mediaLibraryService,
      builder: (context, _) {
        final continueWatching = mediaLibraryService.getContinueWatching(limit: 12);
        final recentFiles = mediaLibraryService.getRecentFiles(limit: 8);
        final playlists = mediaLibraryService.getPlaylists();
        final folders = mediaLibraryService.getFolders();
        final totalMediaCount = mediaLibraryService.getMediaItems().length;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          children: [
            // -----------------------------------------------------------------
            // 1. Welcome / Quick Actions Banner
            // -----------------------------------------------------------------
            _buildHeroBanner(context, colors, vlcTheme, totalMediaCount),

            const SizedBox(height: 28.0),

            // -----------------------------------------------------------------
            // 2. Continue Watching Carousel (if any in-progress items exist)
            // -----------------------------------------------------------------
            if (continueWatching.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                title: 'Continue Watching',
                subtitle: 'Pick up right where you left off',
                actionLabel: '${continueWatching.length} in progress',
                colors: colors,
                vlcTheme: vlcTheme,
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                height: 180.0,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: continueWatching.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14.0),
                  itemBuilder: (context, index) {
                    return _buildContinueWatchingCard(
                      context,
                      continueWatching[index],
                      colors,
                      vlcTheme,
                    );
                  },
                ),
              ),
              const SizedBox(height: 28.0),
            ],

            // -----------------------------------------------------------------
            // 3. Recently Added & Played Media
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              title: 'Recent Media',
              subtitle: 'Recently indexed and played video & audio',
              actionLabel: 'Browse All',
              onActionTap: () => onNavigateToSection?.call('videos'),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
            const SizedBox(height: 12.0),
            if (recentFiles.isEmpty)
              _buildEmptyPlaceholder(
                context,
                message: 'No recent media found. Index a folder or open a video to get started.',
                colors: colors,
                vlcTheme: vlcTheme,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260.0,
                  mainAxisSpacing: 14.0,
                  crossAxisSpacing: 14.0,
                  childAspectRatio: 1.15,
                ),
                itemCount: recentFiles.length,
                itemBuilder: (context, index) {
                  return _buildRecentMediaCard(
                    context,
                    recentFiles[index],
                    colors,
                    vlcTheme,
                  );
                },
              ),

            const SizedBox(height: 28.0),

            // -----------------------------------------------------------------
            // 4. Playlists & Smart Collections
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              title: 'Smart Collections & Playlists',
              subtitle: 'Automated medialibrary groupings',
              colors: colors,
              vlcTheme: vlcTheme,
            ),
            const SizedBox(height: 12.0),
            Row(
              children: playlists.map((p) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: _buildPlaylistCard(context, p, colors, vlcTheme),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28.0),

            // -----------------------------------------------------------------
            // 5. Indexed Folders Row
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              title: 'Indexed Folders',
              subtitle: 'Monitored directory trees auto-scanned for updates',
              actionLabel: '+ Add Folder',
              onActionTap: onAddFolder,
              colors: colors,
              vlcTheme: vlcTheme,
            ),
            const SizedBox(height: 12.0),
            if (folders.isEmpty)
              _buildEmptyPlaceholder(
                context,
                message: 'No folders indexed yet. Add your Movies or Series directory.',
                colors: colors,
                vlcTheme: vlcTheme,
              )
            else
              Wrap(
                spacing: 12.0,
                runSpacing: 10.0,
                children: folders.map((f) => _buildFolderChip(context, f, colors, vlcTheme)).toList(),
              ),

            const SizedBox(height: 40.0),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Component Builders
  // ---------------------------------------------------------------------------

  Widget _buildHeroBanner(
    BuildContext context,
    VlcColors colors,
    VlcThemeData vlcTheme,
    int totalMediaCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Cone Emblem Plate
          Container(
            width: 56.0,
            height: 56.0,
            decoration: BoxDecoration(
              color: colors.accent.subtleBackground,
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.accent.subtleBorder),
            ),
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(32.0, 32.0),
              painter: _HomeConePainter(coneColor: colors.accent.primary),
            ),
          ),
          const SizedBox(width: 18.0),

          // Title & Library Counts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VLC Media Center',
                  style: vlcTheme.typography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  totalMediaCount > 0
                      ? '$totalMediaCount indexed items ready for high-fidelity playback'
                      : 'High-performance cross-platform media player powered by libVLC',
                  style: vlcTheme.typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Quick Action CTA Buttons
          Wrap(
            spacing: 10.0,
            children: [
              if (onOpenMedia != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: VlcGeometry.buttonShape,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  ),
                  onPressed: onOpenMedia,
                  icon: const Icon(Icons.folder_open, size: 16.0),
                  label: const Text('Open File'),
                ),
              if (onOpenStream != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    shape: VlcGeometry.buttonShape,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  ),
                  onPressed: onOpenStream,
                  icon: VlcMonochromeIcon(VlcIconGlyph.stream, size: 14.0, color: colors.textSecondary),
                  label: const Text('Open Stream'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
  }) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: vlcTheme.typography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: vlcTheme.typography.labelSmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        if (actionLabel != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: VlcGeometry.borderRadiusSmall,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                actionLabel,
                style: vlcTheme.typography.bodySmall.copyWith(
                  color: onActionTap != null ? colors.accent.primary : colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueWatchingCard(
    BuildContext context,
    MediaItem item,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Container(
      width: 240.0,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        onTap: () => onPlayItem?.call(item),
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Canvas with Resume Overlay
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5.0)),
                    ),
                    alignment: Alignment.center,
                    child: VlcMonochromeIcon(
                      VlcIconGlyph.play,
                      size: 28.0,
                      color: colors.accent.primary,
                    ),
                  ),

                  // Remaining time badge (bottom-right)
                  Positioned(
                    bottom: 8.0,
                    right: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: VlcGeometry.borderRadiusSmall,
                      ),
                      child: Text(
                        '${item.formattedResumeTime} / ${item.formattedDuration}',
                        style: vlcTheme.typography.monospaceTime.copyWith(
                          fontSize: 9.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Progress bar along bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: item.resumeProgress.clamp(0.0, 1.0),
                      child: Container(height: 3.5, color: colors.accent.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Card metadata
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vlcTheme.typography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    item.folderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vlcTheme.typography.labelSmall.copyWith(
                      color: colors.textTertiary,
                      fontSize: 10.0,
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

  Widget _buildRecentMediaCard(
    BuildContext context,
    MediaItem item,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        onTap: () => onPlayItem?.call(item),
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Preview canvas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5.0)),
                ),
                alignment: Alignment.center,
                child: VlcMonochromeIcon(
                  item.mediaType == MediaType.audio ? VlcIconGlyph.music : VlcIconGlyph.video,
                  size: 26.0,
                  color: colors.textSecondary,
                ),
              ),
            ),

            // Info row
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                          style: vlcTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '${item.formattedDuration} • ${item.folderName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: vlcTheme.typography.labelSmall.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isWatched)
                    const Icon(Icons.check_circle, size: 14.0, color: Colors.greenAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(
    BuildContext context,
    MediaPlaylistGroup group,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VlcMonochromeIcon(
                switch (group.iconGlyph) {
                  'play' => VlcIconGlyph.play,
                  'video' => VlcIconGlyph.video,
                  'music' => VlcIconGlyph.music,
                  _ => VlcIconGlyph.playlist,
                },
                size: 18.0,
                color: colors.accent.primary,
              ),
              const Spacer(),
              Text(
                '${group.itemCount} items',
                style: vlcTheme.typography.monospaceTime.copyWith(
                  fontSize: 10.0,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            group.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: vlcTheme.typography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderChip(
    BuildContext context,
    MediaFolder folder,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VlcMonochromeIcon(VlcIconGlyph.folder, size: 15.0, color: colors.accent.primary),
          const SizedBox(width: 8.0),
          Text(
            folder.name,
            style: vlcTheme.typography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          if (folder.itemCount > 0) ...[
            const SizedBox(width: 6.0),
            Text(
              '(${folder.itemCount})',
              style: vlcTheme.typography.monospaceTime.copyWith(
                fontSize: 10.0,
                color: colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(
    BuildContext context, {
    required String message,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Cone Painter for Home Hero
// -----------------------------------------------------------------------------

class _HomeConePainter extends CustomPainter {
  final Color coneColor;
  _HomeConePainter({required this.coneColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintOrange = Paint()..color = coneColor..style = PaintingStyle.fill;
    final paintWhite = Paint()..color = Colors.white.withValues(alpha: 0.92)..style = PaintingStyle.fill;
    final paintBase = Paint()..color = coneColor.withValues(alpha: 0.80)..style = PaintingStyle.fill;

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
  bool shouldRepaint(covariant _HomeConePainter oldDelegate) => oldDelegate.coneColor != coneColor;
}
