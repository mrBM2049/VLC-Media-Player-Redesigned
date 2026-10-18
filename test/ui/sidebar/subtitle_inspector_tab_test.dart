import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  final testTracks = [
    const VlcSubtitleTrack(id: 1, name: 'Track 1: English [Full/SDH]', language: 'en'),
    const VlcSubtitleTrack(id: 2, name: 'Track 2: Japanese [Original]', language: 'ja'),
  ];

  Widget buildTestWidget({
    required int selectedTrackId,
    required Duration currentDelay,
    required SubtitleAppearance appearance,
    bool isTimelineOverlayEnabled = false,
    ValueChanged<int>? onSelectTrack,
    ValueChanged<Duration>? onDelayChanged,
    ValueChanged<SubtitleAppearance>? onAppearanceChanged,
    ValueChanged<bool>? onToggleTimelineOverlay,
    VoidCallback? onAddSubtitle,
  }) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
          body: SizedBox(
            width: 340.0,
            child: SubtitleInspectorTab(
              tracks: testTracks,
              selectedTrackId: selectedTrackId,
              currentDelay: currentDelay,
              appearance: appearance,
              isTimelineOverlayEnabled: isTimelineOverlayEnabled,
              onSelectTrack: onSelectTrack ?? (_) {},
              onDelayChanged: onDelayChanged ?? (_) {},
              onAppearanceChanged: onAppearanceChanged ?? (_) {},
              onToggleTimelineOverlay: onToggleTimelineOverlay ?? (_) {},
              onAddSubtitle: onAddSubtitle ?? () {},
            ),
          ),
        ),
      );
  }

  group('SubtitleInspectorTab Widget Tests', () {
    testWidgets('Renders track selector, delay controls, live preview, and font options', (tester) async {
      tester.view.physicalSize = const Size(340, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          selectedTrackId: 1,
          currentDelay: Duration.zero,
          appearance: SubtitleAppearance.defaultStyle,
        ),
      );

      // Verify track title and Add Subtitle button
      expect(find.text('ACTIVE TRACK'), findsOneWidget);
      expect(find.text('Add Subtitle...'), findsOneWidget);
      expect(find.text('Track 1: English [Full/SDH]'), findsOneWidget);

      // Verify delay section and stepper buttons
      expect(find.text('SUBTITLE SYNC (DELAY)'), findsOneWidget);
      expect(find.text('0.0 s (In Sync)'), findsOneWidget);
      expect(find.text('-500ms'), findsOneWidget);
      expect(find.text('-50ms'), findsOneWidget);
      expect(find.text('0.0s'), findsOneWidget);
      expect(find.text('+50ms'), findsOneWidget);
      expect(find.text('+500ms'), findsOneWidget);

      // Verify Live Preview box
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.textContaining('dynamite'), findsWidgets);

      // Verify Typography section
      expect(find.text('FONT SCALE'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('FONT FAMILY'), findsOneWidget);
      expect(find.text('OUTLINE / STROKE'), findsOneWidget);
    });

    testWidgets('Tapping stepper buttons triggers onDelayChanged', (tester) async {
      Duration? newDelay;
      await tester.pumpWidget(
        buildTestWidget(
          selectedTrackId: 1,
          currentDelay: Duration.zero,
          appearance: SubtitleAppearance.defaultStyle,
          onDelayChanged: (d) => newDelay = d,
        ),
      );

      // Tap +50ms
      await tester.tap(find.text('+50ms'));
      await tester.pump();
      expect(newDelay, equals(const Duration(milliseconds: 50)));

      // Tap -500ms
      await tester.tap(find.text('-500ms'));
      await tester.pump();
      expect(newDelay, equals(const Duration(milliseconds: -500)));
    });

    testWidgets('Toggling timeline overlay invokes callback', (tester) async {
      bool? toggled;
      await tester.pumpWidget(
        buildTestWidget(
          selectedTrackId: 1,
          currentDelay: Duration.zero,
          appearance: SubtitleAppearance.defaultStyle,
          isTimelineOverlayEnabled: false,
          onToggleTimelineOverlay: (val) => toggled = val,
        ),
      );

      final switchFinder = find.byType(Switch).first;
      await tester.tap(switchFinder);
      await tester.pump();
      expect(toggled, isTrue);
    });
  });
}
