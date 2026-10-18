import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('MusicView Tests', () {
    late Directory tempDir;
    late MediaLibraryService service;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('vlc_music_view_test_');
      service = MediaLibraryService();

      // Seed mock audio files with known tags and names
      final daft1 = File(p.join(tempDir.path, 'Daft Punk - One More Time.mp3'))..createSync();
      final daft2 = File(p.join(tempDir.path, 'Daft Punk - Harder Better Faster.mp3'))..createSync();
      final queen = File(p.join(tempDir.path, 'Queen - Bohemian Rhapsody.flac'))..createSync();
      final movie = File(p.join(tempDir.path, 'Hans Zimmer - Time.wav'))..createSync();

      service.indexFile(daft1.path, durationMs: 320000, artist: 'Daft Punk', album: 'Discovery', genre: 'Electronic');
      service.indexFile(daft2.path, durationMs: 224000, artist: 'Daft Punk', album: 'Discovery', genre: 'Electronic');
      service.indexFile(queen.path, durationMs: 354000, artist: 'Queen', album: 'A Night at the Opera', genre: 'Rock');
      service.indexFile(movie.path, durationMs: 275000, artist: 'Hans Zimmer', album: 'Inception OST', genre: 'Soundtrack');
    });

    tearDown(() {
      service.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('Renders MusicView header, tabs, and songs list', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MusicView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Music Library'), findsOneWidget);
      expect(find.text('4 tracks indexed'), findsOneWidget);

      // Category tab pills
      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Genres'), findsOneWidget);

      // Batch buttons
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Enqueue All'), findsOneWidget);

      // Verify song titles appear in default Songs tab
      expect(find.text('One More Time'), findsOneWidget);
      expect(find.text('Harder Better Faster'), findsOneWidget);
      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
    });

    testWidgets('Switches to Albums tab and groups tracks into Album cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MusicView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Albums tab
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();

      // Albums should be visible
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('A Night at the Opera'), findsOneWidget);
      expect(find.text('Inception OST'), findsOneWidget);

      // Verify track count in subtitle
      expect(find.text('Daft Punk • 2 tracks'), findsOneWidget);

      // Tap on Discovery album to open album detail view
      await tester.tap(find.text('Discovery'));
      await tester.pumpAndSettle();

      expect(find.text('ALBUM'), findsOneWidget);
      expect(find.text('Play Album'), findsOneWidget);
      expect(find.text('One More Time'), findsOneWidget);
      expect(find.text('Harder Better Faster'), findsOneWidget);
    });

    testWidgets('Switches to Artists tab and groups by Artist', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MusicView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Artists tab
      await tester.tap(find.text('Artists'));
      await tester.pumpAndSettle();

      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);
      expect(find.text('Hans Zimmer'), findsOneWidget);

      expect(find.text('1 albums • 2 tracks'), findsOneWidget);
    });

    testWidgets('Switches to Genres tab and groups by Genre', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MusicView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Genres tab
      await tester.tap(find.text('Genres'));
      await tester.pumpAndSettle();

      expect(find.text('Electronic'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Soundtrack'), findsOneWidget);

      expect(find.text('2 tracks'), findsOneWidget);
    });

    testWidgets('Filters music with real-time search', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MusicView(
              mediaLibraryService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Bohemian');
      await tester.pumpAndSettle();

      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('One More Time'), findsNothing);
    });

    testWidgets('Triggers onPlayItem and onAddToQueue callbacks', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      MediaItem? playedItem;
      MediaItem? queuedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MusicView(
              mediaLibraryService: service,
              onPlayItem: (item) => playedItem = item,
              onAddToQueue: (item) => queuedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hover over first track
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('One More Time')));
      await tester.pumpAndSettle();

      // Hover triggers play icon button
      final playBtn = find.byIcon(Icons.play_arrow);
      expect(playBtn, findsWidgets);
      await tester.tap(playBtn.first);
      await tester.pumpAndSettle();
      expect(playedItem?.title, contains('One More Time'));

      // Hover triggers enqueue icon button
      final queueBtn = find.byIcon(Icons.playlist_add);
      expect(queueBtn, findsWidgets);
      await tester.tap(queueBtn.first);
      await tester.pumpAndSettle();
      expect(queuedItem?.title, contains('One More Time'));
    });
  });
}
