/// Subtitle domain models for VLC Modern Redesign
enum SubtitleScope {
  thisFile,
  thisFolder,
  thisPlaylist,
}

extension SubtitleScopeExtension on SubtitleScope {
  String get label {
    switch (this) {
      case SubtitleScope.thisFile:
        return 'This File Only';
      case SubtitleScope.thisFolder:
        return 'This Folder (Batch)';
      case SubtitleScope.thisPlaylist:
        return 'This Playlist (Batch)';
    }
  }

  String get description {
    switch (this) {
      case SubtitleScope.thisFile:
        return 'Apply subtitle strictly to the current playing video';
      case SubtitleScope.thisFolder:
        return 'Auto-match subtitle files against all video files in the current folder';
      case SubtitleScope.thisPlaylist:
        return 'Auto-match subtitle files against all media files in the active playlist';
    }
  }
}

class VlcSubtitleTrack {
  final int id;
  final String name;
  final String language;
  final bool isEmbedded;
  final String? filePath;

  const VlcSubtitleTrack({
    required this.id,
    required this.name,
    this.language = 'und',
    this.isEmbedded = true,
    this.filePath,
  });

  static const VlcSubtitleTrack disabled = VlcSubtitleTrack(
    id: -1,
    name: 'Disable Subtitles',
    language: 'none',
    isEmbedded: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VlcSubtitleTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath;

  @override
  int get hashCode => id.hashCode ^ filePath.hashCode;
}

class OnlineSubtitleResult {
  final String id;
  final String title;
  final String language;
  final String releaseName;
  final String uploader;
  final int downloadCount;
  final double rating;
  final bool hearingImpaired;
  final String downloadUrl;
  final double matchScore;

  const OnlineSubtitleResult({
    required this.id,
    required this.title,
    required this.language,
    required this.releaseName,
    required this.uploader,
    required this.downloadCount,
    required this.rating,
    required this.hearingImpaired,
    required this.downloadUrl,
    required this.matchScore,
  });
}

class BatchSubtitleMatch {
  final String videoPath;
  final String videoFileName;
  final String subtitlePath;
  final String subtitleFileName;
  final int? season;
  final int? episode;
  final double matchScore; // 0.0 - 1.0 (e.g. 0.98 for 98%)
  final bool isConfirmed;

  const BatchSubtitleMatch({
    required this.videoPath,
    required this.videoFileName,
    required this.subtitlePath,
    required this.subtitleFileName,
    this.season,
    this.episode,
    required this.matchScore,
    this.isConfirmed = true,
  });

  BatchSubtitleMatch copyWith({
    String? videoPath,
    String? videoFileName,
    String? subtitlePath,
    String? subtitleFileName,
    int? season,
    int? episode,
    double? matchScore,
    bool? isConfirmed,
  }) {
    return BatchSubtitleMatch(
      videoPath: videoPath ?? this.videoPath,
      videoFileName: videoFileName ?? this.videoFileName,
      subtitlePath: subtitlePath ?? this.subtitlePath,
      subtitleFileName: subtitleFileName ?? this.subtitleFileName,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      matchScore: matchScore ?? this.matchScore,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

