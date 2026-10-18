import 'package:flutter/material.dart';
import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Interactive button used inside TopPlayerBar with strict 6dp rectangular geometry
class VlcTopBarButton extends StatefulWidget {
  final Widget child;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final double width;
  final double height;

  const VlcTopBarButton({
    super.key,
    required this.child,
    this.tooltip,
    this.onPressed,
    this.isActive = false,
    this.width = 36.0,
    this.height = 36.0,
  });

  @override
  State<VlcTopBarButton> createState() => _VlcTopBarButtonState();
}

class _VlcTopBarButtonState extends State<VlcTopBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    final backgroundColor = widget.isActive
        ? colors.accent.subtleBackground
        : _isHovered
            ? colors.surfaceHover
            : Colors.transparent;

    final borderColor = widget.isActive
        ? colors.accent.subtleBorder
        : _isHovered
            ? colors.border
            : Colors.transparent;

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusSmall,
          border: Border.all(color: colors.border, width: 1.0),
        ),
        textStyle: vlcTheme.typography.bodySmall.copyWith(
          color: colors.textPrimary,
        ),
        child: button,
      );
    }

    return button;
  }
}

/// Unified VLC Application Menu Button
/// Displays the signature traffic cone icon and opens the consolidated modern menu.
class UnifiedMenuButton extends StatelessWidget {
  final VoidCallback? onOpenFile;
  final VoidCallback? onOpenStream;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onMenuAction;
  final ValueChanged<VlcThemeMode>? onThemeModeChanged;

  const UnifiedMenuButton({
    super.key,
    this.onOpenFile,
    this.onOpenStream,
    this.onOpenSettings,
    this.onMenuAction,
    this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return PopupMenuButton<String>(
      tooltip: 'VLC Menu',
      offset: const Offset(0, 42),
      shape: VlcGeometry.dialogShape,
      color: colors.surface,
      elevation: 12,
      onSelected: (value) {
        if (value == 'open_file' && onOpenFile != null) {
          onOpenFile!();
        } else if (value == 'open_stream' && onOpenStream != null) {
          onOpenStream!();
        } else if (value == 'settings' && onOpenSettings != null) {
          onOpenSettings!();
        } else if (value == 'theme_dark' && onThemeModeChanged != null) {
          onThemeModeChanged!(VlcThemeMode.dark);
        } else if (value == 'theme_oled' && onThemeModeChanged != null) {
          onThemeModeChanged!(VlcThemeMode.oled);
        } else if (value == 'theme_light' && onThemeModeChanged != null) {
          onThemeModeChanged!(VlcThemeMode.light);
        }
        if (onMenuAction != null) {
          onMenuAction!();
        }
      },
      itemBuilder: (context) => [
        _buildMenuHeader('MEDIA', colors, vlcTheme),
        _buildMenuItem('open_file', 'Open File...', 'Ctrl+O', colors, vlcTheme),
        _buildMenuItem('open_folder', 'Open Folder...', 'Ctrl+Shift+O', colors, vlcTheme),
        _buildMenuItem('open_stream', 'Open Network Stream...', 'Ctrl+N', colors, vlcTheme),
        const PopupMenuDivider(),
        _buildMenuHeader('PLAYBACK', colors, vlcTheme),
        _buildMenuItem('jump_time', 'Jump to Specific Time...', 'Ctrl+T', colors, vlcTheme),
        _buildMenuItem('speed', 'Speed Controls', '', colors, vlcTheme),
        const PopupMenuDivider(),
        _buildMenuHeader('AUDIO & VIDEO', colors, vlcTheme),
        _buildMenuItem('audio_tracks', 'Audio Track...', '', colors, vlcTheme),
        _buildMenuItem('equalizer', 'Equalizer (10-Band)...', '', colors, vlcTheme),
        _buildMenuItem('subtitles', 'Subtitles / Track...', 'V', colors, vlcTheme),
        const PopupMenuDivider(),
        _buildMenuHeader('THEME & APPEARANCE', colors, vlcTheme),
        _buildMenuItem('theme_dark', 'Dark Mode', '', colors, vlcTheme),
        _buildMenuItem('theme_oled', 'OLED Pure Black', '', colors, vlcTheme),
        _buildMenuItem('theme_light', 'Light Mode', '', colors, vlcTheme),
        const PopupMenuDivider(),
        _buildMenuHeader('TOOLS & VIEW', colors, vlcTheme),
        _buildMenuItem('hide_ui', 'Hide UI Completely', 'Ctrl+H', colors, vlcTheme),
        _buildMenuItem('settings', 'Preferences / Settings...', 'Ctrl+P', colors, vlcTheme),
      ],
      child: VlcTopBarButton(
        width: 38.0,
        height: 38.0,
        child: Row(
          mainAxisAlignment: MainAssistanceCenter,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Signature Orange Cone Icon
            CustomPaint(
              size: const Size(18, 18),
              painter: _TrafficConePainter(coneColor: colors.accent.primary),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuHeader(String text, VlcColors colors, VlcThemeData theme) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 26,
      child: Text(
        text,
        style: theme.typography.labelSmall.copyWith(
          color: colors.accent.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    String label,
    String shortcut,
    VlcColors colors,
    VlcThemeData theme,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.typography.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          if (shortcut.isNotEmpty)
            Text(
              shortcut,
              style: theme.typography.monospaceTime.copyWith(
                color: colors.textTertiary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper constant for centering
const MainAxisAlignment MainAssistanceCenter = MainAxisAlignment.center;

/// Folder Breadcrumb Trigger displaying `[Folder Name] › [Media Title]`.
/// Clicking navigates directly to the folder in the library view / drawer.
class FolderBreadcrumbTrigger extends StatefulWidget {
  final String? folderName;
  final String mediaTitle;
  final String? fullPath;
  final VoidCallback? onBreadcrumbTap;

  const FolderBreadcrumbTrigger({
    super.key,
    this.folderName,
    required this.mediaTitle,
    this.fullPath,
    this.onBreadcrumbTap,
  });

  @override
  State<FolderBreadcrumbTrigger> createState() => _FolderBreadcrumbTriggerState();
}

class _FolderBreadcrumbTriggerState extends State<FolderBreadcrumbTrigger> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    final content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onBreadcrumbTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: _isHovered ? colors.surfaceHover : Colors.transparent,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: _isHovered ? colors.border : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Folder icon
              VlcMonochromeIcon(
                VlcIconGlyph.folder,
                size: 16.0,
                color: _isHovered ? colors.accent.primary : colors.textSecondary,
              ),
              const SizedBox(width: 8.0),

              // Folder label
              if (widget.folderName != null && widget.folderName!.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    widget.folderName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vlcTheme.typography.bodyMedium.copyWith(
                      color: _isHovered ? colors.accent.primary : colors.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Text(
                    '›',
                    style: vlcTheme.typography.bodyLarge.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ],

              // Media Title
              Flexible(
                child: Text(
                  widget.mediaTitle.isNotEmpty ? widget.mediaTitle : 'No Media Open',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vlcTheme.typography.bodyLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.fullPath != null && widget.fullPath!.isNotEmpty) {
      return Tooltip(
        message: widget.fullPath!,
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusSmall,
          border: Border.all(color: colors.border, width: 1.0),
        ),
        textStyle: vlcTheme.typography.bodySmall.copyWith(
          color: colors.textPrimary,
        ),
        child: content,
      );
    }

    return content;
  }
}

/// Top Player Bar component for VLC Modern Redesign.
/// Height: 48dp (VlcGeometry.topPlayerBarHeight).
/// Layout:
/// - Left: UnifiedMenuButton (VLC Cone Menu)
/// - Center: FolderBreadcrumbTrigger ([Show Folder] › [Title])
/// - Right: Picture-in-Picture, Fullscreen, and Inspector toggle buttons
class TopPlayerBar extends StatelessWidget {
  final String? folderName;
  final String mediaTitle;
  final String? fullPath;
  final bool isFullscreen;
  final bool isPipActive;
  final bool isDrawerOpen;
  final VlcThemeMode? themeMode;
  final VoidCallback? onOpenFile;
  final VoidCallback? onOpenStream;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onBreadcrumbTap;
  final VoidCallback? onPipToggle;
  final VoidCallback? onFullscreenToggle;
  final VoidCallback? onInspectorToggle;
  final VoidCallback? onLibraryViewToggle;
  final bool isLibraryViewActive;
  final ValueChanged<VlcThemeMode>? onThemeModeChanged;
  final double leftSafeAreaInset;

  const TopPlayerBar({
    super.key,
    this.folderName,
    required this.mediaTitle,
    this.fullPath,
    this.isFullscreen = false,
    this.isPipActive = false,
    this.isDrawerOpen = false,
    this.themeMode,
    this.onOpenFile,
    this.onOpenStream,
    this.onOpenSettings,
    this.onBreadcrumbTap,
    this.onPipToggle,
    this.onFullscreenToggle,
    this.onInspectorToggle,
    this.onLibraryViewToggle,
    this.isLibraryViewActive = false,
    this.onThemeModeChanged,
    this.leftSafeAreaInset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final currentMode = themeMode ?? vlcTheme.mode;

    return Container(
      height: VlcGeometry.topPlayerBarHeight,
      padding: EdgeInsets.only(
        left: leftSafeAreaInset > 0 ? leftSafeAreaInset : VlcGeometry.space12,
        right: VlcGeometry.space12,
        top: 4.0,
        bottom: 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Unified VLC Menu Button
          UnifiedMenuButton(
            onOpenFile: onOpenFile,
            onOpenStream: onOpenStream,
            onOpenSettings: onOpenSettings,
            onThemeModeChanged: onThemeModeChanged,
          ),
          const SizedBox(width: 8.0),

          // 2. Folder Breadcrumb Trigger ([Folder] › [Title])
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FolderBreadcrumbTrigger(
                folderName: folderName,
                mediaTitle: mediaTitle,
                fullPath: fullPath,
                onBreadcrumbTap: onBreadcrumbTap,
              ),
            ),
          ),

          const SizedBox(width: 12.0),

          // 3. Right Action Cluster
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Theme mode toggle (Dark -> OLED -> Light -> Dark)
              if (onThemeModeChanged != null)
                VlcTopBarButton(
                  tooltip: _getThemeTooltip(currentMode),
                  onPressed: () {
                    final next = switch (currentMode) {
                      VlcThemeMode.dark => VlcThemeMode.oled,
                      VlcThemeMode.oled => VlcThemeMode.light,
                      VlcThemeMode.light => VlcThemeMode.dark,
                    };
                    onThemeModeChanged!(next);
                  },
                  child: VlcMonochromeIcon(
                    switch (currentMode) {
                      VlcThemeMode.dark => VlcIconGlyph.themeDark,
                      VlcThemeMode.oled => VlcIconGlyph.themeOled,
                      VlcThemeMode.light => VlcIconGlyph.themeLight,
                    },
                    size: 18.0,
                    color: colors.textPrimary,
                  ),
                ),

              if (onThemeModeChanged != null)
                const SizedBox(width: 6.0),

              // Picture-in-Picture toggle
              if (onPipToggle != null)
                VlcTopBarButton(
                  tooltip: 'Picture in Picture [P]',
                  isActive: isPipActive,
                  onPressed: onPipToggle,
                  child: VlcMonochromeIcon(
                    VlcIconGlyph.pictureInPicture,
                    size: 18.0,
                    color: isPipActive ? colors.accent.primary : colors.textPrimary,
                  ),
                ),

              const SizedBox(width: 6.0),

              // Fullscreen toggle
              if (onFullscreenToggle != null)
                VlcTopBarButton(
                  tooltip: isFullscreen ? 'Exit Fullscreen [F / Esc]' : 'Fullscreen [F]',
                  isActive: isFullscreen,
                  onPressed: onFullscreenToggle,
                  child: VlcMonochromeIcon(
                    isFullscreen ? VlcIconGlyph.exitFullscreen : VlcIconGlyph.fullscreen,
                    size: 18.0,
                    color: isFullscreen ? colors.accent.primary : colors.textPrimary,
                  ),
                ),

              const SizedBox(width: 6.0),

              // Inspector & Presets drawer toggle
              if (onInspectorToggle != null)
                VlcTopBarButton(
                  tooltip: 'Inspector & Presets [I]',
                  isActive: isDrawerOpen,
                  onPressed: onInspectorToggle,
                  child: VlcMonochromeIcon(
                    VlcIconGlyph.settings,
                    size: 18.0,
                    color: isDrawerOpen ? colors.accent.primary : colors.textPrimary,
                  ),
                ),

              if (onLibraryViewToggle != null) ...[
                const SizedBox(width: 6.0),
                VlcTopBarButton(
                  tooltip: 'Media Library View [L / Ctrl+L]',
                  isActive: isLibraryViewActive,
                  onPressed: onLibraryViewToggle,
                  child: VlcMonochromeIcon(
                    VlcIconGlyph.viewGrid,
                    size: 18.0,
                    color: isLibraryViewActive ? colors.accent.primary : colors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeTooltip(VlcThemeMode mode) {
    return switch (mode) {
      VlcThemeMode.dark => 'Theme: Dark (Click for OLED Pure Black)',
      VlcThemeMode.oled => 'Theme: OLED (Click for Light Mode)',
      VlcThemeMode.light => 'Theme: Light (Click for Dark Mode)',
    };
  }
}

// -----------------------------------------------------------------------------
// Traffic Cone Vector Painter (VLC Signature Icon)
// -----------------------------------------------------------------------------

class _TrafficConePainter extends CustomPainter {
  final Color coneColor;

  _TrafficConePainter({required this.coneColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintOrange = Paint()
      ..color = coneColor
      ..style = PaintingStyle.fill;

    final paintWhite = Paint()
      ..color = Colors.white.withOpacity(0.90)
      ..style = PaintingStyle.fill;

    final paintBase = Paint()
      ..color = coneColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Base rectangular plate
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.82, w * 0.80, h * 0.14),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(baseRect, paintBase);

    // Main cone body
    final conePath = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.76, h * 0.82)
      ..lineTo(w * 0.24, h * 0.82)
      ..close();
    canvas.drawPath(conePath, paintOrange);

    // Reflective white stripe 1 (lower)
    final stripe1 = Path()
      ..moveTo(w * 0.33, h * 0.60)
      ..lineTo(w * 0.67, h * 0.60)
      ..lineTo(w * 0.71, h * 0.72)
      ..lineTo(w * 0.29, h * 0.72)
      ..close();
    canvas.drawPath(stripe1, paintWhite);

    // Reflective white stripe 2 (upper)
    final stripe2 = Path()
      ..moveTo(w * 0.40, h * 0.35)
      ..lineTo(w * 0.60, h * 0.35)
      ..lineTo(w * 0.64, h * 0.47)
      ..lineTo(w * 0.36, h * 0.47)
      ..close();
    canvas.drawPath(stripe2, paintWhite);
  }

  @override
  bool shouldRepaint(covariant _TrafficConePainter oldDelegate) {
    return oldDelegate.coneColor != coneColor;
  }
}

