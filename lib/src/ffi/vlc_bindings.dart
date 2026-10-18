import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

enum VlcPlayerState {
  idle,
  opening,
  buffering,
  playing,
  paused,
  stopping,
  stopped,
  ended,
  error,
}

enum VlcSurfaceType {
  nativeWindow,
  metal,
  d3d11,
  androidSurface,
  softwareBgra,
}

enum VlcEventType {
  stateChanged,
  timeChanged,
  positionChanged,
  lengthChanged,
  volumeChanged,
  mutedChanged,
  rateChanged,
  mediaParsed,
  error,
  tracksChanged,
  chapterChanged,
}

final class VlcEventPayloadNative extends Struct {
  @Int32()
  external int type;

  @Int64()
  external int intValue;

  @Float()
  external double floatValue;

  external Pointer<Utf8> stringValue;
}

typedef VlcEventCallbackNative = Void Function(Pointer<VlcEventPayloadNative>, Pointer<Void>);
typedef VlcTrackEnumCallbackNative = Void Function(Int32, Pointer<Utf8>, Pointer<Void>);

/// Low-level C FFI Bindings to libvlc_modern_core
class VlcBridgeBindings {
  late final DynamicLibrary _lib;

  VlcBridgeBindings([String? libraryPath]) {
    try {
      if (libraryPath != null) {
        _lib = DynamicLibrary.open(libraryPath);
      } else if (Platform.isMacOS) {
        final frameworkPath = '${File(Platform.resolvedExecutable).parent.path}/../Frameworks/libvlc_modern_core.dylib';
        final local = File('build/native_core/libvlc_modern_core.dylib');
        if (File(frameworkPath).existsSync()) {
          _lib = DynamicLibrary.open(File(frameworkPath).absolute.path);
        } else if (local.existsSync()) {
          _lib = DynamicLibrary.open(local.absolute.path);
        } else {
          _lib = DynamicLibrary.open('libvlc_modern_core.dylib');
        }
      } else if (Platform.isWindows) {
        final local = File('build/native_core/vlc_modern_core.dll');
        if (local.existsSync()) {
          _lib = DynamicLibrary.open(local.absolute.path);
        } else {
          _lib = DynamicLibrary.open('vlc_modern_core.dll');
        }
      } else if (Platform.isLinux || Platform.isAndroid) {
        final local = File('build/native_core/libvlc_modern_core.so');
        if (local.existsSync()) {
          _lib = DynamicLibrary.open(local.absolute.path);
        } else {
          _lib = DynamicLibrary.open('libvlc_modern_core.so');
        }
      } else if (Platform.isIOS) {
        _lib = DynamicLibrary.process();
      } else {
        throw UnsupportedError('Unsupported platform for VLC bridge');
      }
      _initBindings();
    } catch (_) {
      _initMockBindings();
    }
  }

  VlcBridgeBindings.mock() {
    _initMockBindings();
  }

  /* Function pointers */
  late final int Function() vlcBridgeInit;
  late final void Function() vlcBridgeDestroy;
  late final bool Function() vlcBridgeIsInitialized;
  late final int Function(Pointer<Utf8>) _vlcBridgeOpen;
  late final int Function() vlcBridgePlay;
  late final int Function() vlcBridgePause;
  late final int Function() vlcBridgeStop;
  late final int Function() vlcBridgeTogglePlay;
  late final int Function() vlcBridgeGetTime;
  late final int Function(int) vlcBridgeSetTime;
  late final int Function() vlcBridgeGetLength;
  late final double Function() vlcBridgeGetPosition;
  late final int Function(double) vlcBridgeSetPosition;
  late final double Function() vlcBridgeGetRate;
  late final int Function(double) vlcBridgeSetRate;
  late final int Function() vlcBridgeGetVolume;
  late final int Function(int) vlcBridgeSetVolume;
  late final bool Function() vlcBridgeGetMute;
  late final int Function(bool) vlcBridgeSetMute;
  late final int Function() vlcBridgeToggleMute;
  late final int Function() _vlcBridgeGetState;
  late final int Function() vlcBridgeGetSpuDelay;
  late final int Function(int) vlcBridgeSetSpuDelay;
  late final int Function() vlcBridgeGetAudioDelay;
  late final int Function(int) vlcBridgeSetAudioDelay;
  late final int Function() vlcBridgeGetAudioTrackCount;
  late final int Function() vlcBridgeGetAudioTrack;
  late final int Function(int) vlcBridgeSetAudioTrack;
  late final int Function() vlcBridgeGetSpuCount;
  late final int Function() vlcBridgeGetSpuTrack;
  late final int Function(int) vlcBridgeSetSpuTrack;
  late final int Function(Pointer<Utf8>, bool) _vlcBridgeAddSubtitleFile;
  late final int Function() vlcBridgeGetChapterCount;
  late final int Function() vlcBridgeGetChapter;
  late final int Function(int) vlcBridgeSetChapter;
  late final int Function() vlcBridgeNextChapter;
  late final int Function() vlcBridgePreviousChapter;
  late final int Function() vlcBridgeNextFrame;
  late final int Function(Pointer<Utf8>, int, int) _vlcBridgeTakeSnapshot;
  late final int Function() vlcBridgeEqualizerGetPresetCount;
  late final Pointer<Utf8> Function(int) _vlcBridgeEqualizerGetPresetName;
  late final int Function() vlcBridgeEqualizerGetBandCount;
  late final double Function(int) vlcBridgeEqualizerGetBandFrequency;
  late final int Function(int) vlcBridgeEqualizerSetPreset;
  late final int Function(double) vlcBridgeEqualizerSetPreamp;
  late final double Function() vlcBridgeEqualizerGetPreamp;
  late final int Function(int, double) vlcBridgeEqualizerSetAmp;
  late final double Function(int) vlcBridgeEqualizerGetAmp;
  late final int Function(bool) vlcBridgeEqualizerEnable;
  late final Pointer<Utf8> Function() _vlcBridgeGetVersion;
  late final bool Function() vlcBridgeHasNativeVlc;
  late final int Function(Pointer<Void>) vlcBridgeSetNsobject;
  late final int Function(Pointer<Void>) vlcBridgeSetHwnd;
  late final int Function(Pointer<Void>) vlcBridgeSetAndroidContext;
  late final int Function(int, Pointer<Void>) vlcBridgeSetupGpuSurface;
  late final void Function(Pointer<Uint32>, Pointer<Uint32>) _vlcBridgeGetVideoDimensions;

  void _initBindings() {
    vlcBridgeInit = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_init');
    vlcBridgeDestroy = _lib.lookupFunction<Void Function(), void Function()>('vlc_bridge_destroy');
    vlcBridgeIsInitialized = _lib.lookupFunction<Bool Function(), bool Function()>('vlc_bridge_is_initialized');
    _vlcBridgeOpen = _lib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('vlc_bridge_open');
    vlcBridgePlay = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_play');
    vlcBridgePause = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_pause');
    vlcBridgeStop = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_stop');
    vlcBridgeTogglePlay = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_toggle_play');
    vlcBridgeGetTime = _lib.lookupFunction<Int64 Function(), int Function()>('vlc_bridge_get_time');
    vlcBridgeSetTime = _lib.lookupFunction<Int32 Function(Int64), int Function(int)>('vlc_bridge_set_time');
    vlcBridgeGetLength = _lib.lookupFunction<Int64 Function(), int Function()>('vlc_bridge_get_length');
    vlcBridgeGetPosition = _lib.lookupFunction<Float Function(), double Function()>('vlc_bridge_get_position');
    vlcBridgeSetPosition = _lib.lookupFunction<Int32 Function(Float), int Function(double)>('vlc_bridge_set_position');
    vlcBridgeGetRate = _lib.lookupFunction<Float Function(), double Function()>('vlc_bridge_get_rate');
    vlcBridgeSetRate = _lib.lookupFunction<Int32 Function(Float), int Function(double)>('vlc_bridge_set_rate');
    vlcBridgeGetVolume = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_volume');
    vlcBridgeSetVolume = _lib.lookupFunction<Int32 Function(Int32), int Function(int)>('vlc_bridge_set_volume');
    vlcBridgeGetMute = _lib.lookupFunction<Bool Function(), bool Function()>('vlc_bridge_get_mute');
    vlcBridgeSetMute = _lib.lookupFunction<Int32 Function(Bool), int Function(bool)>('vlc_bridge_set_mute');
    vlcBridgeToggleMute = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_toggle_mute');
    _vlcBridgeGetState = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_state');
    vlcBridgeGetSpuDelay = _lib.lookupFunction<Int64 Function(), int Function()>('vlc_bridge_get_spu_delay');
    vlcBridgeSetSpuDelay = _lib.lookupFunction<Int32 Function(Int64), int Function(int)>('vlc_bridge_set_spu_delay');
    vlcBridgeGetAudioDelay = _lib.lookupFunction<Int64 Function(), int Function()>('vlc_bridge_get_audio_delay');
    vlcBridgeSetAudioDelay = _lib.lookupFunction<Int32 Function(Int64), int Function(int)>('vlc_bridge_set_audio_delay');
    vlcBridgeGetAudioTrackCount = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_audio_track_count');
    vlcBridgeGetAudioTrack = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_audio_track');
    vlcBridgeSetAudioTrack = _lib.lookupFunction<Int32 Function(Int32), int Function(int)>('vlc_bridge_set_audio_track');
    vlcBridgeGetSpuCount = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_spu_count');
    vlcBridgeGetSpuTrack = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_spu_track');
    vlcBridgeSetSpuTrack = _lib.lookupFunction<Int32 Function(Int32), int Function(int)>('vlc_bridge_set_spu_track');
    _vlcBridgeAddSubtitleFile = _lib.lookupFunction<Int32 Function(Pointer<Utf8>, Bool), int Function(Pointer<Utf8>, bool)>('vlc_bridge_add_subtitle_file');
    vlcBridgeGetChapterCount = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_chapter_count');
    vlcBridgeGetChapter = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_get_chapter');
    vlcBridgeSetChapter = _lib.lookupFunction<Int32 Function(Int32), int Function(int)>('vlc_bridge_set_chapter');
    vlcBridgeNextChapter = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_next_chapter');
    vlcBridgePreviousChapter = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_previous_chapter');
    vlcBridgeNextFrame = _lib.lookupFunction<Int32 Function(), int Function()>('vlc_bridge_next_frame');
    _vlcBridgeTakeSnapshot = _lib.lookupFunction<Int32 Function(Pointer<Utf8>, Uint32, Uint32), int Function(Pointer<Utf8>, int, int)>('vlc_bridge_take_snapshot');
    vlcBridgeEqualizerGetPresetCount = _lib.lookupFunction<Uint32 Function(), int Function()>('vlc_bridge_equalizer_get_preset_count');
    _vlcBridgeEqualizerGetPresetName = _lib.lookupFunction<Pointer<Utf8> Function(Uint32), Pointer<Utf8> Function(int)>('vlc_bridge_equalizer_get_preset_name');
    vlcBridgeEqualizerGetBandCount = _lib.lookupFunction<Uint32 Function(), int Function()>('vlc_bridge_equalizer_get_band_count');
    vlcBridgeEqualizerGetBandFrequency = _lib.lookupFunction<Float Function(Uint32), double Function(int)>('vlc_bridge_equalizer_get_band_frequency');
    vlcBridgeEqualizerSetPreset = _lib.lookupFunction<Int32 Function(Uint32), int Function(int)>('vlc_bridge_equalizer_set_preset');
    vlcBridgeEqualizerSetPreamp = _lib.lookupFunction<Int32 Function(Float), int Function(double)>('vlc_bridge_equalizer_set_preamp');
    vlcBridgeEqualizerGetPreamp = _lib.lookupFunction<Float Function(), double Function()>('vlc_bridge_equalizer_get_preamp');
    vlcBridgeEqualizerSetAmp = _lib.lookupFunction<Int32 Function(Uint32, Float), int Function(int, double)>('vlc_bridge_equalizer_set_amp');
    vlcBridgeEqualizerGetAmp = _lib.lookupFunction<Float Function(Uint32), double Function(int)>('vlc_bridge_equalizer_get_amp');
    vlcBridgeEqualizerEnable = _lib.lookupFunction<Int32 Function(Bool), int Function(bool)>('vlc_bridge_equalizer_enable');
    _vlcBridgeGetVersion = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('vlc_bridge_get_version');
    vlcBridgeHasNativeVlc = _lib.lookupFunction<Bool Function(), bool Function()>('vlc_bridge_has_native_vlc');
    vlcBridgeSetNsobject = _lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('vlc_bridge_set_nsobject');
    vlcBridgeSetHwnd = _lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('vlc_bridge_set_hwnd');
    vlcBridgeSetAndroidContext = _lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('vlc_bridge_set_android_context');
    vlcBridgeSetupGpuSurface = _lib.lookupFunction<Int32 Function(Int32, Pointer<Void>), int Function(int, Pointer<Void>)>('vlc_bridge_setup_gpu_surface');
    _vlcBridgeGetVideoDimensions = _lib.lookupFunction<Void Function(Pointer<Uint32>, Pointer<Uint32>), void Function(Pointer<Uint32>, Pointer<Uint32>)>('vlc_bridge_get_video_dimensions');
  }

  void _initMockBindings() {
    vlcBridgeInit = () => 0;
    vlcBridgeDestroy = () {};
    vlcBridgeIsInitialized = () => true;
    _vlcBridgeOpen = (_) => 0;
    vlcBridgePlay = () => 0;
    vlcBridgePause = () => 0;
    vlcBridgeStop = () => 0;
    vlcBridgeTogglePlay = () => 0;
    vlcBridgeGetTime = () => 0;
    vlcBridgeSetTime = (_) => 0;
    vlcBridgeGetLength = () => 100000;
    vlcBridgeGetPosition = () => 0.0;
    vlcBridgeSetPosition = (_) => 0;
    vlcBridgeGetRate = () => 1.0;
    vlcBridgeSetRate = (_) => 0;
    vlcBridgeGetVolume = () => 100;
    vlcBridgeSetVolume = (_) => 0;
    vlcBridgeGetMute = () => false;
    vlcBridgeSetMute = (_) => 0;
    vlcBridgeToggleMute = () => 0;
    _vlcBridgeGetState = () => 0;
    vlcBridgeGetSpuDelay = () => 0;
    vlcBridgeSetSpuDelay = (_) => 0;
    vlcBridgeGetAudioDelay = () => 0;
    vlcBridgeSetAudioDelay = (_) => 0;
    vlcBridgeGetAudioTrackCount = () => 0;
    vlcBridgeGetAudioTrack = () => -1;
    vlcBridgeSetAudioTrack = (_) => 0;
    vlcBridgeGetSpuCount = () => 0;
    vlcBridgeGetSpuTrack = () => -1;
    vlcBridgeSetSpuTrack = (_) => 0;
    _vlcBridgeAddSubtitleFile = (_, __) => 0;
    vlcBridgeGetChapterCount = () => 0;
    vlcBridgeGetChapter = () => 0;
    vlcBridgeSetChapter = (_) => 0;
    vlcBridgeNextChapter = () => 0;
    vlcBridgePreviousChapter = () => 0;
    vlcBridgeNextFrame = () => 0;
    _vlcBridgeTakeSnapshot = (_, __, ___) => 0;
    vlcBridgeEqualizerGetPresetCount = () => 0;
    _vlcBridgeEqualizerGetPresetName = (_) => Pointer.fromAddress(0);
    vlcBridgeEqualizerGetBandCount = () => 0;
    vlcBridgeEqualizerGetBandFrequency = (_) => 0.0;
    vlcBridgeEqualizerSetPreset = (_) => 0;
    vlcBridgeEqualizerSetPreamp = (_) => 0;
    vlcBridgeEqualizerGetPreamp = () => 0.0;
    vlcBridgeEqualizerSetAmp = (_, __) => 0;
    vlcBridgeEqualizerGetAmp = (_) => 0.0;
    vlcBridgeEqualizerEnable = (_) => 0;
    _vlcBridgeGetVersion = () => Pointer.fromAddress(0);
    vlcBridgeHasNativeVlc = () => false;
    vlcBridgeSetNsobject = (_) => 0;
    vlcBridgeSetHwnd = (_) => 0;
    vlcBridgeSetAndroidContext = (_) => 0;
    vlcBridgeSetupGpuSurface = (_, __) => 0;
    _vlcBridgeGetVideoDimensions = (w, h) {
      w.value = 1920;
      h.value = 1080;
    };
  }

  int open(String mrl) {
    final nativeStr = mrl.toNativeUtf8();
    try {
      return _vlcBridgeOpen(nativeStr);
    } finally {
      calloc.free(nativeStr);
    }
  }

  VlcPlayerState getState() {
    final raw = _vlcBridgeGetState();
    if (raw >= 0 && raw < VlcPlayerState.values.length) {
      return VlcPlayerState.values[raw];
    }
    return VlcPlayerState.idle;
  }

  String getVersion() {
    final ptr = _vlcBridgeGetVersion();
    return ptr == Pointer.fromAddress(0) ? 'Unknown' : ptr.toDartString();
  }

  String? getEqualizerPresetName(int index) {
    final ptr = _vlcBridgeEqualizerGetPresetName(index);
    return ptr == Pointer.fromAddress(0) ? null : ptr.toDartString();
  }

  int addSubtitleFile(String path, bool select) {
    final nativeStr = path.toNativeUtf8();
    try {
      return _vlcBridgeAddSubtitleFile(nativeStr, select);
    } finally {
      calloc.free(nativeStr);
    }
  }

  int takeSnapshot(String filepath, int width, int height) {
    final nativeStr = filepath.toNativeUtf8();
    try {
      return _vlcBridgeTakeSnapshot(nativeStr, width, height);
    } finally {
      calloc.free(nativeStr);
    }
  }

  int setNsObject(Pointer<Void> view) => vlcBridgeSetNsobject(view);
  int setHwnd(Pointer<Void> hwnd) => vlcBridgeSetHwnd(hwnd);
  int setAndroidContext(Pointer<Void> awindow) => vlcBridgeSetAndroidContext(awindow);
  int setupGpuSurface(VlcSurfaceType type, [Pointer<Void>? platformContext]) {
    return vlcBridgeSetupGpuSurface(
      type.index,
      platformContext ?? Pointer.fromAddress(0),
    );
  }

  (int, int) getVideoDimensions() {
    final wPtr = calloc<Uint32>();
    final hPtr = calloc<Uint32>();
    try {
      _vlcBridgeGetVideoDimensions(wPtr, hPtr);
      return (wPtr.value, hPtr.value);
    } finally {
      calloc.free(wPtr);
      calloc.free(hPtr);
    }
  }
}

