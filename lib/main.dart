import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models/subtitle_models.dart';
import 'models/audio_models.dart';
import 'ui/popups/subtitle_quick_popup.dart';
import 'ui/popups/add_subtitles_modal.dart';
import 'ui/popups/audio_quick_popup.dart';
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
  late final OsdNotificationController _osdController;
  late final QueueController _queueController;

  String _mediaTitle = 'Big Buck Bunny (4K Remux)';
  String _folderName = 'Demo Media';
  String _fullPath = '/Users/Movies/Demo Media/Big Buck Bunny (4K Remux).mkv';
  bool _isFullscreen = false;
  bool _isPipActive = false;
  bool _isPlaying = false;
  Duration _position = const Duration(minutes: 14, seconds: 28);
  Duration _duration = const Duration(hours: 2, minutes: 15, seconds: 40);
  int _volume = 100;
  bool _isMuted = false;
  double _playbackRate = 1.0;
  VlcRepeatMode _repeatMode = VlcRepeatMode.off;
  bool _isShuffle = false;
  int _selectedSubTrack = 1;
  Duration _subDelay = Duration.zero;

  final List<VlcSubtitleTrack> _demoSubTracks = const [
    VlcSubtitleTrack(id: 1, name: 'Track 1: English [Full/SDH]', language: 'en'),
    VlcSubtitleTrack(id: 2, name: 'Track 2: Spanish [Latin]', language: 'es'),
    VlcSubtitleTrack(id: 3, name: 'Track 3: French [Parisian]', language: 'fr'),
    VlcSubtitleTrack(id: 4, name: 'Track 4: Japanese [Original]', language: 'ja'),
  ];

  int _selectedAudioTrack = 1;
  String _selectedAudioDevice = 'built_in';
  Duration _audioDelay = Duration.zero;

  final List<VlcAudioTrack> _demoAudioTracks = const [
    VlcAudioTrack(id: 1, name: 'Track 1: English (5.1 DTS-HD MA)', language: 'en', codec: 'DTS 5.1', channels: 6),
    VlcAudioTrack(id: 2, name: 'Track 2: English (Director Commentary)', language: 'en', codec: 'AAC Stereo', channels: 2),
    VlcAudioTrack(id: 3, name: 'Track 3: Spanish (Dubbed 5.1)', language: 'es', codec: 'AC3 5.1', channels: 6),
    VlcAudioTrack(id: 4, name: 'Track 4: Japanese (Original Stereo)', language: 'ja', codec: 'FLAC 2.0', channels: 2),
  ];

  final List<VlcAudioOutputDevice> _demoAudioDevices = const [
    VlcAudioOutputDevice(id: 'default', name: 'System Default Output', type: VlcAudioDeviceType.systemDefault),
    VlcAudioOutputDevice(id: 'built_in', name: 'MacBook Air Speakers', type: VlcAudioDeviceType.speakers),
    VlcAudioOutputDevice(id: 'airpods', name: 'AirPods Max (Spatial Audio)', type: VlcAudioDeviceType.bluetooth),
    VlcAudioOutputDevice(id: 'hdmi', name: 'External 4K Monitor HDMI Audio', type: VlcAudioDeviceType.hdmi),
  ];

  @override
  void initState() {
    super.initState();
    _themeController = VlcThemeController(mode: VlcThemeMode.dark);
    _themeController.addListener(_onThemeChanged);

    // Initialize VideoLAN C ABI Bridge Controller
    _playerController = VlcPlayerController();
    _shellController = AppShellController();
    _osdController = OsdNotificationController();

    // Initialize In-Memory Playback Queue
    _queueController = QueueController(
      initialItems: const [
        QueueItem(
          id: 'q1',
          mrl: '/Users/Movies/Demo Media/Big Buck Bunny (4K Remux).mkv',
          title: 'Big Buck Bunny (4K Remux)',
          artist: 'Blender Foundation • 4K 60fps',
          duration: Duration(hours: 2, minutes: 15, seconds: 40),
          isPlaying: true,
        ),
        QueueItem(
          id: 'q2',
          mrl: '/Users/Movies/Demo Media/Elephants Dream (Open Movie).mkv',
          title: 'Elephants Dream (Open Movie)',
          artist: 'Orange Open Movie Project',
          duration: Duration(minutes: 10, seconds: 54),
        ),
        QueueItem(
          id: 'q3',
          mrl: '/Users/Movies/Demo Media/Sintel (4K HDR Master).mkv',
          title: 'Sintel (4K HDR Master)',
          artist: 'Blender Animation Studio',
          duration: Duration(minutes: 15, seconds: 22),
        ),
        QueueItem(
          id: 'q4',
          mrl: '/Users/Movies/Demo Media/Tears of Steel (VFX Remaster).mkv',
          title: 'Tears of Steel (VFX Remaster)',
          artist: 'Mango Open Movie Project',
          duration: Duration(minutes: 12, seconds: 14),
        ),
        QueueItem(
          id: 'q5',
          mrl: '/Users/Movies/Demo Media/Cosmos Laundromat (First Cycle).mkv',
          title: 'Cosmos Laundromat (First Cycle)',
          artist: 'Gooseberry Open Movie',
          duration: Duration(minutes: 12, seconds: 10),
        ),
      ],
      initialIndex: 0,
    );

    // Trigger initial resume prompt preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _osdController.showResumePrompt(
        mediaTitle: _mediaTitle,
        resumePosition: const Duration(minutes: 14, seconds: 28),
        onResume: () {
          setState(() => _position = const Duration(minutes: 14, seconds: 28));
          _osdController.showPill(
            action: 'Resumed at 14:28',
            shortcutKey: 'Space',
            icon: VlcIconGlyph.play,
          );
        },
        onStartOver: () {
          setState(() => _position = Duration.zero);
          _osdController.showPill(
            action: 'Started Over',
            shortcutKey: '0',
            icon: VlcIconGlyph.previous,
          );
        },
      );
    });
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _themeController.dispose();
    _shellController.dispose();
    _osdController.dispose();
    _queueController.dispose();
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
            osdLayer: OSDNotificationLayer(controller: _osdController),

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
                _osdController.showPill(
                  action: 'Theme: ${mode.name.toUpperCase()}',
                  shortcutKey: 'T',
                  icon: VlcIconGlyph.themeDark,
                );
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

            // Bottom Control Area: Thick Seek Bar + Transport Row
            bottomControls: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edge-to-Edge Thick Seek Bar (10dp -> 16dp on hover)
                ThickSeekBar(
                  position: _position,
                  duration: _duration,
                  bufferProgress: 0.65, // simulated 65% streaming buffer
                  chapters: const [
                    ChapterTick(fraction: 0.15, title: 'Chapter 1: Prologue', time: Duration(minutes: 20)),
                    ChapterTick(fraction: 0.40, title: 'Chapter 2: Mountain Waves', time: Duration(minutes: 54)),
                    ChapterTick(fraction: 0.70, title: 'Chapter 3: The Black Hole', time: Duration(hours: 1, minutes: 35)),
                    ChapterTick(fraction: 0.90, title: 'Chapter 4: Epilogue', time: Duration(hours: 2, minutes: 02)),
                  ],
                  waveformSamples: List.generate(120, (i) => (math.sin(i * 0.2).abs() * 0.7) + 0.2),
                  onSeek: (targetTime) {
                    setState(() => _position = targetTime);
                    _playerController.setTime(targetTime.inMilliseconds);
                  },
                ),

                // Primary Bottom Transport Row
                BottomTransportRow(
                  isPlaying: _isPlaying,
                  position: _position,
                  duration: _duration,
                  volume: _volume,
                  isMuted: _isMuted,
                  playbackRate: _playbackRate,
                  repeatMode: _repeatMode,
                  isShuffle: _isShuffle,
                  onPlayPause: () {
                    setState(() => _isPlaying = !_isPlaying);
                  },
                  onPrevious: () {
                    setState(() => _position = Duration.zero);
                  },
              onNext: () {
                setState(() => _position = _duration);
              },
              onStop: () {
                setState(() {
                  _isPlaying = false;
                  _position = Duration.zero;
                });
              },
              onVolumeChanged: (vol) {
                setState(() => _volume = vol);
                _playerController.setVolume(vol);
                _osdController.showPill(
                  action: vol > 100 ? 'Volume $vol% (Overdrive)' : 'Volume $vol%',
                  shortcutKey: '↑/↓',
                  icon: vol > 100 ? VlcIconGlyph.volumeCone : VlcIconGlyph.volumeHigh,
                );
              },
              onToggleMute: () {
                setState(() => _isMuted = !_isMuted);
                _playerController.toggleMute();
                _osdController.showPill(
                  action: _isMuted ? 'Muted' : 'Unmuted (${_volume}%)',
                  shortcutKey: 'M',
                  icon: _isMuted ? VlcIconGlyph.volumeMute : VlcIconGlyph.volumeHigh,
                );
              },
              onRateChanged: (rate) {
                setState(() => _playbackRate = rate);
                _playerController.setRate(rate);
                _osdController.showPill(
                  action: 'Playback Speed: ${rate.toStringAsFixed(2)}x',
                  shortcutKey: '>',
                  icon: VlcIconGlyph.speed,
                );
              },
              onSubtitlesTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black45,
                  builder: (dialogCtx) => Center(
                    child: SubtitleQuickPopup(
                      tracks: _demoSubTracks,
                      selectedTrackId: _selectedSubTrack,
                      currentDelay: _subDelay,
                      onSelectTrack: (id) {
                        setState(() => _selectedSubTrack = id);
                        _playerController.setSubtitleTrack(id);
                        _osdController.showPill(
                          action: id == -1 ? 'Subtitles Disabled' : 'Subtitle Track $id Selected',
                          shortcutKey: 'S',
                          icon: VlcIconGlyph.subtitles,
                        );
                        Navigator.of(dialogCtx).pop();
                      },
                      onDelayChanged: (d) {
                        setState(() => _subDelay = d);
                        _playerController.setSubtitleDelay(d);
                        _osdController.showPill(
                          action: 'Sub Delay: ${d.inMilliseconds} ms',
                          shortcutKey: 'G/H',
                          icon: VlcIconGlyph.subtitles,
                        );
                      },
                      onOpenAddSubtitles: () {
                        Navigator.of(dialogCtx).pop();
                        showDialog(
                          context: context,
                          barrierColor: Colors.black54,
                          builder: (modalCtx) => AddSubtitlesModal(
                            currentVideoPath: _fullPath,
                            folderVideoPaths: [
                              _fullPath,
                              '/Users/Movies/Demo Media/Episode 02.mkv',
                              '/Users/Movies/Demo Media/Episode 03.mkv',
                            ],
                            onApplySingleSubtitle: (path) {
                              _playerController.addSubtitleFile(path, select: true);
                              _osdController.showPill(
                                action: 'Loaded: ${path.split(RegExp(r"[\\/]")).last}',
                                shortcutKey: 'Ctrl+O',
                                icon: VlcIconGlyph.subtitles,
                              );
                            },
                            onApplyBatchSubtitles: (matches) {
                              for (final m in matches) {
                                _playerController.addSubtitleFile(m.subtitlePath, select: false);
                              }
                              _osdController.showPill(
                                action: 'Batch Linked ${matches.length} Subtitles',
                                shortcutKey: 'Ctrl+Shift+S',
                                icon: VlcIconGlyph.subtitles,
                              );
                            },
                          ),
                        );
                      },
                      onClose: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ),
                );
              },
              onAudioTrackTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black45,
                  builder: (dialogCtx) => Center(
                    child: AudioQuickPopup(
                      tracks: _demoAudioTracks,
                      selectedTrackId: _selectedAudioTrack,
                      devices: _demoAudioDevices,
                      selectedDeviceId: _selectedAudioDevice,
                      currentDelay: _audioDelay,
                      onSelectTrack: (id) {
                        setState(() => _selectedAudioTrack = id);
                        _playerController.setAudioTrack(id);
                        _osdController.showPill(
                          action: id == -1 ? 'Audio Disabled' : 'Audio Track $id Active',
                          shortcutKey: 'B',
                          icon: VlcIconGlyph.audioTrack,
                        );
                        Navigator.of(dialogCtx).pop();
                      },
                      onSelectDevice: (devId) {
                        setState(() => _selectedAudioDevice = devId);
                        _playerController.setAudioDevice(devId);
                        final dev = _demoAudioDevices.firstWhere(
                          (d) => d.id == devId,
                          orElse: () => _demoAudioDevices.first,
                        );
                        _osdController.showPill(
                          action: 'Device: ${dev.name}',
                          shortcutKey: 'Audio',
                          icon: VlcIconGlyph.audioTrack,
                        );
                      },
                      onDelayChanged: (d) {
                        setState(() => _audioDelay = d);
                        _playerController.setAudioDelay(d);
                        _osdController.showPill(
                          action: 'Audio Delay: ${d.inMilliseconds} ms',
                          shortcutKey: 'J/K',
                          icon: VlcIconGlyph.audioTrack,
                        );
                      },
                      onOpenEqualizer: () {
                        Navigator.of(dialogCtx).pop();
                        _shellController.toggleDrawer(1); // Open Tab 1: EQ
                      },
                      onClose: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ),
                );
              },
              onEqualizerTap: () {
                _shellController.toggleDrawer(1); // Open Tab 1: EQ
              },
              onRepeatToggle: () {
                setState(() {
                  _repeatMode = switch (_repeatMode) {
                    VlcRepeatMode.off => VlcRepeatMode.all,
                    VlcRepeatMode.all => VlcRepeatMode.one,
                    VlcRepeatMode.one => VlcRepeatMode.off,
                  };
                });
              },
              onShuffleToggle: () {
                setState(() => _isShuffle = !_isShuffle);
              },
              isQueueOpen: _shellController.isQueueOpen,
              onQueueTap: () {
                _shellController.toggleQueue();
                _osdController.showPill(
                  action: _shellController.isQueueOpen ? 'Queue Drawer' : 'Queue Closed',
                  shortcutKey: 'Q',
                  icon: VlcIconGlyph.queue,
                );
              },
            ),
          ],
        ),

        // Temporary Playback Queue Drawer
        queueDrawer: QueueDrawer(
          controller: _queueController,
          onClose: () => _shellController.closeQueue(),
          onPlayItem: (item) {
            setState(() {
              _mediaTitle = item.title;
              _duration = item.duration;
              _position = Duration.zero;
              _isPlaying = true;
            });
            _playerController.play();
            _osdController.showPill(
              action: 'Now Playing: ${item.title}',
              shortcutKey: 'Queue',
              icon: VlcIconGlyph.play,
            );
          },
          onSaveAsPlaylist: () {
            _osdController.showPill(
              action: 'Saved Queue as Playlist (${_queueController.count} items)',
              shortcutKey: 'Ctrl+S',
              icon: VlcIconGlyph.playlist,
            );
          },
          onAddMedia: () {
            _osdController.showPill(
              action: 'Add Media to Queue',
              shortcutKey: 'Ctrl+O',
              icon: VlcIconGlyph.folder,
            );
          },
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

