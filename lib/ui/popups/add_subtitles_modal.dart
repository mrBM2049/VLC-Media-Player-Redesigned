import 'package:flutter/material.dart';
import '../../models/subtitle_models.dart';
import '../../services/opensubtitles_service.dart';
import '../../services/subtitle_matcher_service.dart';
import '../../theme/vlc_theme.dart';

/// AddSubtitlesModal — Comprehensive modal offering Local File Scope selection,
/// OpenSubtitles REST API search, and Batch Season/Episode fuzzy matching.
class AddSubtitlesModal extends StatefulWidget {
  final String currentVideoPath;
  final List<String> folderVideoPaths;
  final List<String> playlistVideoPaths;
  final ValueChanged<String> onApplySingleSubtitle;
  final ValueChanged<List<BatchSubtitleMatch>> onApplyBatchSubtitles;
  final OpenSubtitlesService? openSubtitlesService;

  const AddSubtitlesModal({
    super.key,
    required this.currentVideoPath,
    this.folderVideoPaths = const [],
    this.playlistVideoPaths = const [],
    required this.onApplySingleSubtitle,
    required this.onApplyBatchSubtitles,
    this.openSubtitlesService,
  });

  @override
  State<AddSubtitlesModal> createState() => _AddSubtitlesModalState();
}

class _AddSubtitlesModalState extends State<AddSubtitlesModal> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final OpenSubtitlesService _subService;

  // Local Tab State
  SubtitleScope _selectedScope = SubtitleScope.thisFile;
  String? _selectedLocalFilePath;

  // Online Tab State
  final _searchController = TextEditingController();
  String _selectedLanguage = 'en';
  bool _hearingImpairedOnly = false;
  bool _isSearching = false;
  List<OnlineSubtitleResult> _searchResults = [];

  // Batch Matcher Tab State
  List<String> _droppedSubtitlePaths = [];
  List<BatchSubtitleMatch> _batchMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subService = widget.openSubtitlesService ?? OpenSubtitlesService();

    final videoName = widget.currentVideoPath.split(RegExp(r'[\\/]')).last;
    final meta = SubtitleMatcherService.parseFilename(videoName);
    _searchController.text = meta.cleanedTitle;

    // Trigger initial search with clean video title
    _performOnlineSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performOnlineSearch() async {
    setState(() => _isSearching = true);
    final results = await _subService.search(
      query: _searchController.text,
      language: _selectedLanguage,
      hearingImpairedOnly: _hearingImpairedOnly,
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _runBatchMatcher(List<String> subPaths) {
    _droppedSubtitlePaths = subPaths;
    final targetVideos = _selectedScope == SubtitleScope.thisPlaylist
        ? widget.playlistVideoPaths
        : widget.folderVideoPaths;

    final matches = SubtitleMatcherService.batchMatch(
      videoPaths: targetVideos.isNotEmpty ? targetVideos : [widget.currentVideoPath],
      subtitlePaths: _droppedSubtitlePaths,
    );

    setState(() {
      _batchMatches = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final typography = vlcTheme.typography;
    final accent = colors.accent.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
      child: Container(
        width: 680.0,
        height: 540.0,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VlcGeometry.radiusMedium),
          border: Border.all(color: colors.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24.0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Modal Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(VlcGeometry.radiusMedium),
                ),
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  VlcMonochromeIcon(
                    VlcIconGlyph.subtitles,
                    size: 18.0,
                    color: accent,
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    'ADD SUBTITLES',
                    style: typography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: VlcMonochromeIcon(
                      VlcIconGlyph.close,
                      size: 16.0,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: colors.surfaceVariant,
              child: TabBar(
                controller: _tabController,
                indicatorColor: accent,
                indicatorWeight: 2.0,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: accent,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: typography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Local File & Scope'),
                  Tab(text: 'Online Search (OpenSubtitles)'),
                  Tab(text: 'Batch Auto-Matcher'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLocalScopeTab(colors, typography),
                  _buildOnlineSearchTab(colors, typography),
                  _buildBatchMatcherTab(colors, typography),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: LOCAL FILE & SCOPE ---
  Widget _buildLocalScopeTab(VlcColors colors, VlcTypography typography) {
    final videoName = widget.currentVideoPath.split(RegExp(r'[\\/]')).last;
    final accent = colors.accent.primary;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Media',
            style: typography.labelSmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.movie_outlined, size: 16.0, color: accent),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    videoName,
                    style: typography.bodyMedium.copyWith(color: colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20.0),

          Text(
            'Select Subtitle Scope',
            style: typography.labelSmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8.0),

          // Scope cards
          Row(
            children: SubtitleScope.values.map((scope) {
              final isSelected = scope == _selectedScope;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedScope = scope),
                    borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                    child: Container(
                      height: 72.0,
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accent.subtleBackground : colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                        border: Border.all(
                          color: isSelected ? accent : colors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 14.0,
                                color: isSelected ? accent : colors.textDisabled,
                              ),
                              const SizedBox(width: 6.0),
                              Expanded(
                                child: Text(
                                  scope.label,
                                  style: typography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? accent : colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            scope == SubtitleScope.thisFile
                                ? 'Single playback'
                                : scope == SubtitleScope.thisFolder
                                    ? '${widget.folderVideoPaths.length} videos'
                                    : '${widget.playlistVideoPaths.length} items',
                            style: typography.labelSmall.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24.0),

          Text(
            'Subtitle File',
            style: typography.labelSmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8.0),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38.0,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    _selectedLocalFilePath != null
                        ? _selectedLocalFilePath!.split(RegExp(r'[\\/]')).last
                        : 'No subtitle file chosen (.srt, .sub, .vtt, .ass)',
                    style: typography.bodySmall.copyWith(
                      color: _selectedLocalFilePath != null ? colors.textPrimary : colors.textDisabled,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.surfaceVariant,
                  foregroundColor: colors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                    side: BorderSide(color: colors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                onPressed: () {
                  // Simulate file picker selection or emit file
                  setState(() {
                    _selectedLocalFilePath = '${widget.currentVideoPath.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')}.srt';
                  });
                },
                icon: const Icon(Icons.folder_open, size: 16.0),
                label: const Text('Browse...'),
              ),
            ],
          ),

          const Spacer(),

          // Apply Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              ),
              onPressed: _selectedLocalFilePath != null
                  ? () {
                      if (_selectedScope == SubtitleScope.thisFile) {
                        widget.onApplySingleSubtitle(_selectedLocalFilePath!);
                      } else {
                        _runBatchMatcher([_selectedLocalFilePath!]);
                        _tabController.animateTo(2);
                      }
                      Navigator.of(context).pop();
                    }
                  : null,
              child: Text(
                _selectedScope == SubtitleScope.thisFile ? 'Apply Subtitle' : 'Proceed to Batch Match',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: ONLINE SEARCH ---
  Widget _buildOnlineSearchTab(VlcColors colors, VlcTypography typography) {
    final accent = colors.accent.primary;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Search & Filter Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38.0,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13.0),
                    decoration: InputDecoration(
                      hintText: 'Search title or episode on OpenSubtitles...',
                      hintStyle: TextStyle(color: colors.textDisabled, fontSize: 13.0),
                      prefixIcon: const Icon(Icons.search, size: 18.0),
                      filled: true,
                      fillColor: colors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                    onSubmitted: (_) => _performOnlineSearch(),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Language selector
              Container(
                height: 38.0,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: colors.surfaceVariant,
                    style: TextStyle(color: colors.textPrimary, fontSize: 12.0),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'es', child: Text('Spanish')),
                      DropdownMenuItem(value: 'fr', child: Text('French')),
                      DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                      DropdownMenuItem(value: 'all', child: Text('All Languages')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                        _performOnlineSearch();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                onPressed: _performOnlineSearch,
                child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // SDH Checkbox
          Row(
            children: [
              Checkbox(
                value: _hearingImpairedOnly,
                activeColor: accent,
                checkColor: Colors.black,
                onChanged: (val) {
                  setState(() => _hearingImpairedOnly = val ?? false);
                  _performOnlineSearch();
                },
              ),
              Text(
                'Hearing Impaired (SDH) only',
                style: typography.labelSmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Results List
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator(color: accent))
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'No online subtitles found. Try adjusting query or language.',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6.0),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
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
                                              item.title,
                                              style: typography.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                            decoration: BoxDecoration(
                                              color: colors.surface,
                                              borderRadius: BorderRadius.circular(3.0),
                                              border: Border.all(color: colors.border, width: 0.5),
                                            ),
                                            child: Text(
                                              item.language.toUpperCase(),
                                              style: TextStyle(color: accent, fontSize: 10.0, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (item.hearingImpaired) ...[
                                            const SizedBox(width: 4.0),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(3.0),
                                              ),
                                              child: const Text(
                                                'SDH',
                                                style: TextStyle(color: Colors.blueAccent, fontSize: 9.0, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'Release: ${item.releaseName} • By ${item.uploader} • ★ ${item.rating} (${item.downloadCount} dl)',
                                        style: typography.labelSmall.copyWith(color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                                      side: BorderSide(color: accent),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                  ),
                                  onPressed: () {
                                    widget.onApplySingleSubtitle(item.downloadUrl);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Download & Apply', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: BATCH MATCH TABLE ---
  Widget _buildBatchMatcherTab(VlcColors colors, VlcTypography typography) {
    final accent = colors.accent.primary;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Batch Season & Episode Matcher',
                  style: typography.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: colors.surfaceVariant,
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                  ),
                ),
                onPressed: () {
                  // Simulate scanning folder for subtitles
                  final folderSubs = widget.folderVideoPaths.map((v) {
                    return v.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '.srt');
                  }).toList();
                  _runBatchMatcher(folderSubs);
                },
                icon: const Icon(Icons.refresh, size: 14.0),
                label: const Text('Auto-Scan Subtitles', style: TextStyle(fontSize: 12.0)),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Batch Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            color: colors.surfaceVariant,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Video File', style: TextStyle(color: colors.textSecondary, fontSize: 11.0, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Matched Subtitle', style: TextStyle(color: colors.textSecondary, fontSize: 11.0, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 90.0,
                  child: Text('Confidence', style: TextStyle(color: colors.textSecondary, fontSize: 11.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Matches List
          Expanded(
            child: _batchMatches.isEmpty
                ? Center(
                    child: Text(
                      'No batch matches calculated yet.\nClick "Auto-Scan Subtitles" or browse for files in Tab 1.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12.0),
                    ),
                  )
                : ListView.builder(
                    itemCount: _batchMatches.length,
                    itemBuilder: (context, index) {
                      final match = _batchMatches[index];
                      final scorePct = (match.matchScore * 100).toInt();
                      final isHigh = scorePct >= 80;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                match.videoFileName,
                                style: TextStyle(color: colors.textPrimary, fontSize: 12.0),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_right_alt, size: 16.0, color: Colors.grey),
                            const SizedBox(width: 8.0),
                            Expanded(
                              flex: 3,
                              child: Text(
                                match.subtitleFileName,
                                style: TextStyle(color: accent, fontSize: 12.0),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 90.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: isHigh ? colors.accent.subtleBackground : Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(3.0),
                                  border: Border.all(
                                    color: isHigh ? accent : Colors.red,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '$scorePct% match',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isHigh ? accent : Colors.redAccent,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12.0),

          // Apply All Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              ),
              onPressed: _batchMatches.isNotEmpty
                  ? () {
                      widget.onApplyBatchSubtitles(_batchMatches);
                      Navigator.of(context).pop();
                    }
                  : null,
              icon: const Icon(Icons.done_all, size: 16.0),
              label: Text(
                'Apply ${_batchMatches.length} Batch Matches',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
