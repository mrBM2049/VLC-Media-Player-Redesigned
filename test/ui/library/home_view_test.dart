import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:vlc_modern/models/media_library_models.dart';
import 'package:vlc_modern/services/media_library_service.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/library/home_view.dart';

void main() {
  group('HomeView Widget Tests', () {
    late Directory tempDir;
    late MediaLibraryService service;
    late File file1;
    late File file2;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vlc_home_view_test_');
      service = MediaLibraryService();

      file1 = File(p.join(tempDir.path, 'Big Buck Bunny.mkv'))..createSync();
      file2 = File(p.join(tempDir.path, 'Elephants Dream.mp4'))..createSync();

      service.indexFile(file1.path, durationMs: 600000);
      service.indexFile(file2.path, durationMs: 400000);

      // Create in-progress resume state for Big Buck Bunny
      service.updatePlaybackProgress(
        file1.path,
        positionMs: 180000,
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
      ValueChanged<MediaItem>? onPlayItem,
      VoidCallback? onOpenMedia,
      VoidCallback? onOpenStream,
      VoidCallback? onAddFolder,
      ValueChanged<String>? onNavigateToSection,
    }) {
      return MaterialApp(
        theme: VlcThemeData.dark().toThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: SizedBox(
            width: 1280,
            height: 800,
            child: Scaffold(
              body: HomeView(
                mediaLibraryService: service,
                onPlayItem: onPlayItem,
                onOpenMedia: onOpenMedia,
                onOpenStream: onOpenStream,
                onAddFolder: onAddFolder,
                onNavigateToSection: onNavigateToSection,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders Hero Banner with Welcome title and quick action buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(
        onOpenMedia: () {},
        onOpenStream: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('VLC Media Center'), findsOneWidget);
      expect(find.text('Open File'), findsOneWidget);
      expect(find.text('Open Stream'), findsOneWidget);
    });

    testWidgets('Renders Continue Watching carousel with in-progress media item', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Continue Watching'), findsWidgets);
      expect(find.text('Pick up right where you left off'), findsOneWidget);
      expect(find.text('Big Buck Bunny'), findsWidgets);
    });

    testWidgets('Renders Recent Media section and Smart Playlists', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Media'), findsOneWidget);
      expect(find.text('Smart Collections & Playlists'), findsOneWidget);
      expect(find.text('All Video Library'), findsOneWidget);
    });

    testWidgets('Tapping on a Continue Watching card triggers onPlayItem callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      MediaItem? playedItem;
      await tester.pumpWidget(buildTestableWidget(
        onPlayItem: (it) => playedItem = it,
      ));
      await tester.pumpAndSettle();

      final card = find.text('Big Buck Bunny').first;
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(playedItem, isNotNull);
      expect(playedItem!.title, 'Big Buck Bunny');
    });

    testWidgets('Action buttons trigger callbacks for Open File and Open Stream', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool fileOpened = false;
      bool streamOpened = false;

      await tester.pumpWidget(buildTestableWidget(
        onOpenMedia: () => fileOpened = true,
        onOpenStream: () => streamOpened = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open File'));
      await tester.pumpAndSettle();
      expect(fileOpened, isTrue);

      await tester.tap(find.text('Open Stream'));
      await tester.pumpAndSettle();
      expect(streamOpened, isTrue);
    });
  });
}
