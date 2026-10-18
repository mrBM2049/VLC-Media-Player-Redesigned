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
