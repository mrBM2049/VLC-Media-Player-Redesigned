import 'package:flutter/material.dart';
import '../../models/toolbar_customizer_models.dart';
import '../../theme/theme.dart';

/// Reimagined Drag-and-Drop Interface Customizer with switchable User Profiles.
///
/// Features:
/// - Visual dashed drop zones for Top Bar and Bottom Transport Row.
/// - Available Tool Palette with `Draggable<ToolbarButtonId>` primitives.
/// - Instant profile switching across Standard, Minimalist, Power User, and Music.
/// - Reordering and 1-click removal of toolbar items.
class DragDropLayoutCustomizer extends StatefulWidget {
  final ToolbarProfile? initialProfile;
  final ValueChanged<ToolbarProfile>? onProfileSaved;
  final VoidCallback? onClose;

  const DragDropLayoutCustomizer({
    super.key,
    this.initialProfile,
    this.onProfileSaved,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    ToolbarProfile? profile,
    ValueChanged<ToolbarProfile>? onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DragDropLayoutCustomizer(
        initialProfile: profile,
        onProfileSaved: onSave,
      ),
    );
  }

  @override
  State<DragDropLayoutCustomizer> createState() => _DragDropLayoutCustomizerState();
}

class _DragDropLayoutCustomizerState extends State<DragDropLayoutCustomizer> {
  late ToolbarProfile _activeProfile;
  late List<ToolbarButtonId> _topBarButtons;
  late List<ToolbarButtonId> _bottomBarButtons;

  bool _isHoveringTopZone = false;
  bool _isHoveringBottomZone = false;

  @override
  void initState() {
    super.initState();
    _activeProfile = widget.initialProfile ?? ToolbarProfile.standard;
    _topBarButtons = List.from(_activeProfile.topBarButtons);
    _bottomBarButtons = List.from(_activeProfile.bottomBarButtons);
  }

  void _switchProfile(ToolbarProfile profile) {
    setState(() {
      _activeProfile = profile;
      _topBarButtons = List.from(profile.topBarButtons);
      _bottomBarButtons = List.from(profile.bottomBarButtons);
    });
    _notifySave();
  }

  void _notifySave() {
    final updated = _activeProfile.copyWith(
      topBarButtons: _topBarButtons,
      bottomBarButtons: _bottomBarButtons,
    );
    widget.onProfileSaved?.call(updated);
  }

  void _handleReset() {
    _switchProfile(ToolbarProfile.standard);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toolbars reset to Standard layout.')),
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
        width: 920.0,
        height: 660.0,
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
            // Header Bar
            _buildHeader(colors, vlcTheme),

            // Main Customization Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Player Bar Drop Zone
                    _buildDropZone(
                      title: 'Top Player Bar Layout',
                      buttons: _topBarButtons,
                      isHovered: _isHoveringTopZone,
                      colors: colors,
                      vlcTheme: vlcTheme,
                      onWillAccept: (btn) {
                        setState(() => _isHoveringTopZone = true);
                        return true;
                      },
                      onLeave: (_) => setState(() => _isHoveringTopZone = false),
                      onAccept: (btn) {
                        setState(() {
                          _isHoveringTopZone = false;
                          _topBarButtons.add(btn);
                        });
                        _notifySave();
                      },
                      onRemove: (idx) {
                        setState(() => _topBarButtons.removeAt(idx));
                        _notifySave();
                      },
                    ),

                    const SizedBox(height: 20.0),

                    // Bottom Transport Row Drop Zone
                    _buildDropZone(
                      title: 'Bottom Transport Row Layout',
                      buttons: _bottomBarButtons,
                      isHovered: _isHoveringBottomZone,
                      colors: colors,
                      vlcTheme: vlcTheme,
                      onWillAccept: (btn) {
                        setState(() => _isHoveringBottomZone = true);
                        return true;
                      },
                      onLeave: (_) => setState(() => _isHoveringBottomZone = false),
                      onAccept: (btn) {
                        setState(() {
                          _isHoveringBottomZone = false;
                          _bottomBarButtons.add(btn);
                        });
                        _notifySave();
                      },
                      onRemove: (idx) {
                        setState(() => _bottomBarButtons.removeAt(idx));
                        _notifySave();
                      },
                    ),

                    const SizedBox(height: 24.0),

                    // Available Tool Palette Header
                    Row(
                      children: [
                        Icon(Icons.widgets_outlined, size: 18.0, color: colors.accent.primary),
                        const SizedBox(width: 8.0),
                        Text(
                          'AVAILABLE TOOL PALETTE (Drag into bars above)',
                          style: vlcTheme.typography.labelSmall.copyWith(
                            color: colors.accent.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(child: Divider(color: colors.border, height: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    // Draggable Tool Palette
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant.withOpacity(0.3),
                          borderRadius: VlcGeometry.borderRadiusMedium,
                          border: Border.all(color: colors.border),
                        ),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: ToolbarButtonId.values.map((btn) {
                              return _buildDraggableTool(btn, colors, vlcTheme);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Header Bar with Profile Selector
  // ==========================================
  Widget _buildHeader(VlcColors colors, VlcThemeData vlcTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      color: colors.surfaceVariant.withOpacity(0.4),
      child: Row(
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 22.0, color: colors.accent.primary),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Customize Interface & Toolbars',
              style: vlcTheme.typography.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16.0),

          // User Profile Dropdown
          Text('Profile: ', style: vlcTheme.typography.bodySmall.copyWith(color: colors.textSecondary)),
          Container(
            height: 36.0,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: VlcGeometry.borderRadiusSmall,
              border: Border.all(color: colors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _activeProfile.id,
                dropdownColor: colors.surface,
                icon: Icon(Icons.keyboard_arrow_down, size: 16.0, color: colors.textSecondary),
                style: vlcTheme.typography.bodySmall.copyWith(color: colors.textPrimary),
                onChanged: (id) {
                  final found = ToolbarProfile.defaultProfiles.firstWhere((p) => p.id == id);
                  _switchProfile(found);
                },
                items: ToolbarProfile.defaultProfiles.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(p.name),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12.0),

          // Reset Button
          OutlinedButton(
            onPressed: _handleReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusSmall),
            ),
            child: const Text('Reset Layout'),
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
  // Dashed Drop Zone Container
  // ==========================================
  Widget _buildDropZone({
    required String title,
    required List<ToolbarButtonId> buttons,
    required bool isHovered,
    required VlcColors colors,
    required VlcThemeData vlcTheme,
    required bool Function(ToolbarButtonId) onWillAccept,
    required void Function(ToolbarButtonId?) onLeave,
    required void Function(ToolbarButtonId) onAccept,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: vlcTheme.typography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              '(${buttons.length} items)',
              style: vlcTheme.typography.bodySmall.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        DragTarget<ToolbarButtonId>(
          onWillAcceptWithDetails: (details) => onWillAccept(details.data),
          onLeave: onLeave,
          onAcceptWithDetails: (details) => onAccept(details.data),
          builder: (ctx, candidateData, rejectedData) {
            return CustomPaint(
              painter: _DashedBorderPainter(
                color: isHovered ? colors.accent.primary : colors.border,
                strokeWidth: isHovered ? 2.0 : 1.5,
                gap: 6.0,
                radius: 8.0,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 58.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isHovered
                      ? colors.accent.primary.withOpacity(0.08)
                      : colors.surfaceVariant.withOpacity(0.25),
                  borderRadius: VlcGeometry.borderRadiusMedium,
                ),
                child: buttons.isEmpty
                    ? Center(
                        child: Text(
                          'Drop buttons here to add them to this bar',
                          style: vlcTheme.typography.bodySmall.copyWith(
                            color: colors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: List.generate(buttons.length, (idx) {
                          final btn = buttons[idx];
                          return _buildActiveButtonChip(btn, idx, onRemove, colors, vlcTheme);
                        }),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveButtonChip(
    ToolbarButtonId btn,
    int index,
    void Function(int) onRemove,
    VlcColors colors,
    VlcThemeData vlcTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusSmall,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(btn.icon, size: 14.0, color: colors.accent.primary),
          const SizedBox(width: 6.0),
          Text(
            btn.label,
            style: vlcTheme.typography.bodySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6.0),
          InkWell(
            onTap: () => onRemove(index),
            borderRadius: BorderRadius.circular(10.0),
            child: Icon(Icons.close, size: 14.0, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTool(ToolbarButtonId btn, VlcColors colors, VlcThemeData vlcTheme) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: VlcGeometry.borderRadiusSmall,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(btn.icon, size: 16.0, color: colors.accent.primary),
          const SizedBox(width: 8.0),
          Text(
            btn.label,
            style: vlcTheme.typography.bodySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return Draggable<ToolbarButtonId>(
      data: btn,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: VlcGeometry.borderRadiusSmall,
            border: Border.all(color: colors.accent.primary, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: colors.accent.primary.withOpacity(0.35),
                blurRadius: 16.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(btn.icon, size: 18.0, color: colors.accent.primary),
              const SizedBox(width: 8.0),
              Text(
                btn.label,
                style: vlcTheme.typography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: chip,
      ),
    );
  }
}

/// Custom painter for dashed border drop zones.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + gap;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
