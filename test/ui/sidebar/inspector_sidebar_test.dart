import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/preset_models.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/sidebar/inspector_sidebar.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('InspectorSidebar Widget Tests', () {
    testWidgets('Renders header, preset bar, and 4 tab buttons', (tester) async {
      final presetController = PresetController(folderName: 'Attack on Titan');
      int activeTab = 0;
      bool closed = false;

      await tester.pumpWidget(
        buildTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return InspectorSidebar(
                activeTab: activeTab,
                presetController: presetController,
                onTabChanged: (idx) => setState(() => activeTab = idx),
                onClose: () => closed = true,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Inspector & Presets'), findsOneWidget);

      // Verify Preset Bar
      expect(find.text('Standard (Neutral)'), findsOneWidget);
      expect(find.text('Save settings for all episodes in this show'), findsOneWidget);

      // Verify 4 Tab Buttons
      expect(find.text('Subs'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      // Verify Tab 0 Placeholder
      expect(find.text('Subtitles'), findsOneWidget);

      // Tap Tab 1 (Audio)
      await tester.tap(find.text('Audio'));
      await tester.pumpAndSettle();

      expect(activeTab, 1);
      expect(find.text('Audio & EQ'), findsOneWidget);

      // Tap Tab 2 (Video)
      await tester.tap(find.text('Video'));
      await tester.pumpAndSettle();

      expect(activeTab, 2);
      expect(find.text('Video & Aspect'), findsOneWidget);

      // Tap Tab 3 (Playback)
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(activeTab, 3);
      expect(find.text('Playback'), findsOneWidget);

      // Tap Close button
      await tester.tap(find.byTooltip('Close Inspector'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);

      presetController.dispose();
    });

    testWidgets('Preset picker modal changes active preset', (tester) async {
      final presetController = PresetController();

      await tester.pumpWidget(
        buildTestApp(
          child: InspectorSidebar(
            activeTab: 0,
            presetController: presetController,
            onTabChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap preset banner to open preset picker
      await tester.tap(find.text('Standard (Neutral)'));
      await tester.pumpAndSettle();

      expect(find.text('Select Preset Profile'), findsOneWidget);
      expect(find.text('Anime & Asian Cinema'), findsOneWidget);
      expect(find.text('Action & Blockbuster'), findsOneWidget);

      // Select Anime preset
      await tester.tap(find.text('Anime & Asian Cinema'));
      await tester.pumpAndSettle();

      expect(presetController.activePreset, ShowPresetProfile.anime);
      expect(find.text('Anime & Asian Cinema'), findsOneWidget);

      // Toggle per-show checkbox
      expect(presetController.applyToAllFolderEpisodes, isTrue);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(presetController.applyToAllFolderEpisodes, isFalse);

      presetController.dispose();
    });
  });
}
