import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('Video Models & Adjustment Tests', () {
    test('VlcAspectRatio enum has expected presets and ratio strings', () {
      expect(VlcAspectRatio.values.length, equals(8));
      expect(VlcAspectRatio.original.ratioString, isNull);
      expect(VlcAspectRatio.r16_9.ratioString, equals('16:9'));
      expect(VlcAspectRatio.r4_3.ratioString, equals('4:3'));
      expect(VlcAspectRatio.r21_9.ratioString, equals('21:9'));
      expect(VlcAspectRatio.fitScreen.ratioString, equals('fit'));
      expect(VlcAspectRatio.fillScreen.ratioString, equals('fill'));
    });

    test('VlcCropGeometry enum has expected crops', () {
      expect(VlcCropGeometry.values.length, equals(8));
      expect(VlcCropGeometry.none.cropString, isNull);
      expect(VlcCropGeometry.c16_9.cropString, equals('16:9'));
      expect(VlcCropGeometry.c2_39.cropString, equals('2.39:1'));
    });

    test('VlcVideoRotation enum has 4 cardinal orientations', () {
      expect(VlcVideoRotation.values.length, equals(4));
      expect(VlcVideoRotation.rot0.degrees, equals(0));
      expect(VlcVideoRotation.rot90.degrees, equals(90));
      expect(VlcVideoRotation.rot180.degrees, equals(180));
      expect(VlcVideoRotation.rot270.degrees, equals(270));
    });

    test('VlcDeinterlaceMode enum has correct options', () {
      expect(VlcDeinterlaceMode.values.length, equals(6));
      expect(VlcDeinterlaceMode.off.label, equals('Off'));
      expect(VlcDeinterlaceMode.auto.label, equals('Automatic'));
      expect(VlcDeinterlaceMode.yadif.label, equals('Yadif (2x)'));
    });

    test('VideoFilterPreset standard presets include all 6 visual grades', () {
      final presets = VideoFilterPreset.standardPresets;
      expect(presets.length, equals(6));

      final standard = VideoFilterPreset.standard;
      expect(standard.brightness, equals(1.0));
      expect(standard.contrast, equals(1.0));
      expect(standard.saturation, equals(1.0));
      expect(standard.gamma, equals(1.0));

      final vivid = VideoFilterPreset.vivid;
      expect(vivid.contrast, equals(1.25));
      expect(vivid.saturation, equals(1.40));

      final noir = VideoFilterPreset.noir;
      expect(noir.saturation, equals(0.0));
      expect(noir.contrast, equals(1.40));

      final cinematic = VideoFilterPreset.cinematic;
      expect(cinematic.hue, equals(-12.0));
    });

    test('VideoAdjustState defaults and copyWith behave predictably', () {
      const state = VideoAdjustState();
      expect(state.aspectRatio, equals(VlcAspectRatio.original));
      expect(state.cropGeometry, equals(VlcCropGeometry.none));
      expect(state.rotation, equals(VlcVideoRotation.rot0));
      expect(state.deinterlaceMode, equals(VlcDeinterlaceMode.auto));
      expect(state.brightness, equals(1.0));
      expect(state.contrast, equals(1.0));
      expect(state.saturation, equals(1.0));
      expect(state.gamma, equals(1.0));
      expect(state.hue, equals(0.0));
      expect(state.isAdjustEnabled, isFalse);
      expect(state.hdrToneMapping, isTrue);
      expect(state.hardwareAcceleration, isTrue);

      final modified = state.copyWith(
        aspectRatio: VlcAspectRatio.r16_9,
        rotation: VlcVideoRotation.rot90,
        brightness: 1.2,
        isAdjustEnabled: true,
        hdrToneMapping: false,
      );

      expect(modified.aspectRatio, equals(VlcAspectRatio.r16_9));
      expect(modified.rotation, equals(VlcVideoRotation.rot90));
      expect(modified.brightness, equals(1.2));
      expect(modified.isAdjustEnabled, isTrue);
      expect(modified.hdrToneMapping, isFalse);
      expect(modified.contrast, equals(1.0)); // unchanged
    });
  });
}
