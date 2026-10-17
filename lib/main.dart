import 'package:flutter/material.dart';
import 'vlc_modern.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VlcModernApp());
}

class VlcModernApp extends StatefulWidget {
  const VlcModernApp({super.key});

  @override
  State<VlcModernApp> createState() => _VlcModernAppState();
}

class _VlcModernAppState extends State<VlcModernApp> {
  late final VlcThemeController _themeController;
  late final VlcPlayerController _playerController;
  late final AppShellController _shellController;

  String _mediaTitle = 'Big Buck Bunny (4K Remux)';
  String _folderName = 'Demo Media';
  String _fullPath = '/Users/Movies/Demo Media/Big Buck Bunny (4K Remux).mkv';
  bool _isFullscreen = false;
  bool _isPipActive = false;

  @override
  void initState() {
    super.initState();
    _themeController = VlcThemeController(mode: VlcThemeMode.dark);
    _themeController.addListener(_onThemeChanged);

    // Initialize VideoLAN C ABI Bridge Controller
    _playerController = VlcPlayerController();
    _shellController = AppShellController();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _themeController.dispose();
    _shellController.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _togglePip() {
    setState(() {
      _isPipActive = !_isPipActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentVlcTheme = _themeController.currentTheme;

    return MaterialApp(
      title: 'VLC Modern Redesign',
      debugShowCheckedModeBanner: false,
      theme: currentVlcTheme.toThemeData(),
      home: Builder(
        builder: (context) {
          final colors = currentVlcTheme.colors;

          return AppShell(
            playerController: _playerController,
            shellController: _shellController,
            isFullscreen: _isFullscreen,
            onFullscreenToggle: _toggleFullscreen,

            // Top Player Bar with Theme Switch, Breadcrumbs & Actions
            topBar: TopPlayerBar(
              folderName: _folderName,
              mediaTitle: _mediaTitle,
              fullPath: _fullPath,
              isFullscreen: _isFullscreen,
              isPipActive: _isPipActive,
              isDrawerOpen: _shellController.isDrawerOpen,
              themeMode: _themeController.mode,
              onThemeModeChanged: (mode) {
                _themeController.setThemeMode(mode);
              },
              onPipToggle: _togglePip,
              onFullscreenToggle: _toggleFullscreen,
              onInspectorToggle: () {
                _shellController.toggleDrawer(0);
              },
              onBreadcrumbTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening Folder Library: $_folderName'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: colors.surfaceVariant,
                  ),
                );
              },
            ),

            // Video Surface canvas (displays cone emblem when idle)
            videoSurface: Container(
              color: colors.background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large Signature VLC Cone
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: _VlcBigConePainter(coneColor: colors.accent.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'VLC Modern Redesign',
                      style: currentVlcTheme.typography.titleLarge.copyWith(
                        color: colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Powered by VideoLAN libVLC ${_playerController.vlcVersion}',
                      style: currentVlcTheme.typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Current Theme Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surfaceHover,
                        borderRadius: VlcGeometry.borderRadiusMedium,
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'Active Theme: ${_themeController.mode.name.toUpperCase()}  •  Accent: #FF8800',
                        style: currentVlcTheme.typography.monospaceTime.copyWith(
                          color: colors.accent.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4-Tab Inspector Drawer preview
            rightDrawer: Container(
              color: colors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inspector & Presets',
                        style: currentVlcTheme.typography.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _shellController.closeDrawer(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Tab 1: Subtitles (Synced)', style: currentVlcTheme.typography.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Tab 2: Audio & 10-Band EQ', style: currentVlcTheme.typography.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Tab 3: Video Shaders & Aspect', style: currentVlcTheme.typography.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Tab 4: Playback & Chapters', style: currentVlcTheme.typography.bodyMedium),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VlcBigConePainter extends CustomPainter {
  final Color coneColor;
  _VlcBigConePainter({required this.coneColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintOrange = Paint()..color = coneColor..style = PaintingStyle.fill;
    final paintWhite = Paint()..color = Colors.white.withOpacity(0.92)..style = PaintingStyle.fill;
    final paintBase = Paint()..color = coneColor.withOpacity(0.80)..style = PaintingStyle.fill;

    // Base rectangular plate
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.84, w * 0.80, h * 0.12),
      const Radius.circular(4.0),
    );
    canvas.drawRRect(baseRect, paintBase);

    // Main cone body
    final conePath = Path()
      ..moveTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.78, h * 0.84)
      ..lineTo(w * 0.22, h * 0.84)
      ..close();
    canvas.drawPath(conePath, paintOrange);

    // Reflective white stripe 1 (lower)
    final stripe1 = Path()
      ..moveTo(w * 0.32, h * 0.60)
      ..lineTo(w * 0.68, h * 0.60)
      ..lineTo(w * 0.72, h * 0.73)
      ..lineTo(w * 0.28, h * 0.73)
      ..close();
    canvas.drawPath(stripe1, paintWhite);

    // Reflective white stripe 2 (upper)
    final stripe2 = Path()
      ..moveTo(w * 0.40, h * 0.32)
      ..lineTo(w * 0.60, h * 0.32)
      ..lineTo(w * 0.64, h * 0.45)
      ..lineTo(w * 0.36, h * 0.45)
      ..close();
    canvas.drawPath(stripe2, paintWhite);
  }

  @override
  bool shouldRepaint(covariant _VlcBigConePainter oldDelegate) => oldDelegate.coneColor != coneColor;
}
