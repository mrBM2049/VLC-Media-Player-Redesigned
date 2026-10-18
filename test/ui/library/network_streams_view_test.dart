import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('NetworkStreamsView Tests', () {
    testWidgets('Renders header, stream cards with LIVE badges, and category pills', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: NetworkStreamsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Network Streams & IPTV'), findsOneWidget);
      expect(find.text('Import .m3u'), findsOneWidget);
      expect(find.text('Add Stream URL'), findsOneWidget);

      // Category pills
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Science & Tech'), findsOneWidget);
      expect(find.text('News'), findsOneWidget);
      expect(find.text('Sports'), findsOneWidget);

      // Verify LIVE badges and curated streams appear
      expect(find.text('LIVE'), findsWidgets);
      expect(find.text('NASA TV Live (Official)'), findsOneWidget);
      expect(find.text('Bloomberg Global Live'), findsOneWidget);
      expect(find.text('Red Bull TV Extreme Sports'), findsOneWidget);
    });

    testWidgets('Filters channels by category pill', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: NetworkStreamsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Sports' pill
      await tester.tap(find.text('Sports'));
      await tester.pumpAndSettle();

      expect(find.text('Red Bull TV Extreme Sports'), findsOneWidget);
      expect(find.text('Bloomberg Global Live'), findsNothing);
    });

    testWidgets('Filters channels via search input', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: NetworkStreamsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NASA');
      await tester.pumpAndSettle();

      expect(find.text('NASA TV Live (Official)'), findsOneWidget);
      expect(find.text('Red Bull TV Extreme Sports'), findsNothing);
    });

    testWidgets('Triggers onPlayStream and onAddToQueue callbacks on hover card', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      NetworkStreamChannel? playedChannel;
      NetworkStreamChannel? queuedChannel;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: NetworkStreamsView(
              onPlayStream: (ch) => playedChannel = ch,
              onAddToQueue: (ch) => queuedChannel = ch,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hover over NASA TV card
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('NASA TV Live (Official)')));
      await tester.pumpAndSettle();

      // Play hover button
      final playBtn = find.byIcon(Icons.play_arrow);
      expect(playBtn, findsWidgets);
      await tester.tap(playBtn.first);
      await tester.pumpAndSettle();
      expect(playedChannel?.id, equals('nasa_tv'));

      // Queue hover button
      final queueBtn = find.byIcon(Icons.playlist_add);
      expect(queueBtn, findsWidgets);
      await tester.tap(queueBtn.first);
      await tester.pumpAndSettle();
      expect(queuedChannel?.id, equals('nasa_tv'));
    });
  });
}

