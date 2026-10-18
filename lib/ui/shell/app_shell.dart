import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../src/controller/vlc_player_controller.dart';
import '../../theme/vlc_theme.dart';

/// Controller coordinating chrome visibility, auto-hide timers, drawer states,
/// and shortcut locks for the VLC Modern AppShell.
class AppShellController extends ChangeNotifier {
  final Duration desktopInactivityDuration;
  final Duration mobileInactivityDuration;
  final bool keepVisibleWhenPaused;

  Timer? _inactivityTimer;
  bool _isUiVisible = true;
  bool _isLockedHidden = false;
  bool _isDrawerOpen = false;
  bool _isQueueOpen = false;
  int _activeDrawerTab = 0;
  bool _isHoveringControls = false;

  AppShellController({
    this.desktopInactivityDuration = const Duration(milliseconds: 1800),
    this.mobileInactivityDuration = const Duration(milliseconds: 3000),
    this.keepVisibleWhenPaused = true,
  });

  bool get isUiVisible => _isUiVisible && !_isLockedHidden;
  bool get isLockedHidden => _isLockedHidden;
  bool get isDrawerOpen => _isDrawerOpen;
  bool get isQueueOpen => _isQueueOpen;
  int get activeDrawerTab => _activeDrawerTab;
  bool get isHoveringControls => _isHoveringControls;

  Duration get currentInactivityDuration {
    if (kIsWeb) return desktopInactivityDuration;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return mobileInactivityDuration;
      }
    } catch (_) {}
    return desktopInactivityDuration;
  }

  /// Show the chrome overlays and reset the inactivity timer
  void showUi({bool restartTimer = true}) {
    if (_isLockedHidden) return;

    if (!_isUiVisible) {
      _isUiVisible = true;
      notifyListeners();
    }

    if (restartTimer) {
      resetInactivityTimer();
    }
  }

  /// Hide the chrome overlays
  void hideUi() {
    if (_isHoveringControls || _isDrawerOpen || _isQueueOpen) return;

    if (_isUiVisible) {
      _isUiVisible = false;
      _inactivityTimer?.cancel();
      notifyListeners();
    }
  }

  /// Toggle chrome overlay visibility manually
  void toggleUi() {
    if (_isLockedHidden) {
      unlockHide();
      return;
    }
    if (_isUiVisible) {
      hideUi();
    } else {
      showUi();
    }
  }

  /// Toggle "Hide UI Completely" mode (Ctrl+H / Cmd+H)
  void toggleLockHide() {
    _isLockedHidden = !_isLockedHidden;
    if (_isLockedHidden) {
      _isUiVisible = false;
      _isDrawerOpen = false;
      _isQueueOpen = false;
      _inactivityTimer?.cancel();
    } else {
      _isUiVisible = true;
      resetInactivityTimer();
    }
    notifyListeners();
  }

  void unlockHide() {
    if (_isLockedHidden) {
      _isLockedHidden = false;
      _isUiVisible = true;
      resetInactivityTimer();
      notifyListeners();
    }
  }

  /// Reset the inactivity countdown
  void resetInactivityTimer([bool isPlaying = true]) {
    _inactivityTimer?.cancel();

    if (_isLockedHidden) return;

    // Keep visible if user is interacting with controls, drawer is open, or paused
    if (_isHoveringControls || _isDrawerOpen || _isQueueOpen || (!isPlaying && keepVisibleWhenPaused)) {
      if (!_isUiVisible) {
        _isUiVisible = true;
        notifyListeners();
      }
      return;
    }

    _inactivityTimer = Timer(currentInactivityDuration, () {
      if (!_isHoveringControls && !_isDrawerOpen && !_isQueueOpen) {
        hideUi();
      }
    });
  }

  void setHoveringControls(bool hovering, [bool isPlaying = true]) {
    _isHoveringControls = hovering;
    if (hovering) {
      _inactivityTimer?.cancel();
      if (!_isUiVisible && !_isLockedHidden) {
        _isUiVisible = true;
        notifyListeners();
      }
    } else {
      resetInactivityTimer(isPlaying);
    }
  }

  void openDrawer(int tabIndex) {
    _activeDrawerTab = tabIndex;
    _isDrawerOpen = true;
    _isQueueOpen = false;
    _isUiVisible = true;
    _inactivityTimer?.cancel();
    notifyListeners();
  }

  void closeDrawer([bool isPlaying = true]) {
    if (_isDrawerOpen) {
      _isDrawerOpen = false;
      notifyListeners();
      resetInactivityTimer(isPlaying);
    }
  }

  void toggleDrawer(int tabIndex, [bool isPlaying = true]) {
    if (_isDrawerOpen && _activeDrawerTab == tabIndex) {
      closeDrawer(isPlaying);
    } else {
      openDrawer(tabIndex);
    }
  }

  void openQueue() {
    _isQueueOpen = true;
    _isDrawerOpen = false;
    _isUiVisible = true;
    _inactivityTimer?.cancel();
    notifyListeners();
  }

  void closeQueue([bool isPlaying = true]) {
    if (_isQueueOpen) {
      _isQueueOpen = false;
      notifyListeners();
      resetInactivityTimer(isPlaying);
    }
  }

  void toggleQueue([bool isPlaying = true]) {
    if (_isQueueOpen) {
      closeQueue(isPlaying);
    } else {
      openQueue();
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

/// Standalone, Native Cross-Platform AppShell for VLC Modern Redesign.
/// Layered architecture supporting:
/// - 4K Video surface (Metal / D3D11 / AWindow)
/// - Desktop hover auto-hide (1.8s) & Mobile tap auto-hide (3.0s)
/// - Hide UI Completely (Ctrl+H / Cmd+H) lock mode
/// - TopPlayerBar, BottomTransportRow, OSDNotificationLayer, and InspectorSidebar slots
class AppShell extends StatefulWidget {
  final VlcPlayerController playerController;
  final Widget videoSurface;
  final Widget? topBar;
  final Widget? bottomControls;
  final Widget? osdLayer;
  final Widget? rightDrawer;
  final Widget? queueDrawer;
  final Widget? centerPrompt;
  final AppShellController? shellController;
  final VoidCallback? onFullscreenToggle;
  final VoidCallback? onOpenFile;
  final bool isFullscreen;

  const AppShell({
    super.key,
    required this.playerController,
    required this.videoSurface,
    this.topBar,
    this.bottomControls,
    this.osdLayer,
    this.rightDrawer,
    this.queueDrawer,
    this.centerPrompt,
    this.shellController,
    this.onFullscreenToggle,
    this.onOpenFile,
    this.isFullscreen = false,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  late final AppShellController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  StreamSubscription<VlcPlayerState>? _stateSubscription;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.shellController != null) {
      _controller = widget.shellController!;
    } else {
      _controller = AppShellController();
      _ownsController = true;
    }

    _controller.addListener(_onControllerChanged);

    _stateSubscription = widget.playerController.stateStream.listen((state) {
      final playing = state == VlcPlayerState.playing;
      if (mounted && playing != _isPlaying) {
        setState(() {
          _isPlaying = playing;
        });
        _controller.resetInactivityTimer(_isPlaying);
      }
    });

    // Initial countdown
    _controller.resetInactivityTimer(_isPlaying);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePointerHover(PointerHoverEvent event) {
    if (_controller.isLockedHidden) return;
    _controller.showUi(restartTimer: true);
  }

  void _handleTap() {
    _controller.toggleUi();
  }

  void _handleDoubleTap() {
    if (widget.onFullscreenToggle != null) {
      widget.onFullscreenToggle!();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isMetaOrControl = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    // Ctrl+H or Cmd+H: Toggle "Hide UI Completely"
    if (isMetaOrControl && event.logicalKey == LogicalKeyboardKey.keyH) {
      _controller.toggleLockHide();
      return KeyEventResult.handled;
    }

    // Ctrl+O or Cmd+O: Open File
    if (isMetaOrControl && event.logicalKey == LogicalKeyboardKey.keyO) {
      if (widget.onOpenFile != null) {
        widget.onOpenFile!();
        return KeyEventResult.handled;
      }
    }

    // Space: Toggle Play/Pause
    if (event.logicalKey == LogicalKeyboardKey.space) {
      widget.playerController.togglePlay();
      _controller.showUi(restartTimer: true);
      return KeyEventResult.handled;
    }

    // F: Toggle Fullscreen
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      if (widget.onFullscreenToggle != null) {
        widget.onFullscreenToggle!();
        return KeyEventResult.handled;
      }
    }

    // Q: Toggle Play Queue Drawer
    if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      _controller.toggleQueue(_isPlaying);
      return KeyEventResult.handled;
    }

    // Escape: Close drawer, close queue, or exit fullscreen
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_controller.isQueueOpen) {
        _controller.closeQueue(_isPlaying);
        return KeyEventResult.handled;
      }
      if (_controller.isDrawerOpen) {
        _controller.closeDrawer(_isPlaying);
        return KeyEventResult.handled;
      }
      if (widget.isFullscreen && widget.onFullscreenToggle != null) {
        widget.onFullscreenToggle!();
        return KeyEventResult.handled;
      }
    }

    // Arrow keys: Seeking & Volume
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final curTime = widget.playerController.time.inMilliseconds;
      widget.playerController.setTime(curTime + 10000);
      _controller.showUi(restartTimer: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final curTime = widget.playerController.time.inMilliseconds;
      widget.playerController.setTime((curTime - 10000).clamp(0, double.infinity).toInt());
      _controller.showUi(restartTimer: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final curVol = widget.playerController.volume;
      widget.playerController.setVolume((curVol + 5).clamp(0, 200));
      _controller.showUi(restartTimer: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final curVol = widget.playerController.volume;
      widget.playerController.setVolume((curVol - 5).clamp(0, 200));
      _controller.showUi(restartTimer: true);
      return KeyEventResult.handled;
    }

    // M: Toggle Mute
    if (event.logicalKey == LogicalKeyboardKey.keyM) {
      widget.playerController.toggleMute();
      _controller.showUi(restartTimer: true);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final isUiVisible = _controller.isUiVisible;

    // On desktop, hide mouse cursor if UI auto-hides and video is playing
    final hideCursor = !isUiVisible && _isPlaying;
    final mouseCursor = hideCursor ? SystemMouseCursors.none : SystemMouseCursors.basic;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: mouseCursor,
        onHover: _handlePointerHover,
        child: Scaffold(
          backgroundColor: vlcTheme.colors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ---------------------------------------------------------------
              // Layer 0: Hardware Video Surface
              // ---------------------------------------------------------------
              widget.videoSurface,

              // ---------------------------------------------------------------
              // Layer 1: Gesture / Inactivity Trigger Area
              // ---------------------------------------------------------------
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _handleTap,
                  onDoubleTap: _handleDoubleTap,
                ),
              ),

              // ---------------------------------------------------------------
              // Layer 2: Top Player Bar Slot (Slide & Fade)
              // ---------------------------------------------------------------
              if (widget.topBar != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: MouseRegion(
                    onEnter: (_) => _controller.setHoveringControls(true, _isPlaying),
                    onExit: (_) => _controller.setHoveringControls(false, _isPlaying),
                    child: AnimatedSlide(
                      offset: isUiVisible ? Offset.zero : const Offset(0, -1.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: isUiVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xD90D0D0F), // 85% opacity dark scrim
                                Color(0x660D0D0F), // 40%
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.6, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: widget.topBar!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ---------------------------------------------------------------
              // Layer 3: Bottom Transport Row & Seek Bar Slot (Slide & Fade)
              // ---------------------------------------------------------------
              if (widget.bottomControls != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: MouseRegion(
                    onEnter: (_) => _controller.setHoveringControls(true, _isPlaying),
                    onExit: (_) => _controller.setHoveringControls(false, _isPlaying),
                    child: AnimatedSlide(
                      offset: isUiVisible ? Offset.zero : const Offset(0, 1.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: isUiVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0xF20D0D0F), // 95% opacity bottom dark scrim
                                Color(0x990D0D0F), // 60%
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: widget.bottomControls!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ---------------------------------------------------------------
              // Layer 4: OSD Notification Layer Slot (Pill shortcuts)
              // ---------------------------------------------------------------
              if (widget.osdLayer != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: widget.osdLayer!,
                  ),
                ),

              // ---------------------------------------------------------------
              // Layer 5: Optional Center Prompt (e.g., "Continue Watching")
              // ---------------------------------------------------------------
              if (widget.centerPrompt != null && isUiVisible)
                Positioned(
                  bottom: VlcGeometry.bottomTransportRowHeight + 24.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: widget.centerPrompt!,
                  ),
                ),

              // ---------------------------------------------------------------
              // Layer 6: Right 4-Tab Inspector Drawer (Desktop 340dp)
              // ---------------------------------------------------------------
              if (widget.rightDrawer != null)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: VlcGeometry.inspectorDrawerWidth,
                  child: AnimatedSlide(
                    offset: _controller.isDrawerOpen ? Offset.zero : const Offset(1.0, 0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: widget.rightDrawer!,
                  ),
                ),

              // ---------------------------------------------------------------
              // Layer 7: Temporary Playback Queue Drawer (Desktop 340dp)
              // ---------------------------------------------------------------
              if (widget.queueDrawer != null)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: VlcGeometry.inspectorDrawerWidth,
                  child: AnimatedSlide(
                    offset: _controller.isQueueOpen ? Offset.zero : const Offset(1.0, 0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: widget.queueDrawer!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

