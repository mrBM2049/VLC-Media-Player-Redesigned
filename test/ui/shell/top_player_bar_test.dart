import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('TopPlayerBar Tests', () {
    testWidgets('Renders TopPlayerBar at exact 48dp height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: TopPlayerBar(
              mediaTitle: 'Sample Media.mkv',
            ),
          ),
        ),
      );

      final barFinder = find.byType(TopPlayerBar);
      expect(barFinder, findsOneWidget);

      final barSize = tester.getSize(barFinder);
      expect(barSize.height, VlcGeometry.topPlayerBarHeight);
    });

    testWidgets('Displays folder breadcrumbs and triggers callback on tap', (tester) async {
      bool breadcrumbTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: TopPlayerBar(
              folderName: 'Interstellar (2014)',
              mediaTitle: 'Interstellar.2160p.mkv',
              fullPath: '/Volumes/Media/Movies/Interstellar (2014)/Interstellar.2160p.mkv',
              onBreadcrumbTap: () {
                breadcrumbTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Interstellar (2014)'), findsOneWidget);
      expect(find.text('›'), findsOneWidget);
      expect(find.text('Interstellar.2160p.mkv'), findsOneWidget);

      await tester.tap(find.byType(FolderBreadcrumbTrigger));
      expect(breadcrumbTapped, isTrue);
    });

    testWidgets('Triggers PiP, Fullscreen, and Inspector callbacks', (tester) async {
      bool pipTriggered = false;
      bool fullscreenTriggered = false;
      bool inspectorTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: TopPlayerBar(
              mediaTitle: 'Test Video.mp4',
              onPipToggle: () => pipTriggered = true,
              onFullscreenToggle: () => fullscreenTriggered = true,
              onInspectorToggle: () => inspectorTriggered = true,
            ),
          ),
        ),
      );

      final buttons = find.byType(VlcTopBarButton);
      // We expect 4 buttons: UnifiedMenuButton's child, PiP, Fullscreen, Inspector
      expect(buttons, findsNWidgets(4));

      // Tap PiP button
      await tester.tap(buttons.at(1));
      expect(pipTriggered, isTrue);

      // Tap Fullscreen button
      await tester.tap(buttons.at(2));
      expect(fullscreenTriggered, isTrue);

      // Tap Inspector button
      await tester.tap(buttons.at(3));
      expect(inspectorTriggered, isTrue);
    });

    testWidgets('Enforces strict 6dp rectangular geometry on action buttons (no pill buttons)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: VlcTopBarButton(
              onPressed: () {},
              child: const Icon(Icons.star),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(VlcTopBarButton),
        matching: find.byType(AnimatedContainer),
      );
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<AnimatedContainer>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      // Must strictly be 6dp rectangular radius
      expect(decoration.borderRadius, VlcGeometry.borderRadiusMedium);
      expect(decoration.borderRadius, BorderRadius.circular(6.0));
    });

    testWidgets('Renders theme switch button and cycles through Dark -> OLED -> Light', (tester) async {
      VlcThemeMode? selectedMode;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: TopPlayerBar(
              mediaTitle: 'Theme Test.mp4',
              themeMode: VlcThemeMode.dark,
              onThemeModeChanged: (mode) {
                selectedMode = mode;
              },
            ),
          ),
        ),
      );

      final buttons = find.byType(VlcTopBarButton);
      // Buttons: UnifiedMenuButton (0), ThemeSwitch (1)
      expect(buttons, findsNWidgets(2));

      // Tap Theme Switch button while in Dark mode -> should switch to OLED
      await tester.tap(buttons.at(1));
      expect(selectedMode, VlcThemeMode.oled);
    });
  });
}

