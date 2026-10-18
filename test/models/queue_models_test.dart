import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/queue_models.dart';

void main() {
  group('QueueModels & QueueController Tests', () {
    test('QueueItem equality and copyWith', () {
      const item1 = QueueItem(
        id: '1',
        mrl: '/movies/film.mkv',
        title: 'Film 1',
        duration: Duration(minutes: 90),
      );
      final item2 = item1.copyWith(isPlaying: true);

      expect(item1 == item2, isFalse);
      expect(item2.isPlaying, isTrue);
      expect(item2.id, '1');
      expect(item2.title, 'Film 1');
    });

    test('QueueController initial state and empty calculations', () {
      final controller = QueueController();
      expect(controller.isEmpty, isTrue);
      expect(controller.count, 0);
      expect(controller.currentIndex, -1);
      expect(controller.currentItem, isNull);
      expect(controller.totalDuration, Duration.zero);
      expect(controller.totalRemainingDuration, Duration.zero);
    });

    test('Adding items updates currentIndex and duration', () {
      final controller = QueueController();
      const item1 = QueueItem(
        id: '1',
        mrl: '/path/1.mp4',
        title: 'Episode 1',
        duration: Duration(minutes: 20),
      );
      const item2 = QueueItem(
        id: '2',
        mrl: '/path/2.mp4',
        title: 'Episode 2',
        duration: Duration(minutes: 25),
      );

      controller.addItem(item1);
      expect(controller.count, 1);
      expect(controller.currentIndex, 0);
      expect(controller.currentItem?.id, '1');
      expect(controller.currentItem?.isPlaying, isTrue);
      expect(controller.totalDuration, const Duration(minutes: 20));

      controller.addItem(item2);
      expect(controller.count, 2);
      expect(controller.currentIndex, 0);
      expect(controller.totalDuration, const Duration(minutes: 45));
      expect(controller.totalRemainingDuration, const Duration(minutes: 45));
    });

    test('QueueController reorder adjusts currentIndex properly', () {
      final controller = QueueController(
        initialItems: const [
          QueueItem(id: '1', mrl: '/1', title: 'A', duration: Duration(minutes: 10)),
          QueueItem(id: '2', mrl: '/2', title: 'B', duration: Duration(minutes: 10)),
          QueueItem(id: '3', mrl: '/3', title: 'C', duration: Duration(minutes: 10)),
        ],
        initialIndex: 0,
      );

      // Current playing is A at index 0. Move A to index 2 (Flutter reorder passes newIndex 3)
      controller.reorder(0, 3);
      expect(controller.items[0].id, '2');
      expect(controller.items[1].id, '3');
      expect(controller.items[2].id, '1');
      expect(controller.currentIndex, 2);
      expect(controller.currentItem?.id, '1');
      expect(controller.items[2].isPlaying, isTrue);
      expect(controller.items[0].isPlaying, isFalse);

      // Now move C (index 1) to before B (index 0)
      controller.reorder(1, 0);
      expect(controller.items[0].id, '3');
      expect(controller.items[1].id, '2');
      expect(controller.items[2].id, '1');
      expect(controller.currentIndex, 2);
    });

    test('QueueController remove items adjusts currentIndex', () {
      final controller = QueueController(
        initialItems: const [
          QueueItem(id: '1', mrl: '/1', title: 'A', duration: Duration(minutes: 10)),
          QueueItem(id: '2', mrl: '/2', title: 'B', duration: Duration(minutes: 10)),
          QueueItem(id: '3', mrl: '/3', title: 'C', duration: Duration(minutes: 10)),
        ],
        initialIndex: 1, // B is playing
      );

      // Remove A (before current index)
      controller.removeItem('1');
      expect(controller.count, 2);
      expect(controller.currentIndex, 0);
      expect(controller.currentItem?.id, '2');

      // Remove B (currently playing)
      controller.removeItem('2');
      expect(controller.count, 1);
      expect(controller.currentIndex, 0);
      expect(controller.currentItem?.id, '3');
      expect(controller.currentItem?.isPlaying, isTrue);

      // Clear queue
      controller.clear();
      expect(controller.isEmpty, isTrue);
      expect(controller.currentIndex, -1);
    });

    test('QueueController playNext and playPrevious with Repeat modes', () {
      final controller = QueueController(
        initialItems: const [
          QueueItem(id: '1', mrl: '/1', title: 'A', duration: Duration(minutes: 10)),
          QueueItem(id: '2', mrl: '/2', title: 'B', duration: Duration(minutes: 10)),
        ],
        initialIndex: 0,
      );

      // Next -> item B
      final next = controller.playNext();
      expect(next?.id, '2');
      expect(controller.currentIndex, 1);

      // Next with repeat off -> null
      final beyond = controller.playNext();
      expect(beyond, isNull);
      expect(controller.currentIndex, 1);

      // Set repeat all -> next wraps to item A
      controller.setRepeatMode(QueueRepeatMode.all);
      final wrapNext = controller.playNext();
      expect(wrapNext?.id, '1');
      expect(controller.currentIndex, 0);

      // Previous wraps to item B
      final wrapPrev = controller.playPrevious();
      expect(wrapPrev?.id, '2');
      expect(controller.currentIndex, 1);

      // Set repeat one -> always stays on current
      controller.cycleRepeatMode(); // was all, now one
      expect(controller.repeatMode, QueueRepeatMode.one);
      final repeatCurrent = controller.playNext();
      expect(repeatCurrent?.id, '2');
      expect(controller.currentIndex, 1);
    });
  });
}

