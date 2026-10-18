import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('Audio Models & Equalizer Tests', () {
    test('Standard 10 bands match ISO frequency scale', () {
      final bands = AudioEqualizerBand.standardBands;
      expect(bands.length, equals(10));
      expect(bands[0].frequencyHz, equals(60.0));
      expect(bands[0].label, equals('60 Hz'));
      expect(bands[4].frequencyHz, equals(1000.0));
      expect(bands[4].label, equals('1 kHz'));
      expect(bands[9].frequencyHz, equals(16000.0));
      expect(bands[9].label, equals('16 kHz'));
    });

    test('Standard Equalizer Presets contain exactly 10 bands', () {
      final presets = AudioEqualizerPreset.standardPresets;
      expect(presets.length, equals(6));

      for (final p in presets) {
        expect(p.bands.length, equals(10));
      }

      final flat = AudioEqualizerPreset.flat;
      expect(flat.bands.every((amp) => amp == 0.0), isTrue);

      final bass = AudioEqualizerPreset.bassBoost;
      expect(bass.bands[0], equals(7.0)); // 60Hz boosted by 7dB
      expect(bass.preamp, equals(2.0));

      final vocal = AudioEqualizerPreset.vocalClarity;
      expect(vocal.bands[4], equals(5.0)); // 1kHz dialogue boost
      expect(vocal.bands[5], equals(5.5)); // 3kHz dialogue boost
    });

    test('AudioFilterState defaults and copyWith operate reliably', () {
      const state = AudioFilterState();
      expect(state.isEqEnabled, isTrue);
      expect(state.preamp, equals(0.0));
      expect(state.bands.length, equals(10));
      expect(state.spatialAudio, isFalse);
      expect(state.loudnessNormalization, isFalse);

      final modified = state.copyWith(
        preamp: 3.5,
        spatialAudio: true,
        activePresetId: 'bass_boost',
      );

      expect(modified.preamp, equals(3.5));
      expect(modified.spatialAudio, isTrue);
      expect(modified.activePresetId, equals('bass_boost'));
      expect(modified.isEqEnabled, isTrue);
    });
  });
}
