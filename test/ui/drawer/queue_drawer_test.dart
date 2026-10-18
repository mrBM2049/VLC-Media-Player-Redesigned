import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/queue_models.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/drawer/queue_drawer.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('QueueDrawer Widget Tests', () {
    testWidgets('Renders empty state when queue has no items', (tester) async {
      final controller = QueueController();
      bool addMediaTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          child: QueueDrawer(
            controller: controller,
            onAddMedia: () => addMediaTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Play Queue'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Queue is Empty'), findsOneWidget);
      expect(find.text('Add Media to Queue'), findsOneWidget);

      await tester.tap(find.text('Add Media to Queue'));
      await tester.pumpAndSettle();
      expect(addMediaTapped, isTrue);
    });

    testWidgets('Renders items list, handles selection, removal, and clear', (tester) async {
      final controller = QueueController(
        initialItems: const [
          QueueItem(
            id: 'item_1',
            mrl: '/movies/film1.mkv',
            title: 'Inception (4K Remux)',
            artist: 'Christopher Nolan',
            duration: Duration(hours: 2, minutes: 28),
            isPlaying: true,
          ),
          QueueItem(
            id: 'item_2',
            mrl: '/movies/film2.mkv',
            title: 'Interstellar (IMAX)',
            artist: 'Hans Zimmer Score',
            duration: Duration(hours: 2, minutes: 49),
            isPlaying: false,
          ),
        ],
        initialIndex: 0,
      );

      QueueItem? playedItem;
      bool closed = false;
      bool savePlaylistTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          child: QueueDrawer(
            controller: controller,
            onClose: () => closed = true,
            onPlayItem: (item) => playedItem = item,
            onSaveAsPlaylist: () => savePlaylistTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header info
      expect(find.text('Play Queue'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Inception (4K Remux)'), findsOneWidget);
      expect(find.text('Interstellar (IMAX)'), findsOneWidget);
      expect(find.text('Christopher Nolan'), findsOneWidget);

      // Tap on second item to play
      await tester.tap(find.text('Interstellar (IMAX)'));
      await tester.pumpAndSettle();

      expect(controller.currentIndex, 1);
      expect(playedItem?.id, 'item_2');

      // Tap repeat toggle
      expect(controller.repeatMode, QueueRepeatMode.off);
      await tester.tap(find.byTooltip('Repeat: Off'));
      await tester.pumpAndSettle();
      expect(controller.repeatMode, QueueRepeatMode.all);

      // Tap shuffle toggle
      expect(controller.isShuffle, isFalse);
      await tester.tap(find.byTooltip('Shuffle: Off'));
      await tester.pumpAndSettle();
      expect(controller.isShuffle, isTrue);

      // Tap save playlist
      await tester.tap(find.text('Save Playlist'));
      await tester.pumpAndSettle();
      expect(savePlaylistTapped, isTrue);

      // Tap close button
      await tester.tap(find.byTooltip('Close Queue [Q]'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);

      // Remove first item
      final removeButtons = find.byTooltip('Remove from Queue');
      expect(removeButtons, findsNWidgets(2));
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      expect(controller.count, 1);
      expect(find.text('Inception (4K Remux)'), findsNothing);
      expect(find.text('Interstellar (IMAX)'), findsOneWidget);

      // Clear all
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(controller.isEmpty, isTrue);
      expect(find.text('Queue is Empty'), findsOneWidget);
    });
  });
}

