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
    if (libraryPath != null) {
      _lib = DynamicLibrary.open(libraryPath);
    } else if (Platform.isMacOS) {
      _lib = DynamicLibrary.open('libvlc_modern_core.dylib');
    } else if (Platform.isWindows) {
      _lib = DynamicLibrary.open('vlc_modern_core.dll');
    } else if (Platform.isLinux || Platform.isAndroid) {
      _lib = DynamicLibrary.open('libvlc_modern_core.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('Unsupported platform for VLC bridge');
    }

    _initBindings();
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
}
