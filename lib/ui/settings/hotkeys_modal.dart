import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

/// Functional categorization for player keyboard shortcuts.
enum HotkeyCategory {
  playback('Playback & Navigation', Icons.play_circle_outline),
  audio('Audio & Volume', Icons.volume_up_outlined),
  subtitles('Subtitles & Timing', Icons.subtitles_outlined),
  video('Video & Display', Icons.aspect_ratio_outlined),
  drawers('Drawers & Library', Icons.view_sidebar_outlined),
  general('General & Files', Icons.settings_outlined);

  final String label;
  final IconData icon;

  const HotkeyCategory(this.label, this.icon);
}

/// Representation of a configurable keyboard shortcut mapping.
class HotkeyEntry {
  final String id;
  final String action;
  final String description;
  final String defaultKey;
  final String currentKey;
  final HotkeyCategory category;

  const HotkeyEntry({
    required this.id,
    required this.action,
    required this.description,
    required this.defaultKey,
    required this.currentKey,
    required this.category,
  });

  HotkeyEntry copyWith({
    String? currentKey,
  }) {
    return HotkeyEntry(
      id: id,
      action: action,
      description: description,
      defaultKey: defaultKey,
      currentKey: currentKey ?? this.currentKey,
      category: category,
    );
  }
}

/// Standalone Searchable Hotkeys Modal and Rebinding Dialog.
class HotkeysModal extends StatefulWidget {
  final VoidCallback? onClose;
  final ValueChanged<List<HotkeyEntry>>? onSaveHotkeys;

  const HotkeysModal({
    super.key,
    this.onClose,
    this.onSaveHotkeys,
  });

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const HotkeysModal(),
    );
  }

  @override
  State<HotkeysModal> createState() => _HotkeysModalState();
}

class _HotkeysModalState extends State<HotkeysModal> {
  final TextEditingController _searchController = TextEditingController();
  HotkeyCategory? _selectedCategory;
  String _searchQuery = '';
  late List<HotkeyEntry> _hotkeys;
  String? _rebindTargetId;

  @override
  void initState() {
    super.initState();
    _hotkeys = _getDefaultHotkeys();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static List<HotkeyEntry> _getDefaultHotkeys() {
    return [
      // Playback
      const HotkeyEntry(
        id: 'play_pause',
        action: 'Play / Pause',
        description: 'Toggle video playback or resume from pause',
        defaultKey: 'Space',
        currentKey: 'Space',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'seek_forward_small',
        action: 'Seek Forward (5s)',
        description: 'Jump ahead 5 seconds in current media',
        defaultKey: 'Right',
        currentKey: 'Right',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'seek_backward_small',
        action: 'Seek Backward (5s)',
        description: 'Jump backward 5 seconds in current media',
        defaultKey: 'Left',
        currentKey: 'Left',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'seek_forward_large',
        action: 'Seek Forward (1 min)',
        description: 'Jump ahead 60 seconds',
        defaultKey: 'Ctrl+Right',
        currentKey: 'Ctrl+Right',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'seek_backward_large',
        action: 'Seek Backward (1 min)',
        description: 'Jump backward 60 seconds',
        defaultKey: 'Ctrl+Left',
        currentKey: 'Ctrl+Left',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'next_frame',
        action: 'Next Frame',
        description: 'Step one frame forward while paused',
        defaultKey: 'E',
        currentKey: 'E',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'prev_frame',
        action: 'Previous Frame',
        description: 'Step one frame backward',
        defaultKey: 'Shift+E',
        currentKey: 'Shift+E',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'slower_rate',
        action: 'Slower Playback (-0.1x)',
        description: 'Decrease playback speed',
        defaultKey: '[',
        currentKey: '[',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'faster_rate',
        action: 'Faster Playback (+0.1x)',
        description: 'Increase playback speed',
        defaultKey: ']',
        currentKey: ']',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'normal_rate',
        action: 'Reset Playback Rate (1.0x)',
        description: 'Restore normal 1.0x playback speed',
        defaultKey: '`',
        currentKey: '`',
        category: HotkeyCategory.playback,
      ),
      const HotkeyEntry(
        id: 'cycle_repeat',
        action: 'Cycle Repeat Mode',
        description: 'Switch between Off, Repeat One, and Repeat All',
        defaultKey: 'R',
        currentKey: 'R',
        category: HotkeyCategory.playback,
      ),

      // Audio
      const HotkeyEntry(
        id: 'volume_up',
        action: 'Volume Up (+5%)',
        description: 'Increase volume (up to 200% cone boost)',
        defaultKey: 'Up',
        currentKey: 'Up',
        category: HotkeyCategory.audio,
      ),
      const HotkeyEntry(
        id: 'volume_down',
        action: 'Volume Down (-5%)',
        description: 'Decrease volume',
        defaultKey: 'Down',
        currentKey: 'Down',
        category: HotkeyCategory.audio,
      ),
      const HotkeyEntry(
        id: 'mute',
        action: 'Mute / Unmute',
        description: 'Toggle audio mute',
        defaultKey: 'M',
        currentKey: 'M',
        category: HotkeyCategory.audio,
      ),
      const HotkeyEntry(
        id: 'cycle_audio',
        action: 'Cycle Audio Tracks',
        description: 'Switch between language tracks',
        defaultKey: 'B',
        currentKey: 'B',
        category: HotkeyCategory.audio,
      ),
      const HotkeyEntry(
        id: 'audio_delay_down',
        action: 'Audio Delay -50ms',
        description: 'Shift audio earlier relative to video',
        defaultKey: 'J',
        currentKey: 'J',
        category: HotkeyCategory.audio,
      ),
      const HotkeyEntry(
        id: 'audio_delay_up',
        action: 'Audio Delay +50ms',
        description: 'Shift audio later relative to video',
        defaultKey: 'K',
        currentKey: 'K',
        category: HotkeyCategory.audio,
      ),

      // Subtitles
      const HotkeyEntry(
        id: 'cycle_subtitles',
        action: 'Cycle Subtitles Track',
        description: 'Toggle through available subtitle languages or disable',
        defaultKey: 'V / S',
        currentKey: 'V / S',
        category: HotkeyCategory.subtitles,
      ),
      const HotkeyEntry(
        id: 'sub_delay_down',
        action: 'Subtitle Delay -50ms',
        description: 'Display dialogue earlier',
        defaultKey: 'G',
        currentKey: 'G',
        category: HotkeyCategory.subtitles,
      ),
      const HotkeyEntry(
        id: 'sub_delay_up',
        action: 'Subtitle Delay +50ms',
        description: 'Display dialogue later',
        defaultKey: 'H',
        currentKey: 'H',
        category: HotkeyCategory.subtitles,
      ),

      // Video & Display
      const HotkeyEntry(
        id: 'fullscreen',
        action: 'Toggle Fullscreen',
        description: 'Switch between fullscreen and windowed view',
        defaultKey: 'F',
        currentKey: 'F',
        category: HotkeyCategory.video,
      ),
      const HotkeyEntry(
        id: 'pip',
        action: 'Picture-in-Picture (PiP)',
        description: 'Float miniature video player on top of desktop',
        defaultKey: 'P',
        currentKey: 'P',
        category: HotkeyCategory.video,
      ),
      const HotkeyEntry(
        id: 'aspect_ratio',
        action: 'Cycle Aspect Ratio',
        description: 'Cycle 16:9, 4:3, 21:9, and Original',
        defaultKey: 'A',
        currentKey: 'A',
        category: HotkeyCategory.video,
      ),
      const HotkeyEntry(
        id: 'crop',
        action: 'Cycle Crop Geometry',
        description: 'Crop black bars to fill display',
        defaultKey: 'C',
        currentKey: 'C',
        category: HotkeyCategory.video,
      ),
      const HotkeyEntry(
        id: 'hide_ui',
        action: 'Hide UI Completely',
        description: 'Lock transport controls hidden for immersive viewing',
        defaultKey: 'Ctrl+H',
        currentKey: 'Ctrl+H',
        category: HotkeyCategory.video,
      ),

      // Drawers & Library
      const HotkeyEntry(
        id: 'queue_drawer',
        action: 'Toggle Play Queue Drawer',
        description: 'Slide in the temporary playback queue',
        defaultKey: 'Q',
        currentKey: 'Q',
        category: HotkeyCategory.drawers,
      ),
      const HotkeyEntry(
        id: 'inspector_sidebar',
        action: 'Toggle Inspector & Presets',
        description: 'Open 4-tab audio/video/subtitles equalizer panel',
        defaultKey: 'I',
        currentKey: 'I',
        category: HotkeyCategory.drawers,
      ),
      const HotkeyEntry(
        id: 'media_library',
        action: 'Full Media Library View',
        description: 'Open grid/list browser for indexed videos and music',
        defaultKey: 'Ctrl+L',
        currentKey: 'Ctrl+L',
        category: HotkeyCategory.drawers,
      ),

      // General & Files
      const HotkeyEntry(
        id: 'open_file',
        action: 'Open Media File...',
        description: 'Browse local filesystem for audio/video media',
        defaultKey: 'Ctrl+O',
        currentKey: 'Ctrl+O',
        category: HotkeyCategory.general,
      ),
      const HotkeyEntry(
        id: 'preferences',
        action: 'Preferences / Settings',
        description: 'Open Unified Settings across all 12 categories',
        defaultKey: 'Ctrl+P',
        currentKey: 'Ctrl+P',
        category: HotkeyCategory.general,
      ),
      const HotkeyEntry(
        id: 'bookmark',
        action: 'Add Visual Bookmark',
        description: 'Create timecode bookmark with thumbnail',
        defaultKey: 'Ctrl+B',
        currentKey: 'Ctrl+B',
        category: HotkeyCategory.general,
      ),
    ];
  }

  void _handleResetAll() {
    setState(() {
      _hotkeys = _getDefaultHotkeys();
    });
    widget.onSaveHotkeys?.call(_hotkeys);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All hotkeys reset to default.')),
    );
  }

  void _startRebinding(HotkeyEntry entry) {
    setState(() {
      _rebindTargetId = entry.id;
    });

    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey != LogicalKeyboardKey.escape) {
                final keyLabel = event.logicalKey.keyLabel;
                setState(() {
                  _hotkeys = _hotkeys.map((h) {
                    if (h.id == entry.id) {
                      return h.copyWith(currentKey: keyLabel.isNotEmpty ? keyLabel : 'Custom');
                    }
                    return h;
                  }).toList();
                  _rebindTargetId = null;
                });
                widget.onSaveHotkeys?.call(_hotkeys);
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated "${entry.action}" to $keyLabel')),
                );
              } else {
                Navigator.of(dialogCtx).pop();
              }
            }
          },
          child: AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: VlcGeometry.borderRadiusMedium,
              side: BorderSide(color: colors.border),
            ),
            title: Text(
              'Press Any Key to Rebind',
              style: vlcTheme.typography.titleMedium.copyWith(color: colors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action: ${entry.action}',
                  style: vlcTheme.typography.bodyMedium.copyWith(
                    color: colors.accent.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Press any key or combination on your keyboard. Press Esc to cancel.',
                  style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _rebindTargetId = null);
                  Navigator.of(dialogCtx).pop();
                },
                child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    // Filter hotkeys by category and search query
    final filtered = _hotkeys.where((h) {
      if (_selectedCategory != null && h.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchAction = h.action.toLowerCase().contains(q);
        final matchDesc = h.description.toLowerCase().contains(q);
        final matchKey = h.currentKey.toLowerCase().contains(q);
        final matchCat = h.category.label.toLowerCase().contains(q);
        return matchAction || matchDesc || matchKey || matchCat;
      }
      return true;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Container(
        width: 860.0,
        height: 620.0,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusLarge,
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 36.0, offset: Offset(0, 18)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              color: colors.surfaceVariant.withOpacity(0.4),
              child: Row(
                children: [
                  Icon(Icons.keyboard_outlined, size: 22.0, color: colors.accent.primary),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Keyboard Shortcuts & Hotkeys',
                      style: vlcTheme.typography.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16.0),

                  // Search Field
                  SizedBox(
                    width: 260.0,
                    height: 36.0,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search actions or keys...',
                        hintStyle: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
                        prefixIcon: Icon(Icons.search, size: 16.0, color: colors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14.0),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                        filled: true,
                        fillColor: colors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: VlcGeometry.borderRadiusMedium,
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Reset Defaults Button
                  OutlinedButton(
                    onPressed: _handleResetAll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusSmall),
                    ),
                    child: const Text('Reset All'),
                  ),
                  const SizedBox(width: 12.0),

                  // Close Button
                  IconButton(
                    icon: VlcMonochromeIcon(VlcIconGlyph.close, size: 16.0, color: colors.textSecondary),
                    onPressed: () {
                      widget.onClose?.call();
                      if (Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    tooltip: 'Close [Esc]',
                  ),
                ],
              ),
            ),

            // Category Filter Bar
            Container(
              height: 44.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.2),
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryPill('All Shortcuts', null, colors, vlcTheme),
                  ...HotkeyCategory.values.map(
                    (cat) => _buildCategoryPill(cat.label, cat, colors, vlcTheme),
                  ),
                ],
              ),
            ),

            // Hotkeys Table / List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No shortcuts match "$_searchQuery"',
                        style: vlcTheme.typography.bodyMedium.copyWith(color: colors.textTertiary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => Divider(color: colors.border.withOpacity(0.5), height: 1.0),
                      itemBuilder: (ctx, index) {
                        final entry = filtered[index];
                        final isCustom = entry.currentKey != entry.defaultKey;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                          child: Row(
                            children: [
                              // Category Icon
                              Icon(entry.category.icon, size: 18.0, color: colors.textTertiary),
                              const SizedBox(width: 12.0),

                              // Action & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.action,
                                      style: vlcTheme.typography.bodyMedium.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      entry.description,
                                      style: vlcTheme.typography.bodySmall.copyWith(
                                        color: colors.textTertiary,
                                        fontSize: 11.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16.0),

                              // Key Badge Display
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant,
                                  borderRadius: VlcGeometry.borderRadiusSmall,
                                  border: Border.all(
                                    color: isCustom ? colors.accent.primary : colors.border,
                                    width: isCustom ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  entry.currentKey,
                                  style: vlcTheme.typography.monospaceTime.copyWith(
                                    fontSize: 12.0,
                                    color: isCustom ? colors.accent.primary : colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10.0),

                              // Rebind Action Button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16.0),
                                tooltip: 'Rebind shortcut',
                                color: colors.textSecondary,
                                onPressed: () => _startRebinding(entry),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(
    String label,
    HotkeyCategory? cat,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    final isSelected = _selectedCategory == cat;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          onTap: () => setState(() => _selectedCategory = cat),
          borderRadius: VlcGeometry.borderRadiusSmall,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: isSelected ? colors.accent.primary.withOpacity(0.18) : Colors.transparent,
              borderRadius: VlcGeometry.borderRadiusSmall,
              border: Border.all(
                color: isSelected ? colors.accent.primary : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              style: vlcTheme.typography.labelSmall.copyWith(
                color: isSelected ? colors.accent.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

