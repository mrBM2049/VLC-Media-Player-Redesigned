import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  Widget buildTestWidget({
    required VideoAdjustState adjustState,
    ValueChanged<VideoAdjustState>? onAdjustStateChanged,
    VoidCallback? onTakeSnapshot,
  }) {
    return MaterialApp(
      theme: VlcThemeData.dark().toThemeData(),
      home: Scaffold(
        body: SizedBox(
          width: 340.0,
          child: VideoInspectorTab(
            adjustState: adjustState,
            onAdjustStateChanged: onAdjustStateChanged ?? (_) {},
            onTakeSnapshot: onTakeSnapshot,
          ),
        ),
      ),
    );
  }

  group('VideoInspectorTab Widget Tests', () {
    testWidgets('Renders aspect ratio, crop, rotation, presets, and color sliders', (tester) async {
      tester.view.physicalSize = const Size(340, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          adjustState: const VideoAdjustState(),
          onTakeSnapshot: () {},
        ),
      );

      // Check headings
      expect(find.text('ASPECT RATIO'), findsOneWidget);
      expect(find.text('CROP GEOMETRY'), findsOneWidget);
      expect(find.text('ORIENTATION & ROTATION'), findsOneWidget);
      expect(find.text('VIDEO SHADER & COLOR PRESETS'), findsOneWidget);
      expect(find.text('Color Adjustments (Fine-Tuning)'), findsOneWidget);
      expect(find.text('HARDWARE & ENGINE RENDERING'), findsOneWidget);

      // Check presets
      expect(find.text('Standard / Neutral'), findsOneWidget);
      expect(find.text('Vivid Cinema'), findsOneWidget);
      expect(find.text('Teal & Orange'), findsOneWidget);
      expect(find.text('Noir / Monochrome'), findsOneWidget);

      // Check rotation buttons
      expect(find.text('0°'), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);
      expect(find.text('180°'), findsOneWidget);
      expect(find.text('270°'), findsOneWidget);

      // Check snapshot button
      expect(find.text('Capture Video Snapshot (PNG)'), findsOneWidget);
    });

    testWidgets('Tapping rotation button fires onAdjustStateChanged with updated rotation', (tester) async {
      tester.view.physicalSize = const Size(340, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      VideoAdjustState? updated;
      await tester.pumpWidget(
        buildTestWidget(
          adjustState: const VideoAdjustState(),
          onAdjustStateChanged: (s) => updated = s,
        ),
      );

      await tester.tap(find.text('90°'));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.rotation, equals(VlcVideoRotation.rot90));
    });

    testWidgets('Tapping preset card updates active preset and color properties', (tester) async {
      tester.view.physicalSize = const Size(340, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      VideoAdjustState? updated;
      await tester.pumpWidget(
        buildTestWidget(
          adjustState: const VideoAdjustState(),
          onAdjustStateChanged: (s) => updated = s,
        ),
      );

      await tester.tap(find.text('Vivid Cinema'));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.activePresetId, equals('vivid'));
      expect(updated!.contrast, equals(1.25));
      expect(updated!.saturation, equals(1.40));
      expect(updated!.isAdjustEnabled, isTrue);
    });

    testWidgets('Tapping snapshot button triggers onTakeSnapshot callback', (tester) async {
      tester.view.physicalSize = const Size(340, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool snapshotCalled = false;
      await tester.pumpWidget(
        buildTestWidget(
          adjustState: const VideoAdjustState(),
          onTakeSnapshot: () => snapshotCalled = true,
        ),
      );

      final snapshotBtn = find.text('Capture Video Snapshot (PNG)');
      await tester.scrollUntilVisible(
        snapshotBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(snapshotBtn);
      await tester.pump();

      expect(snapshotCalled, isTrue);
    });

    testWidgets('HDR Tone-Mapping switch toggles HDR state', (tester) async {
      tester.view.physicalSize = const Size(340, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      VideoAdjustState? updated;
      await tester.pumpWidget(
        buildTestWidget(
          adjustState: const VideoAdjustState(hdrToneMapping: true),
          onAdjustStateChanged: (s) => updated = s,
        ),
      );

      final switchFinder = find.byType(Switch).first;
      await tester.scrollUntilVisible(
        switchFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(switchFinder);
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.hdrToneMapping, isFalse);
    });
  });
}
