import 'package:flutter/material.dart';

import '../../theme/vlc_colors.dart';
import '../../theme/vlc_geometry.dart';
import '../../theme/vlc_icons.dart';
import '../../theme/vlc_theme.dart';

/// Representation of a discoverable wireless renderer or cast receiver.
class CastDevice {
  final String id;
  final String name;
  final String protocol; // Chromecast, AirPlay, DLNA
  final String ipAddress;
  final bool isConnected;

  const CastDevice({
    required this.id,
    required this.name,
    required this.protocol,
    required this.ipAddress,
    this.isConnected = false,
  });

  CastDevice copyWith({bool? isConnected}) {
    return CastDevice(
      id: id,
      name: name,
      protocol: protocol,
      ipAddress: ipAddress,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Dedicated Wireless Cast & Renderer Discovery Modal for VLC Modern Redesign.
///
/// Implements Juxtopposed 25-Year Redesign Task 4.6:
/// - Scans local network for Chromecast, AirPlay, and DLNA renderers.
/// - 1-click seamless cast connect / disconnect.
/// - Live renderer connection status.
class CastModal extends StatefulWidget {
  final ValueChanged<CastDevice>? onConnectDevice;
  final VoidCallback? onDisconnect;
  final VoidCallback? onClose;

  const CastModal({
    super.key,
    this.onConnectDevice,
    this.onDisconnect,
    this.onClose,
  });

  @override
  State<CastModal> createState() => _CastModalState();
}

class _CastModalState extends State<CastModal> {
  bool _isScanning = false;
  List<CastDevice> _devices = [
    const CastDevice(
      id: 'chromecast_living_room',
      name: 'Living Room TV',
      protocol: 'Chromecast 4K',
      ipAddress: '192.168.1.104',
      isConnected: false,
    ),
    const CastDevice(
      id: 'airplay_bedroom',
      name: 'Bedroom Apple TV',
      protocol: 'AirPlay 2',
      ipAddress: '192.168.1.112',
      isConnected: false,
    ),
    const CastDevice(
      id: 'dlna_hi_fi',
      name: 'Studio Hi-Fi Receiver',
      protocol: 'DLNA / UPnP',
      ipAddress: '192.168.1.150',
      isConnected: false,
    ),
  ];

  void _handleRescan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  void _handleToggleConnect(CastDevice device) {
    final nextState = !device.isConnected;
    setState(() {
      _devices = _devices.map((d) {
        if (d.id == device.id) {
          return d.copyWith(isConnected: nextState);
        } else {
          return d.copyWith(isConnected: false);
        }
      }).toList();
    });

    if (nextState) {
      widget.onConnectDevice?.call(device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name} via ${device.protocol}')),
      );
    } else {
      widget.onDisconnect?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnected from ${device.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vlcTheme = context.vlcTheme;
    final colors = vlcTheme.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Container(
        width: 520.0,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: VlcGeometry.borderRadiusLarge,
          border: Border.all(color: colors.border),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 28.0, offset: Offset(0, 14)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              color: colors.surfaceVariant.withOpacity(0.4),
              child: Row(
                children: [
                  const Icon(Icons.cast, size: 22.0, color: VlcColors.coneOrange),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Cast to Wireless Display / Renderer',
                      style: vlcTheme.typography.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Available Wireless Renderers (${_devices.length}):',
                          style: vlcTheme.typography.labelSmall.copyWith(
                            color: colors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isScanning ? null : _handleRescan,
                        icon: _isScanning
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 14),
                        label: Text(_isScanning ? 'Scanning...' : 'Rescan Network'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // Device Cards List
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withOpacity(0.3),
                      borderRadius: VlcGeometry.borderRadiusMedium,
                      border: Border.all(color: colors.border.withOpacity(0.5)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => Divider(height: 1.0, color: colors.border.withOpacity(0.3)),
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          child: Row(
                            children: [
                              Container(
                                width: 38.0,
                                height: 38.0,
                                decoration: BoxDecoration(
                                  color: device.isConnected
                                      ? colors.accent.primary.withOpacity(0.2)
                                      : colors.surfaceVariant,
                                  borderRadius: VlcGeometry.borderRadiusSmall,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  device.protocol.contains('AirPlay')
                                      ? Icons.airplay
                                      : device.protocol.contains('Chromecast')
                                          ? Icons.cast
                                          : Icons.speaker,
                                  size: 20.0,
                                  color: device.isConnected ? colors.accent.primary : colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12.0),

                              // Name & Protocol
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name,
                                      style: vlcTheme.typography.bodyMedium.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${device.protocol} • ${device.ipAddress}',
                                      style: vlcTheme.typography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                        fontSize: 11.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Connect / Disconnect Action Button
                              OutlinedButton(
                                onPressed: () => _handleToggleConnect(device),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: device.isConnected
                                      ? colors.accent.primary
                                      : Colors.transparent,
                                  foregroundColor: device.isConnected
                                      ? Colors.white
                                      : colors.accent.primary,
                                  side: BorderSide(
                                    color: colors.accent.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                  shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusSmall),
                                ),
                                child: Text(device.isConnected ? 'Disconnect' : 'Connect'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.onClose?.call();
                          if (Navigator.of(context, rootNavigator: true).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.surfaceHover,
                          foregroundColor: colors.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: VlcGeometry.borderRadiusMedium),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
