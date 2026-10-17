import 'package:flutter/material.dart';
import '../../src/ffi/vlc_bindings.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';
import '../shell/top_player_bar.dart'; // for VlcTopBarButton
import 'volume_control.dart';

enum VlcRepeatMode {
  off,
  all,
  one,
}

/// Primary Bottom Transport Row for VLC Modern Redesign.
/// Height: 60.0dp (VlcGeometry.bottomTransportRowHeight).
/// Layout:
/// - Left: Previous, Play/Pause, Next, Stop + Monospace Timecode (Elapsed / Total or Remaining)
/// - Mid-Left: FullConeVolumeControl (0% to 200% with Overdrive stripes)
/// - Right: Subtitles, Audio Track, Speed selector, Equalizer, Repeat, and Shuffle
class BottomTransportRow extends StatefulWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final int volume;
  final bool isMuted;
  final double playbackRate;
  final VlcRepeatMode repeatMode;
  final bool isShuffle;
  final bool hasSubtitles;
  final bool hasAudioTracks;

  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onStop;
  final ValueChanged<int>? onVolumeChanged;
  final VoidCallback? onToggleMute;
  final ValueChanged<double>? onRateChanged;
  final VoidCallback? onSubtitlesTap;
  final VoidCallback? onAudioTrackTap;
  final VoidCallback? onEqualizerTap;
  final VoidCallback? onRepeatToggle;
  final VoidCallback? onShuffleToggle;

  const BottomTransportRow({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.volume,
    this.isMuted = false,
    this.playbackRate = 1.0,
    this.repeatMode = VlcRepeatMode.off,
    this.isShuffle = false,
    this.hasSubtitles = true,
    this.hasAudioTracks = true,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onStop,
    this.onVolumeChanged,
    this.onToggleMute,
    this.onRateChanged,
    this.onSubtitlesTap,
    this.onAudioTrackTap,
    this.onEqualizerTap,
    this.onRepeatToggle,
    this.onShuffleToggle,
  });

  @override
  State<BottomTransportRow> createState() => _BottomTransportRowState();
}

class _BottomTransportRowState extends State<BottomTransportRow> {
  bool _showRemainingTime = false;

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

  void _cyclePlaybackRate() {
    if (widget.onRateChanged == null) return;
    const rates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = rates.indexWhere((r) => (r - widget.playbackRate).abs() < 0.05);
    final nextIndex = (currentIndex + 1) % rates.length;
    widget.onRateChanged!(rates[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    final elapsedStr = _formatDuration(widget.position);
    final totalOrRemainingStr = _showRemainingTime
        ? '-${_formatDuration(widget.duration - widget.position)}'
        : _formatDuration(widget.duration);

    return Container(
      height: VlcGeometry.bottomTransportRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: VlcGeometry.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -------------------------------------------------------------------
          // 1. Primary Left Transport Controls
          // -------------------------------------------------------------------
          // Previous Chapter / Track
          VlcTopBarButton(
            width: 36.0,
            height: 36.0,
            tooltip: 'Previous [P]',
            onPressed: widget.onPrevious,
            child: VlcMonochromeIcon(
              VlcIconGlyph.previous,
              size: 20.0,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(width: 4.0),

          // Play / Pause prominent button (Signature Accent Highlight)
          VlcTopBarButton(
            width: 42.0,
            height: 42.0,
            tooltip: widget.isPlaying ? 'Pause [Space]' : 'Play [Space]',
            isActive: widget.isPlaying,
            onPressed: widget.onPlayPause,
            child: Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: colors.accent.primary,
                borderRadius: VlcGeometry.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.glow,
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: VlcMonochromeIcon(
                widget.isPlaying ? VlcIconGlyph.pause : VlcIconGlyph.play,
                size: 20.0,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 4.0),

          // Next Chapter / Track
          VlcTopBarButton(
            width: 36.0,
            height: 36.0,
            tooltip: 'Next [N]',
            onPressed: widget.onNext,
            child: VlcMonochromeIcon(
              VlcIconGlyph.next,
              size: 20.0,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(width: 4.0),

          // Stop Button
          VlcTopBarButton(
            width: 34.0,
            height: 34.0,
            tooltip: 'Stop [S]',
            onPressed: widget.onStop,
            child: VlcMonochromeIcon(
              VlcIconGlyph.stop,
              size: 16.0,
              color: colors.textSecondary,
            ),
          ),

          const SizedBox(width: 12.0),

          // Timecode Display (Click to toggle remaining / total)
          Tooltip(
            message: _showRemainingTime ? 'Showing Remaining Time (Click for Total)' : 'Showing Total Duration (Click for Remaining)',
            child: GestureDetector(
              onTap: () => setState(() => _showRemainingTime = !_showRemainingTime),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withOpacity(0.50),
                  borderRadius: VlcGeometry.borderRadiusSmall,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      elapsedStr,
                      style: vlcTheme.typography.monospaceTime.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' / ',
                      style: vlcTheme.typography.monospaceTime.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    Text(
                      totalOrRemainingStr,
                      style: vlcTheme.typography.monospaceTime.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16.0),

          // -------------------------------------------------------------------
          // 2. FullConeVolumeControl (0% to 200%)
          // -------------------------------------------------------------------
          if (widget.onVolumeChanged != null && widget.onToggleMute != null)
            FullConeVolumeControl(
              volume: widget.volume,
              isMuted: widget.isMuted,
              onVolumeChanged: widget.onVolumeChanged!,
              onToggleMute: widget.onToggleMute!,
            ),

          const Spacer(),

          // -------------------------------------------------------------------
          // 3. Right Utility Cluster
          // -------------------------------------------------------------------
          // Subtitles selector
          if (widget.onSubtitlesTap != null)
            VlcTopBarButton(
              width: 34.0,
              height: 34.0,
              tooltip: 'Subtitles [V]',
              isActive: widget.hasSubtitles,
              onPressed: widget.onSubtitlesTap,
              child: VlcMonochromeIcon(
                VlcIconGlyph.subtitles,
                size: 18.0,
                color: widget.hasSubtitles ? colors.accent.primary : colors.textSecondary,
              ),
            ),

          const SizedBox(width: 4.0),

          // Audio track selector
          if (widget.onAudioTrackTap != null)
            VlcTopBarButton(
              width: 34.0,
              height: 34.0,
              tooltip: 'Audio Track [B]',
              isActive: widget.hasAudioTracks,
              onPressed: widget.onAudioTrackTap,
              child: VlcMonochromeIcon(
                VlcIconGlyph.audioTrack,
                size: 18.0,
                color: widget.hasAudioTracks ? colors.accent.primary : colors.textSecondary,
              ),
            ),

          const SizedBox(width: 4.0),

          // Playback Speed Selector (e.g., 1.0x)
          if (widget.onRateChanged != null)
            Tooltip(
              message: 'Playback Speed (${widget.playbackRate.toStringAsFixed(2)}x)',
              child: GestureDetector(
                onTap: _cyclePlaybackRate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 28.0,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: (widget.playbackRate != 1.0) ? colors.accent.subtleBackground : colors.surfaceVariant,
                    borderRadius: VlcGeometry.borderRadiusSmall,
                    border: Border.all(
                      color: (widget.playbackRate != 1.0) ? colors.accent.subtleBorder : colors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.playbackRate.toStringAsFixed(widget.playbackRate == 1.0 ? 1 : 2)}x',
                    style: vlcTheme.typography.monospaceTime.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: (widget.playbackRate != 1.0) ? colors.accent.primary : colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 6.0),

          // 10-Band Equalizer drawer trigger
          if (widget.onEqualizerTap != null)
            VlcTopBarButton(
              width: 34.0,
              height: 34.0,
              tooltip: 'Audio Equalizer & Presets',
              onPressed: widget.onEqualizerTap,
              child: VlcMonochromeIcon(
                VlcIconGlyph.equalizer,
                size: 18.0,
                color: colors.textSecondary,
              ),
            ),

          const SizedBox(width: 4.0),

          // Repeat Mode Toggle (Off -> All -> One)
          if (widget.onRepeatToggle != null)
            VlcTopBarButton(
              width: 34.0,
              height: 34.0,
              tooltip: switch (widget.repeatMode) {
                VlcRepeatMode.off => 'Repeat: Off',
                VlcRepeatMode.all => 'Repeat: All [R]',
                VlcRepeatMode.one => 'Repeat: Current Track [R]',
              },
              isActive: widget.repeatMode != VlcRepeatMode.off,
              onPressed: widget.onRepeatToggle,
              child: VlcMonochromeIcon(
                widget.repeatMode == VlcRepeatMode.one ? VlcIconGlyph.repeatOne : VlcIconGlyph.repeat,
                size: 18.0,
                color: widget.repeatMode != VlcRepeatMode.off ? colors.accent.primary : colors.textSecondary,
              ),
            ),

          const SizedBox(width: 4.0),

          // Shuffle Mode Toggle
          if (widget.onShuffleToggle != null)
            VlcTopBarButton(
              width: 34.0,
              height: 34.0,
              tooltip: widget.isShuffle ? 'Shuffle: On' : 'Shuffle: Off',
              isActive: widget.isShuffle,
              onPressed: widget.onShuffleToggle,
              child: VlcMonochromeIcon(
                VlcIconGlyph.shuffle,
                size: 18.0,
                color: widget.isShuffle ? colors.accent.primary : colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
