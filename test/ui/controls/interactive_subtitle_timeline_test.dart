import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  final sampleCues = [
    const SubtitleDialogueCue(
      start: Duration(seconds: 5),
      end: Duration(seconds: 10),
      text: 'First dialogue cue line',
    ),
    const SubtitleDialogueCue(
      start: Duration(seconds: 12),
      end: Duration(seconds: 18),
      text: 'Second dialogue cue line',
    ),
  ];

  Widget buildTestWidget({
    required Duration position,
    required Duration duration,
    required Duration delay,
    ValueChanged<Duration>? onDelayChanged,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
        body: InteractiveSubtitleTimeline(
          position: position,
          duration: duration,
          delay: delay,
          cues: sampleCues,
          onDelayChanged: onDelayChanged ?? (_) {},
          onClose: onClose,
        ),
      ),
    );
  }

  group('InteractiveSubtitleTimeline Tests', () {
    testWidgets('Renders dialogue cue text and sync offset badge', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          position: const Duration(seconds: 7),
          duration: const Duration(minutes: 5),
          delay: Duration.zero,
        ),
      );

      // Cue at 7s should match first cue
      expect(find.textContaining('First dialogue cue line'), findsOneWidget);
      expect(find.text('0.0s (In Sync)'), findsOneWidget);
      expect(find.text('-50ms'), findsOneWidget);
      expect(find.text('+50ms'), findsOneWidget);
      expect(find.text('0s'), findsOneWidget);
    });

    testWidgets('Tapping stepper buttons triggers onDelayChanged', (tester) async {
      Duration? newDelay;
      await tester.pumpWidget(
        buildTestWidget(
          position: const Duration(seconds: 7),
          duration: const Duration(minutes: 5),
          delay: const Duration(milliseconds: 100),
          onDelayChanged: (d) => newDelay = d,
        ),
      );

      // Tap +50ms
      await tester.tap(find.text('+50ms'));
      await tester.pump();
      expect(newDelay, equals(const Duration(milliseconds: 150)));

      // Tap 0s (reset)
      await tester.tap(find.text('0s'));
      await tester.pump();
      expect(newDelay, equals(Duration.zero));
    });

    testWidgets('Horizontal drag shifts subtitle delay', (tester) async {
      Duration? latestDelay;
      await tester.pumpWidget(
        buildTestWidget(
          position: const Duration(seconds: 7),
          duration: const Duration(minutes: 5),
          delay: Duration.zero,
          onDelayChanged: (d) => latestDelay = d,
        ),
      );

      final dragTarget = find.byType(GestureDetector).first;
      // Drag right by 20 pixels -> 20 * 10ms = +200ms
      await tester.drag(dragTarget, const Offset(20.0, 0.0));
      await tester.pump();

      expect(latestDelay, isNotNull);
      expect(latestDelay!.inMilliseconds, greaterThan(0));
    });
  });
}
