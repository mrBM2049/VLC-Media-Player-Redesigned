import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/vlc_theme.dart';

/// Notification pill model
class OsdPillItem {
  final String action;
  final String? shortcutKey;
  final VlcIconGlyph? icon;
  final Duration displayDuration;

  const OsdPillItem({
    required this.action,
    this.shortcutKey,
    this.icon,
    this.displayDuration = const Duration(milliseconds: 1500),
  });
}

/// Resume prompt data model
class ResumePromptData {
  final String mediaTitle;
  final Duration resumePosition;
  final VoidCallback onResume;
  final VoidCallback? onStartOver;
  final Duration autoDismissDuration;

  const ResumePromptData({
    required this.mediaTitle,
    required this.resumePosition,
    required this.onResume,
    this.onStartOver,
    this.autoDismissDuration = const Duration(seconds: 5),
  });
}

/// Controller coordinating OSD notifications and resume prompts
class OsdNotificationController extends ChangeNotifier {
  OsdPillItem? _activePill;
  ResumePromptData? _activeResumePrompt;
  Timer? _pillTimer;

  OsdPillItem? get activePill => _activePill;
  ResumePromptData? get activeResumePrompt => _activeResumePrompt;

  void showPill({
    required String action,
    String? shortcutKey,
    VlcIconGlyph? icon,
    Duration displayDuration = const Duration(milliseconds: 1500),
  }) {
    _pillTimer?.cancel();
    _activePill = OsdPillItem(
      action: action,
      shortcutKey: shortcutKey,
      icon: icon,
      displayDuration: displayDuration,
    );
    notifyListeners();

    _pillTimer = Timer(displayDuration, () {
      _activePill = null;
      notifyListeners();
    });
  }

  void showResumePrompt({
    required String mediaTitle,
    required Duration resumePosition,
    required VoidCallback onResume,
    VoidCallback? onStartOver,
    Duration autoDismissDuration = const Duration(seconds: 5),
  }) {
    _activeResumePrompt = ResumePromptData(
      mediaTitle: mediaTitle,
      resumePosition: resumePosition,
      onResume: onResume,
      onStartOver: onStartOver,
      autoDismissDuration: autoDismissDuration,
    );
    notifyListeners();
  }

  void dismissPill() {
    _pillTimer?.cancel();
    if (_activePill != null) {
      _activePill = null;
      notifyListeners();
    }
  }

  void dismissResumePrompt() {
    if (_activeResumePrompt != null) {
      _activeResumePrompt = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pillTimer?.cancel();
    super.dispose();
  }
}

/// OSD Notification Layer rendering shortcut-aware top-right pills
/// and bottom-center "Continue Watching" prompts.
class OSDNotificationLayer extends StatelessWidget {
  final OsdNotificationController controller;

  const OSDNotificationLayer({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pill = controller.activePill;
        final resume = controller.activeResumePrompt;

        return Stack(
          fit: StackFit.expand,
          children: [
            // -----------------------------------------------------------------
            // 1. Top-Right Shortcut Pill (IgnorePointer pass-through)
            // -----------------------------------------------------------------
            if (pill != null)
              Positioned(
                top: VlcGeometry.topPlayerBarHeight + 16.0,
                right: 20.0,
                child: IgnorePointer(
                  child: _OsdPillWidget(pill: pill),
                ),
              ),

            // -----------------------------------------------------------------
            // 2. Bottom-Center 5s "Continue Watching" Prompt
            // -----------------------------------------------------------------
            if (resume != null)
              Positioned(
                bottom: VlcGeometry.bottomTransportRowHeight + VlcGeometry.thickSeekBarHeightNormal + 24.0,
                left: 0,
                right: 0,
                child: Center(
                  child: ContinueWatchingPrompt(
                    data: resume,
                    onDismiss: controller.dismissResumePrompt,
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
// Top-Right Shortcut Pill Widget
// -----------------------------------------------------------------------------

class _OsdPillWidget extends StatelessWidget {
  final OsdPillItem pill;

  const _OsdPillWidget({required this.pill});

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20.0 * (1.0 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.92),
          borderRadius: VlcGeometry.borderRadiusMedium,
          border: Border.all(
            color: colors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.40),
              blurRadius: 16.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (pill.icon != null) ...[
              VlcMonochromeIcon(
                pill.icon!,
                size: 16.0,
                color: colors.accent.primary,
              ),
              const SizedBox(width: 8.0),
            ],

            // Action Text
            Text(
              pill.action,
              style: vlcTheme.typography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Bracketed Shortcut Key e.g. [↑] or [Space]
            if (pill.shortcutKey != null && pill.shortcutKey!.isNotEmpty) ...[
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: VlcGeometry.borderRadiusSmall,
                  border: Border.all(color: colors.borderSubtle, width: 0.8),
                ),
                child: Text(
                  pill.shortcutKey!,
                  style: vlcTheme.typography.monospaceTime.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: colors.accent.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom-Center 5s "Continue Watching" Prompt
// -----------------------------------------------------------------------------

class ContinueWatchingPrompt extends StatefulWidget {
  final ResumePromptData data;
  final VoidCallback onDismiss;

  const ContinueWatchingPrompt({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<ContinueWatchingPrompt> createState() => _ContinueWatchingPromptState();
}

class _ContinueWatchingPromptState extends State<ContinueWatchingPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drainController;

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

  @override
  void initState() {
    super.initState();
    _drainController = AnimationController(
      vsync: this,
      duration: widget.data.autoDismissDuration,
    );

    _drainController.forward();
    _drainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _drainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final timeStr = _formatDuration(widget.data.resumePosition);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * scale),
          child: Opacity(
            opacity: scale,
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480.0),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.96),
          borderRadius: VlcGeometry.borderRadiusLarge,
          border: Border.all(
            color: colors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 24.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // Clock / Cone Emblem
                  VlcMonochromeIcon(
                    VlcIconGlyph.bookmark,
                    size: 20.0,
                    color: colors.accent.primary,
                  ),
                  const SizedBox(width: 12.0),

                  // Message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue watching from $timeStr?',
                          style: vlcTheme.typography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (widget.data.mediaTitle.isNotEmpty)
                          Text(
                            widget.data.mediaTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: vlcTheme.typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12.0),

                  // "Resume" prominent button (Cone Orange)
                  GestureDetector(
                    onTap: () {
                      widget.data.onResume();
                      widget.onDismiss();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                      decoration: BoxDecoration(
                        color: colors.accent.primary,
                        borderRadius: VlcGeometry.borderRadiusMedium,
                      ),
                      child: Text(
                        'Resume',
                        style: vlcTheme.typography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8.0),

                  // "Start Over" button
                  if (widget.data.onStartOver != null) ...[
                    GestureDetector(
                      onTap: () {
                        widget.data.onStartOver!();
                        widget.onDismiss();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: VlcGeometry.borderRadiusMedium,
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Text(
                          'Start Over',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                  ],

                  // Dismiss [X]
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: VlcMonochromeIcon(
                        VlcIconGlyph.close,
                        size: 16.0,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5-Second Linear Countdown Progress Bar (Draining)
            AnimatedBuilder(
              animation: _drainController,
              builder: (context, _) {
                final remainingFraction = 1.0 - _drainController.value;
                return Container(
                  height: 2.5,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  color: colors.surfaceVariant,
                  child: FractionallySizedBox(
                    widthFactor: remainingFraction,
                    child: Container(
                      color: colors.accent.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
