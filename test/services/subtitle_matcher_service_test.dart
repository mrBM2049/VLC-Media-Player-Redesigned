import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/services/subtitle_matcher_service.dart';

void main() {
  group('SubtitleMatcherService Filename Parsing Tests', () {
    test('Parses standard S01E05 format accurately', () {
      final meta = SubtitleMatcherService.parseFilename('Interstellar.S01E05.1080p.WEBRip.x265.mkv');
      expect(meta.season, 1);
      expect(meta.episode, 5);
      expect(meta.cleanedTitle, 'interstellar');
    });

    test('Parses 2x14 format accurately', () {
      final meta = SubtitleMatcherService.parseFilename('Breaking.Bad.2x14.BluRay.720p.mkv');
      expect(meta.season, 2);
      expect(meta.episode, 14);
      expect(meta.cleanedTitle, 'breaking bad');
    });

    test('Parses Episode 08 and EP08 formats', () {
      final meta1 = SubtitleMatcherService.parseFilename('The.Mandalorian.Episode.08.mkv');
      expect(meta1.episode, 8);

      final meta2 = SubtitleMatcherService.parseFilename('Show_EP03_1080p.mp4');
      expect(meta2.episode, 3);
    });

    test('Parses anime format [SubGroup] Show - 12 [1080p].mkv', () {
      final meta = SubtitleMatcherService.parseFilename('[Judas] Attack on Titan - 12 [1080p].mkv');
      expect(meta.episode, 12);
    });
  });

  group('SubtitleMatcherService Matching & Similarity Tests', () {
    test('Exact match score is 1.0', () {
      final score = SubtitleMatcherService.matchScore(
        'Severance.S01E01.1080p.mkv',
        'Severance.S01E01.1080p.srt',
      );
      expect(score, 1.0);
    });

    test('Matching episode and season gets high confidence score (> 0.85)', () {
      final score = SubtitleMatcherService.matchScore(
        'Severance.S01E03.1080p.mkv',
        'Severance - Season 1 Episode 3 - English.srt',
      );
      expect(score, greaterThan(0.85));
    });

    test('Different episode numbers get heavy mismatch penalty (< 0.20)', () {
      final score = SubtitleMatcherService.matchScore(
        'Severance.S01E01.mkv',
        'Severance.S01E02.srt',
      );
      expect(score, lessThan(0.20));
    });

    test('Different season numbers get mismatch penalty (< 0.20)', () {
      final score = SubtitleMatcherService.matchScore(
        'Severance.S01E01.mkv',
        'Severance.S02E01.srt',
      );
      expect(score, lessThan(0.20));
    });
  });

  group('SubtitleMatcherService Batch Pairing Tests', () {
    test('Batch pairs multi-episode season accurately', () {
      final videos = [
        '/media/Show.S01E01.mkv',
        '/media/Show.S01E02.mkv',
        '/media/Show.S01E03.mkv',
      ];
      final subs = [
        '/media/subs/Show.1x03.srt',
        '/media/subs/Show.1x01.srt',
        '/media/subs/Show.1x02.srt',
      ];

      final matches = SubtitleMatcherService.batchMatch(
        videoPaths: videos,
        subtitlePaths: subs,
      );

      expect(matches.length, 3);
      // E01 paired with 1x01
      expect(matches[0].videoFileName, 'Show.S01E01.mkv');
      expect(matches[0].subtitleFileName, 'Show.1x01.srt');
      expect(matches[0].episode, 1);
      expect(matches[0].matchScore, greaterThan(0.85));

      // E02 paired with 1x02
      expect(matches[1].videoFileName, 'Show.S01E02.mkv');
      expect(matches[1].subtitleFileName, 'Show.1x02.srt');
      expect(matches[1].episode, 2);

      // E03 paired with 1x03
      expect(matches[2].videoFileName, 'Show.S01E03.mkv');
      expect(matches[2].subtitleFileName, 'Show.1x03.srt');
      expect(matches[2].episode, 3);
    });
  });
}

