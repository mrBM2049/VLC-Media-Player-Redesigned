import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('OSDNotificationLayer Tests', () {
    test('OsdNotificationController displays pill and auto-dismisses', () async {
      final controller = OsdNotificationController();
      expect(controller.activePill, isNull);

      controller.showPill(
        action: 'Volume 85%',
        shortcutKey: '↑',
        icon: VlcIconGlyph.volumeHigh,
        displayDuration: const Duration(milliseconds: 50),
      );

      expect(controller.activePill, isNotNull);
      expect(controller.activePill!.action, 'Volume 85%');
      expect(controller.activePill!.shortcutKey, '↑');

      // Wait for auto-dismiss timer
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.activePill, isNull);

      controller.dispose();
    });

    testWidgets('Renders top-right shortcut pill with action text and shortcut key badge', (tester) async {
      final controller = OsdNotificationController();

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: OSDNotificationLayer(controller: controller),
          ),
        ),
      );

      expect(find.text('Volume 85%'), findsNothing);

      // Trigger notification pill
      controller.showPill(
        action: 'Volume 85%',
        shortcutKey: '↑',
        icon: VlcIconGlyph.volumeHigh,
      );
      await tester.pump();

      expect(find.text('Volume 85%'), findsOneWidget);
      expect(find.text('↑'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('ContinueWatchingPrompt renders formatted time and triggers Resume callback', (tester) async {
      bool resumeClicked = false;
      bool dismissed = false;

      final data = ResumePromptData(
        mediaTitle: 'Interstellar.2160p.mkv',
        resumePosition: const Duration(minutes: 42, seconds: 15),
        onResume: () => resumeClicked = true,
        onStartOver: () {},
        autoDismissDuration: const Duration(seconds: 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: Center(
              child: ContinueWatchingPrompt(
                data: data,
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Continue watching from 42:15?'), findsOneWidget);
      expect(find.text('Interstellar.2160p.mkv'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Start Over'), findsOneWidget);

      // Tap Resume button
      await tester.tap(find.text('Resume'));
      expect(resumeClicked, isTrue);
      expect(dismissed, isTrue);
    });
  });
}
