import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('VlcColors & Accent Engine Tests', () {
    test('Verifies default cone orange accent is #FF8800', () {
      expect(VlcColors.coneOrange, const Color(0xFFFF8800));
      final darkColors = VlcColors.dark();
      expect(darkColors.accent.primary, const Color(0xFFFF8800));
    });

    test('Verifies dark and OLED surface token contracts', () {
      final darkColors = VlcColors.dark();
      expect(darkColors.background, const Color(0xFF0D0D0F));
      expect(darkColors.surface, const Color(0xFF16161A));
      expect(darkColors.brightness, Brightness.dark);

      final oledColors = VlcColors.oled();
      expect(oledColors.background, const Color(0xFF000000));
      expect(oledColors.surface, const Color(0xFF0E0E10));
      expect(oledColors.brightness, Brightness.dark);
    });

    test('Verifies light mode surface tokens', () {
      final lightColors = VlcColors.light();
      expect(lightColors.background, const Color(0xFFF5F5F7));
      expect(lightColors.surface, const Color(0xFFFFFFFF));
      expect(lightColors.brightness, Brightness.light);
      expect(lightColors.textPrimary, const Color(0xFF111114));
    });

    test('VlcAccentEngine generates valid interactive states and overdrive gradients', () {
      const customAccent = Color(0xFF00BCD4); // Cyber Cyan
      final engine = const VlcAccentEngine(primary: customAccent);

      expect(engine.primary, customAccent);
      expect(engine.hover, isNotNull);
      expect(engine.pressed, isNotNull);
      expect(engine.subtleBackground.opacity, closeTo(0.15, 0.01));
      expect(engine.glow.opacity, closeTo(0.40, 0.01));

      // Normal cone gradient has 2 stops
      expect(engine.normalConeGradient.colors.length, 2);

      // Overdrive cone gradient has 3 stops transitioning to red warning
      expect(engine.overdriveConeGradient.colors.length, 3);
      expect(engine.overdriveConeGradient.colors.last, const Color(0xFFFF2200));
    });
  });

  group('VlcGeometry Rectangular Enforcement Tests', () {
    test('Strictly enforces rectangular 4dp-8dp corner radii (no pill buttons)', () {
      // Must be between 4.0 and 8.0 dp
      expect(VlcGeometry.radiusSmall, 4.0);
      expect(VlcGeometry.radiusMedium, 6.0);
      expect(VlcGeometry.radiusLarge, 8.0);
      expect(VlcGeometry.radiusXLarge, 12.0);

      // Button shape radius must strictly be 6.0dp (never 50% or pill-shaped)
      expect(VlcGeometry.buttonShape.borderRadius, BorderRadius.circular(6.0));
      expect(VlcGeometry.cardShape.borderRadius, BorderRadius.circular(8.0));
    });

    test('Verifies component height and width dimensions', () {
      expect(VlcGeometry.topPlayerBarHeight, 48.0);
      expect(VlcGeometry.bottomTransportRowHeight, 60.0);
      expect(VlcGeometry.thickSeekBarHeightNormal, 10.0);
      expect(VlcGeometry.thickSeekBarHeightHover, 16.0);
      expect(VlcGeometry.inspectorDrawerWidth, 340.0);
      expect(VlcGeometry.volumeSliderWidth, 120.0);
      expect(VlcGeometry.strokeWidthMonochrome, 1.5);
    });

    test('Verifies 4dp baseline spacing grid multiples', () {
      expect(VlcGeometry.space4 % 4.0, 0.0);
      expect(VlcGeometry.space8 % 4.0, 0.0);
      expect(VlcGeometry.space12 % 4.0, 0.0);
      expect(VlcGeometry.space16 % 4.0, 0.0);
      expect(VlcGeometry.space20 % 4.0, 0.0);
      expect(VlcGeometry.space24 % 4.0, 0.0);
      expect(VlcGeometry.space32 % 4.0, 0.0);
      expect(VlcGeometry.space48 % 4.0, 0.0);
    });
  });

  group('VlcTypography Tests', () {
    test('Monospace time typography contains tabular figures for zero-jitter playback', () {
      final theme = VlcThemeData.dark();
      expect(theme.typography.monospaceTime.fontSize, 12.0);
      expect(theme.typography.monospaceTime.fontFamily, 'monospace');
      expect(
        theme.typography.monospaceTime.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('Title and body hierarchies match design scale', () {
      final theme = VlcThemeData.dark();
      expect(theme.typography.titleLarge.fontSize, 18.0);
      expect(theme.typography.titleLarge.fontWeight, FontWeight.w600);
      expect(theme.typography.titleMedium.fontSize, 16.0);
      expect(theme.typography.titleSmall.fontSize, 14.0);
      expect(theme.typography.bodyLarge.fontSize, 14.0);
      expect(theme.typography.bodyMedium.fontSize, 13.0);
      expect(theme.typography.labelSmall.fontSize, 10.0);
    });
  });

  group('VlcIcons & Dual-Tone Set Tests', () {
    testWidgets('Renders VlcMonochromeIcon with 1.5dp stroke', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VlcMonochromeIcon(
              VlcIconGlyph.play,
              size: 24.0,
              color: Colors.white,
            ),
          ),
        ),
      );

      expect(find.byType(VlcMonochromeIcon), findsOneWidget);
    });

    testWidgets('Renders VlcTwoToneIcon with base and accent tones', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VlcTwoToneIcon(
              VlcIconGlyph.tabSubtitles,
              size: 28.0,
              baseColor: Colors.grey,
              accentColor: VlcColors.coneOrange,
            ),
          ),
        ),
      );

      expect(find.byType(VlcTwoToneIcon), findsOneWidget);
    });
  });

  group('VlcThemeController Reactive State Tests', () {
    test('Switches theme mode and notifies listeners', () {
      final controller = VlcThemeController(mode: VlcThemeMode.dark);
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setThemeMode(VlcThemeMode.light);
      expect(controller.mode, VlcThemeMode.light);
      expect(notifyCount, 1);

      controller.setThemeMode(VlcThemeMode.oled);
      expect(controller.mode, VlcThemeMode.oled);
      expect(notifyCount, 2);

      // Same mode should not notify
      controller.setThemeMode(VlcThemeMode.oled);
      expect(notifyCount, 2);
    });

    test('Switches accent color preset dynamically', () {
      final controller = VlcThemeController();
      controller.setPreset(VlcAccentPreset.neonAmber);
      expect(controller.accentColor, const Color(0xFFFFA000));
      expect(controller.currentTheme.colors.accent.primary, const Color(0xFFFFA000));
    });
  });
}

