import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/services/settings_service.dart';
import 'package:vlc_modern/theme/theme.dart';
import 'package:vlc_modern/ui/settings/unified_settings_modal.dart';

void main() {
  group('UnifiedSettingsModal Tests (Task 5.1)', () {
    late SettingsService service;

    setUp(() {
      service = SettingsService();
      service.resetToDefaults();
    });

    testWidgets('Renders top bar, 12 categories in sidebar, and basic-to-advanced content', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: UnifiedSettingsModal(settingsService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar elements
      expect(find.text('Preferences & Settings'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Reset Defaults'), findsOneWidget);

      // Verify all 12 categories are present in the sidebar
      for (final cat in SettingsCategory.values) {
        expect(find.text(cat.label), findsAtLeastNWidgets(1));
      }

      // Default selected category is Interface & Appearance
      expect(find.text('BASIC SETTINGS'), findsOneWidget);
      expect(find.text('ADVANCED CONFIGURATION (libVLC Engine Internals)'), findsOneWidget);
      expect(find.text('App Theme Mode'), findsOneWidget);
      expect(find.text('Show On-Screen Display (OSD) Pills'), findsOneWidget);
    });

    testWidgets('Switches categories on sidebar click', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SettingsCategory? switchedCategory;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: UnifiedSettingsModal(
              settingsService: service,
              onCategoryChanged: (cat) => switchedCategory = cat,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click "Audio Output & Devices" in sidebar
      await tester.tap(find.text('Audio Output & Devices'));
      await tester.pumpAndSettle();

      expect(switchedCategory, equals(SettingsCategory.audioOutput));
      expect(find.text('Audio Output Module'), findsOneWidget);
      expect(find.text('Maximum Cone Volume Boost'), findsOneWidget);
      expect(find.text('Volume Step Increment'), findsOneWidget);

      // Click "Video & Acceleration"
      await tester.tap(find.text('Video & Acceleration'));
      await tester.pumpAndSettle();

      expect(switchedCategory, equals(SettingsCategory.videoAcceleration));
      expect(find.text('Hardware Video Decoding'), findsOneWidget);
      expect(find.text('Deinterlace Mode'), findsOneWidget);
    });

    testWidgets('Filters settings live via search bar and displays category tags', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: UnifiedSettingsModal(settingsService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search term "caching"
      await tester.enterText(find.byType(TextField), 'caching');
      await tester.pumpAndSettle();

      expect(find.textContaining('SEARCH RESULTS'), findsOneWidget);
      expect(find.text('Network Stream Caching Buffer'), findsOneWidget);
      expect(find.text('Local File Caching Buffer'), findsOneWidget);
      expect(find.text('Input & Codecs'), findsAtLeastNWidgets(1));

      // Clear search via clear icon button
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Returns to category view
      expect(find.text('BASIC SETTINGS'), findsOneWidget);
    });

    testWidgets('Opens ⓘ info tooltip modal displaying rationale and libVLC flag', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: UnifiedSettingsModal(settingsService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap info icon for "App Theme Mode"
      final infoButtons = find.byIcon(Icons.info_outline);
      expect(infoButtons, findsWidgets);
      await tester.tap(infoButtons.first);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('libVLC Flag: '), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text('Got It'), findsNothing);
    });

    testWidgets('Reset Defaults triggers confirmation alert and restores settings', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      service.setThemeMode(VlcThemeMode.light);
      expect(service.themeMode, equals(VlcThemeMode.light));

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: UnifiedSettingsModal(settingsService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Reset Defaults"
      await tester.tap(find.text('Reset Defaults'));
      await tester.pumpAndSettle();

      expect(find.text('Reset All Preferences?'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);

      // Confirm reset
      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      expect(service.themeMode, equals(VlcThemeMode.dark));
    });
  });
}
