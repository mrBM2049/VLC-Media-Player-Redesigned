import 'dart:async';
import '../ffi/vlc_bindings.dart';
export '../ffi/vlc_bindings.dart';

/// Reactive Player Controller providing unified control of libVLC engine
class VlcPlayerController {
  final VlcBridgeBindings _bindings;

  final _stateController = StreamController<VlcPlayerState>.broadcast();
  final _positionController = StreamController<double>.broadcast();
  final _timeController = StreamController<Duration>.broadcast();
  final _volumeController = StreamController<int>.broadcast();

  Stream<VlcPlayerState> get stateStream => _stateController.stream;
  Stream<double> get positionStream => _positionController.stream;
  Stream<Duration> get timeStream => _timeController.stream;
  Stream<int> get volumeStream => _volumeController.stream;

  VlcPlayerController([VlcBridgeBindings? bindings])
      : _bindings = bindings ?? VlcBridgeBindings() {
    _bindings.vlcBridgeInit();
  }

  factory VlcPlayerController.mock() => VlcPlayerController(VlcBridgeBindings.mock());

  bool get isInitialized => _bindings.vlcBridgeIsInitialized();
  String get vlcVersion => _bindings.getVersion();
  bool get hasNativeEngine => _bindings.vlcBridgeHasNativeVlc();

  /* Playback */
  int open(String mrl) {
    return _bindings.open(mrl);
  }

  int play() {
    final res = _bindings.vlcBridgePlay();
    _stateController.add(VlcPlayerState.playing);
    return res;
  }

  int pause() {
    final res = _bindings.vlcBridgePause();
    _stateController.add(VlcPlayerState.paused);
    return res;
  }

  int togglePlay() {
    final res = _bindings.vlcBridgeTogglePlay();
    _stateController.add(_bindings.getState());
    return res;
  }

  int stop() {
    final res = _bindings.vlcBridgeStop();
    _stateController.add(VlcPlayerState.stopped);
    return res;
  }

  /* Seeking */
  Duration get time => Duration(milliseconds: _bindings.vlcBridgeGetTime());
  Duration get length => Duration(milliseconds: _bindings.vlcBridgeGetLength());
  double get position => _bindings.vlcBridgeGetPosition();

  int seekTo(Duration target) {
    final res = _bindings.vlcBridgeSetTime(target.inMilliseconds);
    _timeController.add(target);
    return res;
  }

  int setTime(int ms) => seekTo(Duration(milliseconds: ms));

  int seekPosition(double pos) {
    final clamped = pos.clamp(0.0, 1.0);
    final res = _bindings.vlcBridgeSetPosition(clamped);
    _positionController.add(clamped);
    return res;
  }

  /* Rate (0.25x - 4.0x) */
  double get rate => _bindings.vlcBridgeGetRate();
  int setRate(double rate) => _bindings.vlcBridgeSetRate(rate);

  /* Volume (0 - 200% Cone Volume) */
  int get volume => _bindings.vlcBridgeGetVolume();
  int setVolume(int vol) {
    final res = _bindings.vlcBridgeSetVolume(vol);
    _volumeController.add(_bindings.vlcBridgeGetVolume());
    return res;
  }

  bool get isMuted => _bindings.vlcBridgeGetMute();
  int setMute(bool mute) => _bindings.vlcBridgeSetMute(mute);
  int toggleMute() => _bindings.vlcBridgeToggleMute();

  /* Delays */
  Duration get subtitleDelay => Duration(microseconds: _bindings.vlcBridgeGetSpuDelay());
  int setSubtitleDelay(Duration delay) => _bindings.vlcBridgeSetSpuDelay(delay.inMicroseconds);

  Duration get audioDelay => Duration(microseconds: _bindings.vlcBridgeGetAudioDelay());
  int setAudioDelay(Duration delay) => _bindings.vlcBridgeSetAudioDelay(delay.inMicroseconds);

  int get audioTrackCount => _bindings.vlcBridgeGetAudioTrackCount();
  int get audioTrack => _bindings.vlcBridgeGetAudioTrack();
  int setAudioTrack(int trackId) => _bindings.vlcBridgeSetAudioTrack(trackId);
  String get audioDevice => _bindings.getAudioDevice();
  int setAudioDevice(String deviceId) => _bindings.setAudioDevice(deviceId);

  int get subtitleTrackCount => _bindings.vlcBridgeGetSpuCount();
  int get subtitleTrack => _bindings.vlcBridgeGetSpuTrack();
  int setSubtitleTrack(int spuId) => _bindings.vlcBridgeSetSpuTrack(spuId);
  int addSubtitleFile(String path, {bool select = true}) => _bindings.addSubtitleFile(path, select);

  /* Chapters */
  int get chapterCount => _bindings.vlcBridgeGetChapterCount();
  int get chapter => _bindings.vlcBridgeGetChapter();
  int setChapter(int ch) => _bindings.vlcBridgeSetChapter(ch);
  int nextChapter() => _bindings.vlcBridgeNextChapter();
  int previousChapter() => _bindings.vlcBridgePreviousChapter();

  /* Frame Stepping & Snapshot */
  int nextFrame() => _bindings.vlcBridgeNextFrame();
  int takeSnapshot(String path, {int width = 0, int height = 0}) =>
      _bindings.takeSnapshot(path, width, height);

  /* 10-Band Equalizer */
  int get equalizerPresetCount => _bindings.vlcBridgeEqualizerGetPresetCount();
  String? getEqualizerPresetName(int idx) => _bindings.getEqualizerPresetName(idx);
  int get equalizerBandCount => _bindings.vlcBridgeEqualizerGetBandCount();
  double getEqualizerBandFrequency(int idx) => _bindings.vlcBridgeEqualizerGetBandFrequency(idx);
  int setEqualizerPreset(int idx) => _bindings.vlcBridgeEqualizerSetPreset(idx);
  int setEqualizerPreamp(double preamp) => _bindings.vlcBridgeEqualizerSetPreamp(preamp);
  double get equalizerPreamp => _bindings.vlcBridgeEqualizerGetPreamp();
  int setEqualizerBandAmp(int band, double amp) => _bindings.vlcBridgeEqualizerSetAmp(band, amp);
  double getEqualizerBandAmp(int band) => _bindings.vlcBridgeEqualizerGetAmp(band);
  int enableEqualizer(bool enable) => _bindings.vlcBridgeEqualizerEnable(enable);

  /* Zero-Copy Hardware Surface */
  int setupGpuSurface(VlcSurfaceType type) => _bindings.setupGpuSurface(type);
  (int, int) get videoDimensions => _bindings.getVideoDimensions();

  void dispose() {
    _stateController.close();
    _positionController.close();
    _timeController.close();
    _volumeController.close();
    _bindings.vlcBridgeDestroy();
  }
}

