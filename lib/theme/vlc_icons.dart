import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'vlc_colors.dart';
import 'vlc_geometry.dart';

/// Available iconography glyphs throughout VLC Modern Redesign
enum VlcIconGlyph {
  // Transport Controls
  play,
  pause,
  previous,
  next,
  stop,
  stepForward,
  stepBackward,

  // Audio & Volume
  volumeMute,
  volumeLow,
  volumeMedium,
  volumeHigh,
  volumeCone,
  equalizer,

  // Video & Display
  fullscreen,
  exitFullscreen,
  pictureInPicture,
  aspectRatio,
  crop,

  // Tracks, Subtitles & Tools
  subtitles,
  audioTrack,
  repeat,
  repeatOne,
  shuffle,
  speed,
  bookmark,
  chapters,

  // Navigation, Library & Shell
  menu,
  folder,
  queue,
  playlist,
  search,
  settings,
  info,
  close,
  chevronDown,
  chevronRight,
  chevronLeft,
  moreVertical,

  // Dual-Tone Inspector Tabs
  tabSubtitles,
  tabAudio,
  tabVideo,
  tabPlayback,
}

/// Monochrome Outline Vector Icon
/// Renders crisp vector paths on a 20dp/24dp grid with standard 1.5dp stroke width.
class VlcMonochromeIcon extends StatelessWidget {
  final VlcIconGlyph glyph;
  final double size;
  final Color? color;
  final double strokeWidth;

  const VlcMonochromeIcon(
    this.glyph, {
    super.key,
    this.size = VlcGeometry.iconSizeMedium,
    this.color,
    this.strokeWidth = VlcGeometry.strokeWidthMonochrome,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Colors.white;

    return CustomPaint(
      size: Size(size, size),
      painter: _VlcMonochromePainter(
        glyph: glyph,
        color: effectiveColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// Two-Tone Accent Vector Icon
/// Renders a secondary contour base with a signature vibrant accent highlight.
/// Specifically designed for category headers, drawer headers, and inspector tabs.
class VlcTwoToneIcon extends StatelessWidget {
  final VlcIconGlyph glyph;
  final double size;
  final Color? baseColor;
  final Color? accentColor;
  final double strokeWidth;

  const VlcTwoToneIcon(
    this.glyph, {
    super.key,
    this.size = VlcGeometry.iconSizeLarge,
    this.baseColor,
    this.accentColor,
    this.strokeWidth = VlcGeometry.strokeWidthMonochrome,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBase = baseColor ?? const Color(0xB3FFFFFF);
    final effectiveAccent = accentColor ?? VlcColors.coneOrange;

    return CustomPaint(
      size: Size(size, size),
      painter: _VlcTwoTonePainter(
        glyph: glyph,
        baseColor: effectiveBase,
        accentColor: effectiveAccent,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Vector Painters
// -----------------------------------------------------------------------------

class _VlcMonochromePainter extends CustomPainter {
  final VlcIconGlyph glyph;
  final Color color;
  final double strokeWidth;

  _VlcMonochromePainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintStroke = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (glyph) {
      case VlcIconGlyph.play:
        // Clean rectangular-angled play triangle
        final path = Path()
          ..moveTo(w * 0.30, h * 0.20)
          ..lineTo(w * 0.78, h * 0.50)
          ..lineTo(w * 0.30, h * 0.80)
          ..close();
        canvas.drawPath(path, paintFill);
        break;

      case VlcIconGlyph.pause:
        // Dual clean vertical rectangular bars
        final barW = w * 0.16;
        final barH = h * 0.60;
        final top = h * 0.20;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.28, top, barW, barH),
            const Radius.circular(1.5),
          ),
          paintFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.56, top, barW, barH),
            const Radius.circular(1.5),
          ),
          paintFill,
        );
        break;

      case VlcIconGlyph.previous:
        // Left bar + left triangle
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.20, h * 0.22, w * 0.12, h * 0.56),
            const Radius.circular(1.0),
          ),
          paintFill,
        );
        final path = Path()
          ..moveTo(w * 0.78, h * 0.22)
          ..lineTo(w * 0.36, h * 0.50)
          ..lineTo(w * 0.78, h * 0.78)
          ..close();
        canvas.drawPath(path, paintFill);
        break;

      case VlcIconGlyph.next:
        // Right triangle + right bar
        final path = Path()
          ..moveTo(w * 0.22, h * 0.22)
          ..lineTo(w * 0.64, h * 0.50)
          ..lineTo(w * 0.22, h * 0.78)
          ..close();
        canvas.drawPath(path, paintFill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.68, h * 0.22, w * 0.12, h * 0.56),
            const Radius.circular(1.0),
          ),
          paintFill,
        );
        break;

      case VlcIconGlyph.stop:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.24, h * 0.24, w * 0.52, h * 0.52),
            const Radius.circular(2.0),
          ),
          paintFill,
        );
        break;

      case VlcIconGlyph.volumeMute:
        _drawSpeakerBody(canvas, size, paintStroke, paintFill);
        // X mark
        canvas.drawLine(Offset(w * 0.68, h * 0.36), Offset(w * 0.88, h * 0.64), paintStroke);
        canvas.drawLine(Offset(w * 0.88, h * 0.36), Offset(w * 0.68, h * 0.64), paintStroke);
        break;

      case VlcIconGlyph.volumeLow:
        _drawSpeakerBody(canvas, size, paintStroke, paintFill);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.45, h * 0.5), width: w * 0.45, height: h * 0.45),
          -math.pi / 4,
          math.pi / 2,
          false,
          paintStroke,
        );
        break;

      case VlcIconGlyph.volumeMedium:
        _drawSpeakerBody(canvas, size, paintStroke, paintFill);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.45, h * 0.5), width: w * 0.42, height: h * 0.42),
          -math.pi / 4,
          math.pi / 2,
          false,
          paintStroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.45, h * 0.5), width: w * 0.65, height: h * 0.65),
          -math.pi / 4,
          math.pi / 2,
          false,
          paintStroke,
        );
        break;

      case VlcIconGlyph.volumeHigh:
      case VlcIconGlyph.volumeCone:
        _drawSpeakerBody(canvas, size, paintStroke, paintFill);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.45, h * 0.5), width: w * 0.38, height: h * 0.38),
          -math.pi / 4,
          math.pi / 2,
          false,
          paintStroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.45, h * 0.5), width: w * 0.58, height: h * 0.58),
          -math.pi / 4,
          math.pi / 2,
          false,
          paintStroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.45, h * 0.5), width: w * 0.78, height: h * 0.78),
          -math.pi / 4,
          math.pi / 2,
          false,
          paintStroke,
        );
        break;

      case VlcIconGlyph.fullscreen:
        // 4 corner brackets
        final len = w * 0.22;
        // Top-left
        canvas.drawLine(Offset(w * 0.18, h * 0.18 + len), Offset(w * 0.18, h * 0.18), paintStroke);
        canvas.drawLine(Offset(w * 0.18, h * 0.18), Offset(w * 0.18 + len, h * 0.18), paintStroke);
        // Top-right
        canvas.drawLine(Offset(w * 0.82 - len, h * 0.18), Offset(w * 0.82, h * 0.18), paintStroke);
        canvas.drawLine(Offset(w * 0.82, h * 0.18), Offset(w * 0.82, h * 0.18 + len), paintStroke);
        // Bottom-left
        canvas.drawLine(Offset(w * 0.18, h * 0.82 - len), Offset(w * 0.18, h * 0.82), paintStroke);
        canvas.drawLine(Offset(w * 0.18, h * 0.82), Offset(w * 0.18 + len, h * 0.82), paintStroke);
        // Bottom-right
        canvas.drawLine(Offset(w * 0.82 - len, h * 0.82), Offset(w * 0.82, h * 0.82), paintStroke);
        canvas.drawLine(Offset(w * 0.82, h * 0.82), Offset(w * 0.82, h * 0.82 - len), paintStroke);
        break;

      case VlcIconGlyph.exitFullscreen:
        final len = w * 0.20;
        // Top-left inwards
        canvas.drawLine(Offset(w * 0.35, h * 0.18), Offset(w * 0.35, h * 0.35), paintStroke);
        canvas.drawLine(Offset(w * 0.18, h * 0.35), Offset(w * 0.35, h * 0.35), paintStroke);
        // Top-right inwards
        canvas.drawLine(Offset(w * 0.65, h * 0.18), Offset(w * 0.65, h * 0.35), paintStroke);
        canvas.drawLine(Offset(w * 0.82, h * 0.35), Offset(w * 0.65, h * 0.35), paintStroke);
        // Bottom-left inwards
        canvas.drawLine(Offset(w * 0.35, h * 0.82), Offset(w * 0.35, h * 0.65), paintStroke);
        canvas.drawLine(Offset(w * 0.18, h * 0.65), Offset(w * 0.35, h * 0.65), paintStroke);
        // Bottom-right inwards
        canvas.drawLine(Offset(w * 0.65, h * 0.82), Offset(w * 0.65, h * 0.65), paintStroke);
        canvas.drawLine(Offset(w * 0.82, h * 0.65), Offset(w * 0.65, h * 0.65), paintStroke);
        break;

      case VlcIconGlyph.pictureInPicture:
        // Outer rect + inner floating rect
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.76, h * 0.64),
            const Radius.circular(3.0),
          ),
          paintStroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.50, h * 0.48, w * 0.32, h * 0.28),
            const Radius.circular(2.0),
          ),
          paintFill,
        );
        break;

      case VlcIconGlyph.subtitles:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.20, w * 0.72, h * 0.60),
            const Radius.circular(3.0),
          ),
          paintStroke,
        );
        // Subtitle lines
        canvas.drawLine(Offset(w * 0.26, h * 0.46), Offset(w * 0.52, h * 0.46), paintStroke);
        canvas.drawLine(Offset(w * 0.26, h * 0.60), Offset(w * 0.74, h * 0.60), paintStroke);
        break;

      case VlcIconGlyph.equalizer:
        // 3 slider tracks
        canvas.drawLine(Offset(w * 0.25, h * 0.18), Offset(w * 0.25, h * 0.82), paintStroke);
        canvas.drawLine(Offset(w * 0.50, h * 0.18), Offset(w * 0.50, h * 0.82), paintStroke);
        canvas.drawLine(Offset(w * 0.75, h * 0.18), Offset(w * 0.75, h * 0.82), paintStroke);
        // Slider thumbs
        canvas.drawCircle(Offset(w * 0.25, h * 0.40), 2.5, paintFill);
        canvas.drawCircle(Offset(w * 0.50, h * 0.65), 2.5, paintFill);
        canvas.drawCircle(Offset(w * 0.75, h * 0.30), 2.5, paintFill);
        break;

      case VlcIconGlyph.menu:
        canvas.drawLine(Offset(w * 0.18, h * 0.30), Offset(w * 0.82, h * 0.30), paintStroke);
        canvas.drawLine(Offset(w * 0.18, h * 0.50), Offset(w * 0.82, h * 0.50), paintStroke);
        canvas.drawLine(Offset(w * 0.18, h * 0.70), Offset(w * 0.82, h * 0.70), paintStroke);
        break;

      case VlcIconGlyph.settings:
        _drawGear(canvas, size, paintStroke);
        break;

      default:
        // Fallback generic outline box
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.6),
            const Radius.circular(3.0),
          ),
          paintStroke,
        );
        break;
    }
  }

  void _drawSpeakerBody(Canvas canvas, Size size, Paint paintStroke, Paint paintFill) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.18, h * 0.38)
      ..lineTo(w * 0.32, h * 0.38)
      ..lineTo(w * 0.52, h * 0.20)
      ..lineTo(w * 0.52, h * 0.80)
      ..lineTo(w * 0.32, h * 0.62)
      ..lineTo(w * 0.18, h * 0.62)
      ..close();
    canvas.drawPath(path, paintFill);
  }

  void _drawGear(Canvas canvas, Size size, Paint paintStroke) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.28;
    canvas.drawCircle(center, radius, paintStroke);
    canvas.drawCircle(center, radius * 0.40, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _VlcMonochromePainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _VlcTwoTonePainter extends CustomPainter {
  final VlcIconGlyph glyph;
  final Color baseColor;
  final Color accentColor;
  final double strokeWidth;

  _VlcTwoTonePainter({
    required this.glyph,
    required this.baseColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintBase = Paint()
      ..color = baseColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintBaseFill = Paint()
      ..color = baseColor.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final paintAccent = Paint()
      ..color = accentColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintAccentFill = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    switch (glyph) {
      case VlcIconGlyph.tabSubtitles:
        // Subtitle drawer tab: Base dialogue box + orange speech text highlight
        final bubbleRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.76, h * 0.60),
          const Radius.circular(4.0),
        );
        canvas.drawRRect(bubbleRect, paintBaseFill);
        canvas.drawRRect(bubbleRect, paintBase);
        // Orange highlighted subtitle dialogue line
        canvas.drawLine(Offset(w * 0.26, h * 0.42), Offset(w * 0.74, h * 0.42), paintAccent);
        canvas.drawLine(Offset(w * 0.26, h * 0.56), Offset(w * 0.56, h * 0.56), paintAccent);
        break;

      case VlcIconGlyph.tabAudio:
        // Audio inspector tab: Base headphones + orange equalizer beat pulse
        final earLeft = Rect.fromLTWH(w * 0.12, h * 0.48, w * 0.14, h * 0.32);
        final earRight = Rect.fromLTWH(w * 0.74, h * 0.48, w * 0.14, h * 0.32);
        canvas.drawRRect(RRect.fromRectAndRadius(earLeft, const Radius.circular(3.0)), paintBaseFill);
        canvas.drawRRect(RRect.fromRectAndRadius(earRight, const Radius.circular(3.0)), paintBaseFill);
        canvas.drawRRect(RRect.fromRectAndRadius(earLeft, const Radius.circular(3.0)), paintBase);
        canvas.drawRRect(RRect.fromRectAndRadius(earRight, const Radius.circular(3.0)), paintBase);
        // Headband arc
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.50, h * 0.48), width: w * 0.62, height: h * 0.50),
          math.pi,
          math.pi,
          false,
          paintBase,
        );
        // Orange waveform center
        canvas.drawLine(Offset(w * 0.42, h * 0.58), Offset(w * 0.42, h * 0.42), paintAccent);
        canvas.drawLine(Offset(w * 0.50, h * 0.65), Offset(w * 0.50, h * 0.35), paintAccent);
        canvas.drawLine(Offset(w * 0.58, h * 0.58), Offset(w * 0.58, h * 0.42), paintAccent);
        break;

      case VlcIconGlyph.tabVideo:
        // Video tab: Film slate/monitor base + orange cone play indicator
        final screenRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.76, h * 0.54),
          const Radius.circular(4.0),
        );
        canvas.drawRRect(screenRect, paintBaseFill);
        canvas.drawRRect(screenRect, paintBase);
        // Base stand
        canvas.drawLine(Offset(w * 0.50, h * 0.72), Offset(w * 0.50, h * 0.84), paintBase);
        canvas.drawLine(Offset(w * 0.32, h * 0.84), Offset(w * 0.68, h * 0.84), paintBase);
        // Vibrant orange play emblem in center
        final playPath = Path()
          ..moveTo(w * 0.42, h * 0.33)
          ..lineTo(w * 0.64, h * 0.45)
          ..lineTo(w * 0.42, h * 0.57)
          ..close();
        canvas.drawPath(playPath, paintAccentFill);
        break;

      case VlcIconGlyph.tabPlayback:
        // Playback tab: Gauge/clock base + orange fast forward / speed dial hand
        final center = Offset(w * 0.50, h * 0.50);
        canvas.drawCircle(center, w * 0.34, paintBase);
        canvas.drawCircle(center, 2.0, paintAccentFill);
        // Orange clock hand
        canvas.drawLine(center, Offset(w * 0.68, h * 0.32), paintAccent);
        break;

      default:
        // Generic two-tone icon: base rounded square + accent dot
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.68),
          const Radius.circular(4.0),
        );
        canvas.drawRRect(rect, paintBase);
        canvas.drawCircle(Offset(w * 0.50, h * 0.50), 3.0, paintAccentFill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _VlcTwoTonePainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

