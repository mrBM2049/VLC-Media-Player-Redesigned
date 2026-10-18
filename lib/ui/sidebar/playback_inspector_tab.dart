import 'package:flutter/material.dart';
import '../../models/playback_models.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_theme.dart';
import '../controls/thick_seek_bar.dart'; // for ChapterTick

/// Playback & Chapters Tab (Tab 4) for the 4-Tab InspectorSidebar.
/// Houses:
/// 1. Playback Speed Fine-Tuning (0.25x to 4.0x) + Quick Presets + Pitch Lock
/// 2. A-to-B Repeat Looper with current timestamp pins
/// 3. Frame Stepping (Next/Prev Frame) & Micro Navigation
/// 4. Chapter Navigator with active chapter highlights
/// 5. Visual Bookmarks List (Ctrl+B) with add/jump/delete
/// 6. Sleep Timer (15m, 30m, 45m, 60m, End of Media)
/// 7. Seek Bar Overlay Display Toggles
class PlaybackInspectorTab extends StatefulWidget {
  final PlaybackStateConfig config;
  final Duration currentPosition;
  final Duration totalDuration;
  final List<ChapterTick> chapters;
  final ValueChanged<PlaybackStateConfig> onConfigChanged;
  final ValueChanged<Duration>? onSeekTo;
  final VoidCallback? onNextFrame;
  final VoidCallback? onPreviousFrame;

  const PlaybackInspectorTab({
    super.key,
    required this.config,
    required this.currentPosition,
    required this.totalDuration,
    this.chapters = const [],
    required this.onConfigChanged,
    this.onSeekTo,
    this.onNextFrame,
    this.onPreviousFrame,
  });

  @override
  State<PlaybackInspectorTab> createState() => _PlaybackInspectorTabState();
}

class _PlaybackInspectorTabState extends State<PlaybackInspectorTab> {
  final TextEditingController _bookmarkTitleController = TextEditingController();

  @override
  void dispose() {
    _bookmarkTitleController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 100).toString();

    if (hours > 0) {
      return '$hours:$minutes:$seconds.$millis';
    }
    return '$minutes:$seconds.$millis';
  }

  String _formatShortDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _addBookmarkAtCurrentPosition() {
    final pos = widget.currentPosition;
    final id = 'bm_${DateTime.now().millisecondsSinceEpoch}';
    final title = 'Bookmark at ${_formatShortDuration(pos)}';

    final updated = List<VlcPlaybackBookmark>.from(widget.config.bookmarks)
      ..add(
        VlcPlaybackBookmark(
          id: id,
          title: title,
          position: pos,
          createdAt: DateTime.now(),
        ),
      );

    widget.onConfigChanged(widget.config.copyWith(bookmarks: updated));
  }

  void _deleteBookmark(String id) {
    final updated = widget.config.bookmarks.where((b) => b.id != id).toList();
    widget.onConfigChanged(widget.config.copyWith(bookmarks: updated));
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final config = widget.config;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      children: [
        // -------------------------------------------------------------
        // 1. Playback Speed Section
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'PLAYBACK SPEED',
                style: vlcTheme.typography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: colors.accent.subtleBackground,
                borderRadius: VlcGeometry.borderRadiusSmall,
                border: Border.all(color: colors.accent.subtleBorder),
              ),
              child: Text(
                '${config.playbackRate.toStringAsFixed(2)}x',
                style: vlcTheme.typography.monospaceTime.copyWith(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: colors.accent.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),

        // Speed Slider (0.25x to 4.0x)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.accent.primary,
            inactiveTrackColor: colors.surfaceHover,
            thumbColor: colors.accent.primary,
            overlayColor: colors.accent.subtleBackground,
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            value: config.playbackRate.clamp(0.25, 4.0),
            min: 0.25,
            max: 4.0,
            divisions: 75,
            onChanged: (val) {
              widget.onConfigChanged(
                config.copyWith(playbackRate: double.parse(val.toStringAsFixed(2))),
              );
            },
          ),
        ),

        // Quick Speed Preset Buttons
        Row(
          children: [
            for (final rate in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]) ...[
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.onConfigChanged(config.copyWith(playbackRate: rate));
                  },
                  borderRadius: VlcGeometry.borderRadiusSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    decoration: BoxDecoration(
                      color: (config.playbackRate - rate).abs() < 0.02
                          ? colors.accent.subtleBackground
                          : colors.surfaceHover,
                      borderRadius: VlcGeometry.borderRadiusSmall,
                      border: Border.all(
                        color: (config.playbackRate - rate).abs() < 0.02
                            ? colors.accent.primary
                            : colors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${rate}x',
                      style: vlcTheme.typography.monospaceTime.copyWith(
                        fontSize: 10.0,
                        fontWeight: (config.playbackRate - rate).abs() < 0.02
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: (config.playbackRate - rate).abs() < 0.02
                            ? colors.accent.primary
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
            ],
          ],
        ),

        const SizedBox(height: 8.0),

        // Preserve Pitch Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Preserve Audio Pitch (Anti-Chipmunk)',
                style: vlcTheme.typography.bodySmall.copyWith(
                  color: colors.textPrimary,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch(
              value: config.preservePitch,
              activeColor: colors.accent.primary,
              onChanged: (val) {
                widget.onConfigChanged(config.copyWith(preservePitch: val));
              },
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 2. A-to-B Repeat Looper
        // -------------------------------------------------------------
        Text(
          'A-TO-B REPEAT LOOPER',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: config.aToBLoop.isActive ? colors.accent.primary : colors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Point A
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Point A',
                          style: vlcTheme.typography.labelSmall.copyWith(
                            color: colors.textSecondary,
                            fontSize: 10.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          config.aToBLoop.pointA != null
                              ? _formatShortDuration(config.aToBLoop.pointA!)
                              : '--:--',
                          style: vlcTheme.typography.monospaceTime.copyWith(
                            fontWeight: FontWeight.w700,
                            color: config.aToBLoop.pointA != null
                                ? colors.accent.primary
                                : colors.textTertiary,
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Icon(Icons.arrow_forward, size: 14.0, color: colors.textTertiary),

                  // Point B
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Point B',
                          style: vlcTheme.typography.labelSmall.copyWith(
                            color: colors.textSecondary,
                            fontSize: 10.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          config.aToBLoop.pointB != null
                              ? _formatShortDuration(config.aToBLoop.pointB!)
                              : '--:--',
                          style: vlcTheme.typography.monospaceTime.copyWith(
                            fontWeight: FontWeight.w700,
                            color: config.aToBLoop.pointB != null
                                ? colors.accent.primary
                                : colors.textTertiary,
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // Action Buttons: Set A, Set B, Clear
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: VlcGeometry.buttonShape,
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        side: BorderSide(color: colors.border),
                      ),
                      onPressed: () {
                        widget.onConfigChanged(
                          config.copyWith(
                            aToBLoop: config.aToBLoop.withPointA(widget.currentPosition),
                          ),
                        );
                      },
                      child: Text(
                        'Set A',
                        style: vlcTheme.typography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: VlcGeometry.buttonShape,
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        side: BorderSide(color: colors.border),
                      ),
                      onPressed: () {
                        widget.onConfigChanged(
                          config.copyWith(
                            aToBLoop: config.aToBLoop.withPointB(widget.currentPosition),
                          ),
                        );
                      },
                      child: Text(
                        'Set B',
                        style: vlcTheme.typography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  InkWell(
                    onTap: () {
                      widget.onConfigChanged(
                        config.copyWith(aToBLoop: config.aToBLoop.cleared()),
                      );
                    },
                    borderRadius: VlcGeometry.borderRadiusSmall,
                    child: Container(
                      padding: const EdgeInsets.all(7.0),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: VlcGeometry.borderRadiusSmall,
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(Icons.close, size: 14.0, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 3. Frame Stepping & Micro Navigation
        // -------------------------------------------------------------
        Text(
          'FRAME STEPPING & MICRO NAVIGATION',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        Row(
          children: [
            // -10s
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: VlcGeometry.buttonShape,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  side: BorderSide(color: colors.border),
                ),
                onPressed: () {
                  final target = widget.currentPosition - const Duration(seconds: 10);
                  widget.onSeekTo?.call(target < Duration.zero ? Duration.zero : target);
                },
                child: Text(
                  '-10s',
                  style: vlcTheme.typography.monospaceTime.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4.0),

            // Previous Frame
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: VlcGeometry.buttonShape,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  side: BorderSide(color: colors.border),
                ),
                onPressed: widget.onPreviousFrame,
                child: Text(
                  '◀ Frame',
                  style: vlcTheme.typography.labelSmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4.0),

            // Next Frame (libvlc_media_player_next_frame)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: VlcGeometry.buttonShape,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  side: BorderSide(color: colors.border),
                ),
                onPressed: widget.onNextFrame,
                child: Text(
                  'Frame ▶',
                  style: vlcTheme.typography.labelSmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4.0),

            // +10s
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: VlcGeometry.buttonShape,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  side: BorderSide(color: colors.border),
                ),
                onPressed: () {
                  final target = widget.currentPosition + const Duration(seconds: 10);
                  widget.onSeekTo?.call(
                    target > widget.totalDuration ? widget.totalDuration : target,
                  );
                },
                child: Text(
                  '+10s',
                  style: vlcTheme.typography.monospaceTime.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 4. Chapters Section
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'CHAPTERS (${widget.chapters.length})',
                style: vlcTheme.typography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.chapters.isNotEmpty)
              Text(
                'Tap to seek',
                style: vlcTheme.typography.labelSmall.copyWith(
                  color: colors.textTertiary,
                  fontSize: 10.0,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6.0),
        if (widget.chapters.isEmpty)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colors.surfaceHover,
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'No chapters detected in current media',
              style: vlcTheme.typography.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceHover,
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < widget.chapters.length; i++) ...[
                  if (i > 0) const Divider(height: 1.0),
                  Builder(
                    builder: (context) {
                      final ch = widget.chapters[i];
                      final isCurrent = widget.currentPosition >= ch.time &&
                          (i == widget.chapters.length - 1 ||
                              widget.currentPosition < widget.chapters[i + 1].time);

                      return InkWell(
                        onTap: () => widget.onSeekTo?.call(ch.time),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                          child: Row(
                            children: [
                              Container(
                                width: 18.0,
                                height: 18.0,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? colors.accent.primary
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(3.0),
                                  border: Border.all(
                                    color: isCurrent
                                        ? colors.accent.primary
                                        : colors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: vlcTheme.typography.monospaceTime.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent
                                        ? Colors.white
                                        : colors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  ch.title,
                                  style: vlcTheme.typography.bodySmall.copyWith(
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCurrent ? colors.accent.primary : colors.textPrimary,
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                _formatShortDuration(ch.time),
                                style: vlcTheme.typography.monospaceTime.copyWith(
                                  fontSize: 11.0,
                                  color: isCurrent ? colors.accent.primary : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 5. Visual Bookmarks List (Ctrl+B)
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'BOOKMARKS (${config.bookmarks.length})',
                style: vlcTheme.typography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: _addBookmarkAtCurrentPosition,
              borderRadius: VlcGeometry.borderRadiusSmall,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: colors.accent.subtleBackground,
                  borderRadius: VlcGeometry.borderRadiusSmall,
                  border: Border.all(color: colors.accent.subtleBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_add, size: 12.0, color: colors.accent.primary),
                    const SizedBox(width: 4.0),
                    Text(
                      'Add [Ctrl+B]',
                      style: vlcTheme.typography.labelSmall.copyWith(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        color: colors.accent.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        if (config.bookmarks.isEmpty)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colors.surfaceHover,
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'No visual bookmarks saved yet',
              style: vlcTheme.typography.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceHover,
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < config.bookmarks.length; i++) ...[
                  if (i > 0) const Divider(height: 1.0),
                  Builder(
                    builder: (context) {
                      final bm = config.bookmarks[i];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Icon(Icons.bookmark, size: 14.0, color: colors.accent.primary),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: InkWell(
                                onTap: () => widget.onSeekTo?.call(bm.position),
                                child: Text(
                                  bm.title,
                                  style: vlcTheme.typography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              _formatShortDuration(bm.position),
                              style: vlcTheme.typography.monospaceTime.copyWith(
                                fontSize: 11.0,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            InkWell(
                              onTap: () => _deleteBookmark(bm.id),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.close, size: 13.0, color: colors.textTertiary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 6. Sleep Timer
        // -------------------------------------------------------------
        Text(
          'SLEEP TIMER',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<VlcSleepTimerPreset>(
              value: config.sleepTimer,
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              onChanged: (newTimer) {
                if (newTimer != null) {
                  widget.onConfigChanged(config.copyWith(sleepTimer: newTimer));
                }
              },
              items: [
                for (final t in VlcSleepTimerPreset.values)
                  DropdownMenuItem<VlcSleepTimerPreset>(
                    value: t,
                    child: Text(
                      t.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // -------------------------------------------------------------
        // 7. Seek Bar Display Overlays
        // -------------------------------------------------------------
        Text(
          'SEEK BAR OVERLAYS',
          style: vlcTheme.typography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: colors.surfaceHover,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              // Waveform
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Audio Waveform Overlay',
                      style: vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Switch(
                    value: config.showWaveformOverlay,
                    activeColor: colors.accent.primary,
                    onChanged: (val) {
                      widget.onConfigChanged(config.copyWith(showWaveformOverlay: val));
                    },
                  ),
                ],
              ),
              const Divider(height: 12.0),

              // Thumbnail Frame Previews
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Thumbnail Hover Previews',
                      style: vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Switch(
                    value: config.showThumbnailPreviewOverlay,
                    activeColor: colors.accent.primary,
                    onChanged: (val) {
                      widget.onConfigChanged(
                        config.copyWith(showThumbnailPreviewOverlay: val),
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 12.0),

              // Chapter Ticks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chapter Marker Ticks',
                      style: vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Switch(
                    value: config.showChapterTicksOverlay,
                    activeColor: colors.accent.primary,
                    onChanged: (val) {
                      widget.onConfigChanged(
                        config.copyWith(showChapterTicksOverlay: val),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
