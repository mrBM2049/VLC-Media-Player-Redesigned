import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../models/media_library_models.dart';

/// VideoLAN medialibrary SQLite indexer and folder watcher service.
///
/// Implements native local indexing of video & audio media, continuous directory
/// watching via live file system streams, automatic TV episode metadata extraction,
/// persistent resume position tracking with auto-watched detection at 90%, and
/// priority sorting (Watched First vs. Unwatched First).
class MediaLibraryService extends ChangeNotifier {
  final Database _db;
  final bool _ownsDatabase;
  final Map<String, StreamSubscription<FileSystemEvent>> _folderWatchers = {};

  final _mediaStreamController = StreamController<List<MediaItem>>.broadcast();
  Stream<List<MediaItem>> get mediaStream => _mediaStreamController.stream;

  static const Set<String> videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.ts',
    '.m2ts',
    '.iso',
  };

  static const Set<String> audioExtensions = {
    '.mp3',
    '.flac',
    '.wav',
    '.aac',
    '.m4a',
    '.ogg',
    '.opus',
    '.wma',
    '.alac',
    '.aiff',
  };

  /// Constructs a MediaLibraryService.
  /// If [database] is not provided, an in-memory or file-backed database is opened.
  MediaLibraryService({Database? database, String? databasePath})
      : _db = database ??
            (databasePath != null
                ? sqlite3.open(databasePath)
                : sqlite3.openInMemory()),
        _ownsDatabase = database == null {
    _initSchema();
  }

  /// Factory constructor for opening the user's persistent medialibrary SQLite file.
  factory MediaLibraryService.persistent({String? customPath}) {
    final dbPath = customPath ?? _getDefaultDatabasePath();
    final dbFile = File(dbPath);
    if (!dbFile.parent.existsSync()) {
      dbFile.parent.createSync(recursive: true);
    }
    final db = sqlite3.open(dbPath);
    return MediaLibraryService(database: db);
  }

  static String _getDefaultDatabasePath() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.join(home, '.vlc_modern', 'medialibrary.db');
  }

  Database get database => _db;

  void _initSchema() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        item_count INTEGER DEFAULT 0,
        last_indexed INTEGER NOT NULL,
        is_banned INTEGER DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mrl TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        duration_ms INTEGER DEFAULT 0,
        last_played INTEGER,
        resume_position_ms INTEGER DEFAULT 0,
        resume_progress REAL DEFAULT 0.0,
        is_watched INTEGER DEFAULT 0,
        play_count INTEGER DEFAULT 0,
        file_size_bytes INTEGER DEFAULT 0,
        folder_path TEXT NOT NULL,
        media_type TEXT NOT NULL,
        thumbnail_path TEXT,
        season INTEGER,
        episode INTEGER,
        artist TEXT,
        album TEXT,
        genre TEXT,
        date_added INTEGER NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        played_at INTEGER NOT NULL,
        duration_watched_ms INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        FOREIGN KEY (media_id) REFERENCES media (id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER NOT NULL,
        time_ms INTEGER NOT NULL,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (media_id) REFERENCES media (id) ON DELETE CASCADE
      );
    ''');

    // Create performance indexes
    _db.execute('CREATE INDEX IF NOT EXISTS idx_media_mrl ON media (mrl);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_media_folder ON media (folder_path);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_media_watched ON media (is_watched);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_media_last_played ON media (last_played);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_media_type ON media (media_type);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_folders_path ON folders (path);');
  }

  /// Indexes a single file, adding or updating its metadata in the database.
  MediaItem? indexFile(String filePath, {int durationMs = 0}) {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final ext = p.extension(filePath).toLowerCase();
    MediaType mediaType;
    if (videoExtensions.contains(ext)) {
      mediaType = MediaType.video;
    } else if (audioExtensions.contains(ext)) {
      mediaType = MediaType.audio;
    } else {
      return null;
    }

    final stat = file.statSync();
    final folderPath = file.parent.path;
    final rawFileName = p.basenameWithoutExtension(filePath);
    final parsed = _parseMediaTitle(rawFileName);

    // Check if media already exists to preserve resume & watched state
    final existingStmt = _db.prepare('SELECT * FROM media WHERE mrl = ? LIMIT 1;');
    final existingRow = existingStmt.select([filePath]);
    existingStmt.dispose();

    final now = DateTime.now().millisecondsSinceEpoch;

    if (existingRow.isNotEmpty) {
      final row = existingRow.first;
      final existingDuration = row['duration_ms'] as int? ?? 0;
      final updatedDuration = durationMs > 0 ? durationMs : existingDuration;

      _db.execute('''
        UPDATE media SET
          title = ?,
          file_size_bytes = ?,
          folder_path = ?,
          duration_ms = ?,
          season = ?,
          episode = ?
        WHERE mrl = ?;
      ''', [
        parsed.title,
        stat.size,
        folderPath,
        updatedDuration,
        parsed.season,
        parsed.episode,
        filePath,
      ]);
    } else {
      _db.execute('''
        INSERT INTO media (
          mrl, title, duration_ms, last_played, resume_position_ms,
          resume_progress, is_watched, play_count, file_size_bytes,
          folder_path, media_type, thumbnail_path, season, episode,
          artist, album, genre, date_added
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''', [
        filePath,
        parsed.title,
        durationMs,
        null,
        0,
        0.0,
        0,
        0,
        stat.size,
        folderPath,
        mediaType.name,
        null,
        parsed.season,
        parsed.episode,
        null,
        null,
        null,
        now,
      ]);
    }

    _notifyUpdated();
    return getMediaItemByMrl(filePath);
  }

  /// Indexes a directory recursively or shallowly, registering media items in SQLite.
  Future<int> indexFolder(String folderPath, {bool recursive = true}) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return 0;

    // Check if folder is banned
    final bannedStmt = _db.prepare('SELECT is_banned FROM folders WHERE path = ? LIMIT 1;');
    final bannedResult = bannedStmt.select([folderPath]);
    bannedStmt.dispose();
    if (bannedResult.isNotEmpty && (bannedResult.first['is_banned'] as int? ?? 0) == 1) {
      return 0;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final folderName = p.basename(folderPath).isEmpty ? folderPath : p.basename(folderPath);

    // Upsert folder in folders table
    _db.execute('''
      INSERT INTO folders (path, name, item_count, last_indexed, is_banned)
      VALUES (?, ?, 0, ?, 0)
      ON CONFLICT(path) DO UPDATE SET
        name = excluded.name,
        last_indexed = excluded.last_indexed;
    ''', [folderPath, folderName, now]);

    int indexedCount = 0;
    try {
      final entities = dir.listSync(recursive: recursive, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (videoExtensions.contains(ext) || audioExtensions.contains(ext)) {
            indexFile(entity.path);
            indexedCount++;
          }
        }
      }
    } catch (e) {
      debugPrint('MediaLibraryService indexFolder error: $e');
    }

    // Update folder item_count
    final countStmt = _db.prepare('SELECT COUNT(*) as cnt FROM media WHERE folder_path LIKE ?;');
    final countRes = countStmt.select(['$folderPath%']);
    final totalItems = countRes.isNotEmpty ? (countRes.first['cnt'] as int? ?? indexedCount) : indexedCount;
    countStmt.dispose();

    _db.execute('UPDATE folders SET item_count = ? WHERE path = ?;', [totalItems, folderPath]);

    _notifyUpdated();
    return indexedCount;
  }

  /// Starts watching a directory for live file changes (additions, deletions, modifications).
  void watchFolder(String folderPath, {bool recursive = true}) {
    final dir = Directory(folderPath);
    if (!dir.existsSync() || _folderWatchers.containsKey(folderPath)) return;

    try {
      final sub = dir.watch(recursive: recursive).listen((event) {
        final ext = p.extension(event.path).toLowerCase();
        final isMedia = videoExtensions.contains(ext) || audioExtensions.contains(ext);
        if (!isMedia) return;

        if (event is FileSystemCreateEvent || event is FileSystemModifyEvent) {
          indexFile(event.path);
        } else if (event is FileSystemDeleteEvent) {
          removeMedia(event.path);
        }
      }, onError: (err) {
        debugPrint('MediaLibrary folder watch error for $folderPath: $err');
      });

      _folderWatchers[folderPath] = sub;
    } catch (e) {
      debugPrint('MediaLibrary could not watch folder $folderPath: $e');
    }
  }

  /// Stops watching a specific folder.
  void unwatchFolder(String folderPath) {
    final sub = _folderWatchers.remove(folderPath);
    sub?.cancel();
  }

  /// Updates playback progress and automatically marks as watched if >= 90%.
  void updatePlaybackProgress(
    String mrl, {
    required int positionMs,
    required int durationMs,
  }) {
    if (durationMs <= 0 && positionMs <= 0) return;

    final progress = durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check existing item
    final existing = getMediaItemByMrl(mrl);
    if (existing == null) {
      // Create record dynamically if not yet indexed
      indexFile(mrl, durationMs: durationMs);
    }

    final isWatched = progress >= 0.90 || (existing?.isWatched ?? false);

    _db.execute('''
      UPDATE media SET
        resume_position_ms = ?,
        resume_progress = ?,
        duration_ms = CASE WHEN ? > 0 THEN ? ELSE duration_ms END,
        is_watched = ?,
        last_played = ?
      WHERE mrl = ?;
    ''', [
      positionMs,
      progress,
      durationMs,
      durationMs,
      isWatched ? 1 : 0,
      now,
      mrl,
    ]);

    _notifyUpdated();
  }

  /// Explicitly marks media item as watched or unwatched.
  void markAsWatched(String mrl, {bool watched = true}) {
    _db.execute('''
      UPDATE media SET
        is_watched = ?,
        resume_progress = CASE WHEN ? = 1 THEN 1.0 ELSE resume_progress END
      WHERE mrl = ?;
    ''', [watched ? 1 : 0, watched ? 1 : 0, mrl]);

    _notifyUpdated();
  }

  /// Records a play count increment and updates last played timestamp.
  void recordPlay(String mrl) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _db.execute('''
      UPDATE media SET
        play_count = play_count + 1,
        last_played = ?
      WHERE mrl = ?;
    ''', [now, mrl]);

    _notifyUpdated();
  }

  /// Records an entry into the playback history table.
  void recordPlaybackHistory(
    String mrl, {
    required int durationWatchedMs,
    required bool completed,
  }) {
    final item = getMediaItemByMrl(mrl);
    if (item == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _db.execute('''
      INSERT INTO history (media_id, played_at, duration_watched_ms, completed)
      VALUES (?, ?, ?, ?);
    ''', [item.id, now, durationWatchedMs, completed ? 1 : 0]);
  }

  /// Retrieves the resume position in milliseconds.
  /// If the item was completed (> 95% or marked watched), returns 0 to start fresh.
  int getResumePosition(String mrl) {
    final item = getMediaItemByMrl(mrl);
    if (item == null) return 0;
    if (item.isWatched && item.resumeProgress >= 0.95) return 0;
    return item.resumePositionMs;
  }

  /// Retrieves a single MediaItem by its MRL/path.
  MediaItem? getMediaItemByMrl(String mrl) {
    final stmt = _db.prepare('SELECT * FROM media WHERE mrl = ? LIMIT 1;');
    final rows = stmt.select([mrl]);
    stmt.dispose();
    if (rows.isEmpty) return null;
    return _rowToMediaItem(rows.first);
  }

  /// Retrieves media items with full filtering, searching, and custom sorting.
  List<MediaItem> getMediaItems({
    MediaSortOrder sortOrder = MediaSortOrder.unwatchedFirst,
    MediaFilter filter = MediaFilter.all,
    String? searchQuery,
    String? folderPath,
  }) {
    final whereClauses = <String>[];
    final params = <dynamic>[];

    // Filter scope
    switch (filter) {
      case MediaFilter.videoOnly:
        whereClauses.add("media_type = 'video'");
        break;
      case MediaFilter.audioOnly:
        whereClauses.add("media_type = 'audio'");
        break;
      case MediaFilter.watchedOnly:
        whereClauses.add("is_watched = 1");
        break;
      case MediaFilter.unwatchedOnly:
        whereClauses.add("is_watched = 0");
        break;
      case MediaFilter.all:
        break;
    }

    // Folder path scope
    if (folderPath != null && folderPath.isNotEmpty) {
      whereClauses.add('folder_path LIKE ?');
      params.add('$folderPath%');
    }

    // Search query scope
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR mrl LIKE ?)');
      final q = '%${searchQuery.trim()}%';
      params.add(q);
      params.add(q);
    }

    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';

    // Order clause based on VideoLAN medialibrary sorting
    String orderBySql;
    switch (sortOrder) {
      case MediaSortOrder.watchedFirst:
        // Watched files first (by lastPlayed DESC), followed by unwatched files
        orderBySql = 'ORDER BY is_watched DESC, last_played DESC, date_added DESC, title COLLATE NOCASE ASC';
        break;
      case MediaSortOrder.unwatchedFirst:
        // Unwatched files first (by dateAdded DESC), followed by watched files
        orderBySql = 'ORDER BY is_watched ASC, date_added DESC, title COLLATE NOCASE ASC';
        break;
      case MediaSortOrder.recentlyPlayed:
        orderBySql = 'ORDER BY last_played DESC, date_added DESC';
        break;
      case MediaSortOrder.titleAz:
        orderBySql = 'ORDER BY title COLLATE NOCASE ASC';
        break;
      case MediaSortOrder.titleZa:
        orderBySql = 'ORDER BY title COLLATE NOCASE DESC';
        break;
      case MediaSortOrder.durationAsc:
        orderBySql = 'ORDER BY duration_ms ASC, title COLLATE NOCASE ASC';
        break;
      case MediaSortOrder.durationDesc:
        orderBySql = 'ORDER BY duration_ms DESC, title COLLATE NOCASE ASC';
        break;
      case MediaSortOrder.dateAddedDesc:
        orderBySql = 'ORDER BY date_added DESC';
        break;
      case MediaSortOrder.fileSizeDesc:
        orderBySql = 'ORDER BY file_size_bytes DESC';
        break;
    }

    final sql = 'SELECT * FROM media $whereSql $orderBySql;';
    final stmt = _db.prepare(sql);
    final rows = stmt.select(params);
    stmt.dispose();

    return rows.map(_rowToMediaItem).toList();
  }

  /// Retrieves "Continue Watching" items (in progress, between 2% and 90%, unwatched).
  List<MediaItem> getContinueWatching({int limit = 10}) {
    final stmt = _db.prepare('''
      SELECT * FROM media
      WHERE resume_position_ms > 2000
        AND resume_progress < 0.90
        AND is_watched = 0
      ORDER BY last_played DESC, date_added DESC
      LIMIT ?;
    ''');
    final rows = stmt.select([limit]);
    stmt.dispose();
    return rows.map(_rowToMediaItem).toList();
  }

  /// Retrieves list of indexed folders.
  List<MediaFolder> getFolders() {
    final rows = _db.select('SELECT * FROM folders WHERE is_banned = 0 ORDER BY name COLLATE NOCASE ASC;');
    return rows.map((row) {
      return MediaFolder(
        id: row['id'] as int? ?? 0,
        path: row['path'] as String,
        name: row['name'] as String,
        itemCount: row['item_count'] as int? ?? 0,
        lastIndexed: DateTime.fromMillisecondsSinceEpoch(row['last_indexed'] as int? ?? 0),
        isBanned: (row['is_banned'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  /// Bans or unbans a folder from being scanned.
  void banFolder(String folderPath, {bool ban = true}) {
    _db.execute('''
      UPDATE folders SET is_banned = ? WHERE path = ?;
    ''', [ban ? 1 : 0, folderPath]);
    if (ban) {
      unwatchFolder(folderPath);
      // Remove media under this folder
      _db.execute('DELETE FROM media WHERE folder_path LIKE ?;', ['$folderPath%']);
    }
    _notifyUpdated();
  }

  /// Removes an indexed media item by MRL.
  void removeMedia(String mrl) {
    _db.execute('DELETE FROM media WHERE mrl = ?;', [mrl]);
    _notifyUpdated();
  }

  /// Clears all indexed items and folders.
  void clearAll() {
    _db.execute('DELETE FROM history;');
    _db.execute('DELETE FROM bookmarks;');
    _db.execute('DELETE FROM media;');
    _db.execute('DELETE FROM folders;');
    _notifyUpdated();
  }

  void _notifyUpdated() {
    notifyListeners();
    final all = getMediaItems();
    if (!_mediaStreamController.isClosed) {
      _mediaStreamController.add(all);
    }
  }

  MediaItem _rowToMediaItem(Row row) {
    return MediaItem(
      id: row['id'] as int? ?? 0,
      mrl: row['mrl'] as String,
      title: row['title'] as String,
      durationMs: row['duration_ms'] as int? ?? 0,
      lastPlayed: row['last_played'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['last_played'] as int)
          : null,
      resumePositionMs: row['resume_position_ms'] as int? ?? 0,
      resumeProgress: (row['resume_progress'] as num?)?.toDouble() ?? 0.0,
      isWatched: (row['is_watched'] as int? ?? 0) == 1,
      playCount: row['play_count'] as int? ?? 0,
      fileSizeBytes: row['file_size_bytes'] as int? ?? 0,
      folderPath: row['folder_path'] as String? ?? '',
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == row['media_type'],
        orElse: () => MediaType.video,
      ),
      thumbnailPath: row['thumbnail_path'] as String?,
      season: row['season'] as int?,
      episode: row['episode'] as int?,
      artist: row['artist'] as String?,
      album: row['album'] as String?,
      genre: row['genre'] as String?,
      dateAdded: row['date_added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['date_added'] as int)
          : DateTime.now(),
    );
  }

  /// Parses titles and detects TV Season/Episode patterns.
  _ParsedMediaInfo _parseMediaTitle(String rawName) {
    // Standard S01E05
    final sxxExx = RegExp(r'[sS](\d{1,2})[eE](\d{1,3})');
    final matchSxx = sxxExx.firstMatch(rawName);
    if (matchSxx != null) {
      final s = int.tryParse(matchSxx.group(1)!);
      final e = int.tryParse(matchSxx.group(2)!);
      final cleanTitle = _cleanTitle(rawName.substring(0, matchSxx.start));
      return _ParsedMediaInfo(
        title: cleanTitle.isEmpty ? _cleanTitle(rawName) : cleanTitle,
        season: s,
        episode: e,
      );
    }

    // 1x05
    final numXnum = RegExp(r'(\d{1,2})x(\d{1,3})');
    final matchNumX = numXnum.firstMatch(rawName);
    if (matchNumX != null) {
      final s = int.tryParse(matchNumX.group(1)!);
      final e = int.tryParse(matchNumX.group(2)!);
      final cleanTitle = _cleanTitle(rawName.substring(0, matchNumX.start));
      return _ParsedMediaInfo(
        title: cleanTitle.isEmpty ? _cleanTitle(rawName) : cleanTitle,
        season: s,
        episode: e,
      );
    }

    // Episode 08 / EP08
    final epRegex = RegExp(r'(?:episode|ep)[._\s-]*(\d{1,3})', caseSensitive: false);
    final matchEp = epRegex.firstMatch(rawName);
    if (matchEp != null) {
      final e = int.tryParse(matchEp.group(1)!);
      final cleanTitle = _cleanTitle(rawName.substring(0, matchEp.start));
      return _ParsedMediaInfo(
        title: cleanTitle.isEmpty ? _cleanTitle(rawName) : cleanTitle,
        season: 1,
        episode: e,
      );
    }

    return _ParsedMediaInfo(title: _cleanTitle(rawName));
  }

  String _cleanTitle(String text) {
    var clean = text
        .replaceAll(RegExp(r'[\._\+]'), ' ')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return clean.isEmpty ? text : clean;
  }

  @override
  void dispose() {
    for (final watcher in _folderWatchers.values) {
      watcher.cancel();
    }
    _folderWatchers.clear();
    _mediaStreamController.close();
    if (_ownsDatabase) {
      _db.dispose();
    }
    super.dispose();
  }
}

class _ParsedMediaInfo {
  final String title;
  final int? season;
  final int? episode;

  const _ParsedMediaInfo({required this.title, this.season, this.episode});
}

