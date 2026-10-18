import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Available toolbar button identifiers for customization.
enum ToolbarButtonId {
  playPause('Play / Pause', Icons.play_arrow),
  stop('Stop Playback', Icons.stop),
  previous('Previous Track', Icons.skip_previous),
  next('Next Track', Icons.skip_next),
  stepForward('Frame Step Forward', Icons.arrow_forward),
  stepBackward('Frame Step Backward', Icons.arrow_back),
  volume('Volume & Mute', Icons.volume_up),
  timeDisplay('Elapsed & Remaining Time', Icons.schedule),
  playbackSpeed('Speed Controller', Icons.speed),
  repeat('Repeat Mode', Icons.repeat),
  shuffle('Shuffle Tracks', Icons.shuffle),
  subtitles('Subtitle Track Quick Menu', Icons.subtitles),
  audioTrack('Audio Track Quick Menu', Icons.audiotrack),
  equalizer('Equalizer Quick Trigger', Icons.equalizer),
  queue('Playback Queue Drawer', Icons.queue_music),
  snapshot('Take Video Snapshot', Icons.camera_alt),
  bookmark('Add Bookmark', Icons.bookmark_add),
  fullscreen('Toggle Fullscreen', Icons.fullscreen),
  pip('Picture-in-Picture', Icons.picture_in_picture);

  final String label;
  final IconData icon;

  const ToolbarButtonId(this.label, this.icon);
}

/// User layout preset profile for toolbar configuration.
class ToolbarProfile {
  final String id;
  final String name;
  final String description;
  final List<ToolbarButtonId> topBarButtons;
  final List<ToolbarButtonId> bottomBarButtons;

  const ToolbarProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.topBarButtons,
    required this.bottomBarButtons,
  });

  ToolbarProfile copyWith({
    String? name,
    String? description,
    List<ToolbarButtonId>? topBarButtons,
    List<ToolbarButtonId>? bottomBarButtons,
  }) {
    return ToolbarProfile(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      topBarButtons: topBarButtons ?? List.from(this.topBarButtons),
      bottomBarButtons: bottomBarButtons ?? List.from(this.bottomBarButtons),
    );
  }

  /// Preset 1: Standard Balanced Juxtopposed Modern Redesign
  static const ToolbarProfile standard = ToolbarProfile(
    id: 'standard',
    name: 'Standard (Balanced)',
    description: 'Clean modern layout with balanced transport and quick drawers.',
    topBarButtons: [
      ToolbarButtonId.pip,
      ToolbarButtonId.fullscreen,
    ],
    bottomBarButtons: [
      ToolbarButtonId.previous,
      ToolbarButtonId.playPause,
      ToolbarButtonId.next,
      ToolbarButtonId.timeDisplay,
      ToolbarButtonId.volume,
      ToolbarButtonId.playbackSpeed,
      ToolbarButtonId.subtitles,
      ToolbarButtonId.audioTrack,
      ToolbarButtonId.queue,
    ],
  );

  /// Preset 2: Minimalist / Cinematic (Pure Immersion)
  static const ToolbarProfile minimal = ToolbarProfile(
    id: 'minimal',
    name: 'Minimalist (Cinematic)',
    description: 'Stripped down to absolute essentials for distraction-free movie viewing.',
    topBarButtons: [
      ToolbarButtonId.fullscreen,
    ],
    bottomBarButtons: [
      ToolbarButtonId.playPause,
      ToolbarButtonId.timeDisplay,
      ToolbarButtonId.volume,
    ],
  );

  /// Preset 3: Power User / Studio Editor
  static const ToolbarProfile powerUser = ToolbarProfile(
    id: 'power_user',
    name: 'Power User (Studio)',
    description: 'Full transport controls with frame stepping, snapshots, and bookmarks.',
    topBarButtons: [
      ToolbarButtonId.snapshot,
      ToolbarButtonId.bookmark,
      ToolbarButtonId.pip,
      ToolbarButtonId.fullscreen,
    ],
    bottomBarButtons: [
      ToolbarButtonId.stepBackward,
      ToolbarButtonId.previous,
      ToolbarButtonId.playPause,
      ToolbarButtonId.stop,
      ToolbarButtonId.next,
      ToolbarButtonId.stepForward,
      ToolbarButtonId.timeDisplay,
      ToolbarButtonId.volume,
      ToolbarButtonId.playbackSpeed,
      ToolbarButtonId.repeat,
      ToolbarButtonId.subtitles,
      ToolbarButtonId.audioTrack,
      ToolbarButtonId.equalizer,
      ToolbarButtonId.queue,
    ],
  );

  /// Preset 4: Audio / Hi-Fi Music Focus
  static const ToolbarProfile audioMusic = ToolbarProfile(
    id: 'audio_music',
    name: 'Music & Hi-Fi',
    description: 'Optimized for music playlists with shuffle, repeat, and equalizer.',
    topBarButtons: [
      ToolbarButtonId.queue,
    ],
    bottomBarButtons: [
      ToolbarButtonId.previous,
      ToolbarButtonId.playPause,
      ToolbarButtonId.next,
      ToolbarButtonId.shuffle,
      ToolbarButtonId.repeat,
      ToolbarButtonId.timeDisplay,
      ToolbarButtonId.volume,
      ToolbarButtonId.equalizer,
      ToolbarButtonId.queue,
    ],
  );

  static const List<ToolbarProfile> defaultProfiles = [
    standard,
    minimal,
    powerUser,
    audioMusic,
  ];
}

