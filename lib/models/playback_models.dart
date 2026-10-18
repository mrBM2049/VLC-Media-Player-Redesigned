import 'package:flutter/foundation.dart';

/// Representation of a user or chapter bookmark
class VlcPlaybackBookmark {
  final String id;
  final String title;
  final Duration position;
  final String? note;
  final DateTime createdAt;

  const VlcPlaybackBookmark({
    required this.id,
    required this.title,
    required this.position,
    this.note,
    required this.createdAt,
  });

  VlcPlaybackBookmark copyWith({
    String? id,
    String? title,
    Duration? position,
    String? note,
    DateTime? createdAt,
  }) {
    return VlcPlaybackBookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      position: position ?? this.position,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VlcPlaybackBookmark &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          position == other.position;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ position.hashCode;
}

/// A-to-B Repeat Looper State
class VlcAtoBLoop {
  final Duration? pointA;
  final Duration? pointB;
  final bool isActive;

  const VlcAtoBLoop({
    this.pointA,
    this.pointB,
    this.isActive = false,
  });

  bool get isComplete => pointA != null && pointB != null && pointB! > pointA!;

  VlcAtoBLoop withPointA(Duration a) {
    // If point B is already set and <= point A, clear point B
    final newB = (pointB != null && pointB! <= a) ? null : pointB;
    final active = newB != null && newB > a;
    return VlcAtoBLoop(pointA: a, pointB: newB, isActive: active);
  }

  VlcAtoBLoop withPointB(Duration b) {
    if (pointA == null || b <= pointA!) {
      return VlcAtoBLoop(pointA: pointA, pointB: b, isActive: false);
    }
    return VlcAtoBLoop(pointA: pointA, pointB: b, isActive: true);
  }

  VlcAtoBLoop cleared() => const VlcAtoBLoop();

  VlcAtoBLoop toggleActive() {
    if (!isComplete) return this;
    return VlcAtoBLoop(pointA: pointA, pointB: pointB, isActive: !isActive);
  }
}

/// Sleep Timer Options
enum VlcSleepTimerPreset {
  off('Off', null),
  m15('15 Minutes', Duration(minutes: 15)),
  m30('30 Minutes', Duration(minutes: 30)),
  m45('45 Minutes', Duration(minutes: 45)),
  m60('60 Minutes (1 Hour)', Duration(hours: 1)),
  m90('90 Minutes', Duration(minutes: 90)),
  endOfMedia('End of Current Media', null);

  final String label;
  final Duration? duration;
  const VlcSleepTimerPreset(this.label, this.duration);
}

/// Comprehensive State for Tab 4 Playback Inspector
class PlaybackStateConfig {
  final double playbackRate; // 0.25 to 4.0
  final bool preservePitch;
  final VlcAtoBLoop aToBLoop;
  final VlcSleepTimerPreset sleepTimer;
  final bool showWaveformOverlay;
  final bool showThumbnailPreviewOverlay;
  final bool showChapterTicksOverlay;
  final List<VlcPlaybackBookmark> bookmarks;

  const PlaybackStateConfig({
    this.playbackRate = 1.0,
    this.preservePitch = true,
    this.aToBLoop = const VlcAtoBLoop(),
    this.sleepTimer = VlcSleepTimerPreset.off,
    this.showWaveformOverlay = true,
    this.showThumbnailPreviewOverlay = true,
    this.showChapterTicksOverlay = true,
    this.bookmarks = const [],
  });

  PlaybackStateConfig copyWith({
    double? playbackRate,
    bool? preservePitch,
    VlcAtoBLoop? aToBLoop,
    VlcSleepTimerPreset? sleepTimer,
    bool? showWaveformOverlay,
    bool? showThumbnailPreviewOverlay,
    bool? showChapterTicksOverlay,
    List<VlcPlaybackBookmark>? bookmarks,
  }) {
    return PlaybackStateConfig(
      playbackRate: playbackRate ?? this.playbackRate,
      preservePitch: preservePitch ?? this.preservePitch,
      aToBLoop: aToBLoop ?? this.aToBLoop,
      sleepTimer: sleepTimer ?? this.sleepTimer,
      showWaveformOverlay: showWaveformOverlay ?? this.showWaveformOverlay,
      showThumbnailPreviewOverlay:
          showThumbnailPreviewOverlay ?? this.showThumbnailPreviewOverlay,
      showChapterTicksOverlay:
          showChapterTicksOverlay ?? this.showChapterTicksOverlay,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
