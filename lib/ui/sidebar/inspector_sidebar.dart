import 'package:flutter/material.dart';
import '../../models/preset_models.dart';
import '../../theme/vlc_theme.dart';
import '../shell/top_player_bar.dart'; // for VlcTopBarButton

/// 4-Tab Inspector Sidebar for VLC Modern Redesign.
/// Width: 340.0dp (VlcGeometry.inspectorDrawerWidth) on Desktop / Sheet on Mobile.
/// Houses:
/// 1. Per-Show Preset Bar (Anime, Action, Late Night, Podcast, Standard)
/// 2. 4 Tabs: Subtitles, Audio & 10-Band EQ, Video & Aspect, Playback & Chapters
class InspectorSidebar extends StatefulWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onClose;
  final VoidCallback? onResetPreset;
  final ValueChanged<bool>? onApplyToFolder;
  final PresetController presetController;
  final Widget? subtitlesTab;
  final Widget? audioTab;
  final Widget? videoTab;
  final Widget? playbackTab;

  const InspectorSidebar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.presetController,
    this.onClose,
    this.onResetPreset,
    this.onApplyToFolder,
    this.subtitlesTab,
    this.audioTab,
    this.videoTab,
    this.playbackTab,
  });

  @override
  State<InspectorSidebar> createState() => _InspectorSidebarState();
}

class _InspectorSidebarState extends State<InspectorSidebar> {
  late int _selectedTab;
  bool _isPresetListExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.activeTab;
  }

  @override
  void didUpdateWidget(InspectorSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTab != oldWidget.activeTab) {
      _selectedTab = widget.activeTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return AnimatedBuilder(
      animation: widget.presetController,
      builder: (context, _) {
        final activePreset = widget.presetController.activePreset;

        return Container(
          width: VlcGeometry.inspectorDrawerWidth,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              left: BorderSide(
                color: colors.border,
                width: VlcGeometry.strokeWidthBorder,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------------------
                // 1. Top Drawer Header
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colors.border.withOpacity(0.50),
                        width: VlcGeometry.strokeWidthBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      VlcMonochromeIcon(
                        VlcIconGlyph.equalizer,
                        size: 18.0,
                        color: colors.accent.primary,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'Inspector & Presets',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: vlcTheme.typography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.onClose != null) ...[
                        const SizedBox(width: 8.0),
                        VlcTopBarButton(
                          width: 28.0,
                          height: 28.0,
                          tooltip: 'Close Inspector',
                          onPressed: widget.onClose,
                          child: Icon(
                            Icons.close,
                            size: 16.0,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // -------------------------------------------------------------
                // 2. Per-Show Preset Bar
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant.withOpacity(0.35),
                    border: Border(
                      bottom: BorderSide(
                        color: colors.border.withOpacity(0.35),
                        width: VlcGeometry.strokeWidthBorder,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preset Dropdown Trigger (Expands inline, no modal popup)
                      InkWell(
                        onTap: () => setState(() => _isPresetListExpanded = !_isPresetListExpanded),
                        borderRadius: VlcGeometry.borderRadiusMedium,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: VlcGeometry.borderRadiusMedium,
                            border: Border.all(
                              color: _isPresetListExpanded ? colors.accent.primary : colors.accent.subtleBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              VlcMonochromeIcon(
                                VlcIconGlyph.bookmark,
                                size: 16.0,
                                color: colors.accent.primary,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activePreset.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: vlcTheme.typography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      activePreset.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: vlcTheme.typography.labelSmall.copyWith(
                                        color: colors.textTertiary,
                                        fontSize: 10.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Icon(
                                _isPresetListExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                size: 18.0,
                                color: _isPresetListExpanded ? colors.accent.primary : colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Inline Expanded Presets List (No popups)
                      if (_isPresetListExpanded) ...[
                        const SizedBox(height: 6.0),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: VlcGeometry.borderRadiusMedium,
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              for (int pIdx = 0; pIdx < widget.presetController.presets.length; pIdx++) ...[
                                Builder(builder: (context) {
                                  final preset = widget.presetController.presets[pIdx];
                                  final isSelected = widget.presetController.activePreset == preset;
                                  return InkWell(
                                    onTap: () {
                                      widget.presetController.selectPreset(preset);
                                      setState(() => _isPresetListExpanded = false);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
                                      decoration: BoxDecoration(
                                        color: isSelected ? colors.accent.subtleBackground : Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                            size: 15.0,
                                            color: isSelected ? colors.accent.primary : colors.textTertiary,
                                          ),
                                          const SizedBox(width: 8.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  preset.name,
                                                  style: vlcTheme.typography.bodySmall.copyWith(
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    color: isSelected ? colors.accent.primary : colors.textPrimary,
                                                    fontSize: 11.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  preset.subtitle,
                                                  style: vlcTheme.typography.labelSmall.copyWith(
                                                    color: colors.textTertiary,
                                                    fontSize: 9.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                if (pIdx < widget.presetController.presets.length - 1)
                                  Divider(height: 1.0, color: colors.border.withOpacity(0.5)),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8.0),

                      // Per-Show Folder Persistence Toggle
                      Row(
                        children: [
                          SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: Checkbox(
                              value: widget.presetController.applyToAllFolderEpisodes,
                              activeColor: colors.accent.primary,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  widget.presetController.setApplyToFolder(val);
                                  widget.onApplyToFolder?.call(val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Save settings for all episodes in this show',
                              style: vlcTheme.typography.labelSmall.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // -------------------------------------------------------------
                // 3. 4-Tab Switcher Row
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant.withOpacity(0.20),
                    border: Border(
                      bottom: BorderSide(
                        color: colors.border.withOpacity(0.30),
                        width: VlcGeometry.strokeWidthBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Subs', VlcIconGlyph.tabSubtitles, colors, vlcTheme),
                      const SizedBox(width: 4.0),
                      _buildTabButton(1, 'Audio', VlcIconGlyph.tabAudio, colors, vlcTheme),
                      const SizedBox(width: 4.0),
                      _buildTabButton(2, 'Video', VlcIconGlyph.tabVideo, colors, vlcTheme),
                      const SizedBox(width: 4.0),
                      _buildTabButton(3, 'Play', VlcIconGlyph.tabPlayback, colors, vlcTheme),
                    ],
                  ),
                ),

                // -------------------------------------------------------------
                // 4. Tab Content Body
                // -------------------------------------------------------------
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab.clamp(0, 3),
                    children: [
                      widget.subtitlesTab ??
                          _buildTabPlaceholder('Subtitles', 'Synced Timeline & Font Styles', VlcIconGlyph.tabSubtitles, colors, vlcTheme),
                      widget.audioTab ??
                          _buildTabPlaceholder('Audio & EQ', 'Delay Slider & 10-Band Equalizer', VlcIconGlyph.tabAudio, colors, vlcTheme),
                      widget.videoTab ??
                          _buildTabPlaceholder('Video & Aspect', 'Crop, Aspect Ratio, Shaders & HDR', VlcIconGlyph.tabVideo, colors, vlcTheme),
                      widget.playbackTab ??
                          _buildTabPlaceholder('Playback', 'Speed 0.25x–4.0x, Bookmarks & Chapters', VlcIconGlyph.tabPlayback, colors, vlcTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(
    int index,
    String label,
    VlcIconGlyph glyph,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isActive = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
          widget.onTabChanged(index);
        },
        borderRadius: VlcGeometry.borderRadiusMedium,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7.0),
          decoration: BoxDecoration(
            color: isActive ? colors.accent.subtleBackground : Colors.transparent,
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(
              color: isActive ? colors.accent.subtleBorder : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VlcTwoToneIcon(
                glyph,
                size: 16.0,
                baseColor: isActive ? colors.accent.primary : colors.textTertiary,
                accentColor: colors.accent.primary,
              ),
              const SizedBox(height: 3.0),
              Text(
                label,
                style: vlcTheme.typography.labelSmall.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? colors.accent.primary : colors.textSecondary,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPlaceholder(
    String title,
    String description,
    VlcIconGlyph glyph,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VlcTwoToneIcon(
              glyph,
              size: 36.0,
              baseColor: colors.textTertiary,
              accentColor: colors.accent.primary,
            ),
            const SizedBox(height: 14.0),
            Text(
              title,
              style: vlcTheme.typography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              description,
              textAlign: TextAlign.center,
              style: vlcTheme.typography.bodySmall.copyWith(
                color: colors.textTertiary,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
