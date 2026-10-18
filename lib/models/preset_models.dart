import 'package:flutter/foundation.dart';

/// Predefined or user-customized preset profile for shows, anime, movies, or podcasts.
/// Encapsulates per-show audio EQ, subtitle appearance, aspect ratio, and playback defaults.
class ShowPresetProfile {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final bool isCustom;

  const ShowPresetProfile({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    this.isCustom = false,
  });

  static const ShowPresetProfile standard = ShowPresetProfile(
    id: 'standard',
    name: 'Standard (Neutral)',
    subtitle: 'Flat EQ • Original Aspect • Default Subs',
    description: 'Original unaltered VideoLAN audio, video colors, and subtitle rendering.',
  );

  static const ShowPresetProfile anime = ShowPresetProfile(
    id: 'anime',
    name: 'Anime & Asian Cinema',
    subtitle: 'Vocal Boost • Crisp Subtitles • 16:9 Fit',
    description: 'Dialogue-clarity audio EQ, high-contrast crisp subtitles, and color vibrance.',
  );

  static const ShowPresetProfile action = ShowPresetProfile(
    id: 'action',
    name: 'Action & Blockbuster',
    subtitle: 'Bass Boost EQ • 2.39:1 Crop • HDR Vivid',
    description: 'Heavy bass boost, anamorphic letterbox crop, and boosted dynamic range.',
  );

  static const ShowPresetProfile lateNight = ShowPresetProfile(
    id: 'late_night',
    name: 'Late Night (Quiet)',
    subtitle: 'Compressed Dynamic Range • Sub Bass Muted',
    description: 'Elevates quiet whispers while suppressing loud explosions and bass frequencies.',
  );

  static const ShowPresetProfile podcast = ShowPresetProfile(
    id: 'podcast',
    name: 'Podcast & Speech',
    subtitle: 'Vocal Enhance • 1.25x Speed',
    description: 'Optimized voice frequencies and mild speed acceleration for spoken content.',
  );

  static const List<ShowPresetProfile> defaultPresets = [
    standard,
    anime,
    action,
    lateNight,
    podcast,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowPresetProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ShowPresetProfile(id: $id, name: $name)';
}

/// Reactive Controller managing active preset profiles and per-show persistence.
class PresetController extends ChangeNotifier {
  final List<ShowPresetProfile> _presets = List.from(ShowPresetProfile.defaultPresets);
  ShowPresetProfile _activePreset = ShowPresetProfile.standard;
  bool _applyToAllFolderEpisodes = true;
  String _folderName;

  PresetController({
    String folderName = 'Demo Media',
    ShowPresetProfile? initialPreset,
    bool initialApplyToFolder = true,
  })  : _folderName = folderName,
        _applyToAllFolderEpisodes = initialApplyToFolder {
    if (initialPreset != null) {
      _activePreset = initialPreset;
    }
  }

  List<ShowPresetProfile> get presets => List.unmodifiable(_presets);
  ShowPresetProfile get activePreset => _activePreset;
  bool get applyToAllFolderEpisodes => _applyToAllFolderEpisodes;
  String get folderName => _folderName;

  void setFolderName(String name) {
    if (_folderName != name) {
      _folderName = name;
      notifyListeners();
    }
  }

  void selectPreset(ShowPresetProfile preset) {
    if (_activePreset != preset) {
      _activePreset = preset;
      notifyListeners();
    }
  }

  void setApplyToFolder(bool value) {
    if (_applyToAllFolderEpisodes != value) {
      _applyToAllFolderEpisodes = value;
      notifyListeners();
    }
  }

  void saveCustomPreset(String name, String description) {
    final custom = ShowPresetProfile(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      subtitle: 'Custom User Profile',
      description: description,
      isCustom: true,
    );
    _presets.add(custom);
    _activePreset = custom;
    notifyListeners();
  }

  void deleteCustomPreset(String id) {
    final index = _presets.indexWhere((p) => p.id == id && p.isCustom);
    if (index != -1) {
      final removed = _presets.removeAt(index);
      if (_activePreset == removed) {
        _activePreset = ShowPresetProfile.standard;
      }
      notifyListeners();
    }
  }
}

