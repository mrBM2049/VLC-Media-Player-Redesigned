import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_theme.dart';

/// Chapter tick model for seekbar markers
class ChapterTick {
  final double fraction; // 0.0 to 1.0
  final String title;
  final Duration time;

  const ChapterTick({
    required this.fraction,
    required this.title,
    required this.time,
  });
}

/// Thick Edge Seek Bar component for VLC Modern Redesign.
/// - Resting height: 10dp (VlcGeometry.thickSeekBarHeightNormal)
/// - Hovered height: 16dp (VlcGeometry.thickSeekBarHeightHover) with ease-out cubic expansion
/// - Scrubber handle: 4dp rectangular thumb with glow
/// - Chapter notches from libVLC chapters
/// - WaveformSeekOverlay audio amplitude bars
/// - Hover frame thumbnail preview popup with clamped bounds
class ThickSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final double bufferProgress; // 0.0 to 1.0
  final List<ChapterTick> chapters;
  final List<double>? waveformSamples;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration>? onSeekPreview;
  final Widget Function(BuildContext context, Duration hoverTime)? thumbnailBuilder;

  const ThickSeekBar({
    super.key,
    required this.position,
    required this.duration,
    this.bufferProgress = 0.0,
    this.chapters = const [],
    this.waveformSamples,
    required this.onSeek,
    this.onSeekPreview,
    this.thumbnailBuilder,
  });

  @override
  State<ThickSeekBar> createState() => _ThickSeekBarState();
}

class _ThickSeekBarState extends State<ThickSeekBar> {
  bool _isHovered = false;
  bool _isDragging = false;
  double _hoverFraction = 0.0;
  double _hoverDx = 0.0;
  double _dragFraction = 0.0;

  String _formatTime(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _updateHover(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0) return;
    final clampedX = localPosition.dx.clamp(0.0, totalWidth);
    final frac = clampedX / totalWidth;
    setState(() {
      _hoverDx = clampedX;
      _hoverFraction = frac;
    });

    if (widget.onSeekPreview != null && widget.duration.inMilliseconds > 0) {
      final previewMs = (frac * widget.duration.inMilliseconds).round();
      widget.onSeekPreview!(Duration(milliseconds: previewMs));
    }
  }

  void _commitSeek(double fraction) {
    if (widget.duration.inMilliseconds <= 0) return;
    final targetMs = (fraction * widget.duration.inMilliseconds).round();
    widget.onSeek(Duration(milliseconds: targetMs));
  }

  ChapterTick? _getHoveredChapter() {
    if (widget.chapters.isEmpty) return null;
    ChapterTick? best;
    for (final ch in widget.chapters) {
      if (_hoverFraction >= ch.fraction) {
        best = ch;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final isExpanded = _isHovered || _isDragging;
    final totalDurationMs = widget.duration.inMilliseconds;
    final currentPositionMs = widget.position.inMilliseconds;

    final progressFraction = totalDurationMs > 0
        ? (currentPositionMs / totalDurationMs).clamp(0.0, 1.0)
        : 0.0;

    final effectiveFraction = _isDragging ? _dragFraction : progressFraction;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final previewTime = Duration(
          milliseconds: (totalDurationMs * _hoverFraction).round(),
        );
        final hoveredChapter = _getHoveredChapter();

        // Calculate clamped popup center position
        const popupWidth = VlcGeometry.hoverPreviewWidth;
        final halfPopup = popupWidth / 2;
        final clampedPopupX = _hoverDx.clamp(halfPopup + 8.0, totalWidth - halfPopup - 8.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // -----------------------------------------------------------------
            // 1. Interactive Seek Bar Track
            // -----------------------------------------------------------------
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (e) {
                setState(() => _isHovered = true);
                _updateHover(e.localPosition, totalWidth);
              },
              onHover: (e) => _updateHover(e.localPosition, totalWidth),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _dragFraction = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragFraction = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
                  });
                },
                onHorizontalDragEnd: (_) {
                  _commitSeek(_dragFraction);
                  setState(() => _isDragging = false);
                },
                onTapDown: (details) {
                  final frac = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
                  _commitSeek(frac);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  height: isExpanded
                      ? VlcGeometry.thickSeekBarHeightHover
                      : VlcGeometry.thickSeekBarHeightNormal,
                  width: totalWidth,
                  child: CustomPaint(
                    size: Size(
                      totalWidth,
                      isExpanded
                          ? VlcGeometry.thickSeekBarHeightHover
                          : VlcGeometry.thickSeekBarHeightNormal,
                    ),
                    painter: _ThickSeekBarPainter(
                      progressFraction: effectiveFraction,
                      bufferFraction: widget.bufferProgress,
                      hoverFraction: _isHovered ? _hoverFraction : null,
                      isExpanded: isExpanded,
                      accent: colors.accent,
                      surfaceColor: colors.surfaceVariant.withOpacity(0.65),
                      borderColor: colors.borderSubtle,
                      chapters: widget.chapters,
                      waveformSamples: widget.waveformSamples,
                    ),
                  ),
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 2. Hover Frame Thumbnail Preview Card
            // -----------------------------------------------------------------
            if (_isHovered && totalDurationMs > 0)
              Positioned(
                left: clampedPopupX - halfPopup,
                bottom: (isExpanded ? VlcGeometry.thickSeekBarHeightHover : VlcGeometry.thickSeekBarHeightNormal) + 12.0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: popupWidth,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: VlcGeometry.borderRadiusLarge,
                        border: Border.all(
                          color: colors.border,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.50),
                            blurRadius: 16.0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 16:9 Thumbnail Frame
                          Container(
                            width: popupWidth,
                            height: VlcGeometry.hoverPreviewHeight,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(VlcGeometry.radiusLarge - 1),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: widget.thumbnailBuilder != null
                                ? widget.thumbnailBuilder!(context, previewTime)
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Simulated video frame raster gradient
                                      CustomPaint(
                                        painter: _SimulatedFramePainter(
                                          timecode: _formatTime(previewTime),
                                          coneColor: colors.accent.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),

                          // Timecode & Chapter Footer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(VlcGeometry.radiusLarge - 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Formatted hover timecode
                                Text(
                                  _formatTime(previewTime),
                                  style: vlcTheme.typography.monospaceTime.copyWith(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.accent.primary,
                                  ),
                                ),

                                // Chapter Name badge (if present)
                                if (hoveredChapter != null)
                                  Flexible(
                                    child: Text(
                                      hoveredChapter.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: vlcTheme.typography.bodySmall.copyWith(
                                        fontSize: 10.0,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Seek Bar Canvas Painter
// -----------------------------------------------------------------------------

class _ThickSeekBarPainter extends CustomPainter {
  final double progressFraction;
  final double bufferFraction;
  final double? hoverFraction;
  final bool isExpanded;
  final VlcAccentEngine accent;
  final Color surfaceColor;
  final Color borderColor;
  final List<ChapterTick> chapters;
  final List<double>? waveformSamples;

  _ThickSeekBarPainter({
    required this.progressFraction,
    required this.bufferFraction,
    required this.hoverFraction,
    required this.isExpanded,
    required this.accent,
    required this.surfaceColor,
    required this.borderColor,
    required this.chapters,
    required this.waveformSamples,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Inactive Background Track
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bgRect,
      Paint()..color = surfaceColor,
    );

    // 2. Audio Waveform Overlay (if available)
    if (waveformSamples != null && waveformSamples!.isNotEmpty) {
      final wavePaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.fill;

      final count = waveformSamples!.length;
      final barWidth = (w / count).clamp(1.0, 4.0);
      final gap = 1.0;

      for (int i = 0; i < count; i++) {
        final sample = waveformSamples![i].clamp(0.1, 1.0);
        final barHeight = (h - 2.0) * sample;
        final x = i * (barWidth + gap);
        if (x >= w) break;

        final barRect = Rect.fromLTWH(x, (h - barHeight) / 2, barWidth, barHeight);
        canvas.drawRect(barRect, wavePaint);
      }
    }

    // 3. Buffer Progress Bar (Streaming/Network media)
    if (bufferFraction > 0.0) {
      final bufferWidth = (w * bufferFraction).clamp(0.0, w);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, bufferWidth, h),
        Paint()..color = Colors.white.withOpacity(0.20),
      );
    }

    // 4. Hover Scrub Indicator (semi-transparent preview tint)
    if (hoverFraction != null) {
      final hoverWidth = (w * hoverFraction!).clamp(0.0, w);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, hoverWidth, h),
        Paint()..color = accent.subtleBackground,
      );
    }

    // 5. Active Playback Progress Bar (Cone Orange gradient)
    final progressWidth = (w * progressFraction).clamp(0.0, w);
    if (progressWidth > 0) {
      final progressPaint = Paint()
        ..shader = accent.normalConeGradient.createShader(
          Rect.fromLTWH(0, 0, w, h),
        );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, progressWidth, h),
        progressPaint,
      );
    }

    // 6. Chapter Ticks (Vertical notch dividers)
    if (chapters.isNotEmpty) {
      final tickPaint = Paint()
        ..color = Colors.black.withOpacity(0.65)
        ..strokeWidth = 1.5;

      for (final ch in chapters) {
        final tickX = w * ch.fraction;
        if (tickX > 2.0 && tickX < w - 2.0) {
          canvas.drawLine(
            Offset(tickX, 0),
            Offset(tickX, h),
            tickPaint,
          );
        }
      }
    }

    // 7. Scrubber Thumb Handle (4dp rectangular slider with glow)
    if (progressWidth > 0) {
      final thumbW = VlcGeometry.thickSeekBarScrubberWidth;
      final thumbX = (progressWidth - (thumbW / 2)).clamp(0.0, w - thumbW);

      final thumbRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(thumbX, 0, thumbW, h),
        const Radius.circular(1.0),
      );

      // Glow drop shadow
      canvas.drawRRect(
        thumbRect.inflate(isExpanded ? 2.0 : 1.0),
        Paint()..color = accent.glow,
      );

      // Solid White Thumb
      canvas.drawRRect(
        thumbRect,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThickSeekBarPainter oldDelegate) {
    return oldDelegate.progressFraction != progressFraction ||
        oldDelegate.bufferFraction != bufferFraction ||
        oldDelegate.hoverFraction != hoverFraction ||
        oldDelegate.isExpanded != isExpanded ||
        oldDelegate.accent != accent ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

// -----------------------------------------------------------------------------
// Simulated Video Frame Painter for Preview Card
// -----------------------------------------------------------------------------

class _SimulatedFramePainter extends CustomPainter {
  final String timecode;
  final Color coneColor;

  _SimulatedFramePainter({required this.timecode, required this.coneColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark cinematic background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF16161A), Color(0xFF0D0D0F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle film scanlines
    final scanlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    for (double y = 0; y < h; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(w, y), scanlinePaint);
    }

    // Small center cone emblem
    final coneCenter = Offset(w * 0.5, h * 0.45);
    final coneRadius = 14.0;
    final conePath = Path()
      ..moveTo(coneCenter.dx, coneCenter.dy - coneRadius)
      ..lineTo(coneCenter.dx + (coneRadius * 0.7), coneCenter.dy + coneRadius)
      ..lineTo(coneCenter.dx - (coneRadius * 0.7), coneCenter.dy + coneRadius)
      ..close();
    canvas.drawPath(conePath, Paint()..color = coneColor.withOpacity(0.50));
  }

  @override
  bool shouldRepaint(covariant _SimulatedFramePainter oldDelegate) =>
      oldDelegate.timecode != timecode || oldDelegate.coneColor != coneColor;
}
