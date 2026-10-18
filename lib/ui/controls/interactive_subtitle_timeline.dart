import 'package:flutter/material.dart';
import '../../models/subtitle_models.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Interactive Subtitle Timeline Overlay component for VLC Modern Redesign.
/// Displayed above the ThickSeekBar.
/// Allows users to visually drag dialogue blocks left or right to sync with speech,
/// especially intuitive while scrubbing or paused.
class InteractiveSubtitleTimeline extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration delay;
  final List<SubtitleDialogueCue> cues;
  final ValueChanged<Duration> onDelayChanged;
  final VoidCallback? onClose;

  const InteractiveSubtitleTimeline({
    super.key,
    required this.position,
    required this.duration,
    required this.delay,
    required this.cues,
    required this.onDelayChanged,
    this.onClose,
  });

  @override
  State<InteractiveSubtitleTimeline> createState() => _InteractiveSubtitleTimelineState();
}

class _InteractiveSubtitleTimelineState extends State<InteractiveSubtitleTimeline> {
  bool _isDragging = false;
  double _accumulatedDelta = 0.0;
  Duration _dragStartDelay = Duration.zero;

  String _formatDelay(Duration d) {
    final ms = d.inMilliseconds;
    if (ms == 0) return '0.0s (In Sync)';
    final sign = ms > 0 ? '+' : '';
    final sec = (ms / 1000.0).toStringAsFixed(2);
    return '$sign${sec}s ($sign$ms ms)';
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final delayMs = widget.delay.inMilliseconds;

    // Find current active cue or nearest cue within +/- 10s
    SubtitleDialogueCue? activeCue;
    for (final cue in widget.cues) {
      if (cue.isActiveAt(widget.position, widget.delay)) {
        activeCue = cue;
        break;
      }
    }
    // If no exact match, show nearest
    activeCue ??= widget.cues.isNotEmpty ? widget.cues.first : null;

    return Container(
      height: 32.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(
          color: _isDragging || delayMs != 0 ? colors.accent.primary : colors.border,
          width: _isDragging ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Subtitle Icon Badge
          VlcMonochromeIcon(
            VlcIconGlyph.subtitles,
            size: 14.0,
            color: colors.accent.primary,
          ),
          const SizedBox(width: 6.0),

          // Draggable Dialogue Cue Block Strip
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                setState(() {
                  _isDragging = true;
                  _accumulatedDelta = 0.0;
                  _dragStartDelay = widget.delay;
                });
              },
              onHorizontalDragUpdate: (details) {
                // 1 physical pixel drag = 10ms delay shift
                _accumulatedDelta += details.delta.dx;
                final shiftMs = (_accumulatedDelta * 10).round();
                final newDelay = _dragStartDelay + Duration(milliseconds: shiftMs);
                widget.onDelayChanged(newDelay);
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: _isDragging
                      ? colors.accent.subtleBackground
                      : colors.surfaceHover,
                  borderRadius: VlcGeometry.borderRadiusSmall,
                  border: Border.all(
                    color: _isDragging ? colors.accent.primary : colors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_indicator,
                      size: 14.0,
                      color: _isDragging ? colors.accent.primary : colors.textTertiary,
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        activeCue != null
                            ? 'Cue: “${activeCue.text}”'
                            : 'Drag dialogue block left/right to sync offset',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: vlcTheme.typography.bodySmall.copyWith(
                          fontSize: 11.0,
                          color: _isDragging ? colors.accent.primary : colors.textPrimary,
                          fontWeight: _isDragging ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    // Live Sync Offset Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: delayMs != 0 ? colors.accent.primary : colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        _formatDelay(widget.delay),
                        style: vlcTheme.typography.monospaceTime.copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          color: delayMs != 0 ? Colors.white : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6.0),

          // Stepper Buttons: [-50ms], [0s], [+50ms]
          _buildQuickStepButton('-50ms', () {
            widget.onDelayChanged(widget.delay - const Duration(milliseconds: 50));
          }, colors, vlcTheme),
          const SizedBox(width: 2.0),
          _buildQuickStepButton('0s', () {
            widget.onDelayChanged(Duration.zero);
          }, colors, vlcTheme, isHighlight: delayMs != 0),
          const SizedBox(width: 2.0),
          _buildQuickStepButton('+50ms', () {
            widget.onDelayChanged(widget.delay + const Duration(milliseconds: 50));
          }, colors, vlcTheme),

          if (widget.onClose != null) ...[
            const SizedBox(width: 4.0),
            InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Icon(Icons.close, size: 14.0, color: colors.textTertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStepButton(
    String label,
    VoidCallback onTap,
    VlcColors colors,
    VlcThemeData vlcTheme, {
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: isHighlight ? colors.accent.subtleBackground : colors.surfaceHover,
          borderRadius: BorderRadius.circular(3.0),
          border: Border.all(
            color: isHighlight ? colors.accent.primary : colors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: vlcTheme.typography.monospaceTime.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isHighlight ? colors.accent.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
