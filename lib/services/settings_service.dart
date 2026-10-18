import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 12 Unified Settings Categories in the Juxtopposed 25-Year Modern Redesign.
enum SettingsCategory {
  interfaceAppearance('Interface & Appearance', Icons.palette_outlined),
  audioOutput('Audio Output & Devices', Icons.volume_up_outlined),
  videoAcceleration('Video & Acceleration', Icons.videocam_outlined),
  subtitlesOsd('Subtitles & OSD', Icons.subtitles_outlined),
  inputCodecs('Input & Codecs', Icons.memory_outlined),
  performanceMemory('Performance & Memory', Icons.speed_outlined),
  networkStreaming('Network & Streaming', Icons.wifi_outlined),
  playlistPlayback('Playlist & Playback', Icons.playlist_play_outlined),
  mediaLibrary('Media Library', Icons.video_library_outlined),
  hotkeysShortcuts('Hotkeys & Shortcuts', Icons.keyboard_outlined),
  privacySecurity('Privacy & Security', Icons.shield_outlined),
  advancedEngine('Advanced Engine & libVLC', Icons.terminal_outlined);

  final String label;
  final IconData icon;

  const SettingsCategory(this.label, this.icon);
}

/// Metadata describing an individual configurable preference item.
class SettingItemMeta {
  final String key;
  final String title;
  final String description;
  final String tooltip;
  final String libvlcFlag;
  final SettingsCategory category;
  final bool isAdvanced;

  const SettingItemMeta({
    required this.key,
    required this.title,
    required this.description,
    required this.tooltip,
    required this.libvlcFlag,
    required this.category,
    this.isAdvanced = false,
  });
}

/// Comprehensive reactive Settings Service managing player preferences across all 12 categories.
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  static SettingsService get instance => _instance;

  SettingsService._internal();

  // ==========================================
  // Category 1: Interface & Appearance
  // ==========================================
  VlcThemeMode _themeMode = VlcThemeMode.dark;
  Color _accentColor = VlcColors.coneOrange;
  bool _showOsdPill = true;
  double _osdDurationSeconds = 2.5;
  double _autoHideControlsDelaySeconds = 1.8;
  bool _rememberWindowGeometry = true;
  bool _smoothVolumeWheel = true;

  // Advanced: Interface
  bool _hardwareCursorRendering = true;
  bool _acrylicWindowVibrancy = true;
  int _uiRefreshRateLimit = 120; // FPS

  // ==========================================
  // Category 2: Audio Output & Devices
  // ==========================================
  String _audioOutputModule = 'Automatic'; // Automatic, CoreAudio, WASAPI, PulseAudio
  String _defaultAudioDevice = 'Default OS Audio Device';
  double _volumeStep = 5.0; // 5% per scroll tick or key press
  double _coneVolumeLimit = 200.0; // Max cone volume: 125%, 150%, 200%
  bool _enableAudioSpatializer = false;
  String _replayGainMode = 'Track'; // None, Track, Album

  // Advanced: Audio
  int _audioResamplerQuality = 3; // 0=Speed (Linear), 3=High Quality (Speex), 4=Studio (SOXR)
  bool _float32AudioProcessing = true;
  int _audioBufferLatencyMs = 120;

  // ==========================================
  // Category 3: Video & Hardware Acceleration
  // ==========================================
  String _hardwareDecoding = 'Automatic'; // Automatic, VideoToolbox, DXVA2, D3D11VA, VAAPI, Disabled
  String _deinterlaceMode = 'Auto'; // Off, Auto, On
  String _deinterlaceAlgorithm = 'Yadif (2x)'; // Bob, Linear, Yadif (2x), Phosphor
  String _postProcessingQuality = 'High'; // Off, Medium, High
  bool _enableHdrTonemapping = true;
  String _videoRendererEngine = 'Impeller Metal / D3D11';

  // Advanced: Video
  bool _zeroCopyGpuTextures = true;
  bool _hardwareColorSpaceConversion = true;
  bool _dropLateFrames = false;

  // ==========================================
  // Category 4: Subtitles & OSD
  // ==========================================
  String _defaultSubtitleLanguage = 'English';
  String _subtitleFontFamily = 'System Default Sans';
  double _subtitleFontSize = 24.0;
  Color _subtitleTextColor = Colors.white;
  String _subtitleOutlineStyle = 'Medium Outline'; // None, Thin Outline, Medium Outline, Heavy Outline
  bool _autoDownloadSubtitles = true;
  String _subtitleEncoding = 'Universal (UTF-8)';

  // Advanced: Subtitles
  double _subtitlePositionVertical = 92.0; // % from top
  int _subtitlesFuzzyMatchThreshold = 75; // % confidence threshold

  // ==========================================
  // Category 5: Input & Codecs
  // ==========================================
  int _networkCachingMs = 1200; // 300, 1200, 3000
  int _fileCachingMs = 1000;
  int _liveCaptureFps = 60;
  int _streamReconnectAttempts = 5;
  String _opticalDriveSpeed = 'Automatic';

  // Advanced: Input & Codecs
  bool _fastSeekKeyframesOnly = true;
  int _ptsClockJitterToleranceMs = 500;

  // ==========================================
  // Category 6: Performance & Memory
  // ==========================================
  int _threadPoolCount = 0; // 0 = Auto-detect CPU cores
  int _memoryCacheLimitMb = 512;
  bool _enableMultiThreadedDecoding = true;

  // Advanced: Performance
  bool _aggressiveFramePruning = false;
  bool _enableVulkanZeroCopy = false;

  // ==========================================
  // Category 7: Network & Streaming
  // ==========================================
  String _httpProxyUrl = '';
  String _customUserAgent = 'VLC/3.0.24 Vetinari (Juxtopposed Modern Redesign)';
  bool _enableUpnpDiscovery = true;
  bool _rtspOverTcp = true;
  bool _enableIpv6 = true;

  // Advanced: Network
  int _networkTimeoutMs = 10000;
  int _maxParallelConnections = 8;

  // ==========================================
  // Category 8: Playlist & Playback
  // ==========================================
  bool _autoPlayNextItem = true;
  bool _pauseOnMinimize = false;
  String _defaultLoopMode = 'Off'; // Off, Loop Single, Loop All
  int _watchedResumeThresholdPercent = 90; // Auto-mark watched at 90%
  String _resumePlaybackPolicy = 'Ask'; // Always, Ask, Never

  // Advanced: Playback
  bool _enqueueFilesOpenedFromExplorer = true;
  bool _pausePlaybackOnHeadphoneDisconnect = true;

  // ==========================================
  // Category 9: Media Library
  // ==========================================
  bool _autoScanLibraryOnStartup = true;
  bool _watchLibraryFoldersLive = true;
  bool _generateVideoThumbnails = true;
  String _thumbnailQuality = 'Medium (480p)';
  bool _ignoreHiddenFiles = true;

  // Advanced: Media Library
  int _maxParallelIndexWorkers = 4;
  bool _autoFetchOnlineMetadata = true;

  // ==========================================
  // Category 10: Hotkeys & Shortcuts
  // ==========================================
  bool _globalMediaKeysEnabled = true;
  String _mouseWheelAction = 'Volume Control'; // Volume Control, Position Scrub, Zoom
  int _smallSeekStepSeconds = 5;
  int _mediumSeekStepSeconds = 10;
  int _largeSeekStepSeconds = 60;

  // Advanced: Hotkeys
  bool _escExitsFullscreenFirst = true;
  bool _spaceAlwaysTogglesPlay = true;

  // ==========================================
  // Category 11: Privacy & Security
  // ==========================================
  bool _saveRecentlyPlayedMedia = true;
  bool _clearRecentMediaOnExit = false;
  bool _autoCheckForUpdates = true;
  bool _anonymousTelemetry = false;
  bool _crashReporting = true;

  // Advanced: Privacy
  bool _blockInsecureHttpStreams = false;
  bool _stripGeoTagsFromMetadata = true;

  // ==========================================
  // Category 12: Advanced Engine & libVLC
  // ==========================================
  String _customLibVlcLaunchArgs = '--no-video-title-show --avcodec-fast';
  String _logVerbosityLevel = 'Warning'; // Silent, Error, Warning, Info, Debug
  bool _enableClockSynchronization = true;
  int _avSyncMicroseconds = 0;

  // Advanced: Engine internals
  bool _directSoundAudioEmulation = false;
  bool _dumpDemuxPacketsToLog = false;

  // ==========================================
  // Getters
  // ==========================================
  VlcThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get showOsdPill => _showOsdPill;
  double get osdDurationSeconds => _osdDurationSeconds;
  double get autoHideControlsDelaySeconds => _autoHideControlsDelaySeconds;
  bool get rememberWindowGeometry => _rememberWindowGeometry;
  bool get smoothVolumeWheel => _smoothVolumeWheel;
  bool get hardwareCursorRendering => _hardwareCursorRendering;
  bool get acrylicWindowVibrancy => _acrylicWindowVibrancy;
  int get uiRefreshRateLimit => _uiRefreshRateLimit;

  String get audioOutputModule => _audioOutputModule;
  String get defaultAudioDevice => _defaultAudioDevice;
  double get volumeStep => _volumeStep;
  double get coneVolumeLimit => _coneVolumeLimit;
  bool get enableAudioSpatializer => _enableAudioSpatializer;
  String get replayGainMode => _replayGainMode;
  int get audioResamplerQuality => _audioResamplerQuality;
  bool get float32AudioProcessing => _float32AudioProcessing;
  int get audioBufferLatencyMs => _audioBufferLatencyMs;

  String get hardwareDecoding => _hardwareDecoding;
  String get deinterlaceMode => _deinterlaceMode;
  String get deinterlaceAlgorithm => _deinterlaceAlgorithm;
  String get postProcessingQuality => _postProcessingQuality;
  bool get enableHdrTonemapping => _enableHdrTonemapping;
  String get videoRendererEngine => _videoRendererEngine;
  bool get zeroCopyGpuTextures => _zeroCopyGpuTextures;
  bool get hardwareColorSpaceConversion => _hardwareColorSpaceConversion;
  bool get dropLateFrames => _dropLateFrames;

  String get defaultSubtitleLanguage => _defaultSubtitleLanguage;
  String get subtitleFontFamily => _subtitleFontFamily;
  double get subtitleFontSize => _subtitleFontSize;
  Color get subtitleTextColor => _subtitleTextColor;
  String get subtitleOutlineStyle => _subtitleOutlineStyle;
  bool get autoDownloadSubtitles => _autoDownloadSubtitles;
  String get subtitleEncoding => _subtitleEncoding;
  double get subtitlePositionVertical => _subtitlePositionVertical;
  int get subtitlesFuzzyMatchThreshold => _subtitlesFuzzyMatchThreshold;

  int get networkCachingMs => _networkCachingMs;
  int get fileCachingMs => _fileCachingMs;
  int get liveCaptureFps => _liveCaptureFps;
  int get streamReconnectAttempts => _streamReconnectAttempts;
  String get opticalDriveSpeed => _opticalDriveSpeed;
  bool get fastSeekKeyframesOnly => _fastSeekKeyframesOnly;
  int get ptsClockJitterToleranceMs => _ptsClockJitterToleranceMs;

  int get threadPoolCount => _threadPoolCount;
  int get memoryCacheLimitMb => _memoryCacheLimitMb;
  bool get enableMultiThreadedDecoding => _enableMultiThreadedDecoding;
  bool get aggressiveFramePruning => _aggressiveFramePruning;
  bool get enableVulkanZeroCopy => _enableVulkanZeroCopy;

  String get httpProxyUrl => _httpProxyUrl;
  String get customUserAgent => _customUserAgent;
  bool get enableUpnpDiscovery => _enableUpnpDiscovery;
  bool get rtspOverTcp => _rtspOverTcp;
  bool get enableIpv6 => _enableIpv6;
  int get networkTimeoutMs => _networkTimeoutMs;
  int get maxParallelConnections => _maxParallelConnections;

  bool get autoPlayNextItem => _autoPlayNextItem;
  bool get pauseOnMinimize => _pauseOnMinimize;
  String get defaultLoopMode => _defaultLoopMode;
  int get watchedResumeThresholdPercent => _watchedResumeThresholdPercent;
  String get resumePlaybackPolicy => _resumePlaybackPolicy;
  bool get enqueueFilesOpenedFromExplorer => _enqueueFilesOpenedFromExplorer;
  bool get pausePlaybackOnHeadphoneDisconnect => _pausePlaybackOnHeadphoneDisconnect;

  bool get autoScanLibraryOnStartup => _autoScanLibraryOnStartup;
  bool get watchLibraryFoldersLive => _watchLibraryFoldersLive;
  bool get generateVideoThumbnails => _generateVideoThumbnails;
  String get thumbnailQuality => _thumbnailQuality;
  bool get ignoreHiddenFiles => _ignoreHiddenFiles;
  int get maxParallelIndexWorkers => _maxParallelIndexWorkers;
  bool get autoFetchOnlineMetadata => _autoFetchOnlineMetadata;

  bool get globalMediaKeysEnabled => _globalMediaKeysEnabled;
  String get mouseWheelAction => _mouseWheelAction;
  int get smallSeekStepSeconds => _smallSeekStepSeconds;
  int get mediumSeekStepSeconds => _mediumSeekStepSeconds;
  int get largeSeekStepSeconds => _largeSeekStepSeconds;
  bool get escExitsFullscreenFirst => _escExitsFullscreenFirst;
  bool get spaceAlwaysTogglesPlay => _spaceAlwaysTogglesPlay;

  bool get saveRecentlyPlayedMedia => _saveRecentlyPlayedMedia;
  bool get clearRecentMediaOnExit => _clearRecentMediaOnExit;
  bool get autoCheckForUpdates => _autoCheckForUpdates;
  bool get anonymousTelemetry => _anonymousTelemetry;
  bool get crashReporting => _crashReporting;
  bool get blockInsecureHttpStreams => _blockInsecureHttpStreams;
  bool get stripGeoTagsFromMetadata => _stripGeoTagsFromMetadata;

  String get customLibVlcLaunchArgs => _customLibVlcLaunchArgs;
  String get logVerbosityLevel => _logVerbosityLevel;
  bool get enableClockSynchronization => _enableClockSynchronization;
  int get avSyncMicroseconds => _avSyncMicroseconds;
  bool get directSoundAudioEmulation => _directSoundAudioEmulation;
  bool get dumpDemuxPacketsToLog => _dumpDemuxPacketsToLog;

  // ==========================================
  // Setters with notifyListeners()
  // ==========================================
  void setThemeMode(VlcThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  void setShowOsdPill(bool val) {
    _showOsdPill = val;
    notifyListeners();
  }

  void setOsdDurationSeconds(double val) {
    _osdDurationSeconds = val;
    notifyListeners();
  }

  void setAutoHideControlsDelaySeconds(double val) {
    _autoHideControlsDelaySeconds = val;
    notifyListeners();
  }

  void setHardwareDecoding(String val) {
    _hardwareDecoding = val;
    notifyListeners();
  }

  void setDeinterlaceMode(String val) {
    _deinterlaceMode = val;
    notifyListeners();
  }

  void setDeinterlaceAlgorithm(String val) {
    _deinterlaceAlgorithm = val;
    notifyListeners();
  }

  void setAudioOutputModule(String val) {
    _audioOutputModule = val;
    notifyListeners();
  }

  void setVolumeStep(double val) {
    _volumeStep = val;
    notifyListeners();
  }

  void setConeVolumeLimit(double val) {
    _coneVolumeLimit = val;
    notifyListeners();
  }

  void setDefaultSubtitleLanguage(String val) {
    _defaultSubtitleLanguage = val;
    notifyListeners();
  }

  void setSubtitleFontSize(double val) {
    _subtitleFontSize = val;
    notifyListeners();
  }

  void setSubtitleOutlineStyle(String val) {
    _subtitleOutlineStyle = val;
    notifyListeners();
  }

  void setNetworkCachingMs(int val) {
    _networkCachingMs = val;
    notifyListeners();
  }

  void setFileCachingMs(int val) {
    _fileCachingMs = val;
    notifyListeners();
  }

  void setAutoPlayNextItem(bool val) {
    _autoPlayNextItem = val;
    notifyListeners();
  }

  void setPauseOnMinimize(bool val) {
    _pauseOnMinimize = val;
    notifyListeners();
  }

  void setWatchedResumeThresholdPercent(int val) {
    _watchedResumeThresholdPercent = val;
    notifyListeners();
  }

  void setGlobalMediaKeysEnabled(bool val) {
    _globalMediaKeysEnabled = val;
    notifyListeners();
  }

  void setMouseWheelAction(String val) {
    _mouseWheelAction = val;
    notifyListeners();
  }

  void setSaveRecentlyPlayedMedia(bool val) {
    _saveRecentlyPlayedMedia = val;
    notifyListeners();
  }

  void setClearRecentMediaOnExit(bool val) {
    _clearRecentMediaOnExit = val;
    notifyListeners();
  }

  void setCustomLibVlcLaunchArgs(String val) {
    _customLibVlcLaunchArgs = val;
    notifyListeners();
  }

  void setLogVerbosityLevel(String val) {
    _logVerbosityLevel = val;
    notifyListeners();
  }

  void setZeroCopyGpuTextures(bool val) {
    _zeroCopyGpuTextures = val;
    notifyListeners();
  }

  void setThreadPoolCount(int val) {
    _threadPoolCount = val;
    notifyListeners();
  }

  void setMemoryCacheLimitMb(int val) {
    _memoryCacheLimitMb = val;
    notifyListeners();
  }

  void setAutoScanLibraryOnStartup(bool val) {
    _autoScanLibraryOnStartup = val;
    notifyListeners();
  }

  void setWatchLibraryFoldersLive(bool val) {
    _watchLibraryFoldersLive = val;
    notifyListeners();
  }

  // ==========================================
  // Reset all to defaults
  // ==========================================
  void resetToDefaults() {
    _themeMode = VlcThemeMode.dark;
    _accentColor = VlcColors.coneOrange;
    _showOsdPill = true;
    _osdDurationSeconds = 2.5;
    _autoHideControlsDelaySeconds = 1.8;
    _rememberWindowGeometry = true;
    _smoothVolumeWheel = true;
    _hardwareCursorRendering = true;
    _acrylicWindowVibrancy = true;
    _uiRefreshRateLimit = 120;

    _audioOutputModule = 'Automatic';
    _defaultAudioDevice = 'Default OS Audio Device';
    _volumeStep = 5.0;
    _coneVolumeLimit = 200.0;
    _enableAudioSpatializer = false;
    _replayGainMode = 'Track';
    _audioResamplerQuality = 3;
    _float32AudioProcessing = true;
    _audioBufferLatencyMs = 120;

    _hardwareDecoding = 'Automatic';
    _deinterlaceMode = 'Auto';
    _deinterlaceAlgorithm = 'Yadif (2x)';
    _postProcessingQuality = 'High';
    _enableHdrTonemapping = true;
    _videoRendererEngine = 'Impeller Metal / D3D11';
    _zeroCopyGpuTextures = true;
    _hardwareColorSpaceConversion = true;
    _dropLateFrames = false;

    _defaultSubtitleLanguage = 'English';
    _subtitleFontFamily = 'System Default Sans';
    _subtitleFontSize = 24.0;
    _subtitleTextColor = Colors.white;
    _subtitleOutlineStyle = 'Medium Outline';
    _autoDownloadSubtitles = true;
    _subtitleEncoding = 'Universal (UTF-8)';
    _subtitlePositionVertical = 92.0;
    _subtitlesFuzzyMatchThreshold = 75;

    _networkCachingMs = 1200;
    _fileCachingMs = 1000;
    _liveCaptureFps = 60;
    _streamReconnectAttempts = 5;
    _opticalDriveSpeed = 'Automatic';
    _fastSeekKeyframesOnly = true;
    _ptsClockJitterToleranceMs = 500;

    _threadPoolCount = 0;
    _memoryCacheLimitMb = 512;
    _enableMultiThreadedDecoding = true;
    _aggressiveFramePruning = false;
    _enableVulkanZeroCopy = false;

    _httpProxyUrl = '';
    _customUserAgent = 'VLC/3.0.24 Vetinari (Juxtopposed Modern Redesign)';
    _enableUpnpDiscovery = true;
    _rtspOverTcp = true;
    _enableIpv6 = true;
    _networkTimeoutMs = 10000;
    _maxParallelConnections = 8;

    _autoPlayNextItem = true;
    _pauseOnMinimize = false;
    _defaultLoopMode = 'Off';
    _watchedResumeThresholdPercent = 90;
    _resumePlaybackPolicy = 'Ask';
    _enqueueFilesOpenedFromExplorer = true;
    _pausePlaybackOnHeadphoneDisconnect = true;

    _autoScanLibraryOnStartup = true;
    _watchLibraryFoldersLive = true;
    _generateVideoThumbnails = true;
    _thumbnailQuality = 'Medium (480p)';
    _ignoreHiddenFiles = true;
    _maxParallelIndexWorkers = 4;
    _autoFetchOnlineMetadata = true;

    _globalMediaKeysEnabled = true;
    _mouseWheelAction = 'Volume Control';
    _smallSeekStepSeconds = 5;
    _mediumSeekStepSeconds = 10;
    _largeSeekStepSeconds = 60;
    _escExitsFullscreenFirst = true;
    _spaceAlwaysTogglesPlay = true;

    _saveRecentlyPlayedMedia = true;
    _clearRecentMediaOnExit = false;
    _autoCheckForUpdates = true;
    _anonymousTelemetry = false;
    _crashReporting = true;
    _blockInsecureHttpStreams = false;
    _stripGeoTagsFromMetadata = true;

    _customLibVlcLaunchArgs = '--no-video-title-show --avcodec-fast';
    _logVerbosityLevel = 'Warning';
    _enableClockSynchronization = true;
    _avSyncMicroseconds = 0;
    _directSoundAudioEmulation = false;
    _dumpDemuxPacketsToLog = false;

    notifyListeners();
  }

  // ==========================================
  // Search catalog across all 12 categories
  // ==========================================
  static final List<SettingItemMeta> catalog = [
    // Category 1: Interface
    const SettingItemMeta(
      key: 'theme_mode',
      title: 'App Theme Mode',
      description: 'Switch between Dark, OLED Pure Black, and Light modes.',
      tooltip: 'Changes UI theme across all views and panels. Default: Dark.',
      libvlcFlag: '--qt-style',
      category: SettingsCategory.interfaceAppearance,
    ),
    const SettingItemMeta(
      key: 'accent_color',
      title: 'Accent Highlight Color',
      description: 'Select brand highlight accent (VLC Signature Cone Orange, Cyan, Purple, Lime, Crimson).',
      tooltip: 'Used on sliders, active badges, and focus rings. Default: Cone Orange #FF8800.',
      libvlcFlag: '--custom-accent',
      category: SettingsCategory.interfaceAppearance,
    ),
    const SettingItemMeta(
      key: 'show_osd',
      title: 'Show On-Screen Display (OSD) Pills',
      description: 'Display top-right shortcut pill overlays on keyboard & remote actions.',
      tooltip: 'Provides immediate visual confirmation of volume, tracks, and seek actions. Default: Enabled.',
      libvlcFlag: '--osd',
      category: SettingsCategory.interfaceAppearance,
    ),
    const SettingItemMeta(
      key: 'autohide_delay',
      title: 'Controls Auto-Hide Delay',
      description: 'Duration before top and bottom transport controls fade out during playback.',
      tooltip: 'Desktop standard is 1.8s. Mobile default is 3.0s.',
      libvlcFlag: '--mouse-hide-timeout',
      category: SettingsCategory.interfaceAppearance,
    ),
    const SettingItemMeta(
      key: 'acrylic_vibrancy',
      title: 'Window Vibrancy & Backdrop Blur',
      description: 'Enable native desktop glass and acrylic translucency behind panels.',
      tooltip: 'Uses macOS NSVisualEffectView or Windows DWM Mica/Acrylic. Default: Enabled.',
      libvlcFlag: '--qt-blur-behind',
      category: SettingsCategory.interfaceAppearance,
      isAdvanced: true,
    ),

    // Category 2: Audio
    const SettingItemMeta(
      key: 'audio_output_module',
      title: 'Audio Output Module',
      description: 'Low-level audio driver interface (CoreAudio, WASAPI, PulseAudio, ALSA).',
      tooltip: 'Automatic selects native low-latency OS driver. Default: Automatic.',
      libvlcFlag: '--aout',
      category: SettingsCategory.audioOutput,
    ),
    const SettingItemMeta(
      key: 'cone_volume_limit',
      title: 'Maximum Cone Volume Boost',
      description: 'Max software gain multiplier allowed on the volume slider (125%, 150%, or 200%).',
      tooltip: 'VLC signature feature allowing volume past 100% for quiet recordings. Default: 200%.',
      libvlcFlag: '--volume-max',
      category: SettingsCategory.audioOutput,
    ),
    const SettingItemMeta(
      key: 'volume_step',
      title: 'Volume Step Increment',
      description: 'Percentage change applied per scroll wheel notch or Up/Down arrow key.',
      tooltip: 'Default: 5%.',
      libvlcFlag: '--volume-step',
      category: SettingsCategory.audioOutput,
    ),
    const SettingItemMeta(
      key: 'audio_resampler',
      title: 'Audio Resampling Quality',
      description: 'DSP algorithm used when converting source sampling rates to hardware clock.',
      tooltip: 'Speex and SOXR provide pristine audio fidelity without aliasing artifacts. Default: Speex.',
      libvlcFlag: '--audio-resampler',
      category: SettingsCategory.audioOutput,
      isAdvanced: true,
    ),

    // Category 3: Video
    const SettingItemMeta(
      key: 'hardware_decoding',
      title: 'Hardware Video Decoding',
      description: 'GPU-accelerated video decoding (VideoToolbox on macOS, DXVA2 on Windows, VAAPI on Linux).',
      tooltip: 'Drastically reduces CPU usage and battery drain on high-bitrate 4K/8K media. Default: Automatic.',
      libvlcFlag: '--avcodec-hw',
      category: SettingsCategory.videoAcceleration,
    ),
    const SettingItemMeta(
      key: 'deinterlace_mode',
      title: 'Deinterlace Mode',
      description: 'Automatic or forced deinterlacing for broadcast TV, DVD, and interlaced 1080i streams.',
      tooltip: 'Auto detects interlaced frames and applies interpolation. Default: Auto.',
      libvlcFlag: '--deinterlace',
      category: SettingsCategory.videoAcceleration,
    ),
    const SettingItemMeta(
      key: 'deinterlace_algorithm',
      title: 'Deinterlace Filter Algorithm',
      description: 'Algorithm used to weave and smooth interlaced fields.',
      tooltip: 'Yadif (2x) reconstructs full frame rate with motion compensation. Default: Yadif (2x).',
      libvlcFlag: '--deinterlace-mode',
      category: SettingsCategory.videoAcceleration,
    ),
    const SettingItemMeta(
      key: 'zero_copy_textures',
      title: 'Zero-Copy Direct GPU Surfaces',
      description: 'Stream decoded GPU frames directly to Impeller Metal/D3D11 without CPU buffer copies.',
      tooltip: 'Eliminates RAM copy bottleneck for 60fps+ 4K HDR playback. Default: Enabled.',
      libvlcFlag: '--gpu-zero-copy',
      category: SettingsCategory.videoAcceleration,
      isAdvanced: true,
    ),

    // Category 4: Subtitles
    const SettingItemMeta(
      key: 'default_subtitle_lang',
      title: 'Preferred Subtitle Language',
      description: 'Language track automatically selected when opening media with multiple streams.',
      tooltip: 'Matches against ISO 639-1 language codes in embedded tracks. Default: English.',
      libvlcFlag: '--sub-language',
      category: SettingsCategory.subtitlesOsd,
    ),
    const SettingItemMeta(
      key: 'subtitle_font_size',
      title: 'Subtitle Text Size',
      description: 'Font point size for text-based subtitles (SRT, ASS, VTT).',
      tooltip: 'Scales subtitles relative to video viewport. Default: 24pt.',
      libvlcFlag: '--freetype-fontsize',
      category: SettingsCategory.subtitlesOsd,
    ),
    const SettingItemMeta(
      key: 'auto_download_subs',
      title: 'Auto-Fetch Missing Subtitles',
      description: 'Query OpenSubtitles.org hash index when media has no embedded subtitles.',
      tooltip: 'Automatically pairs matching subtitle files in background. Default: Enabled.',
      libvlcFlag: '--sub-autodownload',
      category: SettingsCategory.subtitlesOsd,
    ),

    // Category 5: Input & Codecs
    const SettingItemMeta(
      key: 'network_caching',
      title: 'Network Stream Caching Buffer',
      description: 'Buffer duration (ms) for HTTP, HLS, RTSP, and IPTV network streams.',
      tooltip: 'Higher caching avoids buffering on unstable connections. Low Latency: 300ms. Standard: 1200ms.',
      libvlcFlag: '--network-caching',
      category: SettingsCategory.inputCodecs,
    ),
    const SettingItemMeta(
      key: 'file_caching',
      title: 'Local File Caching Buffer',
      description: 'Read-ahead buffer for local disk media and USB flash storage.',
      tooltip: 'Default: 1000ms.',
      libvlcFlag: '--file-caching',
      category: SettingsCategory.inputCodecs,
    ),

    // Category 6: Performance
    const SettingItemMeta(
      key: 'thread_pool_count',
      title: 'Decoder Multi-Threading Threads',
      description: 'Number of worker threads allocated for software decoding (0 = auto CPU count).',
      tooltip: 'Default: Auto (0).',
      libvlcFlag: '--avcodec-threads',
      category: SettingsCategory.performanceMemory,
    ),
    const SettingItemMeta(
      key: 'memory_cache_limit',
      title: 'Memory Cache Ceiling (MB)',
      description: 'Maximum RAM allocated for video frame cache and audio pre-roll.',
      tooltip: 'Default: 512MB.',
      libvlcFlag: '--cache-memory-limit',
      category: SettingsCategory.performanceMemory,
    ),

    // Category 7: Network
    const SettingItemMeta(
      key: 'upnp_discovery',
      title: 'Enable UPnP / DLNA Discovery',
      description: 'Discover media servers, Plex, Jellyfin, and smart TVs on local Wi-Fi.',
      tooltip: 'Default: Enabled.',
      libvlcFlag: '--upnp',
      category: SettingsCategory.networkStreaming,
    ),
    const SettingItemMeta(
      key: 'rtsp_tcp',
      title: 'RTSP Interleaved over TCP',
      description: 'Force RTSP streams over TCP instead of UDP to penetrate strict firewalls.',
      tooltip: 'Default: Enabled.',
      libvlcFlag: '--rtsp-tcp',
      category: SettingsCategory.networkStreaming,
    ),

    // Category 8: Playlist & Playback
    const SettingItemMeta(
      key: 'autoplay_next',
      title: 'Auto-Play Next in Queue / Folder',
      description: 'Automatically begin playback of subsequent episode or music track.',
      tooltip: 'Seamless continuous binge playback. Default: Enabled.',
      libvlcFlag: '--play-and-exit=0',
      category: SettingsCategory.playlistPlayback,
    ),
    const SettingItemMeta(
      key: 'pause_on_minimize',
      title: 'Pause When Window Minimized',
      description: 'Temporarily pause video playback when the player window is minimized or hidden.',
      tooltip: 'Default: Disabled.',
      libvlcFlag: '--pause-on-minimize',
      category: SettingsCategory.playlistPlayback,
    ),
    const SettingItemMeta(
      key: 'watched_threshold',
      title: 'Watched Mark Threshold',
      description: 'Progress percentage at which media is automatically marked as Watched in the library.',
      tooltip: 'Default: 90%.',
      libvlcFlag: '--medialib-watched-threshold',
      category: SettingsCategory.playlistPlayback,
    ),

    // Category 9: Media Library
    const SettingItemMeta(
      key: 'autoscan_startup',
      title: 'Scan Folders on Startup',
      description: 'Re-index monitored media folders for newly added episodes and songs on application launch.',
      tooltip: 'Default: Enabled.',
      libvlcFlag: '--medialib-startup-scan',
      category: SettingsCategory.mediaLibrary,
    ),
    const SettingItemMeta(
      key: 'watch_folders_live',
      title: 'Live Directory Watching',
      description: 'Subscribe to OS file system events to instantly index new files dropped into video folders.',
      tooltip: 'Uses macOS FSEvents or Windows ReadDirectoryChangesW. Default: Enabled.',
      libvlcFlag: '--medialib-fs-watch',
      category: SettingsCategory.mediaLibrary,
    ),

    // Category 10: Hotkeys
    const SettingItemMeta(
      key: 'global_media_keys',
      title: 'Global Hardware Media Keys',
      description: 'Respond to Play/Pause, Next, and Prev keys even when VLC is in background.',
      tooltip: 'Default: Enabled.',
      libvlcFlag: '--global-hotkeys',
      category: SettingsCategory.hotkeysShortcuts,
    ),
    const SettingItemMeta(
      key: 'mouse_wheel_action',
      title: 'Mouse Scroll Wheel Action',
      description: 'Primary function when scrolling mouse wheel over the video surface.',
      tooltip: 'Options: Volume Control (0-200%), Position Scrub, Zoom. Default: Volume Control.',
      libvlcFlag: '--hotkey-mousewheel',
      category: SettingsCategory.hotkeysShortcuts,
    ),

    // Category 11: Privacy & Security
    const SettingItemMeta(
      key: 'save_recent_media',
      title: 'Save Recently Played Media',
      description: 'Maintain history of played files for Continue Watching and Recents list.',
      tooltip: 'Default: Enabled.',
      libvlcFlag: '--save-recent',
      category: SettingsCategory.privacySecurity,
    ),
    const SettingItemMeta(
      key: 'telemetry',
      title: 'Anonymous Usage Telemetry',
      description: 'Share anonymous usage metrics with VideoLAN. (Disabled by default).',
      tooltip: 'Default: Disabled.',
      libvlcFlag: '--no-telemetry',
      category: SettingsCategory.privacySecurity,
    ),

    // Category 12: Advanced Engine & libVLC
    const SettingItemMeta(
      key: 'custom_libvlc_args',
      title: 'Custom libVLC Command-Line Flags',
      description: 'Direct arguments passed to libvlc_new() initialization in the native C core.',
      tooltip: 'Allows power users to customize low-level engine parameters. Default: --no-video-title-show --avcodec-fast.',
      libvlcFlag: '--custom-args',
      category: SettingsCategory.advancedEngine,
      isAdvanced: true,
    ),
    const SettingItemMeta(
      key: 'log_verbosity',
      title: 'Engine Logging Verbosity',
      description: 'Log detail level captured from libvlc_log_set callback.',
      tooltip: 'Options: Silent (0), Error (1), Warning (2), Info (3), Debug (4). Default: Warning.',
      libvlcFlag: '-vvv',
      category: SettingsCategory.advancedEngine,
      isAdvanced: true,
    ),
  ];

  /// Search across all setting items by title, description, key, or libvlcFlag.
  List<SettingItemMeta> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return catalog;
    return catalog.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.tooltip.toLowerCase().contains(q) ||
          item.libvlcFlag.toLowerCase().contains(q) ||
          item.category.label.toLowerCase().contains(q);
    }).toList();
  }
}

