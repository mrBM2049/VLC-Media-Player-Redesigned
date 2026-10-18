import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  final testChapters = [
    const ChapterTick(
      fraction: 0.15,
      title: 'Chapter 1: The Launch',
      time: Duration(minutes: 15),
    ),
    const ChapterTick(
      fraction: 0.45,
      title: 'Chapter 2: Gargantua',
      time: Duration(minutes: 45),
    ),
    const ChapterTick(
      fraction: 0.85,
      title: 'Chapter 3: Homecoming',
      time: Duration(hours: 1, minutes: 25),
    ),
  ];

  Widget buildTestWidget({
    required PlaybackStateConfig config,
    required Duration currentPosition,
    required Duration totalDuration,
    List<ChapterTick> chapters = const [],
    ValueChanged<PlaybackStateConfig>? onConfigChanged,
    ValueChanged<Duration>? onSeekTo,
    VoidCallback? onNextFrame,
    VoidCallback? onPreviousFrame,
  }) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
        body: SizedBox(
          width: 340.0,
          child: PlaybackInspectorTab(
            config: config,
            currentPosition: currentPosition,
            totalDuration: totalDuration,
            chapters: chapters,
            onConfigChanged: onConfigChanged ?? (_) {},
            onSeekTo: onSeekTo,
            onNextFrame: onNextFrame,
            onPreviousFrame: onPreviousFrame,
          ),
        ),
      ),
    );
  }

  group('PlaybackInspectorTab Widget Tests', () {
    testWidgets('Renders all sections: speed, looper, stepping, chapters, bookmarks, sleep timer, overlays', (tester) async {
      tester.view.physicalSize = const Size(340, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          config: const PlaybackStateConfig(),
          currentPosition: const Duration(minutes: 20),
          totalDuration: const Duration(hours: 2),
          chapters: testChapters,
        ),
      );

      // Section Titles
      expect(find.text('PLAYBACK SPEED'), findsOneWidget);
      expect(find.text('1.00x'), findsWidgets);
      expect(find.text('A-TO-B REPEAT LOOPER'), findsOneWidget);
      expect(find.text('FRAME STEPPING & MICRO NAVIGATION'), findsOneWidget);
      expect(find.text('CHAPTERS (3)'), findsOneWidget);
      expect(find.text('BOOKMARKS (0)'), findsOneWidget);
      expect(find.text('SLEEP TIMER'), findsOneWidget);
      expect(find.text('SEEK BAR OVERLAYS'), findsOneWidget);

      // Chapter Items
      expect(find.text('Chapter 1: The Launch'), findsOneWidget);
      expect(find.text('Chapter 2: Gargantua'), findsOneWidget);

      // Overlay toggles
      expect(find.text('Audio Waveform Overlay'), findsOneWidget);
      expect(find.text('Thumbnail Hover Previews'), findsOneWidget);
      expect(find.text('Chapter Marker Ticks'), findsOneWidget);
    });

    testWidgets('Tapping speed preset button updates playback rate', (tester) async {
      tester.view.physicalSize = const Size(340, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PlaybackStateConfig? updated;
      await tester.pumpWidget(
        buildTestWidget(
          config: const PlaybackStateConfig(playbackRate: 1.0),
          currentPosition: Duration.zero,
          totalDuration: const Duration(hours: 1),
          onConfigChanged: (c) => updated = c,
        ),
      );

      await tester.tap(find.text('1.5x'));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.playbackRate, equals(1.5));
    });

    testWidgets('Setting Point A and Point B in A-to-B Looper', (tester) async {
      tester.view.physicalSize = const Size(340, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PlaybackStateConfig currentConfig = const PlaybackStateConfig();

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (ctx, setState) {
            return buildTestWidget(
              config: currentConfig,
              currentPosition: const Duration(minutes: 10),
              totalDuration: const Duration(hours: 1),
              onConfigChanged: (c) {
                setState(() => currentConfig = c);
              },
            );
          },
        ),
      );

      // Tap "Set A"
      await tester.tap(find.text('Set A'));
      await tester.pump();

      expect(currentConfig.aToBLoop.pointA, equals(const Duration(minutes: 10)));
      expect(currentConfig.aToBLoop.pointB, isNull);

      // Tap "Set B"
      await tester.tap(find.text('Set B'));
      await tester.pump();

      // Since position is still 10:00 (not > A), pointB is not > A so isActive is false
      expect(currentConfig.aToBLoop.pointB, equals(const Duration(minutes: 10)));
    });

    testWidgets('Frame Stepping Next Frame and Previous Frame triggers callbacks', (tester) async {
      tester.view.physicalSize = const Size(340, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool nextFrameCalled = false;
      bool prevFrameCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          config: const PlaybackStateConfig(),
          currentPosition: const Duration(minutes: 5),
          totalDuration: const Duration(hours: 1),
          onNextFrame: () => nextFrameCalled = true,
          onPreviousFrame: () => prevFrameCalled = true,
        ),
      );

      await tester.tap(find.text('Frame ▶'));
      await tester.pump();
      expect(nextFrameCalled, isTrue);

      await tester.tap(find.text('◀ Frame'));
      await tester.pump();
      expect(prevFrameCalled, isTrue);
    });

    testWidgets('Adding and deleting a bookmark', (tester) async {
      tester.view.physicalSize = const Size(340, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PlaybackStateConfig currentConfig = const PlaybackStateConfig();

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (ctx, setState) {
            return buildTestWidget(
              config: currentConfig,
              currentPosition: const Duration(minutes: 12, seconds: 34),
              totalDuration: const Duration(hours: 1),
              onConfigChanged: (c) {
                setState(() => currentConfig = c);
              },
            );
          },
        ),
      );

      // Tap "Add [Ctrl+B]"
      await tester.tap(find.text('Add [Ctrl+B]'));
      await tester.pump();

      expect(currentConfig.bookmarks.length, equals(1));
      expect(currentConfig.bookmarks.first.position, equals(const Duration(minutes: 12, seconds: 34)));

      // Delete bookmark
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pump();

      expect(currentConfig.bookmarks.isEmpty, isTrue);
    });

    testWidgets('Tapping a chapter triggers onSeekTo', (tester) async {
      tester.view.physicalSize = const Size(340, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Duration? seekTarget;

      await tester.pumpWidget(
        buildTestWidget(
          config: const PlaybackStateConfig(),
          currentPosition: Duration.zero,
          totalDuration: const Duration(hours: 2),
          chapters: testChapters,
          onSeekTo: (d) => seekTarget = d,
        ),
      );

      await tester.tap(find.text('Chapter 2: Gargantua'));
      await tester.pump();

      expect(seekTarget, equals(const Duration(minutes: 45)));
    });
  });
}
