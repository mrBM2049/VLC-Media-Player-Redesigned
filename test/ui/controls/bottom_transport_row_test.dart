import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('BottomTransportRow & FullConeVolumeControl Tests', () {
    testWidgets('Renders BottomTransportRow at exact 60dp height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: BottomTransportRow(
              isPlaying: false,
              position: Duration(minutes: 14, seconds: 28),
              duration: Duration(hours: 2, minutes: 15),
              volume: 100,
            ),
          ),
        ),
      );

      final rowFinder = find.byType(BottomTransportRow);
      expect(rowFinder, findsOneWidget);

      final rowSize = tester.getSize(rowFinder);
      expect(rowSize.height, VlcGeometry.bottomTransportRowHeight);
    });

    testWidgets('Monospace timecode displays elapsed/total and toggles to remaining time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: BottomTransportRow(
              isPlaying: true,
              position: Duration(minutes: 10, seconds: 0),
              duration: Duration(minutes: 30, seconds: 0),
              volume: 100,
            ),
          ),
        ),
      );

      // Check initial total duration
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('30:00'), findsOneWidget);

      // Tap timecode to toggle remaining time
      await tester.tap(find.text('10:00'));
      await tester.pump();

      // Remaining duration: 30 - 10 = 20 mins -> -20:00
      expect(find.text('-20:00'), findsOneWidget);
    });

    testWidgets('Play/Pause prominent button triggers callback', (tester) async {
      bool playPauseTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: BottomTransportRow(
              isPlaying: false,
              position: Duration.zero,
              duration: const Duration(minutes: 5),
              volume: 80,
              onPlayPause: () => playPauseTriggered = true,
            ),
          ),
        ),
      );

      // Prominent play button has play glyph
      expect(find.byType(BottomTransportRow), findsOneWidget);
      final buttons = find.byType(VlcTopBarButton);

      // Tap Play button (index 1: Prev=0, Play=1, Next=2, Stop=3)
      await tester.tap(buttons.at(1));
      expect(playPauseTriggered, isTrue);
    });

    testWidgets('FullConeVolumeControl slider adjusts volume 0-200% and triggers callback', (tester) async {
      int recordedVolume = 100;
      bool muteTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: FullConeVolumeControl(
              volume: 100,
              onVolumeChanged: (vol) => recordedVolume = vol,
              onToggleMute: () => muteTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byType(FullConeVolumeControl), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Tap mute button
      final muteBtn = find.descendant(
        of: find.byType(FullConeVolumeControl),
        matching: find.byType(VlcTopBarButton),
      );
      await tester.tap(muteBtn);
      expect(muteTriggered, isTrue);

      // Drag volume slider to 75% width -> 150% overdrive
      final sliderGesture = find.descendant(
        of: find.byType(FullConeVolumeControl),
        matching: find.byType(GestureDetector),
      );
      final sliderRect = tester.getRect(sliderGesture);

      // Tap at 75% width (overdrive range)
      final tapTarget = Offset(sliderRect.left + (sliderRect.width * 0.75), sliderRect.center.dy);
      await tester.tapAt(tapTarget);
      await tester.pump();

      expect(recordedVolume, closeTo(150, 5));
    });

    testWidgets('Right utility cluster triggers speed, repeat, subtitles, and EQ callbacks', (tester) async {
      bool subtitlesTriggered = false;
      bool eqTriggered = false;
      bool repeatTriggered = false;
      double newRate = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: BottomTransportRow(
              isPlaying: true,
              position: Duration.zero,
              duration: const Duration(minutes: 10),
              volume: 100,
              playbackRate: 1.0,
              onSubtitlesTap: () => subtitlesTriggered = true,
              onEqualizerTap: () => eqTriggered = true,
              onRepeatToggle: () => repeatTriggered = true,
              onRateChanged: (r) => newRate = r,
            ),
          ),
        ),
      );

      // Tap speed selector badge
      await tester.tap(find.text('1.0x'));
      await tester.pump();
      expect(newRate, 1.25);

      // Tap subtitles button
      final allButtons = find.byType(VlcTopBarButton);
      // Find subtitles button
      await tester.tap(find.byTooltip('Subtitles [V]'));
      expect(subtitlesTriggered, isTrue);

      // Tap EQ button
      await tester.tap(find.byTooltip('Audio Equalizer & Presets'));
      expect(eqTriggered, isTrue);

      // Tap Repeat button
      await tester.tap(find.byTooltip('Repeat: Off'));
      expect(repeatTriggered, isTrue);
    });
  });
}

