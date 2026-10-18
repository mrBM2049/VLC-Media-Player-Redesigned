import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/theme/theme.dart';
import 'package:vlc_modern/ui/settings/hotkeys_modal.dart';

void main() {
  group('HotkeysModal Widget Tests (Task 5.2)', () {
    testWidgets('Renders modal header, category pills, search bar, and hotkey list', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: HotkeysModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keyboard Shortcuts & Hotkeys'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);
      expect(find.text('All Shortcuts'), findsOneWidget);

      // Verify visible category pills
      expect(find.text('Playback & Navigation'), findsOneWidget);
      expect(find.text('Audio & Volume'), findsOneWidget);
      expect(find.text('Subtitles & Timing'), findsOneWidget);

      // Default common shortcuts visible in top viewport
      expect(find.text('Play / Pause'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Next Frame'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('Filters hotkeys by category pill', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: HotkeysModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Audio & Volume" pill
      await tester.tap(find.text('Audio & Volume'));
      await tester.pumpAndSettle();

      expect(find.text('Volume Up (+5%)'), findsOneWidget);
      expect(find.text('Volume Down (-5%)'), findsOneWidget);
      expect(find.text('Mute / Unmute'), findsOneWidget);

      // Playback shortcuts should be filtered out
      expect(find.text('Play / Pause'), findsNothing);
    });

    testWidgets('Filters hotkeys live by search query', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: HotkeysModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type "delay" in search field
      await tester.enterText(find.byType(TextField), 'delay');
      await tester.pumpAndSettle();

      expect(find.text('Audio Delay -50ms'), findsOneWidget);
      expect(find.text('Audio Delay +50ms'), findsOneWidget);
      expect(find.text('Subtitle Delay -50ms'), findsOneWidget);
      expect(find.text('Subtitle Delay +50ms'), findsOneWidget);
      expect(find.text('Play / Pause'), findsNothing);

      // Clear search
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Play / Pause'), findsOneWidget);
    });

    testWidgets('Opens rebind dialog when edit button is tapped', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: HotkeysModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editButtons = find.byIcon(Icons.edit_outlined);
      expect(editButtons, findsWidgets);

      // Tap first edit button (Play / Pause)
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Press Any Key to Rebind'), findsOneWidget);
      expect(find.text('Action: Play / Pause'), findsOneWidget);

      // Cancel rebind dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Press Any Key to Rebind'), findsNothing);
    });

    testWidgets('Reset All restores hotkeys to defaults', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: HotkeysModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      expect(find.text('All hotkeys reset to default.'), findsOneWidget);
    });
  });
}
