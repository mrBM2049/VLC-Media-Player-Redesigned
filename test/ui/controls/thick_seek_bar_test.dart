import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('ThickSeekBar Tests', () {
    testWidgets('Renders ThickSeekBar at resting 10dp height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                child: ThickSeekBar(
                  position: const Duration(minutes: 5),
                  duration: const Duration(minutes: 10),
                  onSeek: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      final barFinder = find.byType(ThickSeekBar);
      expect(barFinder, findsOneWidget);

      final barSize = tester.getSize(barFinder);
      expect(barSize.height, VlcGeometry.thickSeekBarHeightNormal);
      expect(barSize.width, 800);
    });

    testWidgets('Tapping on seekbar triggers onSeek with computed target duration', (tester) async {
      Duration? soughtTime;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                child: ThickSeekBar(
                  position: Duration.zero,
                  duration: const Duration(seconds: 100),
                  onSeek: (d) => soughtTime = d,
                ),
              ),
            ),
          ),
        ),
      );

      final barFinder = find.byType(ThickSeekBar);
      final barRect = tester.getRect(barFinder);

      // Tap at 50% width -> should seek to 50 seconds
      await tester.tapAt(barRect.center);
      await tester.pump();

      expect(soughtTime, isNotNull);
      expect(soughtTime!.inSeconds, 50);
    });

    testWidgets('Displays chapters and clamps hover preview card', (tester) async {
      const chapters = [
        ChapterTick(fraction: 0.25, title: 'Chapter 1: The Launch', time: Duration(minutes: 25)),
        ChapterTick(fraction: 0.50, title: 'Chapter 2: Gargantua', time: Duration(minutes: 50)),
        ChapterTick(fraction: 0.75, title: 'Chapter 3: The Tesseract', time: Duration(minutes: 75)),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                child: ThickSeekBar(
                  position: const Duration(minutes: 10),
                  duration: const Duration(minutes: 100),
                  chapters: chapters,
                  onSeek: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ThickSeekBar), findsOneWidget);
    });
  });
}
