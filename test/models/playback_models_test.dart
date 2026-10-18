import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('Playback Models & Looper Tests', () {
    test('VlcPlaybackBookmark equality, copyWith, and fields', () {
      final now = DateTime.now();
      final bm = VlcPlaybackBookmark(
        id: 'bm1',
        title: 'Action Scene Climax',
        position: const Duration(minutes: 42, seconds: 15),
        createdAt: now,
      );

      expect(bm.id, equals('bm1'));
      expect(bm.title, equals('Action Scene Climax'));
      expect(bm.position, equals(const Duration(minutes: 42, seconds: 15)));

      final copied = bm.copyWith(title: 'Edited Title');
      expect(copied.title, equals('Edited Title'));
      expect(copied.position, equals(bm.position));
      expect(copied.id, equals(bm.id));
    });

    test('VlcAtoBLoop logic: setting Point A, Point B, clearing, and completing', () {
      const loop = VlcAtoBLoop();
      expect(loop.isActive, isFalse);
      expect(loop.isComplete, isFalse);
      expect(loop.pointA, isNull);
      expect(loop.pointB, isNull);

      final withA = loop.withPointA(const Duration(seconds: 10));
      expect(withA.pointA, equals(const Duration(seconds: 10)));
      expect(withA.pointB, isNull);
      expect(withA.isComplete, isFalse);
      expect(withA.isActive, isFalse);

      final withB = withA.withPointB(const Duration(seconds: 35));
      expect(withB.pointA, equals(const Duration(seconds: 10)));
      expect(withB.pointB, equals(const Duration(seconds: 35)));
      expect(withB.isComplete, isTrue);
      expect(withB.isActive, isTrue);

      // Toggling active state
      final toggled = withB.toggleActive();
      expect(toggled.isActive, isFalse);

      // Setting Point A past Point B resets Point B
      final movedA = withB.withPointA(const Duration(seconds: 40));
      expect(movedA.pointA, equals(const Duration(seconds: 40)));
      expect(movedA.pointB, isNull);
      expect(movedA.isActive, isFalse);

      // Clearing loop
      final cleared = withB.cleared();
      expect(cleared.pointA, isNull);
      expect(cleared.pointB, isNull);
      expect(cleared.isActive, isFalse);
    });

    test('VlcSleepTimerPreset values and durations', () {
      expect(VlcSleepTimerPreset.values.length, equals(7));
      expect(VlcSleepTimerPreset.off.duration, isNull);
      expect(VlcSleepTimerPreset.m15.duration, equals(const Duration(minutes: 15)));
      expect(VlcSleepTimerPreset.m60.duration, equals(const Duration(hours: 1)));
      expect(VlcSleepTimerPreset.endOfMedia.duration, isNull);
    });

    test('PlaybackStateConfig defaults and copyWith', () {
      const config = PlaybackStateConfig();
      expect(config.playbackRate, equals(1.0));
      expect(config.preservePitch, isTrue);
      expect(config.aToBLoop.isActive, isFalse);
      expect(config.sleepTimer, equals(VlcSleepTimerPreset.off));
      expect(config.showWaveformOverlay, isTrue);
      expect(config.showThumbnailPreviewOverlay, isTrue);
      expect(config.showChapterTicksOverlay, isTrue);
      expect(config.bookmarks.isEmpty, isTrue);

      final updated = config.copyWith(
        playbackRate: 1.5,
        preservePitch: false,
        sleepTimer: VlcSleepTimerPreset.m30,
        showWaveformOverlay: false,
      );

      expect(updated.playbackRate, equals(1.5));
      expect(updated.preservePitch, isFalse);
      expect(updated.sleepTimer, equals(VlcSleepTimerPreset.m30));
      expect(updated.showWaveformOverlay, isFalse);
      expect(updated.showThumbnailPreviewOverlay, isTrue); // unchanged
    });
  });
}

