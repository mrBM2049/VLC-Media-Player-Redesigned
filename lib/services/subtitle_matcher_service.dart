import 'dart:math';
import '../models/subtitle_models.dart';

/// Parsed metadata extracted from media/subtitle filenames
class ParsedEpisodeMeta {
  final String rawName;
  final String cleanedTitle;
  final int? season;
  final int? episode;

  const ParsedEpisodeMeta({
    required this.rawName,
    required this.cleanedTitle,
    this.season,
    this.episode,
  });
}

/// Intelligent batch season and episode fuzzy-matching service
class SubtitleMatcherService {
  static final RegExp _sExPattern = RegExp(r'[sS](\d{1,2})[eE](\d{1,3})');
  static final RegExp _xPattern = RegExp(r'(?:^|[^a-zA-Z0-9])(\d{1,2})x(\d{1,3})(?:$|[^a-zA-Z0-9])');
  static final RegExp _seasonPattern = RegExp(r'[sS]eason[._ -]?(\d{1,2})', caseSensitive: false);
  static final RegExp _epPattern = RegExp(r'(?:[eE][pP]?|[eE]pisode)[._ -]?(\d{1,3})', caseSensitive: false);
  static final RegExp _animePattern = RegExp(r'[-_ ](\d{2,3})(?:v\d+)?(?:\[|\.|\s|$)', caseSensitive: false);

  static final List<String> _releaseJunk = [
    '1080p', '720p', '480p', '2160p', '4k', 'uhd', 'hdr', 'hdr10',
    'webrip', 'web-dl', 'bluray', 'bdrip', 'brrip', 'hdtv',
    'x264', 'x265', 'hevc', 'avc', '10bit', 'aac', 'ac3', 'dts',
    'dts-hd', 'atmos', 'proper', 'repack', 'yts', 'psa', 'rarbg',
    'eztv', 'galaxy', 'sub', 'srt', 'vtt', 'ass', 'ssa', 'mkv', 'mp4', 'avi'
  ];

  /// Parses a filename to extract Season, Episode and a clean title string
  static ParsedEpisodeMeta parseFilename(String filename) {
    // Strip extension
    final lastDot = filename.lastIndexOf('.');
    final baseName = (lastDot > 0) ? filename.substring(0, lastDot) : filename;

    int? season;
    int? episode;

    // 1. Try S01E02
    final matchSE = _sExPattern.firstMatch(baseName);
    if (matchSE != null) {
      season = int.tryParse(matchSE.group(1)!);
      episode = int.tryParse(matchSE.group(2)!);
    } else {
      // 2. Try 1x02
      final matchX = _xPattern.firstMatch(baseName);
      if (matchX != null) {
        season = int.tryParse(matchX.group(1)!);
        episode = int.tryParse(matchX.group(2)!);
      } else {
        // 3. Try Season N and Episode N
        final matchSeason = _seasonPattern.firstMatch(baseName);
        if (matchSeason != null) {
          season = int.tryParse(matchSeason.group(1)!);
        }
        final matchEP = _epPattern.firstMatch(baseName);
        if (matchEP != null) {
          episode = int.tryParse(matchEP.group(1)!);
        } else {
          // 4. Try anime number e.g. - 05
          final matchAnime = _animePattern.firstMatch(baseName);
          if (matchAnime != null) {
            episode = int.tryParse(matchAnime.group(1)!);
          }
        }
      }
    }

    // Clean title for fuzzy matching: strip episode/season patterns
    String cleaned = baseName.toLowerCase();
    cleaned = cleaned.replaceAll(_sExPattern, ' ');
    cleaned = cleaned.replaceAll(_xPattern, ' ');
    cleaned = cleaned.replaceAll(_seasonPattern, ' ');
    cleaned = cleaned.replaceAll(_epPattern, ' ');
    cleaned = cleaned.replaceAll(_animePattern, ' ');

    for (final junk in _releaseJunk) {
      cleaned = cleaned.replaceAll(RegExp('\\b$junk\\b', caseSensitive: false), ' ');
    }
    // Remove brackets, dots, underscores, dashes
    cleaned = cleaned.replaceAll(RegExp(r'[\[\]\(\)\{\}\._\-]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedEpisodeMeta(
      rawName: filename,
      cleanedTitle: cleaned,
      season: season,
      episode: episode,
    );
  }

  /// Calculates Levenshtein string similarity score in range [0.0, 1.0]
  static double calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final d = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    final distance = d[s1.length][s2.length];
    final maxLen = max(s1.length, s2.length);
    return (1.0 - (distance / maxLen)).clamp(0.0, 1.0);
  }

  /// Computes composite match score between a video and a subtitle file
  static double matchScore(String videoFilename, String subtitleFilename) {
    final vMeta = parseFilename(videoFilename);
    final sMeta = parseFilename(subtitleFilename);

    // Exact filename match (ignoring extensions)
    final vBase = videoFilename.substring(0, videoFilename.lastIndexOf('.') > 0 ? videoFilename.lastIndexOf('.') : videoFilename.length);
    final sBase = subtitleFilename.substring(0, subtitleFilename.lastIndexOf('.') > 0 ? subtitleFilename.lastIndexOf('.') : subtitleFilename.length);
    if (vBase.toLowerCase() == sBase.toLowerCase()) {
      return 1.0;
    }

    double score = 0.0;

    // Episode & Season evaluation
    if (vMeta.episode != null && sMeta.episode != null) {
      if (vMeta.episode == sMeta.episode) {
        // Episodes match!
        if (vMeta.season != null && sMeta.season != null) {
          if (vMeta.season == sMeta.season) {
            // Both Season & Episode match exactly -> base 0.85
            score = 0.85;
          } else {
            // Different seasons -> mismatch penalty
            return 0.15;
          }
        } else {
          // Season unknown on one side, but episode matches
          score = 0.75;
        }
      } else {
        // Explicitly different episodes -> mismatch
        return 0.10;
      }
    }

    // Title string similarity (scaled into remaining headroom)
    final titleSim = calculateSimilarity(vMeta.cleanedTitle, sMeta.cleanedTitle);

    if (score > 0.0) {
      // Blend episode match with title similarity
      return (score + (titleSim * 0.15)).clamp(0.0, 1.0);
    }

    // Fallback: no episode parsed on one or both files -> pure title similarity
    return titleSim;
  }

  /// Batch matches a list of video file paths against a list of subtitle file paths
  static List<BatchSubtitleMatch> batchMatch({
    required List<String> videoPaths,
    required List<String> subtitlePaths,
  }) {
    final results = <BatchSubtitleMatch>[];
    final remainingSubs = List<String>.from(subtitlePaths);

    for (final videoPath in videoPaths) {
      final videoName = videoPath.split(RegExp(r'[\\/]')).last;
      final vMeta = parseFilename(videoName);

      String? bestSubPath;
      double highestScore = -1.0;

      for (final subPath in remainingSubs) {
        final subName = subPath.split(RegExp(r'[\\/]')).last;
        final score = matchScore(videoName, subName);

        if (score > highestScore) {
          highestScore = score;
          bestSubPath = subPath;
        }
      }

      if (bestSubPath != null && highestScore >= 0.40) {
        final subName = bestSubPath.split(RegExp(r'[\\/]')).last;
        results.add(
          BatchSubtitleMatch(
            videoPath: videoPath,
            videoFileName: videoName,
            subtitlePath: bestSubPath,
            subtitleFileName: subName,
            season: vMeta.season,
            episode: vMeta.episode,
            matchScore: double.parse(highestScore.toStringAsFixed(2)),
            isConfirmed: highestScore >= 0.70,
          ),
        );
        // Once paired with high confidence, remove to avoid re-assigning
        if (highestScore >= 0.75) {
          remainingSubs.remove(bestSubPath);
        }
      }
    }

    // Sort by season and episode if present, else by video name
    results.sort((a, b) {
      if (a.season != null && b.season != null && a.season != b.season) {
        return a.season!.compareTo(b.season!);
      }
      if (a.episode != null && b.episode != null && a.episode != b.episode) {
        return a.episode!.compareTo(b.episode!);
      }
      return a.videoFileName.compareTo(b.videoFileName);
    });

    return results;
  }
}

