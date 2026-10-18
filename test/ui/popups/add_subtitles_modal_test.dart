import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/subtitle_models.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/popups/add_subtitles_modal.dart';

void main() {
  group('AddSubtitlesModal Widget Tests', () {
    testWidgets('Renders all 3 tabs: Local Scope, Online Search, and Batch Matcher', (tester) async {
      String? singleSubApplied;
      List<BatchSubtitleMatch>? batchSubsApplied;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: AddSubtitlesModal(
              currentVideoPath: '/media/Severance.S01E01.1080p.mkv',
              folderVideoPaths: const [
                '/media/Severance.S01E01.1080p.mkv',
                '/media/Severance.S01E02.1080p.mkv',
              ],
              onApplySingleSubtitle: (path) => singleSubApplied = path,
              onApplyBatchSubtitles: (matches) => batchSubsApplied = matches,
            ),
          ),
        ),
      );

      // Verify Header & Tabs
      expect(find.text('ADD SUBTITLES'), findsOneWidget);
      expect(find.text('Local File & Scope'), findsOneWidget);
      expect(find.text('Online Search (OpenSubtitles)'), findsOneWidget);
      expect(find.text('Batch Auto-Matcher'), findsOneWidget);

      // Verify Tab 1 Scopes
      expect(find.text('This File Only'), findsOneWidget);
      expect(find.text('This Folder (Batch)'), findsOneWidget);
      expect(find.text('This Playlist (Batch)'), findsOneWidget);

      // Browse / select a local file
      await tester.tap(find.text('Browse...'));
      await tester.pump();

      expect(find.text('Severance.S01E01.1080p.srt'), findsOneWidget);

      // Switch to Tab 3: Batch Auto-Matcher first
      await tester.tap(find.text('Batch Auto-Matcher'));
      await tester.pumpAndSettle();

      expect(find.text('Batch Season & Episode Matcher'), findsOneWidget);
      expect(find.text('Auto-Scan Subtitles'), findsOneWidget);

      // Trigger Auto-Scan
      await tester.tap(find.text('Auto-Scan Subtitles'));
      await tester.pumpAndSettle();

      expect(find.text('Severance.S01E01.1080p.mkv'), findsOneWidget);
      expect(find.text('Severance.S01E02.1080p.mkv'), findsOneWidget);
      expect(find.text('Apply 2 Batch Matches'), findsOneWidget);

      // Switch to Tab 2: Online Search
      await tester.tap(find.text('Online Search (OpenSubtitles)'));
      await tester.pumpAndSettle();

      expect(find.text('Hearing Impaired (SDH) only'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      // Verify online results render
      expect(find.text('Download & Apply'), findsWidgets);

      // Test Download & Apply (which completes & closes dialog)
      await tester.tap(find.text('Download & Apply').first);
      expect(singleSubApplied, isNotNull);
      expect(batchSubsApplied, isNull);
    });
  });
}

