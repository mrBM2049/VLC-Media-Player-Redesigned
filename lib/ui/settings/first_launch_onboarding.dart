import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// First Launch Onboarding Experience for the VLC Modern Redesign.
///
/// Steps:
/// 1. Theme & Accent Customizer with live preview.
/// 2. Essential Hotkeys Cheat-Sheet.
/// 3. Media Library setup & launch.
class FirstLaunchOnboarding extends StatefulWidget {
  final VoidCallback? onComplete;
  final ValueChanged<VlcThemeMode>? onThemeModeChanged;
  final ValueChanged<Color>? onAccentColorChanged;

  const FirstLaunchOnboarding({
    super.key,
    this.onComplete,
    this.onThemeModeChanged,
    this.onAccentColorChanged,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onComplete,
    ValueChanged<VlcThemeMode>? onThemeModeChanged,
    ValueChanged<Color>? onAccentColorChanged,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FirstLaunchOnboarding(
        onComplete: onComplete,
        onThemeModeChanged: onThemeModeChanged,
        onAccentColorChanged: onAccentColorChanged,
      ),
    );
  }

  @override
  State<FirstLaunchOnboarding> createState() => _FirstLaunchOnboardingState();
}

class _FirstLaunchOnboardingState extends State<FirstLaunchOnboarding> {
  int _currentStep = 0; // 0 = Theme & Accent, 1 = Shortcuts, 2 = Ready
  VlcThemeMode _selectedTheme = VlcThemeMode.dark;
  Color _selectedAccent = VlcColors.coneOrange;

  static const List<Color> _accentPresets = [
    VlcColors.coneOrange, // #FF8800
    Color(0xFF00D2FF),   // Electric Cyan
    Color(0xFFA855F7),   // Royal Purple
    Color(0xFF84CC16),   // Lime Green
    Color(0xFFF43F5E),   // Crimson
  ];

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete?.call();
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
      child: Container(
        width: 780.0,
        height: 560.0,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusLarge,
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 40.0, offset: Offset(0, 20)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header Progress Bar
            _buildProgressBar(colors),

            // Step Content Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 28.0),
                child: switch (_currentStep) {
                  0 => _buildThemeStep(colors, vlcTheme),
                  1 => _buildShortcutsStep(colors, vlcTheme),
                  _ => _buildReadyStep(colors, vlcTheme),
                },
              ),
            ),

            // Footer Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              color: colors.surfaceVariant.withOpacity(0.35),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _handleBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onComplete?.call();
                      if (Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    child: Text('Skip Setup', style: TextStyle(color: colors.textTertiary)),
                  ),
                  const SizedBox(width: 12.0),
                  ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                      shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
                    ),
                    child: Text(_currentStep == 2 ? 'Start Watching' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(VlcColors colors) {
    return Container(
      height: 4.0,
      width: double.infinity,
      color: colors.surfaceVariant,
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        widthFactor: (_currentStep + 1) / 3.0,
        child: Container(color: _selectedAccent),
      ),
    );
  }

  // ==========================================
  // Step 0: Theme & Accent Customizer
  // ==========================================
  Widget _buildThemeStep(VlcColors colors, VlcThemeData vlcTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: _selectedAccent.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.palette_outlined, color: _selectedAccent, size: 18.0),
            ),
            const SizedBox(width: 12.0),
            Text(
              'Personalize Your Experience',
              style: vlcTheme.typography.titleLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          'Select your preferred workspace theme and signature accent color.',
          style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 24.0),

        // Theme Palette Selector
        Text(
          'APPEARANCE THEME',
          style: vlcTheme.typography.labelSmall.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            _buildThemeOptionCard(
              title: 'Dark Modern',
              desc: 'Juxtopposed charcoal canvas',
              mode: VlcThemeMode.dark,
              colors: colors,
              vlcTheme: vlcTheme,
            ),
            const SizedBox(width: 12.0),
            _buildThemeOptionCard(
              title: 'OLED Pure Black',
              desc: 'High-contrast true black (#000000)',
              mode: VlcThemeMode.oled,
              colors: colors,
              vlcTheme: vlcTheme,
            ),
            const SizedBox(width: 12.0),
            _buildThemeOptionCard(
              title: 'Clean Light',
              desc: 'Crisp studio paper contrast',
              mode: VlcThemeMode.light,
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ],
        ),

        const SizedBox(height: 24.0),

        // Accent Color Swatches
        Text(
          'SIGNATURE ACCENT COLOR',
          style: vlcTheme.typography.labelSmall.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10.0),
        Row(
          children: _accentPresets.map((color) {
            final isSelected = _selectedAccent == color;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedAccent = color);
                widget.onAccentColorChanged?.call(color);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 14.0),
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                  ],
                ),
                child: isSelected ? const Icon(Icons.check, size: 20.0, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String desc,
    required VlcThemeMode mode,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
  }) {
    final isSelected = _selectedTheme == mode;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedTheme = mode);
          widget.onThemeModeChanged?.call(mode);
        },
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: isSelected ? _selectedAccent.withOpacity(0.12) : colors.surfaceVariant,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: isSelected ? _selectedAccent : colors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    mode == VlcThemeMode.light ? Icons.light_mode : Icons.dark_mode,
                    size: 18.0,
                    color: isSelected ? _selectedAccent : colors.textPrimary,
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 16.0, color: _selectedAccent),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: vlcTheme.typography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                desc,
                style: vlcTheme.typography.bodySmall.copyWith(
                  color: colors.textTertiary,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Step 1: Essential Shortcuts Cheat-Sheet
  // ==========================================
  Widget _buildShortcutsStep(VlcColors colors, VlcThemeData vlcTheme) {
    const shortcuts = [
      ('Space', 'Play / Pause Video', 'Instant playback toggle'),
      ('F', 'Fullscreen Mode', 'Escape to return to windowed view'),
      ('V / S', 'Cycle Subtitle Tracks', 'Switch embedded dialogue or SRTs'),
      ('B', 'Cycle Audio Tracks', 'Toggle languages or multi-channel audio'),
      ('Q', 'Play Queue Drawer', 'Drag and reorder temporary playback'),
      ('Ctrl+P', 'Unified Preferences', 'Full 12-category settings modal'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: _selectedAccent.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.keyboard_outlined, color: _selectedAccent, size: 18.0),
            ),
            const SizedBox(width: 12.0),
            Text(
              'Master Essential Hotkeys',
              style: vlcTheme.typography.titleLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          'VLC Modern preserves all classic muscle memory keyboard shortcuts.',
          style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 20.0),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 3.2,
            ),
            itemCount: shortcuts.length,
            itemBuilder: (ctx, index) {
              final item = shortcuts[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: VlcGeometry.borderRadiusSmall,
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        item.$1,
                        style: vlcTheme.typography.monospaceTime.copyWith(
                          fontSize: 12.0,
                          color: _selectedAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.$2,
                            style: vlcTheme.typography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.$3,
                            style: vlcTheme.typography.bodySmall.copyWith(
                              color: colors.textTertiary,
                              fontSize: 11.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Step 2: Ready to Watch
  // ==========================================
  Widget _buildReadyStep(VlcColors colors, VlcThemeData vlcTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72.0,
          height: 72.0,
          decoration: BoxDecoration(
            color: _selectedAccent.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_outline, color: _selectedAccent, size: 44.0),
        ),
        const SizedBox(height: 20.0),
        Text(
          'You are all set!',
          style: vlcTheme.typography.titleLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Your preferences have been saved. Drop in any audio or video file to start playing.',
          textAlign: TextAlign.center,
          style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 24.0),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16.0, color: _selectedAccent),
              const SizedBox(width: 8.0),
              Text(
                'You can reopen Preferences at any time with Ctrl+P',
                style: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

