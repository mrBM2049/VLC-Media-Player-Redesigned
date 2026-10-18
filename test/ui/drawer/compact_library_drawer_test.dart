import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vlc_modern/models/media_library_models.dart';
import 'package:vlc_modern/services/media_library_service.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/drawer/compact_library_drawer.dart';

void main() {
  group('CompactLibraryDrawer Widget Tests', () {
    late Directory tempDir;
    late MediaLibraryService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vlc_compact_drawer_test_');
      service = MediaLibraryService(); // In-memory SQLite
    });

    tearDown(() {
      service.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Widget createTestWidget({
      VoidCallback? onClose,
      ValueChanged<MediaItem>? onPlayItem,
      ValueChanged<MediaItem>? onAddToQueue,
      ValueChanged<List<MediaItem>>? onPlayAll,
      ValueChanged<List<MediaItem>>? onEnqueueAll,
      VoidCallback? onAddFolder,
      String? currentMrl,
      String? activeFolderPath,
    }) {
      return MaterialApp(
        theme: VlcThemeData.dark().toThemeData(),
        home: Scaffold(
          body: CompactLibraryDrawer(
            mediaLibraryService: service,
            onClose: onClose,
            onPlayItem: onPlayItem,
            onAddToQueue: onAddToQueue,
            onPlayAll: onPlayAll,
            onEnqueueAll: onEnqueueAll,
            onAddFolder: onAddFolder,
            currentMrl: currentMrl,
            activeFolderPath: activeFolderPath,
          ),
        ),
      );
    }

    testWidgets('Renders empty state when no media is indexed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Media Found'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Renders indexed media items with TV episode tags and durations', (tester) async {
      final ep1 = File(p.join(tempDir.path, 'Attack.On.Titan.S04E01.mkv'))..createSync();
      final ep2 = File(p.join(tempDir.path, 'Attack.On.Titan.S04E02.mkv'))..createSync();

      service.indexFile(ep1.path, durationMs: 1440000); // 24m
      service.indexFile(ep2.path, durationMs: 1500000); // 25m

      await tester.pumpWidget(createTestWidget(
        activeFolderPath: tempDir.path,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Attack On Titan'), findsNWidgets(2));
      expect(find.text('S04E01'), findsOneWidget);
      expect(find.text('S04E02'), findsOneWidget);
      expect(find.text('24:00'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('2 items • 49m'), findsOneWidget);
    });

    testWidgets('Header close button triggers onClose callback', (tester) async {
      bool closed = false;
      await tester.pumpWidget(createTestWidget(
        onClose: () => closed = true,
      ));
      await tester.pumpAndSettle();

      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('Segment pills filter items (Unwatched vs Watched)', (tester) async {
      final v1 = File(p.join(tempDir.path, 'Episode_01.mkv'))..createSync();
      final v2 = File(p.join(tempDir.path, 'Episode_02.mkv'))..createSync();

      service.indexFile(v1.path, durationMs: 100000);
      service.indexFile(v2.path, durationMs: 100000);

      // Mark Ep 1 as watched
      service.markAsWatched(v1.path, watched: true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial tab: All -> both displayed
      expect(find.text('Episode 01'), findsOneWidget);
      expect(find.text('Episode 02'), findsOneWidget);

      // Switch to Unwatched
      await tester.tap(find.byKey(const ValueKey('tab_unwatched')));
      await tester.pumpAndSettle();

      expect(find.text('Episode 01'), findsNothing);
      expect(find.text('Episode 02'), findsOneWidget);

      // Switch to Watched
      await tester.tap(find.byKey(const ValueKey('tab_watched')));
      await tester.pumpAndSettle();

      expect(find.text('Episode 01'), findsOneWidget);
      expect(find.text('Episode 02'), findsNothing);
    });

    testWidgets('Search query filters items in real time', (tester) async {
      final f1 = File(p.join(tempDir.path, 'Interstellar.mkv'))..createSync();
      final f2 = File(p.join(tempDir.path, 'Inception.mkv'))..createSync();

      service.indexFile(f1.path, durationMs: 10000000);
      service.indexFile(f2.path, durationMs: 9000000);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Interstellar'), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget);

      // Search for "inter"
      await tester.enterText(find.byType(TextField), 'inter');
      await tester.pumpAndSettle();

      expect(find.text('Interstellar'), findsOneWidget);
      expect(find.text('Inception'), findsNothing);
    });

    testWidgets('Play button and Add to Queue button invoke callbacks', (tester) async {
      final f = File(p.join(tempDir.path, 'Cosmos.mkv'))..createSync();
      service.indexFile(f.path, durationMs: 600000);

      MediaItem? playedItem;
      MediaItem? enqueuedItem;

      await tester.pumpWidget(createTestWidget(
        onPlayItem: (item) => playedItem = item,
        onAddToQueue: (item) => enqueuedItem = item,
      ));
      await tester.pumpAndSettle();

      // Tap Play icon button
      final playBtn = find.byTooltip('Play Now');
      expect(playBtn, findsOneWidget);
      await tester.tap(playBtn);
      await tester.pumpAndSettle();
      expect(playedItem, isNotNull);
      expect(playedItem!.title, equals('Cosmos'));

      // Tap Add to Queue icon button
      final queueBtn = find.byTooltip('Add to Queue');
      expect(queueBtn, findsOneWidget);
      await tester.tap(queueBtn);
      await tester.pumpAndSettle();
      expect(enqueuedItem, isNotNull);
      expect(enqueuedItem!.title, equals('Cosmos'));
    });

    testWidgets('Footer Play All and Enqueue All trigger callbacks', (tester) async {
      final f1 = File(p.join(tempDir.path, 'Show_1.mkv'))..createSync();
      final f2 = File(p.join(tempDir.path, 'Show_2.mkv'))..createSync();
      service.indexFile(f1.path, durationMs: 100000);
      service.indexFile(f2.path, durationMs: 100000);

      List<MediaItem>? playedAll;
      List<MediaItem>? enqueuedAll;

      await tester.pumpWidget(createTestWidget(
        onPlayAll: (items) => playedAll = items,
        onEnqueueAll: (items) => enqueuedAll = items,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play All'));
      await tester.pumpAndSettle();
      expect(playedAll, isNotNull);
      expect(playedAll!.length, equals(2));

      await tester.tap(find.text('Enqueue All'));
      await tester.pumpAndSettle();
      expect(enqueuedAll, isNotNull);
      expect(enqueuedAll!.length, equals(2));
    });

    testWidgets('Items are wrapped with Draggable<MediaItem>', (tester) async {
      final f = File(p.join(tempDir.path, 'Episode_01.mkv'))..createSync();
      service.indexFile(f.path, durationMs: 100000);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final draggableFinder = find.byType(Draggable<MediaItem>);
      expect(draggableFinder, findsOneWidget);
      final draggable = tester.widget<Draggable<MediaItem>>(draggableFinder);
      expect(draggable.data?.title, equals('Episode 01'));
    });
  });
}
