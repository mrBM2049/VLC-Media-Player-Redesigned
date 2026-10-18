import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/media_library_models.dart';

void main() {
  group('MediaItem Domain Model Tests', () {
    test('Formatted duration returns hh:mm:ss for long media and mm:ss for short media', () {
      final shortItem = MediaItem(
        id: 1,
        mrl: '/movies/clip.mp4',
        title: 'Clip',
        durationMs: 125000, // 2m 5s
        folderPath: '/movies',
        dateAdded: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(shortItem.formattedDuration, equals('02:05'));

      final longItem = MediaItem(
        id: 2,
        mrl: '/movies/feature.mkv',
        title: 'Feature Film',
        durationMs: 7325000, // 2h 2m 5s
        folderPath: '/movies',
        dateAdded: DateTime.now(),
      );
      expect(longItem.formattedDuration, equals('02:02:05'));

      final zeroItem = MediaItem(
        id: 3,
        mrl: '/movies/zero.mp4',
        title: 'Zero',
        durationMs: 0,
        folderPath: '/movies',
        dateAdded: DateTime.now(),
      );
      expect(zeroItem.formattedDuration, equals('00:00'));
    });

    test('Formatted resume time formats correctly', () {
      final item = MediaItem(
        id: 1,
        mrl: '/shows/ep1.mkv',
        title: 'Episode 1',
        durationMs: 3600000,
        resumePositionMs: 1545000, // 25m 45s
        folderPath: '/shows',
        dateAdded: DateTime.now(),
      );
      expect(item.formattedResumeTime, equals('25:45'));
    });

    test('Formatted file size computes KB, MB, and GB accurately', () {
      final kbItem = MediaItem(
        id: 1,
        mrl: '/audio/track.mp3',
        title: 'Track',
        fileSizeBytes: 512 * 1024,
        folderPath: '/audio',
        dateAdded: DateTime.now(),
      );
      expect(kbItem.formattedFileSize, equals('512 KB'));

      final mbItem = MediaItem(
        id: 2,
        mrl: '/video/short.mp4',
        title: 'Short',
        fileSizeBytes: 150 * 1024 * 1024,
        folderPath: '/video',
        dateAdded: DateTime.now(),
      );
      expect(mbItem.formattedFileSize, equals('150 MB'));

      final gbItem = MediaItem(
        id: 3,
        mrl: '/video/film.mkv',
        title: 'Film',
        fileSizeBytes: (4.5 * 1024 * 1024 * 1024).toInt(),
        folderPath: '/video',
        dateAdded: DateTime.now(),
      );
      expect(gbItem.formattedFileSize, equals('4.5 GB'));
    });

    test('DisplayName formats S01E05 pattern when season & episode are present', () {
      final showItem = MediaItem(
        id: 1,
        mrl: '/tv/pilot.mkv',
        title: 'Pilot',
        season: 1,
        episode: 1,
        folderPath: '/tv',
        dateAdded: DateTime.now(),
      );
      expect(showItem.displayName, equals('S01E01 - Pilot'));

      final movieItem = MediaItem(
        id: 2,
        mrl: '/movies/inception.mkv',
        title: 'Inception',
        folderPath: '/movies',
        dateAdded: DateTime.now(),
      );
      expect(movieItem.displayName, equals('Inception'));
    });

    test('Serialization toMap and fromMap roundtrips preserves all fields', () {
      final now = DateTime.now();
      final original = MediaItem(
        id: 42,
        mrl: '/media/video.mp4',
        title: 'Test Title',
        durationMs: 120000,
        lastPlayed: now,
        resumePositionMs: 60000,
        resumeProgress: 0.5,
        isWatched: true,
        playCount: 3,
        fileSizeBytes: 1048576,
        folderPath: '/media',
        mediaType: MediaType.video,
        thumbnailPath: '/thumbs/42.jpg',
        season: 2,
        episode: 7,
        artist: 'Director',
        album: 'Season 2',
        genre: 'Drama',
        dateAdded: now,
      );

      final map = original.toMap();
      final reconstituted = MediaItem.fromMap(map);

      expect(reconstituted.id, equals(original.id));
      expect(reconstituted.mrl, equals(original.mrl));
      expect(reconstituted.title, equals(original.title));
      expect(reconstituted.isWatched, isTrue);
      expect(reconstituted.resumePositionMs, equals(60000));
      expect(reconstituted.season, equals(2));
      expect(reconstituted.episode, equals(7));
      expect(reconstituted.mediaType, equals(MediaType.video));
    });

    test('Json string serialization and deserialization behaves as expected', () {
      final item = MediaItem(
        id: 5,
        mrl: '/audio/song.flac',
        title: 'Song',
        mediaType: MediaType.audio,
        folderPath: '/audio',
        dateAdded: DateTime.now(),
      );
      final jsonStr = item.toJson();
      final parsed = MediaItem.fromJson(jsonStr);
      expect(parsed.id, equals(item.id));
      expect(parsed.mrl, equals(item.mrl));
      expect(parsed.mediaType, equals(MediaType.audio));
    });
  });

  group('MediaFolder Domain Model Tests', () {
    test('MediaFolder toMap and fromMap maintains integrity', () {
      final now = DateTime.now();
      final folder = MediaFolder(
        id: 10,
        path: '/Volumes/Storage/Anime',
        name: 'Anime',
        itemCount: 24,
        lastIndexed: now,
        isBanned: false,
      );

      final map = folder.toMap();
      final restored = MediaFolder.fromMap(map);

      expect(restored.id, equals(10));
      expect(restored.path, equals('/Volumes/Storage/Anime'));
      expect(restored.name, equals('Anime'));
      expect(restored.itemCount, equals(24));
      expect(restored.isBanned, isFalse);
    });
  });
}
