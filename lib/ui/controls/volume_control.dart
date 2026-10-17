import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';
import '../shell/top_player_bar.dart'; // for VlcTopBarButton

/// Full Cone Volume Control widget providing 0% to 200% volume adjustment
/// with nominal 100% notch and diagonal software overdrive stripes past 100%.
class FullConeVolumeControl extends StatefulWidget {
  final int volume; // 0 to 200
  final bool isMuted;
  final ValueChanged<int> onVolumeChanged;
  final VoidCallback onToggleMute;

  const FullConeVolumeControl({
    super.key,
    required this.volume,
    this.isMuted = false,
    required this.onVolumeChanged,
    required this.onToggleMute,
  });

  @override
  State<FullConeVolumeControl> createState() => _FullConeVolumeControlState();
}

class _FullConeVolumeControlState extends State<FullConeVolumeControl> {
  bool _isHovered = false;
  bool _isDragging = false;

  VlcIconGlyph _getVolumeIcon() {
    if (widget.isMuted || widget.volume == 0) {
      return VlcIconGlyph.volumeMute;
    } else if (widget.volume < 35) {
      return VlcIconGlyph.volumeLow;
    } else if (widget.volume < 70) {
      return VlcIconGlyph.volumeMedium;
    } else if (widget.volume <= 100) {
      return VlcIconGlyph.volumeHigh;
    } else {
      return VlcIconGlyph.volumeCone;
    }
  }

  void _handleDragUpdate(Offset localPosition, double trackWidth) {
    final clampedX = localPosition.dx.clamp(0.0, trackWidth);
    final fraction = clampedX / trackWidth;
    final newVol = (fraction * 200).round().clamp(0, 200);
    widget.onVolumeChanged(newVol);
  }

  void _handleScroll(PointerScrollEvent event) {
    final delta = event.scrollDelta.dy;
    if (delta < 0) {
      // Scroll Up -> Volume +5%
      widget.onVolumeChanged((widget.volume + 5).clamp(0, 200));
    } else if (delta > 0) {
      // Scroll Down -> Volume -5%
      widget.onVolumeChanged((widget.volume - 5).clamp(0, 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final effectiveVol = widget.isMuted ? 0 : widget.volume;
    final isOverdrive = effectiveVol > 100;

    final volumeText = widget.isMuted
        ? 'Muted'
        : isOverdrive
            ? '${widget.volume}% (Overdrive)'
            : '${widget.volume}%';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent) {
            _handleScroll(signal);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Speaker Icon / Mute Button
            VlcTopBarButton(
              width: 32.0,
              height: 32.0,
              tooltip: widget.isMuted ? 'Unmute [M]' : 'Mute [M]',
              onPressed: widget.onToggleMute,
              child: VlcMonochromeIcon(
                _getVolumeIcon(),
                size: 18.0,
                color: widget.isMuted
                    ? colors.textDisabled
                    : isOverdrive
                        ? const Color(0xFFFF5500)
                        : colors.textPrimary,
              ),
            ),

            const SizedBox(width: 6.0),

            // Horizontal 0-200% Striped Slider Track
            Tooltip(
              message: volumeText,
              waitDuration: const Duration(milliseconds: 300),
              child: GestureDetector(
                key: const ValueKey('volume_slider_gesture'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() => _isDragging = true);
                  _handleDragUpdate(details.localPosition, VlcGeometry.volumeSliderWidth);
                },
                onHorizontalDragUpdate: (details) {
                  _handleDragUpdate(details.localPosition, VlcGeometry.volumeSliderWidth);
                },
                onHorizontalDragEnd: (_) {
                  setState(() => _isDragging = false);
                },
                onTapDown: (details) {
                  _handleDragUpdate(details.localPosition, VlcGeometry.volumeSliderWidth);
                },
                child: Container(
                  width: VlcGeometry.volumeSliderWidth,
                  height: 28.0, // generous touch/hit target
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size(VlcGeometry.volumeSliderWidth, 8.0),
                    painter: _ConeVolumeSliderPainter(
                      volume: effectiveVol,
                      isHovered: _isHovered || _isDragging,
                      accent: colors.accent,
                      surfaceColor: colors.surfaceVariant,
                      borderColor: colors.border,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8.0),

            // Monospace Percentage Label
            SizedBox(
              width: 36.0,
              child: Text(
                '${effectiveVol}%',
                style: vlcTheme.typography.monospaceTime.copyWith(
                  fontSize: 11.0,
                  color: isOverdrive
                      ? const Color(0xFFFF5500)
                      : colors.textSecondary,
                  fontWeight: isOverdrive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Cone Volume Slider Track Painter (0% to 200% with Overdrive Stripes)
// -----------------------------------------------------------------------------

class _ConeVolumeSliderPainter extends CustomPainter {
  final int volume; // 0 to 200
  final bool isHovered;
  final VlcAccentEngine accent;
  final Color surfaceColor;
  final Color borderColor;

  _ConeVolumeSliderPainter({
    required this.volume,
    required this.isHovered,
    required this.accent,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final trackHeight = isHovered ? 6.0 : 4.0;
    final trackTop = (h - trackHeight) / 2;
    final trackRadius = Radius.circular(trackHeight / 2);

    // 1. Background Inactive Track
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackTop, w, trackHeight),
      trackRadius,
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = surfaceColor,
    );

    // 2. Active Volume Bar
    final progressFraction = (volume / 200.0).clamp(0.0, 1.0);
    final activeWidth = w * progressFraction;

    if (activeWidth > 0) {
      final activeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackTop, activeWidth, trackHeight),
        trackRadius,
      );

      final normalWidth = w * 0.50; // 100% volume is at 50% width

      if (activeWidth <= normalWidth) {
        // Normal Range (0% to 100%): Signature Cone Orange Gradient
        final paint = Paint()
          ..shader = accent.normalConeGradient.createShader(
            Rect.fromLTWH(0, trackTop, normalWidth, trackHeight),
          );
        canvas.drawRRect(activeRect, paint);
      } else {
        // Overdrive Range (100% to 200%): Overdrive Gradient + Stripes
        final paint = Paint()
          ..shader = accent.overdriveConeGradient.createShader(
            Rect.fromLTWH(0, trackTop, w, trackHeight),
          );
        canvas.drawRRect(activeRect, paint);

        // Draw diagonal software overdrive hatch stripes on the section > 100%
        canvas.save();
        canvas.clipRRect(activeRect);

        final stripePaint = Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..strokeWidth = 1.5;

        for (double x = normalWidth; x < activeWidth + 10; x += 5.0) {
          canvas.drawLine(
            Offset(x, trackTop + trackHeight),
            Offset(x + 4.0, trackTop),
            stripePaint,
          );
        }
        canvas.restore();
      }
    }

    // 3. Unity Gain (100%) Notch Tick Mark at 50% width
    final notchX = w * 0.50;
    final notchPaint = Paint()
      ..color = Colors.white.withOpacity(0.60)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(notchX, trackTop - 2.0),
      Offset(notchX, trackTop + trackHeight + 2.0),
      notchPaint,
    );

    // 4. Scrubber Thumb Handle
    if (isHovered && activeWidth > 0) {
      final thumbX = (activeWidth - 2.5).clamp(0.0, w - 5.0);
      final thumbRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(thumbX, (h - 12.0) / 2, 5.0, 12.0),
        const Radius.circular(2.0),
      );

      // Glow behind thumb
      canvas.drawRRect(
        thumbRect.inflate(1.5),
        Paint()..color = (volume > 100 ? const Color(0xFFFF5500) : accent.primary).withOpacity(0.40),
      );

      // Solid thumb body
      canvas.drawRRect(
        thumbRect,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConeVolumeSliderPainter oldDelegate) {
    return oldDelegate.volume != volume ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.accent != accent ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

