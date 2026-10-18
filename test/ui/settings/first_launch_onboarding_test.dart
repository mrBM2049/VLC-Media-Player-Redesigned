import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/theme/theme.dart';
import 'package:vlc_modern/ui/settings/first_launch_onboarding.dart';

void main() {
  group('FirstLaunchOnboarding Tests (Task 5.2)', () {
    testWidgets('Renders Step 0 with theme options and accent swatches', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      VlcThemeMode? selectedTheme;
      Color? selectedAccent;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: FirstLaunchOnboarding(
              onThemeModeChanged: (m) => selectedTheme = m,
              onAccentColorChanged: (c) => selectedAccent = c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personalize Your Experience'), findsOneWidget);
      expect(find.text('Dark Modern'), findsOneWidget);
      expect(find.text('OLED Pure Black'), findsOneWidget);
      expect(find.text('Clean Light'), findsOneWidget);

      // Tap OLED theme
      await tester.tap(find.text('OLED Pure Black'));
      await tester.pumpAndSettle();
      expect(selectedTheme, equals(VlcThemeMode.oled));

      // Tap Continue button to advance to Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: Shortcuts
      expect(find.text('Master Essential Hotkeys'), findsOneWidget);
      expect(find.text('Play / Pause Video'), findsOneWidget);
      expect(find.text('Fullscreen Mode'), findsOneWidget);

      // Tap Continue button to advance to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Ready to Watch
      expect(find.text('You are all set!'), findsOneWidget);
      expect(find.text('Start Watching'), findsOneWidget);
    });

    testWidgets('Tapping Start Watching invokes onComplete callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: FirstLaunchOnboarding(
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Finish
      await tester.tap(find.text('Start Watching'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('Skip Setup invokes onComplete immediately', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: FirstLaunchOnboarding(
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip Setup'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}

