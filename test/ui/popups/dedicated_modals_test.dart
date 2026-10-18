import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('Dedicated Modals Tests (Task 4.6)', () {
    testWidgets('StreamModal handles URL entry, buffer selection, and opens stream', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? openedUrl;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: StreamModal(
              onOpenStream: (url) => openedUrl = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Network Stream'), findsOneWidget);
      expect(find.text('Low Latency (300ms)'), findsOneWidget);
      expect(find.text('Standard (1200ms)'), findsOneWidget);
      expect(find.text('High Reliability (5000ms)'), findsOneWidget);

      // Enter stream URL
      await tester.enterText(find.byType(TextField), 'https://live.example.com/hls.m3u8');
      await tester.pumpAndSettle();

      // Switch buffer preset
      await tester.tap(find.text('Low Latency (300ms)'));
      await tester.pumpAndSettle();

      // Tap Play Stream button
      await tester.tap(find.text('Play Stream'));
      await tester.pumpAndSettle();

      expect(openedUrl, equals('https://live.example.com/hls.m3u8'));
    });

    testWidgets('CaptureDeviceModal renders devices and invokes onOpenCapture', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? chosenVideo;
      String? chosenAudio;
      String? chosenRes;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: CaptureDeviceModal(
              onOpenCapture: (v, a, r) {
                chosenVideo = v;
                chosenAudio = a;
                chosenRes = r;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Capture Device'), findsOneWidget);
      expect(find.text('FaceTime HD Camera'), findsOneWidget);
      expect(find.text('Built-in Microphone (CoreAudio)'), findsOneWidget);
      expect(find.text('1920x1080 @ 60 FPS'), findsOneWidget);

      // Tap Open Device
      await tester.tap(find.text('Open Device'));
      await tester.pumpAndSettle();

      expect(chosenVideo, equals('FaceTime HD Camera'));
      expect(chosenAudio, equals('Built-in Microphone (CoreAudio)'));
      expect(chosenRes, equals('1920x1080 @ 60 FPS'));
    });

    testWidgets('ConvertModal validates inputs and triggers conversion lifecycle', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? srcPath;
      String? profile;
      String? dstPath;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: ConvertModal(
              onStartConvert: (s, p, d) {
                srcPath = s;
                profile = p;
                dstPath = d;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Convert & Save Media'), findsOneWidget);
      expect(find.text('Video - H.264 + AAC (MP4)'), findsOneWidget);

      // Enter source & destination paths directly into the two textfields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), '/Users/Movies/raw_source.mkv');
      await tester.enterText(textFields.at(1), '/Users/Movies/output.mp4');
      await tester.pumpAndSettle();

      // Tap deinterlace checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Tap Start Conversion
      await tester.tap(find.text('Start Conversion'));
      await tester.pump(); // Advance first frame
      await tester.pump(const Duration(milliseconds: 350)); // Advance progress frame

      expect(srcPath, equals('/Users/Movies/raw_source.mkv'));
      expect(profile, equals('Video - H.264 + AAC (MP4)'));
      expect(dstPath, equals('/Users/Movies/output.mp4'));

      // Wait for simulated finish
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    });

    testWidgets('CastModal renders devices and toggles wireless connection state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      CastDevice? connectedDevice;
      bool disconnected = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: CastModal(
              onConnectDevice: (d) => connectedDevice = d,
              onDisconnect: () => disconnected = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cast to Wireless Display / Renderer'), findsOneWidget);
      expect(find.text('Living Room TV'), findsOneWidget);
      expect(find.text('Bedroom Apple TV'), findsOneWidget);
      expect(find.text('Studio Hi-Fi Receiver'), findsOneWidget);

      // Connect to Living Room TV
      final connectButtons = find.text('Connect');
      expect(connectButtons, findsNWidgets(3));
      await tester.tap(connectButtons.first);
      await tester.pumpAndSettle();

      expect(connectedDevice?.id, equals('chromecast_living_room'));
      expect(find.text('Disconnect'), findsOneWidget);

      // Disconnect from Living Room TV
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(disconnected, isTrue);
    });
  });
}

