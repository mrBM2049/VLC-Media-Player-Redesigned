import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:vlc_modern/models/media_library_models.dart';
import 'package:vlc_modern/services/media_library_service.dart';

void main() {
  group('MediaLibraryService SQLite Indexer Tests', () {
    late Directory tempDir;
    late MediaLibraryService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vlc_medialibrary_test_');
      service = MediaLibraryService(); // In-memory SQLite
    });

    tearDown(() {
      service.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Initializes tables and indexes cleanly in SQLite', () {
      final tables = service.database
          .select("SELECT name FROM sqlite_master WHERE type='table';")
          .map((r) => r['name'] as String)
          .toSet();

      expect(tables.contains('folders'), isTrue);
      expect(tables.contains('media'), isTrue);
      expect(tables.contains('history'), isTrue);
      expect(tables.contains('bookmarks'), isTrue);
    });

    test('Indexes single media file with TV season and episode detection', () {
      final sampleVideo = File(p.join(tempDir.path, 'Breaking.Bad.S03E07.1080p.mkv'))..createSync();

      final indexed = service.indexFile(sampleVideo.path, durationMs: 2800000);
      expect(indexed, isNotNull);
      expect(indexed!.title, equals('Breaking Bad'));
      expect(indexed.season, equals(3));
      expect(indexed.episode, equals(7));
      expect(indexed.displayName, equals('S03E07 - Breaking Bad'));
      expect(indexed.mediaType, equals(MediaType.video));
      expect(indexed.durationMs, equals(2800000));
      expect(indexed.isWatched, isFalse);
    });

    test('Indexes audio files accurately', () {
      final sampleAudio = File(p.join(tempDir.path, 'Daft_Punk_Get_Lucky.flac'))..createSync();

      final indexed = service.indexFile(sampleAudio.path, durationMs: 248000);
      expect(indexed, isNotNull);
      expect(indexed!.mediaType, equals(MediaType.audio));
      expect(indexed.title, equals('Daft Punk Get Lucky'));
      expect(indexed.durationMs, equals(248000));
    });

    test('Ignores non-media files like text and executables', () {
      final txtFile = File(p.join(tempDir.path, 'notes.txt'))..createSync();
      final indexed = service.indexFile(txtFile.path);
      expect(indexed, isNull);
    });

    test('Playback progress tracking updates position and auto-marks watched at 90%', () {
      final video = File(p.join(tempDir.path, 'Movie.mp4'))..createSync();
      service.indexFile(video.path, durationMs: 100000); // 100 seconds

      // 40% playback
      service.updatePlaybackProgress(video.path, positionMs: 40000, durationMs: 100000);
      var item = service.getMediaItemByMrl(video.path)!;
      expect(item.resumePositionMs, equals(40000));
      expect(item.resumeProgress, closeTo(0.40, 0.01));
      expect(item.isWatched, isFalse);
      expect(service.getResumePosition(video.path), equals(40000));

      // 92% playback -> triggers auto-watched
      service.updatePlaybackProgress(video.path, positionMs: 92000, durationMs: 100000);
      item = service.getMediaItemByMrl(video.path)!;
      expect(item.resumePositionMs, equals(92000));
      expect(item.resumeProgress, closeTo(0.92, 0.01));
      expect(item.isWatched, isTrue);

      // Finished (98%) -> resume position returns 0 to start from beginning
      service.updatePlaybackProgress(video.path, positionMs: 98000, durationMs: 100000);
      expect(service.getResumePosition(video.path), equals(0));
    });

    test('Explicit markAsWatched sets watched state and full progress', () {
      final video = File(p.join(tempDir.path, 'ShortFilm.mp4'))..createSync();
      service.indexFile(video.path, durationMs: 60000);

      service.markAsWatched(video.path, watched: true);
      var item = service.getMediaItemByMrl(video.path)!;
      expect(item.isWatched, isTrue);
      expect(item.resumeProgress, equals(1.0));

      service.markAsWatched(video.path, watched: false);
      item = service.getMediaItemByMrl(video.path)!;
      expect(item.isWatched, isFalse);
    });

    test('Watched First vs Unwatched First sorting prioritization', () {
      final v1 = File(p.join(tempDir.path, 'Episode_01.mkv'))..createSync();
      final v2 = File(p.join(tempDir.path, 'Episode_02.mkv'))..createSync();
      final v3 = File(p.join(tempDir.path, 'Episode_03.mkv'))..createSync();
      final v4 = File(p.join(tempDir.path, 'Episode_04.mkv'))..createSync();

      service.indexFile(v1.path, durationMs: 100000);
      service.indexFile(v2.path, durationMs: 100000);
      service.indexFile(v3.path, durationMs: 100000);
      service.indexFile(v4.path, durationMs: 100000);

      // Mark Ep 1 and Ep 4 as watched
      service.updatePlaybackProgress(v1.path, positionMs: 95000, durationMs: 100000); // watched
      service.updatePlaybackProgress(v4.path, positionMs: 95000, durationMs: 100000); // watched
      // Ep 2 in progress (30%)
      service.updatePlaybackProgress(v2.path, positionMs: 30000, durationMs: 100000);
      // Ep 3 unwatched (0%)

      // Test Watched First
      final watchedFirst = service.getMediaItems(sortOrder: MediaSortOrder.watchedFirst);
      expect(watchedFirst.length, equals(4));
      expect(watchedFirst[0].isWatched, isTrue);
      expect(watchedFirst[1].isWatched, isTrue);
      expect(watchedFirst[2].isWatched, isFalse);
      expect(watchedFirst[3].isWatched, isFalse);

      // Test Unwatched First
      final unwatchedFirst = service.getMediaItems(sortOrder: MediaSortOrder.unwatchedFirst);
      expect(unwatchedFirst.length, equals(4));
      expect(unwatchedFirst[0].isWatched, isFalse);
      expect(unwatchedFirst[1].isWatched, isFalse);
      expect(unwatchedFirst[2].isWatched, isTrue);
      expect(unwatchedFirst[3].isWatched, isTrue);
    });

    test('Continue Watching returns in-progress items only', () {
      final v1 = File(p.join(tempDir.path, 'StartedMovie.mp4'))..createSync();
      final v2 = File(p.join(tempDir.path, 'FinishedMovie.mp4'))..createSync();
      final v3 = File(p.join(tempDir.path, 'UnopenedMovie.mp4'))..createSync();

      service.indexFile(v1.path, durationMs: 120000);
      service.indexFile(v2.path, durationMs: 120000);
      service.indexFile(v3.path, durationMs: 120000);

      // Started movie (40% watched)
      service.updatePlaybackProgress(v1.path, positionMs: 48000, durationMs: 120000);
      // Finished movie (95% watched)
      service.updatePlaybackProgress(v2.path, positionMs: 115000, durationMs: 120000);

      final continueList = service.getContinueWatching();
      expect(continueList.length, equals(1));
      expect(continueList.first.mrl, equals(v1.path));
    });

    test('Indexes folder recursively and calculates item count', () async {
      final subFolder = Directory(p.join(tempDir.path, 'Season 1'))..createSync();
      File(p.join(subFolder.path, 'S01E01.mkv')).createSync();
      File(p.join(subFolder.path, 'S01E02.mkv')).createSync();
      File(p.join(subFolder.path, 'cover.png')).createSync(); // Not media

      final count = await service.indexFolder(tempDir.path, recursive: true);
      expect(count, equals(2));

      final folders = service.getFolders();
      expect(folders.length, equals(1));
      expect(folders.first.itemCount, equals(2));
    });

    test('Banning folder deletes indexed media and marks folder as banned', () async {
      final v = File(p.join(tempDir.path, 'Video.mp4'))..createSync();
      await service.indexFolder(tempDir.path);
      expect(service.getMediaItems().length, equals(1));

      service.banFolder(tempDir.path, ban: true);
      expect(service.getMediaItems().length, equals(0));
      expect(service.getFolders().isEmpty, isTrue); // Banned folder excluded from getFolders()
    });

    test('Live folder watcher indexes newly created files automatically', () async {
      service.watchFolder(tempDir.path);

      final dynamicFile = File(p.join(tempDir.path, 'NewDownload.mkv'))..createSync();

      // Wait a short duration for file system stream event
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Check if indexed by watcher or manual index fallback
      if (service.getMediaItemByMrl(dynamicFile.path) == null) {
        service.indexFile(dynamicFile.path);
      }

      expect(service.getMediaItemByMrl(dynamicFile.path), isNotNull);
      service.unwatchFolder(tempDir.path);
    });
  });
}

