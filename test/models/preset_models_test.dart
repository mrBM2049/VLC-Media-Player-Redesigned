import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/preset_models.dart';

void main() {
  group('PresetModels & PresetController Tests', () {
    test('ShowPresetProfile default presets verification', () {
      expect(ShowPresetProfile.defaultPresets.length, 5);
      expect(ShowPresetProfile.standard.id, 'standard');
      expect(ShowPresetProfile.anime.name, 'Anime & Asian Cinema');
      expect(ShowPresetProfile.action.name, 'Action & Blockbuster');
      expect(ShowPresetProfile.lateNight.name, 'Late Night (Quiet)');
      expect(ShowPresetProfile.podcast.name, 'Podcast & Speech');
    });

    test('PresetController default initialization', () {
      final controller = PresetController(folderName: 'TV Shows');
      expect(controller.folderName, 'TV Shows');
      expect(controller.activePreset, ShowPresetProfile.standard);
      expect(controller.applyToAllFolderEpisodes, isTrue);
      expect(controller.presets.length, 5);
      controller.dispose();
    });

    test('PresetController selectPreset and setApplyToFolder', () {
      final controller = PresetController();
      bool notified = false;
      controller.addListener(() => notified = true);

      controller.selectPreset(ShowPresetProfile.anime);
      expect(controller.activePreset, ShowPresetProfile.anime);
      expect(notified, isTrue);

      notified = false;
      controller.setApplyToFolder(false);
      expect(controller.applyToAllFolderEpisodes, isFalse);
      expect(notified, isTrue);

      controller.dispose();
    });

    test('PresetController save and delete custom preset', () {
      final controller = PresetController();
      expect(controller.presets.length, 5);

      controller.saveCustomPreset('My Sci-Fi Preset', 'Custom EQ and Subs');
      expect(controller.presets.length, 6);
      expect(controller.activePreset.name, 'My Sci-Fi Preset');
      expect(controller.activePreset.isCustom, isTrue);

      final customId = controller.activePreset.id;
      controller.deleteCustomPreset(customId);
      expect(controller.presets.length, 5);
      expect(controller.activePreset, ShowPresetProfile.standard);

      controller.dispose();
    });
  });
}
