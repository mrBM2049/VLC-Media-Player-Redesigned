import 'package:flutter/material.dart';
import 'vlc_colors.dart';
import 'vlc_geometry.dart';
import 'vlc_typography.dart';

enum VlcThemeMode {
  dark,
  oled,
  light,
}

/// Unified Theme Data container implementing Flutter's ThemeExtension
/// for seamless context-based access (`context.vlcTheme` or `VlcTheme.of(context)`).
class VlcThemeData extends ThemeExtension<VlcThemeData> {
  final VlcThemeMode mode;
  final VlcColors colors;
  final VlcGeometry geometry;
  final VlcTypography typography;

  const VlcThemeData({
    required this.mode,
    required this.colors,
    required this.geometry,
    required this.typography,
  });

  /// Factory creating default Dark theme with signature #FF8800 Cone Orange accent
  factory VlcThemeData.dark({Color accentColor = VlcColors.coneOrange}) {
    final colors = VlcColors.dark(accentColor: accentColor);
    final typography = VlcTypography.create(
      primaryColor: colors.textPrimary,
      secondaryColor: colors.textSecondary,
      mutedColor: colors.textTertiary,
    );
    return VlcThemeData(
      mode: VlcThemeMode.dark,
      colors: colors,
      geometry: const VlcGeometry(),
      typography: typography,
    );
  }

  /// Factory creating pure Black OLED theme for OLED/Mini-LED displays
  factory VlcThemeData.oled({Color accentColor = VlcColors.coneOrange}) {
    final colors = VlcColors.oled(accentColor: accentColor);
    final typography = VlcTypography.create(
      primaryColor: colors.textPrimary,
      secondaryColor: colors.textSecondary,
      mutedColor: colors.textTertiary,
    );
    return VlcThemeData(
      mode: VlcThemeMode.oled,
      colors: colors,
      geometry: const VlcGeometry(),
      typography: typography,
    );
  }

  /// Factory creating clean Light theme
  factory VlcThemeData.light({Color accentColor = VlcColors.coneOrange}) {
    final colors = VlcColors.light(accentColor: accentColor);
    final typography = VlcTypography.create(
      primaryColor: colors.textPrimary,
      secondaryColor: colors.textSecondary,
      mutedColor: colors.textTertiary,
    );
    return VlcThemeData(
      mode: VlcThemeMode.light,
      colors: colors,
      geometry: const VlcGeometry(),
      typography: typography,
    );
  }

  /// Exports standard Flutter ThemeData matching the exact Figma specifications
  ThemeData toThemeData() {
    final isDark = mode != VlcThemeMode.light;

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      cardColor: colors.surface,
      dividerColor: colors.border,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.accent.primary,
        onPrimary: Colors.white,
        secondary: colors.accent.primary,
        onSecondary: Colors.white,
        error: VlcColors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      cardTheme: const CardThemeData(
        color: VlcColors.darkSurface,
        shape: VlcGeometry.cardShape,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: VlcGeometry.dialogShape,
        elevation: 8,
      ),
      extensions: [this],
    );
  }

  @override
  ThemeExtension<VlcThemeData> copyWith({
    VlcThemeMode? mode,
    VlcColors? colors,
    VlcGeometry? geometry,
    VlcTypography? typography,
  }) {
    return VlcThemeData(
      mode: mode ?? this.mode,
      colors: colors ?? this.colors,
      geometry: geometry ?? this.geometry,
      typography: typography ?? this.typography,
    );
  }

  @override
  ThemeExtension<VlcThemeData> lerp(covariant ThemeExtension<VlcThemeData>? other, double t) {
    if (other is! VlcThemeData) return this;
    return VlcThemeData(
      mode: t < 0.5 ? mode : other.mode,
      colors: VlcColors.lerp(colors, other.colors, t),
      geometry: geometry,
      typography: VlcTypography.lerp(typography, other.typography, t),
    );
  }
}

/// Static accessor helper
class VlcTheme {
  static VlcThemeData of(BuildContext context) {
    final extension = Theme.of(context).extension<VlcThemeData>();
    return extension ?? VlcThemeData.dark();
  }
}

/// BuildContext extension shortcut: `context.vlcTheme`
extension VlcThemeContextExtension on BuildContext {
  VlcThemeData get vlcTheme => VlcTheme.of(this);
  VlcColors get vlcColors => vlcTheme.colors;
  VlcGeometry get vlcGeometry => vlcTheme.geometry;
  VlcTypography get vlcTypography => vlcTheme.typography;
  VlcAccentEngine get vlcAccent => vlcTheme.colors.accent;
}

/// Reactive Theme Controller & Notifier for live theme mode / accent color switching
class VlcThemeController extends ChangeNotifier {
  VlcThemeMode _mode;
  Color _accentColor;

  VlcThemeController({
    VlcThemeMode mode = VlcThemeMode.dark,
    Color accentColor = VlcColors.coneOrange,
  })  : _mode = mode,
        _accentColor = accentColor;

  VlcThemeMode get mode => _mode;
  Color get accentColor => _accentColor;

  VlcThemeData get currentTheme {
    switch (_mode) {
      case VlcThemeMode.dark:
        return VlcThemeData.dark(accentColor: _accentColor);
      case VlcThemeMode.oled:
        return VlcThemeData.oled(accentColor: _accentColor);
      case VlcThemeMode.light:
        return VlcThemeData.light(accentColor: _accentColor);
    }
  }

  void setThemeMode(VlcThemeMode mode) {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  void setAccentColor(Color color) {
    if (_accentColor != color) {
      _accentColor = color;
      notifyListeners();
    }
  }

  void setPreset(VlcAccentPreset preset) {
    setAccentColor(preset.color);
  }
}
