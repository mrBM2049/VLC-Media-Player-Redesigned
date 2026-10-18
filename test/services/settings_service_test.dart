import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/services/settings_service.dart';
import 'package:vlc_modern/theme/theme.dart';

void main() {
  group('SettingsService Tests across 12 Categories (Task 5.1)', () {
    late SettingsService service;

    setUp(() {
      service = SettingsService();
      service.resetToDefaults();
    });

    test('Initializes with default values across all 12 categories', () {
      // 1. Interface
      expect(service.themeMode, equals(VlcThemeMode.dark));
      expect(service.accentColor, equals(VlcColors.coneOrange));
      expect(service.showOsdPill, isTrue);
      expect(service.autoHideControlsDelaySeconds, equals(1.8));

      // 2. Audio
      expect(service.audioOutputModule, equals('Automatic'));
      expect(service.coneVolumeLimit, equals(200.0));
      expect(service.volumeStep, equals(5.0));

      // 3. Video
      expect(service.hardwareDecoding, equals('Automatic'));
      expect(service.deinterlaceMode, equals('Auto'));
      expect(service.zeroCopyGpuTextures, isTrue);

      // 4. Subtitles
      expect(service.defaultSubtitleLanguage, equals('English'));
      expect(service.subtitleFontSize, equals(24.0));
      expect(service.autoDownloadSubtitles, isTrue);

      // 5. Input
      expect(service.networkCachingMs, equals(1200));
      expect(service.fileCachingMs, equals(1000));

      // 6. Performance
      expect(service.threadPoolCount, equals(0));
      expect(service.memoryCacheLimitMb, equals(512));

      // 7. Network
      expect(service.enableUpnpDiscovery, isTrue);
      expect(service.rtspOverTcp, isTrue);

      // 8. Playback
      expect(service.autoPlayNextItem, isTrue);
      expect(service.pauseOnMinimize, isFalse);
      expect(service.watchedResumeThresholdPercent, equals(90));

      // 9. Media Library
      expect(service.autoScanLibraryOnStartup, isTrue);
      expect(service.watchLibraryFoldersLive, isTrue);

      // 10. Hotkeys
      expect(service.globalMediaKeysEnabled, isTrue);
      expect(service.mouseWheelAction, equals('Volume Control'));

      // 11. Privacy
      expect(service.saveRecentlyPlayedMedia, isTrue);
      expect(service.anonymousTelemetry, isFalse);

      // 12. Advanced Engine
      expect(service.logVerbosityLevel, equals('Warning'));
      expect(service.customLibVlcLaunchArgs, contains('--no-video-title-show'));
    });

    test('Notifies listeners when settings are modified', () {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      service.setThemeMode(VlcThemeMode.oled);
      expect(service.themeMode, equals(VlcThemeMode.oled));
      expect(notifyCount, equals(1));

      service.setHardwareDecoding('VideoToolbox');
      expect(service.hardwareDecoding, equals('VideoToolbox'));
      expect(notifyCount, equals(2));

      service.setNetworkCachingMs(3000);
      expect(service.networkCachingMs, equals(3000));
      expect(notifyCount, equals(3));

      service.setConeVolumeLimit(150.0);
      expect(service.coneVolumeLimit, equals(150.0));
      expect(notifyCount, equals(4));
    });

    test('resetToDefaults restores altered settings back to initial state', () {
      service.setThemeMode(VlcThemeMode.light);
      service.setHardwareDecoding('Disabled');
      service.setNetworkCachingMs(300);
      service.setWatchedResumeThresholdPercent(80);

      expect(service.themeMode, equals(VlcThemeMode.light));
      expect(service.hardwareDecoding, equals('Disabled'));
      expect(service.networkCachingMs, equals(300));
      expect(service.watchedResumeThresholdPercent, equals(80));

      service.resetToDefaults();

      expect(service.themeMode, equals(VlcThemeMode.dark));
      expect(service.hardwareDecoding, equals('Automatic'));
      expect(service.networkCachingMs, equals(1200));
      expect(service.watchedResumeThresholdPercent, equals(90));
    });

    test('Search returns matching catalog items by title, description, or libvlcFlag', () {
      // Empty search returns all catalog items
      final all = service.search('');
      expect(all.length, equals(SettingsService.catalog.length));

      // Search by keyword "hardware"
      final hw = service.search('hardware');
      expect(hw.any((m) => m.key == 'hardware_decoding'), isTrue);

      // Search by libvlc flag "--network-caching"
      final flagResults = service.search('--network-caching');
      expect(flagResults, isNotEmpty);
      expect(flagResults.first.key, equals('network_caching'));

      // Search by category label "Subtitles"
      final subResults = service.search('subtitles');
      expect(subResults.any((m) => m.category == SettingsCategory.subtitlesOsd), isTrue);
    });
  });
}
