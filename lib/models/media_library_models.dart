import 'dart:convert';

/// Media type classification adhering to VideoLAN medialibrary spec.
enum MediaType {
  video,
  audio,
  stream,
}

/// Sorting orders for media indexing, highlighting Watched / Unwatched prioritization.
enum MediaSortOrder {
  watchedFirst,
  unwatchedFirst,
  recentlyPlayed,
  titleAz,
  titleZa,
  durationAsc,
  durationDesc,
  dateAddedDesc,
  fileSizeDesc,
}

/// Filter scopes for library queries.
enum MediaFilter {
  all,
  videoOnly,
  audioOnly,
  watchedOnly,
  unwatchedOnly,
}

/// Domain model representing an indexed media file in the VideoLAN medialibrary.
class MediaItem {
  final int id;
  final String mrl;
  final String title;
  final int durationMs;
  final DateTime? lastPlayed;
  final int resumePositionMs;
  final double resumeProgress; // 0.0 - 1.0
  final bool isWatched;
  final int playCount;
  final int fileSizeBytes;
  final String folderPath;
  final MediaType mediaType;
  final String? thumbnailPath;
  final int? season;
  final int? episode;
  final String? artist;
  final String? album;
  final String? genre;
  final DateTime dateAdded;

  const MediaItem({
    required this.id,
    required this.mrl,
    required this.title,
    this.durationMs = 0,
    this.lastPlayed,
    this.resumePositionMs = 0,
    this.resumeProgress = 0.0,
    this.isWatched = false,
    this.playCount = 0,
    this.fileSizeBytes = 0,
    required this.folderPath,
    this.mediaType = MediaType.video,
    this.thumbnailPath,
    this.season,
    this.episode,
    this.artist,
    this.album,
    this.genre,
    required this.dateAdded,
  });

  /// Human-readable duration in mm:ss or hh:mm:ss format.
  String get formattedDuration {
    if (durationMs <= 0) return '00:00';
    final totalSeconds = (durationMs / 1000).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Human-readable resume time.
  String get formattedResumeTime {
    if (resumePositionMs <= 0) return '00:00';
    final totalSeconds = (resumePositionMs / 1000).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Human-readable file size (KB, MB, GB).
  String get formattedFileSize {
    if (fileSizeBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = fileSizeBytes.toDouble();
    var i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${suffixes[i]}';
  }

  /// Formatted display title with Season/Episode tag if available.
  String get displayName {
    if (season != null && episode != null) {
      final s = season!.toString().padLeft(2, '0');
      final ep = episode!.toString().padLeft(2, '0');
      return 'S${s}E$ep - $title';
    }
    return title;
  }

  /// Directory or folder name extracted from folderPath or mrl.
  String get folderName {
    if (folderPath.isNotEmpty) {
      final segments = folderPath.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) return segments.last;
    }
    return 'Media';
  }

  MediaItem copyWith({
    int? id,
    String? mrl,
    String? title,
    int? durationMs,
    DateTime? lastPlayed,
    int? resumePositionMs,
    double? resumeProgress,
    bool? isWatched,
    int? playCount,
    int? fileSizeBytes,
    String? folderPath,
    MediaType? mediaType,
    String? thumbnailPath,
    int? season,
    int? episode,
    String? artist,
    String? album,
    String? genre,
    DateTime? dateAdded,
  }) {
    return MediaItem(
      id: id ?? this.id,
      mrl: mrl ?? this.mrl,
      title: title ?? this.title,
      durationMs: durationMs ?? this.durationMs,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      resumePositionMs: resumePositionMs ?? this.resumePositionMs,
      resumeProgress: resumeProgress ?? this.resumeProgress,
      isWatched: isWatched ?? this.isWatched,
      playCount: playCount ?? this.playCount,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      folderPath: folderPath ?? this.folderPath,
      mediaType: mediaType ?? this.mediaType,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mrl': mrl,
      'title': title,
      'duration_ms': durationMs,
      'last_played': lastPlayed?.millisecondsSinceEpoch,
      'resume_position_ms': resumePositionMs,
      'resume_progress': resumeProgress,
      'is_watched': isWatched ? 1 : 0,
      'play_count': playCount,
      'file_size_bytes': fileSizeBytes,
      'folder_path': folderPath,
      'media_type': mediaType.name,
      'thumbnail_path': thumbnailPath,
      'season': season,
      'episode': episode,
      'artist': artist,
      'album': album,
      'genre': genre,
      'date_added': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as int? ?? 0,
      mrl: map['mrl'] as String,
      title: map['title'] as String,
      durationMs: map['duration_ms'] as int? ?? 0,
      lastPlayed: map['last_played'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played'] as int)
          : null,
      resumePositionMs: map['resume_position_ms'] as int? ?? 0,
      resumeProgress: (map['resume_progress'] as num?)?.toDouble() ?? 0.0,
      isWatched: (map['is_watched'] as int? ?? 0) == 1,
      playCount: map['play_count'] as int? ?? 0,
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      folderPath: map['folder_path'] as String? ?? '',
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == map['media_type'],
        orElse: () => MediaType.video,
      ),
      thumbnailPath: map['thumbnail_path'] as String?,
      season: map['season'] as int?,
      episode: map['episode'] as int?,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      genre: map['genre'] as String?,
      dateAdded: map['date_added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int)
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory MediaItem.fromJson(String source) =>
      MediaItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mrl == other.mrl &&
          isWatched == other.isWatched &&
          resumePositionMs == other.resumePositionMs &&
          playCount == other.playCount;

  @override
  int get hashCode =>
      id.hashCode ^
      mrl.hashCode ^
      isWatched.hashCode ^
      resumePositionMs.hashCode ^
      playCount.hashCode;

  @override
  String toString() =>
      'MediaItem(id: $id, title: $title, mrl: $mrl, watched: $isWatched, resume: ${resumePositionMs}ms, progress: ${(resumeProgress * 100).toStringAsFixed(1)}%)';
}

/// Model representing a watched directory in VideoLAN medialibrary.
class MediaFolder {
  final int id;
  final String path;
  final String name;
  final int itemCount;
  final DateTime lastIndexed;
  final bool isBanned;

  const MediaFolder({
    required this.id,
    required this.path,
    required this.name,
    this.itemCount = 0,
    required this.lastIndexed,
    this.isBanned = false,
  });

  MediaFolder copyWith({
    int? id,
    String? path,
    String? name,
    int? itemCount,
    DateTime? lastIndexed,
    bool? isBanned,
  }) {
    return MediaFolder(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      itemCount: itemCount ?? this.itemCount,
      lastIndexed: lastIndexed ?? this.lastIndexed,
      isBanned: isBanned ?? this.isBanned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'item_count': itemCount,
      'last_indexed': lastIndexed.millisecondsSinceEpoch,
      'is_banned': isBanned ? 1 : 0,
    };
  }

  factory MediaFolder.fromMap(Map<String, dynamic> map) {
    return MediaFolder(
      id: map['id'] as int? ?? 0,
      path: map['path'] as String,
      name: map['name'] as String,
      itemCount: map['item_count'] as int? ?? 0,
      lastIndexed: map['last_indexed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_indexed'] as int)
          : DateTime.now(),
      isBanned: (map['is_banned'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaFolder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path;

  @override
  int get hashCode => id.hashCode ^ path.hashCode;

  @override
  String toString() => 'MediaFolder(id: $id, name: $name, items: $itemCount, path: $path)';
}

/// Playback history entry.
class MediaPlaybackHistoryEntry {
  final int id;
  final int mediaId;
  final DateTime playedAt;
  final int durationWatchedMs;
  final bool completed;

  const MediaPlaybackHistoryEntry({
    required this.id,
    required this.mediaId,
    required this.playedAt,
    this.durationWatchedMs = 0,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'media_id': mediaId,
      'played_at': playedAt.millisecondsSinceEpoch,
      'duration_watched_ms': durationWatchedMs,
      'completed': completed ? 1 : 0,
    };
  }

  factory MediaPlaybackHistoryEntry.fromMap(Map<String, dynamic> map) {
    return MediaPlaybackHistoryEntry(
      id: map['id'] as int? ?? 0,
      mediaId: map['media_id'] as int,
      playedAt: DateTime.fromMillisecondsSinceEpoch(map['played_at'] as int),
      durationWatchedMs: map['duration_watched_ms'] as int? ?? 0,
      completed: (map['completed'] as int? ?? 0) == 1,
    );
  }
}

