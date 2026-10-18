import 'package:flutter/material.dart';
import '../../models/subtitle_models.dart';
import '../../theme/vlc_theme.dart';

/// SubtitleQuickPopup — Instant desktop flyout / mobile sheet for switching subtitle tracks
/// and micro-adjusting SPU delay in milliseconds.
class SubtitleQuickPopup extends StatelessWidget {
  final List<VlcSubtitleTrack> tracks;
  final int selectedTrackId;
  final Duration currentDelay;
  final ValueChanged<int> onSelectTrack;
  final ValueChanged<Duration> onDelayChanged;
  final VoidCallback onOpenAddSubtitles;
  final VoidCallback? onOpenInspector;
  final VoidCallback? onClose;

  const SubtitleQuickPopup({
    super.key,
    required this.tracks,
    required this.selectedTrackId,
    required this.currentDelay,
    required this.onSelectTrack,
    required this.onDelayChanged,
    required this.onOpenAddSubtitles,
    this.onOpenInspector,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;
    final typography = vlcTheme.typography;
    final delayMs = currentDelay.inMilliseconds;
    final accent = colors.accent.primary;

    final allTracks = [
      VlcSubtitleTrack.disabled,
      ...tracks,
    ];

    return Container(
      width: 340.0,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(VlcGeometry.radiusMedium),
        border: Border.all(color: colors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  VlcMonochromeIcon(
                    VlcIconGlyph.subtitles,
                    size: 16.0,
                    color: accent,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'SUBTITLES',
                    style: typography.titleSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  if (onClose != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                      onTap: onClose,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: VlcMonochromeIcon(
                          VlcIconGlyph.close,
                          size: 14.0,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1.0, thickness: 1.0),

            // Track List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180.0),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                itemCount: allTracks.length,
                itemBuilder: (context, index) {
                  final track = allTracks[index];
                  final isSelected = track.id == selectedTrackId;

                  return InkWell(
                    onTap: () => onSelectTrack(track.id),
                    child: Container(
                      height: 34.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      color: isSelected ? colors.accent.subtleBackground : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 14.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: isSelected ? accent : colors.textDisabled,
                                width: 1.5,
                              ),
                              color: isSelected ? accent : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check, size: 10.0, color: Colors.black),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              track.name,
                              style: typography.bodyMedium.copyWith(
                                color: isSelected ? accent : colors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (track.language != 'und' && track.language != 'none')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(3.0),
                                border: Border.all(color: colors.border, width: 0.5),
                              ),
                              child: Text(
                                track.language.toUpperCase(),
                                style: typography.labelSmall.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1.0, thickness: 1.0),

            // SPU Delay Stepper
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtitle Delay',
                        style: typography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                      Text(
                        '${delayMs >= 0 ? '+' : ''}$delayMs ms',
                        style: typography.monospaceTime.copyWith(
                          color: delayMs == 0 ? colors.textPrimary : accent,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildStepButton(
                        label: '-100ms',
                        onTap: () => onDelayChanged(currentDelay - const Duration(milliseconds: 100)),
                        colors: colors,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: '-50ms',
                        onTap: () => onDelayChanged(currentDelay - const Duration(milliseconds: 50)),
                        colors: colors,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: 'Reset',
                        onTap: () => onDelayChanged(Duration.zero),
                        colors: colors,
                        isAccent: delayMs != 0,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: '+50ms',
                        onTap: () => onDelayChanged(currentDelay + const Duration(milliseconds: 50)),
                        colors: colors,
                      ),
                      const SizedBox(width: 4.0),
                      _buildStepButton(
                        label: '+100ms',
                        onTap: () => onDelayChanged(currentDelay + const Duration(milliseconds: 100)),
                        colors: colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1.0, thickness: 1.0),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.surface,
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                      ),
                      onPressed: onOpenAddSubtitles,
                      icon: const Icon(Icons.add, size: 16.0),
                      label: const Text('Add Subtitles...', style: TextStyle(fontSize: 12.0)),
                    ),
                  ),
                  if (onOpenInspector != null) ...[
                    const SizedBox(width: 8.0),
                    IconButton(
                      tooltip: 'Advanced Subtitle Inspector',
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
                          side: BorderSide(color: colors.border),
                        ),
                      ),
                      onPressed: onOpenInspector,
                      icon: VlcMonochromeIcon(
                        VlcIconGlyph.settings,
                        size: 16.0,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required String label,
    required VoidCallback onTap,
    required VlcColors colors,
    bool isAccent = false,
  }) {
    final accent = colors.accent.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
        child: Container(
          height: 26.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isAccent ? colors.accent.subtleBackground : colors.surface,
            borderRadius: BorderRadius.circular(VlcGeometry.radiusSmall),
            border: Border.all(
              color: isAccent ? accent : colors.border,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: isAccent ? FontWeight.w700 : FontWeight.w500,
              color: isAccent ? accent : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
