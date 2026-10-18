import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/theme/theme.dart';
import 'package:vlc_modern/ui/controls/mobile_gesture_overlay.dart';

void main() {
  group('MobileGestureOverlay Tests (Task 5.4)', () {
    testWidgets('Renders child and forwards single tap event', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: MobileGestureOverlay(
              onTap: () => tapped = true,
              child: const Center(child: Text('Video Canvas Child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Video Canvas Child'), findsOneWidget);

      await tester.tap(find.text('Video Canvas Child'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Vertical swipe on right half adjusts volume and displays Volume HUD', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      double? updatedVolume;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: MobileGestureOverlay(
                volume: 1.0,
                onVolumeChanged: (v) => updatedVolume = v,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe up on right half (x = 650, y = 400 to 200)
      await tester.dragFrom(const Offset(650, 400), const Offset(0, -150));
      await tester.pump();

      expect(updatedVolume, isNotNull);
      expect(updatedVolume!, greaterThan(1.0));
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      // Drain HUD auto-hide timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });

    testWidgets('Vertical swipe on left half adjusts brightness and displays Brightness HUD', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      double? updatedBrightness;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: MobileGestureOverlay(
                brightness: 0.5,
                onBrightnessChanged: (b) => updatedBrightness = b,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe up on left half (x = 150, y = 400 to 200)
      await tester.dragFrom(const Offset(150, 400), const Offset(0, -150));
      await tester.pump();

      expect(updatedBrightness, isNotNull);
      expect(updatedBrightness!, greaterThan(0.5));
      expect(find.byIcon(Icons.brightness_6), findsOneWidget);

      // Drain HUD auto-hide timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });

    testWidgets('Double-tap on right half seeks forward +10s with ripple', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Duration? seekDelta;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: MobileGestureOverlay(
                onSeekRelative: (d) => seekDelta = d,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Double-tap on right side (x = 680, y = 300)
      await tester.tapAt(const Offset(680, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(680, 300));
      await tester.pump();

      expect(seekDelta, equals(const Duration(seconds: 10)));
      expect(find.text('+10s'), findsOneWidget);

      // Drain ripple timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });

    testWidgets('Double-tap on left half seeks backward -10s with ripple', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Duration? seekDelta;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: MobileGestureOverlay(
                onSeekRelative: (d) => seekDelta = d,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Double-tap on left side (x = 120, y = 300)
      await tester.tapAt(const Offset(120, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(120, 300));
      await tester.pump();

      expect(seekDelta, equals(const Duration(seconds: -10)));
      expect(find.text('-10s'), findsOneWidget);

      // Drain ripple timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });
  });
}
