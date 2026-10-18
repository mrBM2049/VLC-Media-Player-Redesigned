import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Touch gesture & HUD overlay for mobile / tablet touchscreens.
///
/// Implements:
/// - Vertical swipe on right half: Volume (0–200% with Cone HUD).
/// - Vertical swipe on left half: Brightness (0–100% with Sun HUD).
/// - Double-tap left/right: Seek `±10s` with directional animated ripple.
/// - Single-tap: Toggle player transport chrome.
class MobileGestureOverlay extends StatefulWidget {
  final Widget child;
  final double volume; // 0.0 to 2.0
  final double brightness; // 0.0 to 1.0
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<double>? onBrightnessChanged;
  final ValueChanged<Duration>? onSeekRelative;
  final VoidCallback? onTap;

  const MobileGestureOverlay({
    super.key,
    required this.child,
    this.volume = 1.0,
    this.brightness = 0.8,
    this.onVolumeChanged,
    this.onBrightnessChanged,
    this.onSeekRelative,
    this.onTap,
  });

  @override
  State<MobileGestureOverlay> createState() => _MobileGestureOverlayState();
}

class _MobileGestureOverlayState extends State<MobileGestureOverlay> {
  // HUD state flags
  bool _showVolumeHud = false;
  bool _showBrightnessHud = false;
  bool _showSeekForwardRipple = false;
  bool _showSeekBackwardRipple = false;

  late double _currentVolume;
  late double _currentBrightness;

  Timer? _volumeHudTimer;
  Timer? _brightnessHudTimer;
  Timer? _seekRippleTimer;

  @override
  void initState() {
    super.initState();
    _currentVolume = widget.volume;
    _currentBrightness = widget.brightness;
  }

  @override
  void didUpdateWidget(MobileGestureOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.volume != widget.volume) {
      _currentVolume = widget.volume;
    }
    if (oldWidget.brightness != widget.brightness) {
      _currentBrightness = widget.brightness;
    }
  }

  @override
  void dispose() {
    _volumeHudTimer?.cancel();
    _brightnessHudTimer?.cancel();
    _seekRippleTimer?.cancel();
    super.dispose();
  }

  void _handleVerticalDrag(DragUpdateDetails details, BoxConstraints constraints) {
    final dx = details.localPosition.dx;
    final dyDelta = details.delta.dy;
    final isRightSide = dx > (constraints.maxWidth / 2.0);

    // Negative delta = dragging upward = increase
    final sensitivity = 1.0 / (constraints.maxHeight * 0.7);
    final deltaNormalized = -dyDelta * sensitivity;

    if (isRightSide) {
      // Volume swipe (0.0 to 2.0 cone volume)
      setState(() {
        _currentVolume = (_currentVolume + (deltaNormalized * 2.0)).clamp(0.0, 2.0);
        _showVolumeHud = true;
      });
      widget.onVolumeChanged?.call(_currentVolume);

      _volumeHudTimer?.cancel();
      _volumeHudTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showVolumeHud = false);
      });
    } else {
      // Brightness swipe (0.0 to 1.0)
      setState(() {
        _currentBrightness = (_currentBrightness + deltaNormalized).clamp(0.0, 1.0);
        _showBrightnessHud = true;
      });
      widget.onBrightnessChanged?.call(_currentBrightness);

      _brightnessHudTimer?.cancel();
      _brightnessHudTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showBrightnessHud = false);
      });
    }
  }

  void _handleDoubleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final dx = details.localPosition.dx;
    final width = constraints.maxWidth;

    if (dx > width * 0.6) {
      // Right 40%: Seek Forward +10s
      widget.onSeekRelative?.call(const Duration(seconds: 10));
      setState(() {
        _showSeekForwardRipple = true;
        _showSeekBackwardRipple = false;
      });
      _seekRippleTimer?.cancel();
      _seekRippleTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _showSeekForwardRipple = false);
      });
    } else if (dx < width * 0.4) {
      // Left 40%: Seek Backward -10s
      widget.onSeekRelative?.call(const Duration(seconds: -10));
      setState(() {
        _showSeekBackwardRipple = true;
        _showSeekForwardRipple = false;
      });
      _seekRippleTimer?.cancel();
      _seekRippleTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _showSeekBackwardRipple = false);
      });
    } else {
      // Center 20%: Trigger tap action (Toggle play / chrome)
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        return GestureDetector(
          onTap: widget.onTap,
          onDoubleTapDown: (details) => _handleDoubleTapDown(details, constraints),
          onVerticalDragUpdate: (details) => _handleVerticalDrag(details, constraints),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Underlying Child (Video surface / canvas)
              widget.child,

              // Volume HUD Overlay (Right side of screen)
              if (_showVolumeHud)
                Align(
                  alignment: const Alignment(0.82, 0.0),
                  child: _buildVerticalHud(
                    icon: Icons.volume_up,
                    label: '${(_currentVolume * 100).toInt()}%',
                    fraction: (_currentVolume / 2.0).clamp(0.0, 1.0),
                    isOverdrive: _currentVolume > 1.0,
                    colors: colors,
                    vlcTheme: vlcTheme,
                  ),
                ),

              // Brightness HUD Overlay (Left side of screen)
              if (_showBrightnessHud)
                Align(
                  alignment: const Alignment(-0.82, 0.0),
                  child: _buildVerticalHud(
                    icon: Icons.brightness_6,
                    label: '${(_currentBrightness * 100).toInt()}%',
                    fraction: _currentBrightness.clamp(0.0, 1.0),
                    isOverdrive: false,
                    colors: colors,
                    vlcTheme: vlcTheme,
                  ),
                ),

              // Seek Forward +10s Animated Ripple
              if (_showSeekForwardRipple)
                Align(
                  alignment: const Alignment(0.65, 0.0),
                  child: _buildSeekRipple(
                    icon: Icons.fast_forward,
                    label: '+10s',
                    colors: colors,
                    vlcTheme: vlcTheme,
                  ),
                ),

              // Seek Backward -10s Animated Ripple
              if (_showSeekBackwardRipple)
                Align(
                  alignment: const Alignment(-0.65, 0.0),
                  child: _buildSeekRipple(
                    icon: Icons.fast_rewind,
                    label: '-10s',
                    colors: colors,
                    vlcTheme: vlcTheme,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerticalHud({
    required IconData icon,
    required String label,
    required double fraction,
    required bool isOverdrive,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
  }) {
    return Container(
      width: 48.0,
      height: 190.0,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border.withOpacity(0.6)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 18.0, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20.0,
            color: isOverdrive ? VlcColors.error : colors.accent.primary,
          ),
          const SizedBox(height: 10.0),
          // Vertical gauge bar
          Expanded(
            child: Container(
              width: 6.0,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(3.0),
              ),
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: isOverdrive ? VlcColors.error : colors.accent.primary,
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            label,
            style: vlcTheme.typography.monospaceTime.copyWith(
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              color: isOverdrive ? VlcColors.error : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekRipple({
    required IconData icon,
    required String label,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
  }) {
    return Container(
      width: 90.0,
      height: 90.0,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        shape: BoxShape.circle,
        border: Border.all(color: colors.accent.primary.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.accent.primary.withOpacity(0.3),
            blurRadius: 20.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28.0, color: colors.accent.primary),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: vlcTheme.typography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
