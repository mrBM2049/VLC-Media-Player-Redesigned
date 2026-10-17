import 'package:flutter/material.dart';

/// Predefined accent colors available in VLC Modern Redesign
enum VlcAccentPreset {
  coneOrange('Cone Orange', Color(0xFFFF8800)),
  neonAmber('Neon Amber', Color(0xFFFFA000)),
  flameRed('Flame Red', Color(0xFFFF5722)),
  cyberCyan('Cyber Cyan', Color(0xFF00BCD4)),
  matrixGreen('Matrix Green', Color(0xFF4CAF50)),
  vlcClassic('Classic Gold', Color(0xFFFF9800));

  final String label;
  final Color color;
  const VlcAccentPreset(this.label, this.color);
}

/// Dynamic Accent Color Engine generating harmonious interactive shades,
/// glows, and cone overdrive gradients from any base accent color.
class VlcAccentEngine {
  final Color primary;

  const VlcAccentEngine({this.primary = const Color(0xFFFF8800)});

  /// Slightly illuminated tint for hover states (+15% brightness)
  Color get hover {
    final hsl = HSLColor.fromColor(primary);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }

  /// Deepened rich tint for pressed/active states
  Color get pressed {
    final hsl = HSLColor.fromColor(primary);
    return hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
  }

  /// 15% opacity subtle background tint for tags, badges, and selection highlights
  Color get subtleBackground => primary.withOpacity(0.15);

  /// 25% opacity border highlight
  Color get subtleBorder => primary.withOpacity(0.25);

  /// 40% opacity luminous glow for seekbar scrubbers and active tab indicators
  Color get glow => primary.withOpacity(0.40);

  /// 60% opacity secondary highlight
  Color get semiTransparent => primary.withOpacity(0.60);

  /// Gradient for Cone volume slider (0% to 100% normal range)
  LinearGradient get normalConeGradient => LinearGradient(
        colors: [
          primary.withOpacity(0.85),
          primary,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  /// Gradient for Cone volume overdrive slider (100% to 200% boost range)
  /// Transitions from primary accent to hot warning orange/red
  LinearGradient get overdriveConeGradient => LinearGradient(
        colors: [
          primary,
          const Color(0xFFFF5500),
          const Color(0xFFFF2200),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  VlcAccentEngine copyWith({Color? primary}) {
    return VlcAccentEngine(primary: primary ?? this.primary);
  }

  static VlcAccentEngine lerp(VlcAccentEngine a, VlcAccentEngine b, double t) {
    return VlcAccentEngine(
      primary: Color.lerp(a.primary, b.primary, t) ?? a.primary,
    );
  }
}

/// Comprehensive color palette tokens for Dark, OLED, and Light themes.
/// Figma File: TKMz3UlzGRDOxFHHXq4Bln
class VlcColors {
  // Official signature cone color
  static const Color coneOrange = Color(0xFFFF8800);

  // --- Dark Surface Tokens (Default) ---
  static const Color darkBackground = Color(0xFF0D0D0F);
  static const Color darkSurface = Color(0xFF16161A);
  static const Color darkSurfaceVariant = Color(0xFF1C1C22);
  static const Color darkSurfaceHover = Color(0xFF23232A);
  static const Color darkBorder = Color(0xFF2A2A33);
  static const Color darkBorderSubtle = Color(0xFF1E1E26);

  // --- OLED Surface Tokens (Pure Black) ---
  static const Color oledBackground = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0E0E10);
  static const Color oledSurfaceVariant = Color(0xFF141418);
  static const Color oledSurfaceHover = Color(0xFF1B1B20);
  static const Color oledBorder = Color(0xFF24242C);
  static const Color oledBorderSubtle = Color(0xFF18181F);

  // --- Light Surface Tokens ---
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEBEBF0);
  static const Color lightSurfaceHover = Color(0xFFE2E2E8);
  static const Color lightBorder = Color(0xFFD1D1D6);
  static const Color lightBorderSubtle = Color(0xFFE5E5EA);

  // --- Typography / Content Foreground Tokens ---
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color darkTextTertiary = Color(0x73FFFFFF);  // 45% white
  static const Color darkTextDisabled = Color(0x33FFFFFF);  // 20% white

  static const Color lightTextPrimary = Color(0xFF111114);
  static const Color lightTextSecondary = Color(0xB3111114); // 70%
  static const Color lightTextTertiary = Color(0x73111114);  // 45%
  static const Color lightTextDisabled = Color(0x33111114);  // 20%

  // --- Semantic & Status Colors ---
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFCC00);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF0A84FF);

  // --- Overlays & Glassmorphism ---
  static const Color darkScrim = Color(0xA6000000);      // 65% black
  static const Color darkGlassBackdrop = Color(0xBF16161A); // 75% darkSurface
  static const Color lightGlassBackdrop = Color(0xD9FFFFFF); // 85% white
  static const Color transparent = Colors.transparent;

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceHover;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color glassBackdrop;
  final VlcAccentEngine accent;

  const VlcColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceHover,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.glassBackdrop,
    this.accent = const VlcAccentEngine(),
  });

  factory VlcColors.dark({Color accentColor = coneOrange}) {
    return VlcColors(
      brightness: Brightness.dark,
      background: darkBackground,
      surface: darkSurface,
      surfaceVariant: darkSurfaceVariant,
      surfaceHover: darkSurfaceHover,
      border: darkBorder,
      borderSubtle: darkBorderSubtle,
      textPrimary: darkTextPrimary,
      textSecondary: darkTextSecondary,
      textTertiary: darkTextTertiary,
      textDisabled: darkTextDisabled,
      glassBackdrop: darkGlassBackdrop,
      accent: VlcAccentEngine(primary: accentColor),
    );
  }

  factory VlcColors.oled({Color accentColor = coneOrange}) {
    return VlcColors(
      brightness: Brightness.dark,
      background: oledBackground,
      surface: oledSurface,
      surfaceVariant: oledSurfaceVariant,
      surfaceHover: oledSurfaceHover,
      border: oledBorder,
      borderSubtle: oledBorderSubtle,
      textPrimary: darkTextPrimary,
      textSecondary: darkTextSecondary,
      textTertiary: darkTextTertiary,
      textDisabled: darkTextDisabled,
      glassBackdrop: const Color(0xE60E0E10),
      accent: VlcAccentEngine(primary: accentColor),
    );
  }

  factory VlcColors.light({Color accentColor = coneOrange}) {
    return VlcColors(
      brightness: Brightness.light,
      background: lightBackground,
      surface: lightSurface,
      surfaceVariant: lightSurfaceVariant,
      surfaceHover: lightSurfaceHover,
      border: lightBorder,
      borderSubtle: lightBorderSubtle,
      textPrimary: lightTextPrimary,
      textSecondary: lightTextSecondary,
      textTertiary: lightTextTertiary,
      textDisabled: lightTextDisabled,
      glassBackdrop: lightGlassBackdrop,
      accent: VlcAccentEngine(primary: accentColor),
    );
  }

  VlcColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceHover,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? glassBackdrop,
    VlcAccentEngine? accent,
  }) {
    return VlcColors(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      glassBackdrop: glassBackdrop ?? this.glassBackdrop,
      accent: accent ?? this.accent,
    );
  }

  static VlcColors lerp(VlcColors a, VlcColors b, double t) {
    return VlcColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      background: Color.lerp(a.background, b.background, t) ?? a.background,
      surface: Color.lerp(a.surface, b.surface, t) ?? a.surface,
      surfaceVariant: Color.lerp(a.surfaceVariant, b.surfaceVariant, t) ?? a.surfaceVariant,
      surfaceHover: Color.lerp(a.surfaceHover, b.surfaceHover, t) ?? a.surfaceHover,
      border: Color.lerp(a.border, b.border, t) ?? a.border,
      borderSubtle: Color.lerp(a.borderSubtle, b.borderSubtle, t) ?? a.borderSubtle,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t) ?? a.textPrimary,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t) ?? a.textSecondary,
      textTertiary: Color.lerp(a.textTertiary, b.textTertiary, t) ?? a.textTertiary,
      textDisabled: Color.lerp(a.textDisabled, b.textDisabled, t) ?? a.textDisabled,
      glassBackdrop: Color.lerp(a.glassBackdrop, b.glassBackdrop, t) ?? a.glassBackdrop,
      accent: VlcAccentEngine.lerp(a.accent, b.accent, t),
    );
  }
}
