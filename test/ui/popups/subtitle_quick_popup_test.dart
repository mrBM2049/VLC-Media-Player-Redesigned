import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/subtitle_models.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/popups/subtitle_quick_popup.dart';

void main() {
  group('SubtitleQuickPopup Widget Tests', () {
    const testTracks = [
      VlcSubtitleTrack(id: 1, name: 'English [Full]', language: 'en'),
      VlcSubtitleTrack(id: 2, name: 'Spanish [Latin]', language: 'es'),
      VlcSubtitleTrack(id: 3, name: 'Japanese [Original]', language: 'ja'),
    ];

    testWidgets('Renders all tracks, SPU delay stepper, and actions', (tester) async {
      int selectedTrack = 1;
      Duration delay = const Duration(milliseconds: 50);
      bool addSubsOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: Center(
              child: SubtitleQuickPopup(
                tracks: testTracks,
                selectedTrackId: selectedTrack,
                currentDelay: delay,
                onSelectTrack: (id) => selectedTrack = id,
                onDelayChanged: (d) => delay = d,
                onOpenAddSubtitles: () => addSubsOpened = true,
              ),
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('SUBTITLES'), findsOneWidget);

      // Verify Track options
      expect(find.text('Disable Subtitles'), findsOneWidget);
      expect(find.text('English [Full]'), findsOneWidget);
      expect(find.text('Spanish [Latin]'), findsOneWidget);
      expect(find.text('Japanese [Original]'), findsOneWidget);

      // Verify Delay display
      expect(find.text('+50 ms'), findsOneWidget);

      // Test delay stepper buttons
      await tester.tap(find.text('+50ms'));
      expect(delay.inMilliseconds, 100);

      await tester.tap(find.text('-100ms'));
      expect(delay.inMilliseconds, -50);

      await tester.tap(find.text('Reset'));
      expect(delay.inMilliseconds, 0);

      // Test switching track
      await tester.tap(find.text('Spanish [Latin]'));
      expect(selectedTrack, 2);

      // Test Add Subtitles action
      await tester.tap(find.text('Add Subtitles...'));
      expect(addSubsOpened, isTrue);
    });
  });
}
