import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('VideosView Tests', () {
    late Directory tempDir;
    late MediaLibraryService service;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('vlc_videos_view_test_');
      service = MediaLibraryService();

      // Seed mock videos using physical temp files with exact extensions
      final inception = File(p.join(tempDir.path, 'Inception.2010.mkv'))..createSync();
      final interstellar = File(p.join(tempDir.path, 'Interstellar.2014.mp4'))..createSync();
      final bb1 = File(p.join(tempDir.path, 'Breaking.Bad.S01E01.mkv'))..createSync();
      final bb2 = File(p.join(tempDir.path, 'Breaking.Bad.S01E02.mkv'))..createSync();
      final cat = File(p.join(tempDir.path, 'funny_cat.mp4'))..createSync();

      service.indexFile(inception.path, durationMs: 8880000); // 148 min movie
      service.indexFile(interstellar.path, durationMs: 10140000); // 169 min movie
      service.indexFile(bb1.path, durationMs: 3480000); // TV S1E1
      service.indexFile(bb2.path, durationMs: 2880000); // TV S1E2
      service.indexFile(cat.path, durationMs: 15000); // Clip 15s
    });

    tearDown(() {
      service.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('Renders VideosView header, category pills, and video cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: VideosView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Videos Library'), findsOneWidget);
      expect(find.text('5 items (5 total indexed)'), findsOneWidget);

      // Category segmentation pills
      expect(find.text('All Videos'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('Clips'), findsOneWidget);

      // Batch buttons
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Enqueue All'), findsOneWidget);

      // Verify video titles appear
      expect(find.text('Inception 2010'), findsOneWidget);
      expect(find.text('Interstellar 2014'), findsOneWidget);
      expect(find.text('funny cat'), findsOneWidget);
    });

    testWidgets('Filters by Movies category pill', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: VideosView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Movies' filter
      await tester.tap(find.text('Movies'));
      await tester.pumpAndSettle();

      // Both movies should be present
      expect(find.text('Inception 2010'), findsOneWidget);
      expect(find.text('Interstellar 2014'), findsOneWidget);

      // Clip and TV show should not be present
      expect(find.text('funny cat'), findsNothing);
      expect(find.text('S01E01 - Breaking Bad'), findsNothing);
    });

    testWidgets('Filters by TV Shows and groups by Series/Season', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: VideosView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'TV Shows' filter
      await tester.tap(find.text('TV Shows'));
      await tester.pumpAndSettle();

      // Series group container header
      expect(find.text('2 Episodes'), findsOneWidget);

      // Episodes list
      expect(find.text('S01E01 - Breaking Bad'), findsOneWidget);
      expect(find.text('S01E02 - Breaking Bad'), findsOneWidget);

      // Movies & Clips should not appear
      expect(find.text('Inception 2010'), findsNothing);
      expect(find.text('funny cat'), findsNothing);
    });

    testWidgets('Filters by Clips category pill', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: VideosView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Clips' filter
      await tester.tap(find.text('Clips'));
      await tester.pumpAndSettle();

      // Only funny cat should be present
      expect(find.text('funny cat'), findsOneWidget);
      expect(find.text('Inception 2010'), findsNothing);
    });

    testWidgets('Search input filters video titles in real-time', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: VideosView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Interstellar');
      await tester.pumpAndSettle();

      expect(find.text('Interstellar 2014'), findsOneWidget);
      expect(find.text('Inception 2010'), findsNothing);
      expect(find.text('funny cat'), findsNothing);
    });

    testWidgets('Triggers onPlayItem and onAddToQueue callbacks', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      MediaItem? queuedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: VideosView(
              mediaLibraryService: service,
              onAddToQueue: (item) => queuedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first queue button
      final queueButtons = find.byTooltip('Add to Queue');
      expect(queueButtons, findsWidgets);
      await tester.tap(queueButtons.first);
      await tester.pumpAndSettle();

      expect(queuedItem, isNotNull);
    });
  });
}
