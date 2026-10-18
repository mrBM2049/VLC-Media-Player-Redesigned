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

/// Background shading style behind subtitle text
enum SubtitleBackgroundStyle {
  none,
  semiTransparent,
  solidBlack,
  roundedBox,
}

extension SubtitleBackgroundStyleExtension on SubtitleBackgroundStyle {
  String get label {
    switch (this) {
      case SubtitleBackgroundStyle.none:
        return 'None';
      case SubtitleBackgroundStyle.semiTransparent:
        return 'Shadow Box (50%)';
      case SubtitleBackgroundStyle.solidBlack:
        return 'Solid Black';
      case SubtitleBackgroundStyle.roundedBox:
        return 'Rounded Box';
    }
  }
}

/// Screen positioning alignment for subtitle dialogue
enum SubtitleAlignment {
  bottom,
  top,
  center,
}

/// Subtitle styling appearance profile
class SubtitleAppearance {
  final double fontScale; // 0.5 (50%) to 2.0 (200%), default 1.0 (100%)
  final String fontFamily; // Inter, Trebuchet MS, Roboto, Courier New, Times New Roman
  final int textColorValue; // 0xFFFFFFFF
  final double textOpacity; // 0.5 to 1.0
  final double outlineWidth; // 0.0 to 4.0 dp
  final int outlineColorValue; // 0xFF000000
  final SubtitleBackgroundStyle backgroundStyle;
  final SubtitleAlignment alignment;
  final double verticalOffset; // 0 to 100 dp
  final bool isRelativeSizing; // true = % of screen, false = precise px

  const SubtitleAppearance({
    this.fontScale = 1.0,
    this.fontFamily = 'Inter',
    this.textColorValue = 0xFFFFFFFF,
    this.textOpacity = 1.0,
    this.outlineWidth = 2.0,
    this.outlineColorValue = 0xFF000000,
    this.backgroundStyle = SubtitleBackgroundStyle.none,
    this.alignment = SubtitleAlignment.bottom,
    this.verticalOffset = 24.0,
    this.isRelativeSizing = true,
  });

  static const SubtitleAppearance defaultStyle = SubtitleAppearance();

  static const SubtitleAppearance anime = SubtitleAppearance(
    fontScale: 1.1,
    fontFamily: 'Inter',
    textColorValue: 0xFFFFF176, // Soft yellow
    outlineWidth: 2.5,
    outlineColorValue: 0xFF000000,
    backgroundStyle: SubtitleBackgroundStyle.none,
  );

  static const SubtitleAppearance highContrast = SubtitleAppearance(
    fontScale: 1.25,
    fontFamily: 'Inter',
    textColorValue: 0xFFFFFFFF,
    outlineWidth: 3.0,
    outlineColorValue: 0xFF000000,
    backgroundStyle: SubtitleBackgroundStyle.solidBlack,
  );

  static const SubtitleAppearance closedCaptions = SubtitleAppearance(
    fontScale: 1.05,
    fontFamily: 'Courier New',
    textColorValue: 0xFFFFFFFF,
    outlineWidth: 0.0,
    backgroundStyle: SubtitleBackgroundStyle.semiTransparent,
  );

  SubtitleAppearance copyWith({
    double? fontScale,
    String? fontFamily,
    int? textColorValue,
    double? textOpacity,
    double? outlineWidth,
    int? outlineColorValue,
    SubtitleBackgroundStyle? backgroundStyle,
    SubtitleAlignment? alignment,
    double? verticalOffset,
    bool? isRelativeSizing,
  }) {
    return SubtitleAppearance(
      fontScale: fontScale ?? this.fontScale,
      fontFamily: fontFamily ?? this.fontFamily,
      textColorValue: textColorValue ?? this.textColorValue,
      textOpacity: textOpacity ?? this.textOpacity,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      outlineColorValue: outlineColorValue ?? this.outlineColorValue,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      alignment: alignment ?? this.alignment,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      isRelativeSizing: isRelativeSizing ?? this.isRelativeSizing,
    );
  }
}

/// Represents a timed dialogue cue for the interactive subtitle timeline
class SubtitleDialogueCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleDialogueCue({
    required this.start,
    required this.end,
    required this.text,
  });

  Duration get duration => end - start;

  bool isActiveAt(Duration time, Duration delay) {
    final effectiveTime = time - delay;
    return effectiveTime >= start && effectiveTime <= end;
  }
}


