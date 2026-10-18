/// Audio domain models for VLC Modern Redesign

enum VlcAudioDeviceType {
  speakers,
  headphones,
  bluetooth,
  hdmi,
  usb,
  systemDefault,
}

class VlcAudioTrack {
  final int id;
  final String name;
  final String language;
  final String codec;
  final int channels;
  final bool isEmbedded;

  const VlcAudioTrack({
    required this.id,
    required this.name,
    this.language = 'und',
    this.codec = 'PCM',
    this.channels = 2,
    this.isEmbedded = true,
  });

  static const VlcAudioTrack disabled = VlcAudioTrack(
    id: -1,
    name: 'Disable Audio',
    language: 'none',
    codec: 'None',
    channels: 0,
    isEmbedded: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VlcAudioTrack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VlcAudioOutputDevice {
  final String id;
  final String name;
  final VlcAudioDeviceType type;
  final bool isSelected;

  const VlcAudioOutputDevice({
    required this.id,
    required this.name,
    this.type = VlcAudioDeviceType.speakers,
    this.isSelected = false,
  });

  VlcAudioOutputDevice copyWith({
    String? id,
    String? name,
    VlcAudioDeviceType? type,
    bool? isSelected,
  }) {
    return VlcAudioOutputDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Standard 10-band ISO Equalizer definitions matching libvlc_audio_equalizer_t
class AudioEqualizerBand {
  final int index;
  final double frequencyHz;
  final String label;

  const AudioEqualizerBand({
    required this.index,
    required this.frequencyHz,
    required this.label,
  });

  static const List<AudioEqualizerBand> standardBands = [
    AudioEqualizerBand(index: 0, frequencyHz: 60.0, label: '60 Hz'),
    AudioEqualizerBand(index: 1, frequencyHz: 170.0, label: '170 Hz'),
    AudioEqualizerBand(index: 2, frequencyHz: 310.0, label: '310 Hz'),
    AudioEqualizerBand(index: 3, frequencyHz: 600.0, label: '600 Hz'),
    AudioEqualizerBand(index: 4, frequencyHz: 1000.0, label: '1 kHz'),
    AudioEqualizerBand(index: 5, frequencyHz: 3000.0, label: '3 kHz'),
    AudioEqualizerBand(index: 6, frequencyHz: 6000.0, label: '6 kHz'),
    AudioEqualizerBand(index: 7, frequencyHz: 12000.0, label: '12 kHz'),
    AudioEqualizerBand(index: 8, frequencyHz: 14000.0, label: '14 kHz'),
    AudioEqualizerBand(index: 9, frequencyHz: 16000.0, label: '16 kHz'),
  ];
}

/// Visual Audio Filter Preset card model
class AudioEqualizerPreset {
  final String id;
  final String name;
  final String subtitle;
  final String iconKey;
  final double preamp;
  final List<double> bands; // 10 amplitude values in dB (-20.0 to +20.0)

  const AudioEqualizerPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconKey,
    this.preamp = 0.0,
    required this.bands,
  });

  static const AudioEqualizerPreset flat = AudioEqualizerPreset(
    id: 'flat',
    name: 'Flat (Neutral)',
    subtitle: 'Zero coloration • Pure studio sound',
    iconKey: 'flat',
    preamp: 0.0,
    bands: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  );

  static const AudioEqualizerPreset bassBoost = AudioEqualizerPreset(
    id: 'bass_boost',
    name: 'Bass Boost',
    subtitle: 'Punchy low end • Sub-woofer impact',
    iconKey: 'bass',
    preamp: 2.0,
    bands: [7.0, 6.0, 4.5, 2.0, 0.0, 0.0, 1.0, 2.0, 3.0, 3.5],
  );

  static const AudioEqualizerPreset vocalClarity = AudioEqualizerPreset(
    id: 'vocal_clarity',
    name: 'Vocal Clarity',
    subtitle: 'Dialogue boost • Whisper isolation',
    iconKey: 'vocal',
    preamp: 1.0,
    bands: [-2.0, -1.0, 0.0, 2.5, 5.0, 5.5, 4.0, 2.0, 0.0, -1.0],
  );

  static const AudioEqualizerPreset lateNight = AudioEqualizerPreset(
    id: 'late_night',
    name: 'Late Night',
    subtitle: 'Dynamic compression • Quiet explosions',
    iconKey: 'moon',
    preamp: 0.0,
    bands: [-6.0, -4.0, -2.0, 1.0, 3.5, 4.0, 2.0, 0.0, -3.0, -5.0],
  );

  static const AudioEqualizerPreset rock = AudioEqualizerPreset(
    id: 'rock',
    name: 'Rock / Modern',
    subtitle: 'V-Curve EQ • High energy',
    iconKey: 'rock',
    preamp: 1.5,
    bands: [5.0, 4.0, 2.0, -1.0, -2.5, -1.5, 2.0, 4.0, 5.5, 6.0],
  );

  static const AudioEqualizerPreset classical = AudioEqualizerPreset(
    id: 'classical',
    name: 'Classical & Acoustic',
    subtitle: 'Natural strings • Smooth warmth',
    iconKey: 'classical',
    preamp: 0.5,
    bands: [4.0, 3.5, 2.5, 1.5, -1.0, -1.5, 0.0, 2.5, 3.5, 4.0],
  );

  static const List<AudioEqualizerPreset> standardPresets = [
    flat,
    bassBoost,
    vocalClarity,
    lateNight,
    rock,
    classical,
  ];
}

/// Reactive State for Audio Effects, 10-Band EQ & Spatial Filters
class AudioFilterState {
  final bool isEqEnabled;
  final double preamp;
  final List<double> bands; // 10 bands
  final String activePresetId;
  final bool spatialAudio;
  final bool loudnessNormalization;

  const AudioFilterState({
    this.isEqEnabled = true,
    this.preamp = 0.0,
    this.bands = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    this.activePresetId = 'flat',
    this.spatialAudio = false,
    this.loudnessNormalization = false,
  });

  AudioFilterState copyWith({
    bool? isEqEnabled,
    double? preamp,
    List<double>? bands,
    String? activePresetId,
    bool? spatialAudio,
    bool? loudnessNormalization,
  }) {
    return AudioFilterState(
      isEqEnabled: isEqEnabled ?? this.isEqEnabled,
      preamp: preamp ?? this.preamp,
      bands: bands != null ? List<double>.from(bands) : this.bands,
      activePresetId: activePresetId ?? this.activePresetId,
      spatialAudio: spatialAudio ?? this.spatialAudio,
      loudnessNormalization: loudnessNormalization ?? this.loudnessNormalization,
    );
  }
}


