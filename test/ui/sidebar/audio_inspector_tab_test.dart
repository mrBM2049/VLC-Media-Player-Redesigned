import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  final testTracks = [
    const VlcAudioTrack(id: 1, name: 'Track 1: English (5.1 DTS)', language: 'en', codec: 'DTS 5.1', channels: 6),
    const VlcAudioTrack(id: 2, name: 'Track 2: Commentary', language: 'en', codec: 'AAC Stereo', channels: 2),
  ];

  final testDevices = [
    const VlcAudioOutputDevice(id: 'built_in', name: 'MacBook Air Speakers', type: VlcAudioDeviceType.speakers),
    const VlcAudioOutputDevice(id: 'airpods', name: 'AirPods Max', type: VlcAudioDeviceType.bluetooth),
  ];

  Widget buildTestWidget({
    required int selectedTrackId,
    required String selectedDeviceId,
    required Duration currentDelay,
    required AudioFilterState filterState,
    ValueChanged<int>? onSelectTrack,
    ValueChanged<String>? onSelectDevice,
    ValueChanged<Duration>? onDelayChanged,
    ValueChanged<AudioFilterState>? onFilterStateChanged,
  }) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
        body: SizedBox(
          width: 340.0,
          child: AudioInspectorTab(
            tracks: testTracks,
            selectedTrackId: selectedTrackId,
            devices: testDevices,
            selectedDeviceId: selectedDeviceId,
            currentDelay: currentDelay,
            filterState: filterState,
            onSelectTrack: onSelectTrack ?? (_) {},
            onSelectDevice: onSelectDevice ?? (_) {},
            onDelayChanged: onDelayChanged ?? (_) {},
            onFilterStateChanged: onFilterStateChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('AudioInspectorTab Widget Tests', () {
    testWidgets('Renders tracks, devices, delay, preamp, preset cards, and 10 bands', (tester) async {
      tester.view.physicalSize = const Size(340, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          selectedTrackId: 1,
          selectedDeviceId: 'built_in',
          currentDelay: Duration.zero,
          filterState: const AudioFilterState(),
        ),
      );

      // Verify sections
      expect(find.text('AUDIO TRACK'), findsOneWidget);
      expect(find.text('OUTPUT DEVICE'), findsOneWidget);
      expect(find.text('AUDIO SYNC (DELAY)'), findsOneWidget);
      expect(find.text('0.0 s (In Sync)'), findsOneWidget);
      expect(find.text('10-Band Graphic Equalizer'), findsOneWidget);
      expect(find.text('PREAMP GAIN'), findsOneWidget);
      expect(find.text('AUDIO FILTER PRESETS'), findsOneWidget);

      // Verify preset cards
      expect(find.text('Flat (Neutral)'), findsOneWidget);
      expect(find.text('Bass Boost'), findsOneWidget);
      expect(find.text('Vocal Clarity'), findsOneWidget);

      // Verify frequency slider section
      expect(find.text('10-Band Frequency Sliders (ISO)'), findsOneWidget);
      expect(find.text('60Hz'), findsOneWidget);
      expect(find.text('1kHz'), findsOneWidget);
      expect(find.text('16kHz'), findsOneWidget);

      // Verify Spatial Audio section
      expect(find.text('SPATIAL & DYNAMIC ENHANCEMENTS'), findsOneWidget);
      expect(find.text('Spatial Audio Virtualizer'), findsOneWidget);
    });

    testWidgets('Selecting a preset card updates AudioFilterState', (tester) async {
      tester.view.physicalSize = const Size(340, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AudioFilterState? updatedState;
      await tester.pumpWidget(
        buildTestWidget(
          selectedTrackId: 1,
          selectedDeviceId: 'built_in',
          currentDelay: Duration.zero,
          filterState: const AudioFilterState(),
          onFilterStateChanged: (s) => updatedState = s,
        ),
      );

      // Tap 'Bass Boost' card
      await tester.tap(find.text('Bass Boost'));
      await tester.pump();

      expect(updatedState, isNotNull);
      expect(updatedState!.activePresetId, equals('bass_boost'));
      expect(updatedState!.preamp, equals(2.0));
      expect(updatedState!.bands[0], equals(7.0));
    });

    testWidgets('Tapping delay stepper buttons triggers onDelayChanged', (tester) async {
      tester.view.physicalSize = const Size(340, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Duration? newDelay;
      await tester.pumpWidget(
        buildTestWidget(
          selectedTrackId: 1,
          selectedDeviceId: 'built_in',
          currentDelay: Duration.zero,
          filterState: const AudioFilterState(),
          onDelayChanged: (d) => newDelay = d,
        ),
      );

      // Tap +50ms
      await tester.tap(find.text('+50ms'));
      await tester.pump();
      expect(newDelay, equals(const Duration(milliseconds: 50)));

      // Tap -500ms
      await tester.tap(find.text('-500ms'));
      await tester.pump();
      expect(newDelay, equals(const Duration(milliseconds: -500)));
    });

    testWidgets('Toggling spatial audio switch updates state', (tester) async {
      tester.view.physicalSize = const Size(340, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AudioFilterState? updated;
      await tester.pumpWidget(
        buildTestWidget(
          selectedTrackId: 1,
          selectedDeviceId: 'built_in',
          currentDelay: Duration.zero,
          filterState: const AudioFilterState(spatialAudio: false),
          onFilterStateChanged: (s) => updated = s,
        ),
      );

      final switches = find.byType(Switch);
      // EQ is switch 0, Spatial is switch 1, Loudness is switch 2
      await tester.tap(switches.at(1));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.spatialAudio, isTrue);
    });
  });
}

