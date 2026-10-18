import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'models/subtitle_models.dart';
import 'models/audio_models.dart';
import 'ui/popups/subtitle_quick_popup.dart';
import 'ui/popups/add_subtitles_modal.dart';
import 'ui/popups/audio_quick_popup.dart';
import 'ui/popups/open_media_modal.dart';
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
  late final PresetController _presetController;
  late final MediaLibraryService _mediaLibraryService;

  String _mediaTitle = 'Big Buck Bunny (4K Remux)';
  String _folderName = 'Demo Media';
  String _fullPath = '/Users/Movies/Demo Media/Big Buck Bunny (4K Remux).mkv';
  bool _isFullscreen = false;
  bool _isPipActive = false;
  bool _isFullLibraryView = false;
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
  bool _isSubtitleTimelineVisible = true;
  SubtitleAppearance _subtitleAppearance = SubtitleAppearance.defaultStyle;

  final List<SubtitleDialogueCue> _demoSubtitleCues = const [
    SubtitleDialogueCue(
      start: Duration(minutes: 14, seconds: 20),
      end: Duration(minutes: 14, seconds: 26),
      text: 'Look at that rabbit... It’s dynamite!',
    ),
    SubtitleDialogueCue(
      start: Duration(minutes: 14, seconds: 28),
      end: Duration(minutes: 14, seconds: 34),
      text: 'We need to move quickly before dusk falls.',
    ),
    SubtitleDialogueCue(
      start: Duration(minutes: 14, seconds: 38),
      end: Duration(minutes: 14, seconds: 45),
      text: 'Check the perimeter sensor readings right now.',
    ),
  ];

  final List<VlcSubtitleTrack> _demoSubTracks = const [
    VlcSubtitleTrack(id: 1, name: 'Track 1: English [Full/SDH]', language: 'en'),
    VlcSubtitleTrack(id: 2, name: 'Track 2: Spanish [Latin]', language: 'es'),
    VlcSubtitleTrack(id: 3, name: 'Track 3: French [Parisian]', language: 'fr'),
    VlcSubtitleTrack(id: 4, name: 'Track 4: Japanese [Original]', language: 'ja'),
  ];

  int _selectedAudioTrack = 1;
  String _selectedAudioDevice = 'built_in';
  Duration _audioDelay = Duration.zero;
  AudioFilterState _audioFilterState = const AudioFilterState();
  VideoAdjustState _videoAdjustState = const VideoAdjustState();
  PlaybackStateConfig _playbackConfig = const PlaybackStateConfig();

  final List<ChapterTick> _chapters = const [
    ChapterTick(fraction: 0.15, title: 'Chapter 1: Prologue', time: Duration(minutes: 20)),
    ChapterTick(fraction: 0.40, title: 'Chapter 2: Mountain Waves', time: Duration(minutes: 54)),
    ChapterTick(fraction: 0.70, title: 'Chapter 3: The Black Hole', time: Duration(hours: 1, minutes: 35)),
    ChapterTick(fraction: 0.90, title: 'Chapter 4: Epilogue', time: Duration(hours: 2, minutes: 02)),
  ];

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
    _shellController.addListener(_onShellChanged);
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

    // Initialize Per-Show Preset Controller
    _presetController = PresetController(
      onPresetChanged: (preset) {
        _osdController.showPill(
          action: 'Profile: ${preset.name}',
          shortcutKey: 'P',
          icon: VlcIconGlyph.equalizer,
        );
      },
    );

    // Initialize VideoLAN Medialibrary SQLite Indexer
    _mediaLibraryService = MediaLibraryService();

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

  void _onShellChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _themeController.dispose();
    _shellController.removeListener(_onShellChanged);
    _shellController.dispose();
    _osdController.dispose();
    _queueController.dispose();
    _presetController.dispose();
    _mediaLibraryService.dispose();
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

  void _cycleSubtitles() {
    setState(() {
      if (_selectedSubTrack == -1) {
        _selectedSubTrack = _demoSubTracks.first.id;
      } else {
        final idx = _demoSubTracks.indexWhere((t) => t.id == _selectedSubTrack);
        if (idx == -1 || idx == _demoSubTracks.length - 1) {
          _selectedSubTrack = -1; // disabled
        } else {
          _selectedSubTrack = _demoSubTracks[idx + 1].id;
        }
      }
    });
    _playerController.setSubtitleTrack(_selectedSubTrack);
    final trackName = _selectedSubTrack == -1
        ? 'Disabled'
        : _demoSubTracks.firstWhere((t) => t.id == _selectedSubTrack).name;
    _osdController.showPill(
      action: 'Subtitles: $trackName',
      shortcutKey: 'V / S',
      icon: VlcIconGlyph.subtitles,
    );
  }

  void _cycleAudioTrack() {
    setState(() {
      final idx = _demoAudioTracks.indexWhere((t) => t.id == _selectedAudioTrack);
      if (idx == -1 || idx == _demoAudioTracks.length - 1) {
        _selectedAudioTrack = _demoAudioTracks.first.id;
      } else {
        _selectedAudioTrack = _demoAudioTracks[idx + 1].id;
      }
    });
    _playerController.setAudioTrack(_selectedAudioTrack);
    final trackName = _demoAudioTracks.firstWhere((t) => t.id == _selectedAudioTrack).name;
    _osdController.showPill(
      action: 'Audio: $trackName',
      shortcutKey: 'B',
      icon: VlcIconGlyph.audioTrack,
    );
  }

  void _cycleAspectRatio() {
    final values = VlcAspectRatio.values;
    final curIdx = values.indexOf(_videoAdjustState.aspectRatio);
    final nextAspect = values[(curIdx + 1) % values.length];
    setState(() {
      _videoAdjustState = _videoAdjustState.copyWith(aspectRatio: nextAspect);
    });
    _osdController.showPill(
      action: 'Aspect: ${nextAspect.label}',
      shortcutKey: 'A',
      icon: VlcIconGlyph.aspectRatio,
    );
  }

  void _cycleCrop() {
    final values = VlcCropGeometry.values;
    final curIdx = values.indexOf(_videoAdjustState.cropGeometry);
    final nextCrop = values[(curIdx + 1) % values.length];
    setState(() {
      _videoAdjustState = _videoAdjustState.copyWith(cropGeometry: nextCrop);
    });
    _osdController.showPill(
      action: 'Crop: ${nextCrop.label}',
      shortcutKey: 'C',
      icon: VlcIconGlyph.crop,
    );
  }

  void _addBookmark() {
    final pos = _position;
    final id = 'bm_${DateTime.now().millisecondsSinceEpoch}';
    final title = 'Bookmark at ${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}';
    final updated = List<VlcPlaybackBookmark>.from(_playbackConfig.bookmarks)
      ..add(VlcPlaybackBookmark(
        id: id,
        title: title,
        position: pos,
        createdAt: DateTime.now(),
      ));
    setState(() {
      _playbackConfig = _playbackConfig.copyWith(bookmarks: updated);
    });
    _osdController.showPill(
      action: 'Added Bookmark [${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}]',
      shortcutKey: 'Ctrl+B',
      icon: VlcIconGlyph.bookmark,
    );
  }

  void _cycleRepeatMode() {
    setState(() {
      _repeatMode = switch (_repeatMode) {
        VlcRepeatMode.off => VlcRepeatMode.all,
        VlcRepeatMode.all => VlcRepeatMode.one,
        VlcRepeatMode.one => VlcRepeatMode.off,
      };
    });
    _osdController.showPill(
      action: switch (_repeatMode) {
        VlcRepeatMode.off => 'Repeat: Off',
        VlcRepeatMode.all => 'Repeat: All',
        VlcRepeatMode.one => 'Repeat: Track',
      },
      shortcutKey: 'R',
      icon: _repeatMode == VlcRepeatMode.one ? VlcIconGlyph.repeatOne : VlcIconGlyph.repeat,
    );
  }

  void _loadAndPlayMedia(String mrl) {
    final fileName = p.basename(mrl);
    final folderName = p.basename(p.dirname(mrl));

    // Index or retrieve in VideoLAN medialibrary
    final item = _mediaLibraryService.indexFile(mrl);
    final resumeMs = _mediaLibraryService.getResumePosition(mrl);

    setState(() {
      _fullPath = mrl;
      _mediaTitle = item?.title ?? (fileName.isNotEmpty ? fileName : mrl);
      _folderName = folderName.isNotEmpty ? folderName : 'Media';
      _position = Duration.zero;
      _isPlaying = true;
    });

    _playerController.open(mrl);
    _playerController.play();

    // Check if item has a saved resume position (> 2 seconds)
    if (resumeMs > 2000) {
      final resumeDur = Duration(milliseconds: resumeMs);
      _osdController.showResumePrompt(
        mediaTitle: _mediaTitle,
        resumePosition: resumeDur,
        onResume: () {
          setState(() => _position = resumeDur);
          _playerController.setTime(resumeMs);
          _osdController.showPill(
            action: 'Resumed at ${item?.formattedResumeTime ?? ''}',
            shortcutKey: 'Space',
            icon: VlcIconGlyph.play,
          );
        },
        onStartOver: () {
          setState(() => _position = Duration.zero);
          _playerController.setTime(0);
          _mediaLibraryService.updatePlaybackProgress(mrl, positionMs: 0, durationMs: item?.durationMs ?? 0);
          _osdController.showPill(
            action: 'Started Over',
            shortcutKey: '0',
            icon: VlcIconGlyph.previous,
          );
        },
      );
    }

    // Add or activate in queue
    final existingIdx = _queueController.items.indexWhere((it) => it.mrl == mrl);
    if (existingIdx != -1) {
      _queueController.playIndex(existingIdx);
    } else {
      _queueController.addItem(
        QueueItem(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}',
          mrl: mrl,
          title: _mediaTitle,
          artist: _folderName,
          duration: Duration(milliseconds: item?.durationMs ?? const Duration(minutes: 30).inMilliseconds),
          isPlaying: true,
        ),
      );
    }

    _osdController.showPill(
      action: 'Playing: $_mediaTitle',
      shortcutKey: 'Ctrl+O',
      icon: VlcIconGlyph.play,
    );
  }

  void _showOpenMediaModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => OpenMediaModal(
        onOpenMedia: (mrl) {
          _loadAndPlayMedia(mrl);
        },
        onClose: () => Navigator.of(dialogCtx).pop(),
      ),
    );
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
          if (_isFullLibraryView) {
            return FullLibraryView(
              mediaLibraryService: _mediaLibraryService,
              currentMrl: _fullPath,
              currentTitle: _mediaTitle,
              isPlaying: _isPlaying,
              position: _position,
              duration: _duration,
              volume: _volume,
              isMuted: _isMuted,
              onReturnToPlayer: () {
                setState(() => _isFullLibraryView = false);
                _osdController.showPill(
                  action: 'Returned to Video Player',
                  shortcutKey: 'Esc',
                  icon: VlcIconGlyph.play,
                );
              },
              onPlayItem: (item) {
                setState(() {
                  _mediaTitle = item.displayName;
                  _fullPath = item.mrl;
                  _folderName = item.folderName;
                  _position = Duration(milliseconds: item.resumePositionMs);
                  _duration = Duration(milliseconds: item.durationMs > 0 ? item.durationMs : 120000);
                  _isPlaying = true;
                  _isFullLibraryView = false;
                });
                _playerController.open(item.mrl);
                _playerController.play();
                _osdController.showPill(
                  action: 'Playing: ${item.displayName}',
                  shortcutKey: 'Space',
                  icon: VlcIconGlyph.play,
                );
              },
              onAddToQueue: (item) {
                _queueController.addItem(QueueItem(
                  id: 'item_${DateTime.now().microsecondsSinceEpoch}',
                  mrl: item.mrl,
                  title: item.displayName,
                  artist: item.artist ?? item.folderName,
                  duration: Duration(milliseconds: item.durationMs),
                ));
                _osdController.showPill(
                  action: 'Added: ${item.displayName}',
                  shortcutKey: 'Q',
                  icon: VlcIconGlyph.queue,
                );
              },
              onPlayAll: (items) {
                if (items.isEmpty) return;
                setState(() {
                  _mediaTitle = items.first.displayName;
                  _fullPath = items.first.mrl;
                  _folderName = items.first.folderName;
                  _position = Duration(milliseconds: items.first.resumePositionMs);
                  _duration = Duration(milliseconds: items.first.durationMs > 0 ? items.first.durationMs : 120000);
                  _isPlaying = true;
                  _isFullLibraryView = false;
                });
                _playerController.open(items.first.mrl);
                _playerController.play();
                _queueController.clear();
                for (int i = 0; i < items.length; i++) {
                  _queueController.addItem(QueueItem(
                    id: 'queue_batch_$i',
                    mrl: items[i].mrl,
                    title: items[i].displayName,
                    artist: items[i].artist ?? items[i].folderName,
                    duration: Duration(milliseconds: items[i].durationMs),
                    isPlaying: i == 0,
                  ));
                }
                _osdController.showPill(
                  action: 'Playing ${items.length} items',
                  shortcutKey: 'Enter',
                  icon: VlcIconGlyph.play,
                );
              },
              onEnqueueAll: (items) {
                for (int i = 0; i < items.length; i++) {
                  _queueController.addItem(QueueItem(
                    id: 'queue_batch_${DateTime.now().microsecondsSinceEpoch}_$i',
                    mrl: items[i].mrl,
                    title: items[i].displayName,
                    artist: items[i].artist ?? items[i].folderName,
                    duration: Duration(milliseconds: items[i].durationMs),
                  ));
                }
                _osdController.showPill(
                  action: 'Enqueued ${items.length} items',
                  shortcutKey: 'Q',
                  icon: VlcIconGlyph.queue,
                );
              },
              onTogglePlayPause: () {
                setState(() => _isPlaying = !_isPlaying);
                _playerController.togglePlay();
              },
              onNext: () {
                final current = _queueController.playNext();
                if (current != null) {
                  setState(() {
                    _mediaTitle = current.title;
                    _fullPath = current.mrl;
                  });
                }
              },
              onPrevious: () {
                final current = _queueController.playPrevious();
                if (current != null) {
                  setState(() {
                    _mediaTitle = current.title;
                    _fullPath = current.mrl;
                  });
                }
              },
              onVolumeChanged: (vol) {
                setState(() => _volume = vol);
                _playerController.setVolume(vol);
              },
              onToggleMute: () {
                setState(() => _isMuted = !_isMuted);
                _playerController.toggleMute();
              },
              onAddFolder: () => _showOpenMediaModal(context),
            );
          }

          final colors = currentVlcTheme.colors;

          return AppShell(
            playerController: _playerController,
            shellController: _shellController,
            isFullscreen: _isFullscreen,
            onFullscreenToggle: _toggleFullscreen,
            onOpenFile: () => _showOpenMediaModal(context),
            onCycleSubtitles: _cycleSubtitles,
            onCycleAudio: _cycleAudioTrack,
            onCycleAspectRatio: _cycleAspectRatio,
            onCycleCrop: _cycleCrop,
            onToggleInspector: () => _shellController.toggleDrawer(_shellController.activeDrawerTab),
            onNextFrame: () {
              _playerController.nextFrame();
              _osdController.showPill(
                action: 'Next Frame',
                shortcutKey: 'E',
                icon: VlcIconGlyph.stepForward,
              );
            },
            onPreviousFrame: () {
              _osdController.showPill(
                action: 'Previous Frame',
                shortcutKey: 'Shift+E',
                icon: VlcIconGlyph.stepBackward,
              );
            },
            onAdjustRate: (newRate) {
              setState(() {
                _playbackRate = newRate;
                _playbackConfig = _playbackConfig.copyWith(playbackRate: newRate);
              });
              _osdController.showPill(
                action: 'Speed: ${newRate.toStringAsFixed(2)}x',
                shortcutKey: '[ / ]',
                icon: VlcIconGlyph.speed,
              );
            },
            onCycleRepeat: _cycleRepeatMode,
            onBookmark: _addBookmark,
            onSubtitleDelay: (d) {
              setState(() => _subDelay = d);
              _osdController.showPill(
                action: 'Subtitle Delay: ${d.inMilliseconds} ms',
                shortcutKey: 'G / H',
                icon: VlcIconGlyph.subtitles,
              );
            },
            onAudioDelay: (d) {
              setState(() => _audioDelay = d);
              _osdController.showPill(
                action: 'Audio Delay: ${d.inMilliseconds} ms',
                shortcutKey: 'J / K',
                icon: VlcIconGlyph.audioTrack,
              );
            },
            onToggleFullLibrary: () {
              setState(() => _isFullLibraryView = !_isFullLibraryView);
              _osdController.showPill(
                action: _isFullLibraryView ? 'Media Library' : 'Video Player',
                shortcutKey: 'Ctrl+L',
                icon: VlcIconGlyph.viewGrid,
              );
            },
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
              onOpenFile: () => _showOpenMediaModal(context),
              onOpenStream: () => _showOpenMediaModal(context),
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
              onLibraryViewToggle: () {
                setState(() => _isFullLibraryView = !_isFullLibraryView);
                _osdController.showPill(
                  action: _isFullLibraryView ? 'Media Library' : 'Video Player',
                  shortcutKey: 'Ctrl+L',
                  icon: VlcIconGlyph.viewGrid,
                );
              },
              isLibraryViewActive: _isFullLibraryView,
              onBreadcrumbTap: () {
                _shellController.toggleLibrary(_isPlaying);
                _osdController.showPill(
                  action: _shellController.isLibraryOpen ? 'Library: $_folderName' : 'Library Closed',
                  shortcutKey: 'L',
                  icon: VlcIconGlyph.folder,
                );
              },
            ),

            // Video Surface canvas (displays cone emblem and Open Media CTA when idle)
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
                    // Prominent Open Media CTA Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: VlcGeometry.buttonShape,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      onPressed: () => _showOpenMediaModal(context),
                      icon: const Icon(Icons.folder_open, size: 20, color: Colors.white),
                      label: Text(
                        'Open Media [Ctrl+O / ⌘O]',
                        style: currentVlcTheme.typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a video/audio file, enter a stream URL, or pick demo media',
                      style: currentVlcTheme.typography.labelSmall.copyWith(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                if (_isSubtitleTimelineVisible && _selectedSubTrack != -1)
                  InteractiveSubtitleTimeline(
                    position: _position,
                    duration: _duration,
                    delay: _subDelay,
                    cues: _demoSubtitleCues,
                    onDelayChanged: (d) {
                      setState(() => _subDelay = d);
                      _playerController.setSubtitleDelay(d);
                      _osdController.showPill(
                        action: 'Subtitle Delay: ${d.inMilliseconds} ms',
                        shortcutKey: 'G/H',
                        icon: VlcIconGlyph.subtitles,
                      );
                    },
                    onClose: () {
                      setState(() => _isSubtitleTimelineVisible = false);
                    },
                  ),

                // Edge-to-Edge Thick Seek Bar (10dp -> 16dp on hover)
                ThickSeekBar(
                  position: _position,
                  duration: _duration,
                  bufferProgress: 0.65, // simulated 65% streaming buffer
                  chapters: _playbackConfig.showChapterTicksOverlay ? _chapters : const [],
                  waveformSamples: _playbackConfig.showWaveformOverlay
                      ? List.generate(120, (i) => (math.sin(i * 0.2).abs() * 0.7) + 0.2)
                      : null,
                  onSeek: (targetTime) {
                    setState(() => _position = targetTime);
                    _playerController.setTime(targetTime.inMilliseconds);
                    _mediaLibraryService.updatePlaybackProgress(
                      _fullPath,
                      positionMs: targetTime.inMilliseconds,
                      durationMs: _duration.inMilliseconds,
                    );
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
                _shellController.toggleDrawer(0); // Open Tab 0: Subtitles in Inspector
              },
              onAudioTrackTap: () {
                _shellController.toggleDrawer(1); // Open Tab 1: Audio & EQ in Inspector
              },
              onEqualizerTap: () {
                _shellController.toggleDrawer(1); // Open Tab 1: Audio & EQ in Inspector
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

        // Compact Media Library Drawer (Desktop 340dp left drawer)
        libraryDrawer: CompactLibraryDrawer(
          mediaLibraryService: _mediaLibraryService,
          currentMrl: _fullPath,
          activeFolderPath: _folderName,
          onClose: () => _shellController.closeLibrary(_isPlaying),
          onPlayItem: (item) => _loadAndPlayMedia(item.mrl),
          onAddToQueue: (item) {
            _queueController.addItem(
              QueueItem(
                id: 'q_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
                mrl: item.mrl,
                title: item.displayName,
                artist: item.formattedDuration,
                duration: Duration(milliseconds: item.durationMs),
              ),
            );
            _osdController.showPill(
              action: 'Enqueued: ${item.displayName}',
              shortcutKey: '+',
              icon: VlcIconGlyph.queue,
            );
          },
          onPlayAll: (items) {
            if (items.isEmpty) return;
            _queueController.clear();
            for (final item in items) {
              _queueController.addItem(
                QueueItem(
                  id: 'q_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
                  mrl: item.mrl,
                  title: item.displayName,
                  artist: item.formattedDuration,
                  duration: Duration(milliseconds: item.durationMs),
                ),
              );
            }
            _loadAndPlayMedia(items.first.mrl);
          },
          onEnqueueAll: (items) {
            for (final item in items) {
              _queueController.addItem(
                QueueItem(
                  id: 'q_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
                  mrl: item.mrl,
                  title: item.displayName,
                  artist: item.formattedDuration,
                  duration: Duration(milliseconds: item.durationMs),
                ),
              );
            }
            _osdController.showPill(
              action: 'Enqueued ${items.length} items',
              shortcutKey: '+',
              icon: VlcIconGlyph.queue,
            );
          },
          onAddFolder: () => _showOpenMediaModal(context),
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
            _showOpenMediaModal(context);
          },
        ),

        // 4-Tab Inspector Drawer & Preset Bar
        rightDrawer: InspectorSidebar(
          activeTab: _shellController.activeDrawerTab,
          onTabChanged: (idx) => _shellController.openDrawer(idx),
          onClose: () => _shellController.closeDrawer(),
          presetController: _presetController,
          subtitlesTab: SubtitleInspectorTab(
            tracks: _demoSubTracks,
            selectedTrackId: _selectedSubTrack,
            currentDelay: _subDelay,
            appearance: _subtitleAppearance,
            isTimelineOverlayEnabled: _isSubtitleTimelineVisible,
            onSelectTrack: (id) {
              setState(() => _selectedSubTrack = id);
              _playerController.setSubtitleTrack(id);
              _osdController.showPill(
                action: id == -1 ? 'Subtitles Disabled' : 'Subtitle Track $id Selected',
                shortcutKey: 'S',
                icon: VlcIconGlyph.subtitles,
              );
            },
            onDelayChanged: (d) {
              setState(() => _subDelay = d);
              _playerController.setSubtitleDelay(d);
              _osdController.showPill(
                action: 'Subtitle Delay: ${d.inMilliseconds} ms',
                shortcutKey: 'G/H',
                icon: VlcIconGlyph.subtitles,
              );
            },
            onAppearanceChanged: (app) {
              setState(() => _subtitleAppearance = app);
            },
            onToggleTimelineOverlay: (val) {
              setState(() => _isSubtitleTimelineVisible = val);
              _osdController.showPill(
                action: val ? 'Timeline Sync Bar Enabled' : 'Timeline Sync Bar Hidden',
                shortcutKey: 'Timeline',
                icon: VlcIconGlyph.subtitles,
              );
            },
            onAddSubtitle: () {
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
                      action: 'Batch Subtitles Applied (${matches.length} files)',
                      shortcutKey: 'Batch',
                      icon: VlcIconGlyph.subtitles,
                    );
                  },
                ),
              );
            },
          ),
          audioTab: AudioInspectorTab(
            tracks: _demoAudioTracks,
            selectedTrackId: _selectedAudioTrack,
            devices: _demoAudioDevices,
            selectedDeviceId: _selectedAudioDevice,
            currentDelay: _audioDelay,
            filterState: _audioFilterState,
            onSelectTrack: (id) {
              setState(() => _selectedAudioTrack = id);
              _playerController.setAudioTrack(id);
              _osdController.showPill(
                action: id == -1 ? 'Audio Muted' : 'Audio Track $id Selected',
                shortcutKey: 'B',
                icon: VlcIconGlyph.audioTrack,
              );
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
            onFilterStateChanged: (state) {
              setState(() => _audioFilterState = state);
              _playerController.enableEqualizer(state.isEqEnabled);
              _playerController.setEqualizerPreamp(state.preamp);
              for (int i = 0; i < state.bands.length; i++) {
                _playerController.setEqualizerBandAmp(i, state.bands[i]);
              }
              _osdController.showPill(
                action: 'EQ: ${state.activePresetId.replaceAll("_", " ").toUpperCase()}',
                shortcutKey: 'EQ',
                icon: VlcIconGlyph.equalizer,
              );
            },
          ),
          videoTab: VideoInspectorTab(
            adjustState: _videoAdjustState,
            onAdjustStateChanged: (newState) {
              setState(() => _videoAdjustState = newState);
              _osdController.showPill(
                action: 'Video: ${newState.aspectRatio.label} • ${newState.rotation.label}',
                shortcutKey: 'A',
                icon: VlcIconGlyph.aspectRatio,
              );
            },
            onTakeSnapshot: () {
              final path = '/tmp/vlc_snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
              _playerController.takeSnapshot(path);
              _osdController.showPill(
                action: 'Snapshot: ${path.split(RegExp(r"[\\/]")).last}',
                shortcutKey: 'Shift+S',
                icon: VlcIconGlyph.aspectRatio,
              );
            },
          ),
          playbackTab: PlaybackInspectorTab(
            config: _playbackConfig,
            currentPosition: _position,
            totalDuration: _duration,
            chapters: _chapters,
            onConfigChanged: (newConfig) {
              setState(() {
                _playbackConfig = newConfig;
                _playbackRate = newConfig.playbackRate;
              });
              _playerController.setRate(newConfig.playbackRate);
              _osdController.showPill(
                action: 'Speed: ${newConfig.playbackRate.toStringAsFixed(2)}x',
                shortcutKey: '>',
                icon: VlcIconGlyph.speed,
              );
            },
            onSeekTo: (target) {
              setState(() => _position = target);
              _playerController.seekTo(target);
              _osdController.showPill(
                action: 'Seek: ${target.inMinutes}:${(target.inSeconds % 60).toString().padLeft(2, '0')}',
                shortcutKey: 'Seek',
                icon: VlcIconGlyph.play,
              );
            },
            onNextFrame: () {
              _playerController.nextFrame();
              _osdController.showPill(
                action: 'Next Frame',
                shortcutKey: 'E',
                icon: VlcIconGlyph.stepForward,
              );
            },
            onPreviousFrame: () {
              _osdController.showPill(
                action: 'Previous Frame',
                shortcutKey: 'Shift+E',
                icon: VlcIconGlyph.stepBackward,
              );
            },
          ),
          onResetPreset: () {
            _osdController.showPill(
              action: 'Reset to Standard Profile',
              shortcutKey: 'Preset',
              icon: VlcIconGlyph.equalizer,
            );
          },
          onApplyToFolder: (apply) {
            _osdController.showPill(
              action: apply ? 'Preset linked to folder' : 'Preset set for file only',
              shortcutKey: 'Scope',
              icon: VlcIconGlyph.playlist,
            );
          },
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

