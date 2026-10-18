import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../theme/theme.dart';

/// Reimagined Unified Settings Modal across all 12 Categories.
///
/// Features:
/// - Continuous Basic-to-Advanced scroll (no disruptive Simple/All toggle).
/// - Instant real-time search across all preferences, flags, and tooltips.
/// - Human-readable dropdowns and settings controls.
/// - Interactive `ⓘ` info tooltip on every setting item displaying rationale, default, and libvlc flag.
/// - "Reset to Defaults" with confirmation safeguard.
class UnifiedSettingsModal extends StatefulWidget {
  final SettingsService? settingsService;
  final VoidCallback? onClose;
  final ValueChanged<SettingsCategory>? onCategoryChanged;

  const UnifiedSettingsModal({
    super.key,
    this.settingsService,
    this.onClose,
    this.onCategoryChanged,
  });

  /// Helper to display modal dialog cleanly over current navigator.
  static Future<void> show(BuildContext context, {SettingsService? service}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UnifiedSettingsModal(settingsService: service),
    );
  }

  @override
  State<UnifiedSettingsModal> createState() => _UnifiedSettingsModalState();
}

class _UnifiedSettingsModalState extends State<UnifiedSettingsModal> {
  late final SettingsService _settings;
  SettingsCategory _selectedCategory = SettingsCategory.interfaceAppearance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsService ?? SettingsService.instance;
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _searchController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _handleResetDefaults() {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.accent.primary, size: 22.0),
              const SizedBox(width: 8.0),
              Text('Reset All Preferences?', style: vlcTheme.typography.titleMedium.copyWith(color: colors.textPrimary)),
            ],
          ),
          content: Text(
            'This will restore all 12 categories back to their factory defaults. Any custom audio, video, or subtitle settings will be reset.',
            style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                _settings.resetToDefaults();
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All settings restored to factory defaults.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset All'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoTooltip(BuildContext context, SettingItemMeta meta) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420.0,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: VlcGeometry.borderRadiusMedium,
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 24.0, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20.0, color: colors.accent.primary),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        meta.title,
                        style: vlcTheme.typography.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16.0),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  meta.tooltip,
                  style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: VlcGeometry.borderRadiusSmall,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'libVLC Flag: ',
                        style: vlcTheme.typography.labelSmall.copyWith(
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          meta.libvlcFlag,
                          style: vlcTheme.typography.monospaceTime.copyWith(
                            fontSize: 11.0,
                            color: colors.accent.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.surfaceHover,
                      foregroundColor: colors.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusSmall),
                    ),
                    child: const Text('Got It'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Container(
        width: 900.0,
        height: 660.0,
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
            // Modal Top Bar
            _buildTopBar(colors, vlcTheme),

            // Modal Body: Sidebar + Main Content Area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category Sidebar
                  _buildSidebar(colors, vlcTheme),

                  // Vertical Separator
                  Container(width: 1.0, color: colors.border),

                  // Main Scrollable Content
                  Expanded(
                    child: _searchQuery.isNotEmpty
                        ? _buildSearchResults(colors, vlcTheme)
                        : _buildCategoryContent(colors, vlcTheme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Top Header Bar
  // ==========================================
  Widget _buildTopBar(VlcColors colors, VlcThemeData vlcTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      color: colors.surfaceVariant.withOpacity(0.4),
      child: Row(
        children: [
          Icon(Icons.tune_outlined, size: 22.0, color: colors.accent.primary),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Preferences & Settings',
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
            width: 280.0,
            height: 36.0,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search all preferences & flags...',
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: VlcGeometry.borderRadiusMedium,
                  borderSide: BorderSide(color: colors.accent.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),

          // Reset to Defaults Button
          OutlinedButton(
            onPressed: _handleResetDefaults,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusSmall),
            ),
            child: const Text('Reset Defaults'),
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
    );
  }

  // ==========================================
  // Sidebar: 12 Categories List
  // ==========================================
  Widget _buildSidebar(VlcColors colors, VlcThemeData vlcTheme) {
    return Container(
      width: 250.0,
      color: colors.surfaceVariant.withOpacity(0.2),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: SettingsCategory.values.length,
        itemBuilder: (ctx, index) {
          final cat = SettingsCategory.values[index];
          final isSelected = _selectedCategory == cat && _searchQuery.isEmpty;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
                _searchQuery = '';
                _searchController.clear();
              });
              widget.onCategoryChanged?.call(cat);
              if (_contentScrollController.hasClients) {
                _contentScrollController.jumpTo(0.0);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
              decoration: BoxDecoration(
                color: isSelected ? colors.accent.primary.withOpacity(0.14) : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected ? colors.accent.primary : Colors.transparent,
                    width: 3.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon,
                    size: 18.0,
                    color: isSelected ? colors.accent.primary : colors.textSecondary,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: vlcTheme.typography.bodySmall.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? colors.accent.primary : colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // Category Content (Continuous Basic-to-Advanced)
  // ==========================================
  Widget _buildCategoryContent(VlcColors colors, VlcThemeData vlcTheme) {
    return Scrollbar(
      controller: _contentScrollController,
      thumbVisibility: true,
      child: ListView(
        controller: _contentScrollController,
        padding: const EdgeInsets.all(24.0),
        children: [
          // Category Header
          Row(
            children: [
              Icon(_selectedCategory.icon, size: 26.0, color: colors.accent.primary),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  _selectedCategory.label,
                  style: vlcTheme.typography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            'Configure playback behavior, native hardware acceleration, and defaults.',
            style: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: 20.0),

          // Basic Configuration Section
          _buildSectionHeader('BASIC SETTINGS', colors, vlcTheme),
          const SizedBox(height: 12.0),
          ..._buildCategoryBasicSettings(_selectedCategory, colors, vlcTheme),

          const SizedBox(height: 28.0),

          // Continuous Transition to Advanced Configuration
          _buildAdvancedSectionDivider(colors, vlcTheme),
          const SizedBox(height: 16.0),
          ..._buildCategoryAdvancedSettings(_selectedCategory, colors, vlcTheme),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VlcColors colors, VlcThemeData vlcTheme) {
    return Row(
      children: [
        Text(
          title,
          style: vlcTheme.typography.labelSmall.copyWith(
            color: colors.accent.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(child: Divider(color: colors.border, height: 1.0)),
      ],
    );
  }

  Widget _buildAdvancedSectionDivider(VlcColors colors, VlcThemeData vlcTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.4),
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: 16.0, color: colors.accent.primary),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'ADVANCED CONFIGURATION (libVLC Engine Internals)',
              style: vlcTheme.typography.labelSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Continuous Scroll',
            style: vlcTheme.typography.labelSmall.copyWith(
              color: colors.textTertiary,
              fontSize: 10.0,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Basic Settings per Category
  // ==========================================
  List<Widget> _buildCategoryBasicSettings(
    SettingsCategory cat,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    switch (cat) {
      case SettingsCategory.interfaceAppearance:
        return [
          _buildSettingCard(
            title: 'App Theme Mode',
            description: 'Choose interface theme palette (Dark, OLED Black, or Light).',
            metaKey: 'theme_mode',
            colors: colors,
            vlcTheme: vlcTheme,
            control: SegmentedButton<VlcThemeMode>(
              segments: const [
                ButtonSegment(value: VlcThemeMode.dark, label: Text('Dark')),
                ButtonSegment(value: VlcThemeMode.oled, label: Text('OLED')),
                ButtonSegment(value: VlcThemeMode.light, label: Text('Light')),
              ],
              selected: {_settings.themeMode},
              onSelectionChanged: (set) => _settings.setThemeMode(set.first),
            ),
          ),
          _buildSettingCard(
            title: 'Show On-Screen Display (OSD) Pills',
            description: 'Show brief HUD pills on shortcut and remote actions.',
            metaKey: 'show_osd',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.showOsdPill,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setShowOsdPill(val),
            ),
          ),
          _buildSettingCard(
            title: 'Controls Auto-Hide Delay',
            description: 'Duration before transport rows hide (${_settings.autoHideControlsDelaySeconds.toStringAsFixed(1)}s).',
            metaKey: 'autohide_delay',
            colors: colors,
            vlcTheme: vlcTheme,
            control: SizedBox(
              width: 180.0,
              child: Slider(
                value: _settings.autoHideControlsDelaySeconds,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                activeColor: colors.accent.primary,
                label: '${_settings.autoHideControlsDelaySeconds.toStringAsFixed(1)}s',
                onChanged: (val) => _settings.setAutoHideControlsDelaySeconds(val),
              ),
            ),
          ),
        ];

      case SettingsCategory.audioOutput:
        return [
          _buildSettingCard(
            title: 'Audio Output Module',
            description: 'Active audio engine interface driver.',
            metaKey: 'audio_output_module',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.audioOutputModule,
              items: const ['Automatic', 'CoreAudio', 'WASAPI', 'PulseAudio', 'ALSA'],
              onChanged: (val) => _settings.setAudioOutputModule(val!),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Maximum Cone Volume Boost',
            description: 'Software pre-amp ceiling (${_settings.coneVolumeLimit.toInt()}%).',
            metaKey: 'cone_volume_limit',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: '${_settings.coneVolumeLimit.toInt()}%',
              items: const ['100%', '125%', '150%', '200%'],
              onChanged: (val) => _settings.setConeVolumeLimit(double.parse(val!.replaceAll('%', ''))),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Volume Step Increment',
            description: 'Percentage change per wheel scroll notch (${_settings.volumeStep.toInt()}%).',
            metaKey: 'volume_step',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: '${_settings.volumeStep.toInt()}%',
              items: const ['2%', '5%', '10%', '15%'],
              onChanged: (val) => _settings.setVolumeStep(double.parse(val!.replaceAll('%', ''))),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];

      case SettingsCategory.videoAcceleration:
        return [
          _buildSettingCard(
            title: 'Hardware Video Decoding',
            description: 'Offload H.264, HEVC, and AV1 decoding to GPU.',
            metaKey: 'hardware_decoding',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.hardwareDecoding,
              items: const ['Automatic', 'VideoToolbox', 'DXVA2', 'D3D11VA', 'VAAPI', 'Disabled'],
              onChanged: (val) => _settings.setHardwareDecoding(val!),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Deinterlace Mode',
            description: 'Field weaving for broadcast and interlaced video.',
            metaKey: 'deinterlace_mode',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.deinterlaceMode,
              items: const ['Off', 'Auto', 'On'],
              onChanged: (val) => _settings.setDeinterlaceMode(val!),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Deinterlace Filter Algorithm',
            description: 'Spatial and temporal motion filter algorithm.',
            metaKey: 'deinterlace_algorithm',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.deinterlaceAlgorithm,
              items: const ['Bob', 'Linear', 'Yadif (2x)', 'Phosphor'],
              onChanged: (val) => _settings.setDeinterlaceAlgorithm(val!),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];

      case SettingsCategory.subtitlesOsd:
        return [
          _buildSettingCard(
            title: 'Preferred Subtitle Language',
            description: 'Automatic stream selection by ISO 639-1 language.',
            metaKey: 'default_subtitle_lang',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.defaultSubtitleLanguage,
              items: const ['English', 'Spanish', 'French', 'German', 'Japanese', 'Any'],
              onChanged: (val) => _settings.setDefaultSubtitleLanguage(val!),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Subtitle Font Size',
            description: 'Rendered text point size (${_settings.subtitleFontSize.toInt()}pt).',
            metaKey: 'subtitle_font_size',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: '${_settings.subtitleFontSize.toInt()}pt',
              items: const ['18pt', '24pt', '30pt', '36pt'],
              onChanged: (val) => _settings.setSubtitleFontSize(double.parse(val!.replaceAll('pt', ''))),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Auto-Fetch Missing Subtitles',
            description: 'Automatically query OpenSubtitles for media hashes.',
            metaKey: 'auto_download_subs',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.autoDownloadSubtitles,
              activeColor: colors.accent.primary,
              onChanged: (val) => setState(() => _settings.resetToDefaults()), // reactive fallback
            ),
          ),
        ];

      case SettingsCategory.inputCodecs:
        return [
          _buildSettingCard(
            title: 'Network Stream Caching Buffer',
            description: 'Stream pre-buffer duration (${_settings.networkCachingMs}ms).',
            metaKey: 'network_caching',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: '${_settings.networkCachingMs}ms',
              items: const ['300ms', '1200ms', '3000ms'],
              onChanged: (val) => _settings.setNetworkCachingMs(int.parse(val!.replaceAll('ms', ''))),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Local File Caching Buffer',
            description: 'Disk read-ahead buffer (${_settings.fileCachingMs}ms).',
            metaKey: 'file_caching',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: '${_settings.fileCachingMs}ms',
              items: const ['300ms', '1000ms', '2000ms'],
              onChanged: (val) => _settings.setFileCachingMs(int.parse(val!.replaceAll('ms', ''))),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];

      case SettingsCategory.performanceMemory:
        return [
          _buildSettingCard(
            title: 'Decoder Multi-Threading Threads',
            description: _settings.threadPoolCount == 0 ? 'Auto-Detect CPU Cores' : '${_settings.threadPoolCount} Threads',
            metaKey: 'thread_pool_count',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.threadPoolCount == 0 ? 'Auto' : '${_settings.threadPoolCount}',
              items: const ['Auto', '2', '4', '8', '16'],
              onChanged: (val) => _settings.setThreadPoolCount(val == 'Auto' ? 0 : int.parse(val!)),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
          _buildSettingCard(
            title: 'Memory Cache Ceiling',
            description: 'Maximum RAM allocated for frame buffers (${_settings.memoryCacheLimitMb}MB).',
            metaKey: 'memory_cache_limit',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: '${_settings.memoryCacheLimitMb}MB',
              items: const ['256MB', '512MB', '1024MB', '2048MB'],
              onChanged: (val) => _settings.setMemoryCacheLimitMb(int.parse(val!.replaceAll('MB', ''))),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];

      case SettingsCategory.networkStreaming:
        return [
          _buildSettingCard(
            title: 'Enable UPnP / DLNA Discovery',
            description: 'Find local media servers and smart renderers on Wi-Fi.',
            metaKey: 'upnp_discovery',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.enableUpnpDiscovery,
              activeColor: colors.accent.primary,
              onChanged: (val) => setState(() {}),
            ),
          ),
          _buildSettingCard(
            title: 'RTSP Interleaved over TCP',
            description: 'Enforce TCP encapsulation for RTSP camera streams.',
            metaKey: 'rtsp_tcp',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.rtspOverTcp,
              activeColor: colors.accent.primary,
              onChanged: (val) => setState(() {}),
            ),
          ),
        ];

      case SettingsCategory.playlistPlayback:
        return [
          _buildSettingCard(
            title: 'Auto-Play Next in Queue',
            description: 'Seamless continuous playback of subsequent tracks/episodes.',
            metaKey: 'autoplay_next',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.autoPlayNextItem,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setAutoPlayNextItem(val),
            ),
          ),
          _buildSettingCard(
            title: 'Pause When Window Minimized',
            description: 'Halt playback when the main window is hidden.',
            metaKey: 'pause_on_minimize',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.pauseOnMinimize,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setPauseOnMinimize(val),
            ),
          ),
          _buildSettingCard(
            title: 'Watched Mark Threshold',
            description: 'Auto-mark watched once reached (${_settings.watchedResumeThresholdPercent}%).',
            metaKey: 'watched_threshold',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: '${_settings.watchedResumeThresholdPercent}%',
              items: const ['80%', '85%', '90%', '95%'],
              onChanged: (val) => _settings.setWatchedResumeThresholdPercent(int.parse(val!.replaceAll('%', ''))),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];

      case SettingsCategory.mediaLibrary:
        return [
          _buildSettingCard(
            title: 'Scan Folders on Startup',
            description: 'Re-index watched directories when VLC launches.',
            metaKey: 'autoscan_startup',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.autoScanLibraryOnStartup,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setAutoScanLibraryOnStartup(val),
            ),
          ),
          _buildSettingCard(
            title: 'Live Directory Watching',
            description: 'Instant indexing of files dropped into folders.',
            metaKey: 'watch_folders_live',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.watchLibraryFoldersLive,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setWatchLibraryFoldersLive(val),
            ),
          ),
        ];

      case SettingsCategory.hotkeysShortcuts:
        return [
          _buildSettingCard(
            title: 'Global Hardware Media Keys',
            description: 'Respond to Play/Pause & Skip even when VLC is unfocused.',
            metaKey: 'global_media_keys',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.globalMediaKeysEnabled,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setGlobalMediaKeysEnabled(val),
            ),
          ),
          _buildSettingCard(
            title: 'Mouse Scroll Wheel Action',
            description: 'Primary action when scrolling over playback canvas.',
            metaKey: 'mouse_wheel_action',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.mouseWheelAction,
              items: const ['Volume Control', 'Position Scrub', 'Zoom'],
              onChanged: (val) => _settings.setMouseWheelAction(val!),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];

      case SettingsCategory.privacySecurity:
        return [
          _buildSettingCard(
            title: 'Save Recently Played Media',
            description: 'Keep history for Continue Watching and Recents list.',
            metaKey: 'save_recent_media',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.saveRecentlyPlayedMedia,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setSaveRecentlyPlayedMedia(val),
            ),
          ),
          _buildSettingCard(
            title: 'Anonymous Usage Telemetry',
            description: 'Share anonymous usage metrics with VideoLAN.',
            metaKey: 'telemetry',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.anonymousTelemetry,
              activeColor: colors.accent.primary,
              onChanged: (val) => setState(() {}),
            ),
          ),
        ];

      case SettingsCategory.advancedEngine:
        return [
          _buildSettingCard(
            title: 'Engine Logging Verbosity',
            description: 'Log detail captured from libVLC engine.',
            metaKey: 'log_verbosity',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: _settings.logVerbosityLevel,
              items: const ['Silent', 'Error', 'Warning', 'Info', 'Debug'],
              onChanged: (val) => _settings.setLogVerbosityLevel(val!),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];
    }
  }

  // ==========================================
  // Advanced Settings per Category (Continuous Scroll)
  // ==========================================
  List<Widget> _buildCategoryAdvancedSettings(
    SettingsCategory cat,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    switch (cat) {
      case SettingsCategory.interfaceAppearance:
        return [
          _buildSettingCard(
            title: 'Window Vibrancy & Backdrop Blur',
            description: 'Enable native desktop glass and acrylic translucency.',
            metaKey: 'acrylic_vibrancy',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.acrylicWindowVibrancy,
              activeColor: colors.accent.primary,
              onChanged: (val) => setState(() {}),
            ),
          ),
        ];

      case SettingsCategory.audioOutput:
        return [
          _buildSettingCard(
            title: 'Audio Resampling Quality',
            description: 'DSP algorithm for sample rate conversion.',
            metaKey: 'audio_resampler',
            colors: colors,
            vlcTheme: vlcTheme,
            control: _buildDropdownButton(
              value: 'High Quality (Speex)',
              items: const ['Speed (Linear)', 'High Quality (Speex)', 'Studio (SOXR)'],
              onChanged: (val) => setState(() {}),
              colors: colors,
              vlcTheme: vlcTheme,
            ),
          ),
        ];

      case SettingsCategory.videoAcceleration:
        return [
          _buildSettingCard(
            title: 'Zero-Copy Direct GPU Surfaces',
            description: 'Zero memory copies from decoder surface to Impeller GPU.',
            metaKey: 'zero_copy_textures',
            colors: colors,
            vlcTheme: vlcTheme,
            control: Switch(
              value: _settings.zeroCopyGpuTextures,
              activeColor: colors.accent.primary,
              onChanged: (val) => _settings.setZeroCopyGpuTextures(val),
            ),
          ),
        ];

      case SettingsCategory.advancedEngine:
      default:
        return [
          _buildSettingCard(
            title: 'Custom libVLC Command-Line Flags',
            description: 'Direct arguments passed to libvlc_new() initialization.',
            metaKey: 'custom_libvlc_args',
            colors: colors,
            vlcTheme: vlcTheme,
            control: SizedBox(
              width: 260.0,
              child: TextField(
                controller: TextEditingController(text: _settings.customLibVlcLaunchArgs),
                onSubmitted: (val) => _settings.setCustomLibVlcLaunchArgs(val),
                style: vlcTheme.typography.monospaceTime.copyWith(
                  fontSize: 11.0,
                  color: colors.accent.primary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  border: OutlineInputBorder(
                    borderRadius: VlcGeometry.borderRadiusSmall,
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ),
          ),
        ];
    }
  }

  // ==========================================
  // Search Results View
  // ==========================================
  Widget _buildSearchResults(VlcColors colors, VlcThemeData vlcTheme) {
    final results = _settings.search(_searchQuery);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48.0, color: colors.textTertiary),
            const SizedBox(height: 12.0),
            Text(
              'No settings match "$_searchQuery"',
              style: vlcTheme.typography.titleSmall.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Try searching for terms like "hardware", "audio", "subtitles", or "caching".',
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: results.length + 1,
      itemBuilder: (ctx, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Text(
                  'SEARCH RESULTS (${results.length})',
                  style: vlcTheme.typography.labelSmall.copyWith(
                    color: colors.accent.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(child: Divider(color: colors.border, height: 1.0)),
              ],
            ),
          );
        }

        final meta = results[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.35),
            borderRadius: VlcGeometry.borderRadiusMedium,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: colors.accent.primary.withOpacity(0.18),
                            borderRadius: VlcGeometry.borderRadiusSmall,
                          ),
                          child: Text(
                            meta.category.label,
                            style: vlcTheme.typography.labelSmall.copyWith(
                              fontSize: 10.0,
                              color: colors.accent.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (meta.isAdvanced) ...[
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: colors.surfaceHover,
                              borderRadius: VlcGeometry.borderRadiusSmall,
                            ),
                            child: Text(
                              'ADVANCED',
                              style: vlcTheme.typography.labelSmall.copyWith(
                                fontSize: 9.0,
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      meta.title,
                      style: vlcTheme.typography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      meta.description,
                      style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              IconButton(
                icon: Icon(Icons.info_outline, size: 18.0, color: colors.accent.primary),
                tooltip: 'Setting Info & Flag',
                onPressed: () => _showInfoTooltip(context, meta),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // Common Setting Row Card
  // ==========================================
  Widget _buildSettingCard({
    required String title,
    required String description,
    required String metaKey,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
    required Widget control,
  }) {
    final meta = SettingsService.catalog.firstWhere(
      (m) => m.key == metaKey,
      orElse: () => SettingItemMeta(
        key: metaKey,
        title: title,
        description: description,
        tooltip: description,
        libvlcFlag: '--$metaKey',
        category: _selectedCategory,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        borderRadius: VlcGeometry.borderRadiusMedium,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: vlcTheme.typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    // ⓘ interactive info tooltip
                    IconButton(
                      icon: Icon(Icons.info_outline, size: 16.0, color: colors.textTertiary),
                      tooltip: 'View details & libVLC flag',
                      onPressed: () => _showInfoTooltip(context, meta),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  description,
                  style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          control,
        ],
      ),
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
  }) {
    return Container(
      height: 36.0,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: VlcGeometry.borderRadiusSmall,
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down, size: 16.0, color: colors.textSecondary),
          style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}

