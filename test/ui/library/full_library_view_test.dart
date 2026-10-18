import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:vlc_modern/models/media_library_models.dart';
import 'package:vlc_modern/services/media_library_service.dart';
import 'package:vlc_modern/theme/vlc_icons.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/library/full_library_view.dart';

void main() {
  late Directory tempDir;
  late MediaLibraryService service;
  late File fileBunny;
  late File fileElephants;
  late File fileAudio;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vlc_full_library_test_');
    service = MediaLibraryService(); // In-memory SQLite

    fileBunny = File(p.join(tempDir.path, 'Big Buck Bunny.mkv'))..createSync();
    fileElephants = File(p.join(tempDir.path, 'Elephants Dream.mp4'))..createSync();
    fileAudio = File(p.join(tempDir.path, 'Track01.mp3'))..createSync();

    service.indexFile(fileBunny.path, durationMs: 600000);
    service.indexFile(fileElephants.path, durationMs: 400000);
    service.indexFile(fileAudio.path, durationMs: 180000);

    // Update progress on Big Buck Bunny
    service.updatePlaybackProgress(
      fileBunny.path,
      positionMs: 150000,
      durationMs: 600000,
    );
  });

  tearDown(() {
    service.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestableWidget({
    VoidCallback? onReturnToPlayer,
    ValueChanged<MediaItem>? onPlayItem,
    ValueChanged<MediaItem>? onAddToQueue,
    ValueChanged<List<MediaItem>>? onPlayAll,
    ValueChanged<List<MediaItem>>? onEnqueueAll,
  }) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1280, 800)),
        child: SizedBox(
          width: 1280,
          height: 800,
          child: FullLibraryView(
            mediaLibraryService: service,
            currentMrl: '/Users/Movies/Demo/Big Buck Bunny.mkv',
            currentTitle: 'Big Buck Bunny',
            isPlaying: true,
            position: const Duration(minutes: 2, seconds: 30),
            duration: const Duration(minutes: 10),
            volume: 100,
            onReturnToPlayer: onReturnToPlayer,
            onPlayItem: onPlayItem,
            onAddToQueue: onAddToQueue,
            onPlayAll: onPlayAll,
            onEnqueueAll: onEnqueueAll,
          ),
        ),
      ),
    );
  }

  group('FullLibraryView Tests', () {
    testWidgets('Renders pinned sidebar with navigation items and folders', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('VLC Media'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Streams'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('INDEXED FOLDERS'), findsOneWidget);
      expect(find.text('Return to Player'), findsOneWidget);
    });

    testWidgets('Renders top breadcrumb bar with search and layout switcher', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip('Grid View'), findsOneWidget);
      expect(find.byTooltip('List View'), findsOneWidget);
      expect(find.byTooltip('Details View'), findsOneWidget);
    });

    testWidgets('Switches layout mode from Grid to List and Details', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Default is GridView
      expect(find.byType(GridView), findsOneWidget);

      // Switch to List View
      await tester.tap(find.byTooltip('List View'));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsWidgets);

      // Switch to Details View
      await tester.tap(find.byTooltip('Details View'));
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('NAME'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);
    });

    testWidgets('Filter pills filter media items (All, Unwatched, Watched, In Progress)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unwatched'), findsOneWidget);
      expect(find.text('Watched'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      // Tap In Progress pill (Big Buck Bunny is at 25% progress)
      await tester.tap(find.text('In Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Big Buck Bunny'), findsWidgets);
    });

    testWidgets('Draggable MiniPlayerOverlay displays title, progress and transport controls', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      bool maximized = false;
      await tester.pumpWidget(buildTestableWidget(
        onReturnToPlayer: () => maximized = true,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MiniPlayerOverlay), findsOneWidget);
      expect(find.text('Big Buck Bunny'), findsWidgets);

      // Maximize button returns to video player
      final maximizeBtn = find.byTooltip('Maximize to Fullscreen [Esc]');
      expect(maximizeBtn, findsOneWidget);
      await tester.tap(maximizeBtn);
      await tester.pumpAndSettle();
      expect(maximized, isTrue);
    });

    testWidgets('Search query filters media in real time', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Elephants Dream'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Bunny');
      await tester.pumpAndSettle();

      expect(find.text('Big Buck Bunny'), findsWidgets);
      expect(find.text('Elephants Dream'), findsNothing);
    });

    testWidgets('Play item and Enqueue actions invoke callbacks', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      MediaItem? playedItem;
      MediaItem? queuedItem;

      await tester.pumpWidget(buildTestableWidget(
        onPlayItem: (it) => playedItem = it,
        onAddToQueue: (it) => queuedItem = it,
      ));
      await tester.pumpAndSettle();

      // Switch to List View where play button is directly visible
      await tester.tap(find.byTooltip('List View'));
      await tester.pumpAndSettle();

      // Tap on item card to play
      final card = find.text('Elephants Dream');
      expect(card, findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(playedItem, isNotNull);
      expect(playedItem!.title, 'Elephants Dream');
    });

    testWidgets('Return to player button triggers onReturnToPlayer callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      bool returned = false;
      await tester.pumpWidget(buildTestableWidget(
        onReturnToPlayer: () => returned = true,
      ));
      await tester.pumpAndSettle();

      final returnBtn = find.text('Return to Player');
      expect(returnBtn, findsOneWidget);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      expect(returned, isTrue);
    });
  });
}
