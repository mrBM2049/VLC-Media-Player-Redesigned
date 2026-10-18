import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/popups/open_media_modal.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('OpenMediaModal Widget Tests', () {
    testWidgets('Renders Local File tab and handles path submission', (tester) async {
      String? openedMedia;
      bool closed = false;

      await tester.pumpWidget(
        buildTestApp(
          child: OpenMediaModal(
            onOpenMedia: (mrl) => openedMedia = mrl,
            onClose: () => closed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Media'), findsOneWidget);
      expect(find.text('Browse Computer (Native File Picker)...'), findsOneWidget);
      expect(find.text('Local File'), findsOneWidget);
      expect(find.text('Network Stream'), findsOneWidget);
      expect(find.text('Demo Clips'), findsOneWidget);

      // Enter manual file path and submit
      await tester.enterText(find.byType(TextField), '/movies/custom_movie.mp4');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(openedMedia, '/movies/custom_movie.mp4');
      expect(closed, isTrue);
    });

    testWidgets('Switches to Network Stream tab and submits stream URL', (tester) async {
      String? openedMedia;

      await tester.pumpWidget(
        buildTestApp(
          child: OpenMediaModal(
            onOpenMedia: (mrl) => openedMedia = mrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Network Stream
      await tester.tap(find.text('Network Stream'));
      await tester.pumpAndSettle();

      expect(find.text('Play Network Stream'), findsOneWidget);

      // Enter stream URL
      await tester.enterText(find.byType(TextField), 'https://test.stream/live.m3u8');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Network Stream'));
      await tester.pumpAndSettle();

      expect(openedMedia, 'https://test.stream/live.m3u8');
    });

    testWidgets('Switches to Demo Clips tab and selects a clip', (tester) async {
      String? openedMedia;

      await tester.pumpWidget(
        buildTestApp(
          child: OpenMediaModal(
            onOpenMedia: (mrl) => openedMedia = mrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Demo Clips
      await tester.tap(find.text('Demo Clips'));
      await tester.pumpAndSettle();

      expect(find.text('Big Buck Bunny (4K 60fps)'), findsOneWidget);
      expect(find.text('Sintel (4K HDR)'), findsOneWidget);

      // Tap first clip Play button
      final playButtons = find.text('Play');
      expect(playButtons, findsWidgets);
      await tester.tap(playButtons.first);
      await tester.pumpAndSettle();

      expect(openedMedia, contains('BigBuckBunny.mp4'));
    });
  });
}
