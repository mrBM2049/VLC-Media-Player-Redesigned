import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/player/music_player_canvas.dart';

void main() {
  group('MusicPlayerCanvas Tests', () {
    testWidgets('Renders album artwork, title, artist, audio format badge, and timestamps', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: MusicPlayerCanvas(
              title: 'One More Time',
              artist: 'Daft Punk',
              album: 'Discovery',
              audioFormat: 'FLAC • 24-bit / 96kHz',
              isPlaying: true,
              position: Duration(minutes: 2, seconds: 15),
              duration: Duration(minutes: 5, seconds: 20),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Metadata verification
      expect(find.text('One More Time'), findsOneWidget);
      expect(find.text('Daft Punk — Discovery'), findsOneWidget);
      expect(find.text('FLAC • 24-BIT / 96KHZ'), findsOneWidget);

      // Timestamps verification
      expect(find.text('02:15'), findsOneWidget);
      expect(find.text('-03:05'), findsOneWidget);
    });

    testWidgets('Interactive Waveform Seek Bar triggers onSeek callback on tap', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Duration? seekTarget;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MusicPlayerCanvas(
              title: 'Bohemian Rhapsody',
              artist: 'Queen',
              album: 'A Night at the Opera',
              isPlaying: false,
              position: const Duration(minutes: 1, seconds: 0),
              duration: const Duration(minutes: 6, seconds: 0),
              onSeek: (pos) => seekTarget = pos,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the GestureDetector for the waveform
      final waveformGesture = find.byType(GestureDetector);
      expect(waveformGesture, findsWidgets);

      // Tap on the right side of the waveform (towards 75% progress)
      final waveformRect = tester.getRect(waveformGesture.first);
      await tester.tapAt(Offset(waveformRect.left + (waveformRect.width * 0.75), waveformRect.center.dy));
      await tester.pumpAndSettle();

      expect(seekTarget, isNotNull);
      // 75% of 6 minutes (360,000ms) is roughly 270,000ms (4.5 min)
      expect(seekTarget!.inSeconds, greaterThan(200));
    });

    testWidgets('Stops spinning vinyl disc animation when paused', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: MusicPlayerCanvas(
              title: 'Time',
              artist: 'Hans Zimmer',
              album: 'Inception',
              isPlaying: false,
              position: Duration.zero,
              duration: Duration(minutes: 4, seconds: 35),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final discFinder = find.byKey(const ValueKey('vinyl_disc_rotation'));
      expect(discFinder, findsOneWidget);
      final rotation = tester.widget<RotationTransition>(discFinder);
      expect(rotation.turns.isAnimating, isFalse);
    });
  });
}
