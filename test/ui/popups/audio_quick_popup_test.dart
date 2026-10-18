import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/audio_models.dart';
import 'package:vlc_modern/theme/vlc_theme.dart';
import 'package:vlc_modern/ui/popups/audio_quick_popup.dart';

void main() {
  group('AudioQuickPopup Widget Tests', () {
    const testTracks = [
      VlcAudioTrack(id: 1, name: 'English (5.1 DTS-HD)', language: 'en', codec: 'DTS 5.1'),
      VlcAudioTrack(id: 2, name: 'Spanish (Stereo)', language: 'es', codec: 'AAC'),
    ];

    const testDevices = [
      VlcAudioOutputDevice(id: 'built_in', name: 'Built-in MacBook Speakers', type: VlcAudioDeviceType.speakers),
      VlcAudioOutputDevice(id: 'airpods', name: 'AirPods Max', type: VlcAudioDeviceType.bluetooth),
      VlcAudioOutputDevice(id: 'hdmi', name: 'LG 4K Display Audio', type: VlcAudioDeviceType.hdmi),
    ];

    testWidgets('Renders tracks, hardware output devices, delay stepper and handles callbacks', (tester) async {
      int selectedTrack = 1;
      String selectedDevice = 'built_in';
      Duration audioDelay = const Duration(milliseconds: 100);
      bool equalizerOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: AudioQuickPopup(
                    tracks: testTracks,
                    selectedTrackId: selectedTrack,
                    devices: testDevices,
                    selectedDeviceId: selectedDevice,
                    currentDelay: audioDelay,
                    onSelectTrack: (id) => setState(() => selectedTrack = id),
                    onSelectDevice: (devId) => setState(() => selectedDevice = devId),
                    onDelayChanged: (d) => setState(() => audioDelay = d),
                    onOpenEqualizer: () => equalizerOpened = true,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('AUDIO & OUTPUT'), findsOneWidget);

      // Verify Track options
      expect(find.text('Disable Audio'), findsOneWidget);
      expect(find.text('English (5.1 DTS-HD)'), findsOneWidget);
      expect(find.text('Spanish (Stereo)'), findsOneWidget);

      // Verify Hardware output devices
      expect(find.text('Built-in MacBook Speakers'), findsOneWidget);
      expect(find.text('AirPods Max'), findsOneWidget);
      expect(find.text('LG 4K Display Audio'), findsOneWidget);

      // Verify initial audio delay readout
      expect(find.text('+100 ms'), findsOneWidget);

      // Test switching track
      await tester.tap(find.text('Spanish (Stereo)'));
      await tester.pump();
      expect(selectedTrack, 2);

      // Test switching hardware output device
      await tester.tap(find.text('AirPods Max'));
      await tester.pump();
      expect(selectedDevice, 'airpods');

      // Test delay stepper buttons
      // Initial 100ms -> +50ms = 150ms
      await tester.tap(find.text('+50ms'));
      await tester.pump();
      expect(audioDelay.inMilliseconds, 150);

      // 150ms -> -100ms = 50ms
      await tester.tap(find.text('-100ms'));
      await tester.pump();
      expect(audioDelay.inMilliseconds, 50);

      // 50ms -> -50ms = 0ms
      await tester.tap(find.text('-50ms'));
      await tester.pump();
      expect(audioDelay.inMilliseconds, 0);

      // 0ms -> -50ms = -50ms
      await tester.tap(find.text('-50ms'));
      await tester.pump();
      expect(audioDelay.inMilliseconds, -50);

      // -50ms -> Reset = 0ms
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(audioDelay.inMilliseconds, 0);

      // Test Equalizer button
      await tester.tap(find.text('10-Band Equalizer & Effects...'));
      expect(equalizerOpened, isTrue);
    });
  });
}

