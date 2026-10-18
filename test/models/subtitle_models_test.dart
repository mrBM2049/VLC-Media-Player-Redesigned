import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('Subtitle Models & Appearance Tests', () {
    test('Default SubtitleAppearance matches standard specs', () {
      const app = SubtitleAppearance.defaultStyle;
      expect(app.fontScale, equals(1.0));
      expect(app.fontFamily, equals('Inter'));
      expect(app.textColorValue, equals(0xFFFFFFFF));
      expect(app.outlineWidth, equals(2.0));
      expect(app.backgroundStyle, equals(SubtitleBackgroundStyle.none));
      expect(app.isRelativeSizing, isTrue);
    });

    test('Anime preset has yellow text and enhanced outline', () {
      const app = SubtitleAppearance.anime;
      expect(app.fontScale, equals(1.1));
      expect(app.textColorValue, equals(0xFFFFF176));
      expect(app.outlineWidth, equals(2.5));
    });

    test('High contrast preset has solid black background box', () {
      const app = SubtitleAppearance.highContrast;
      expect(app.backgroundStyle, equals(SubtitleBackgroundStyle.solidBlack));
      expect(app.fontScale, equals(1.25));
    });

    test('SubtitleAppearance copyWith updates values correctly', () {
      const base = SubtitleAppearance.defaultStyle;
      final updated = base.copyWith(
        fontScale: 1.5,
        fontFamily: 'Trebuchet MS',
        backgroundStyle: SubtitleBackgroundStyle.roundedBox,
        isRelativeSizing: false,
      );

      expect(updated.fontScale, equals(1.5));
      expect(updated.fontFamily, equals('Trebuchet MS'));
      expect(updated.backgroundStyle, equals(SubtitleBackgroundStyle.roundedBox));
      expect(updated.isRelativeSizing, isFalse);
    });

    test('SubtitleDialogueCue accurately calculates active state with delay', () {
      const cue = SubtitleDialogueCue(
        start: Duration(seconds: 10),
        end: Duration(seconds: 15),
        text: 'Hello world',
      );

      expect(cue.duration, equals(const Duration(seconds: 5)));

      // At 12s with 0 delay -> active
      expect(cue.isActiveAt(const Duration(seconds: 12), Duration.zero), isTrue);

      // At 8s with 0 delay -> not active
      expect(cue.isActiveAt(const Duration(seconds: 8), Duration.zero), isFalse);

      // At 8s with -2s delay (subtitles shifted 2s earlier) -> effective = 8 - (-2) = 10s -> active!
      expect(cue.isActiveAt(const Duration(seconds: 8), const Duration(seconds: -2)), isTrue);
    });
  });
}
