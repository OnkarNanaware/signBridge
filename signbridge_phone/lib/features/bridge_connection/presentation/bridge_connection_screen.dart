import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';
import 'package:signbridge_phone/shared/widgets/panel_card.dart';
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Shows the Office Kit Bridge connection details, IP addresses, QR code,
/// and WebSocket server controls.
class BridgeConnectionScreen extends ConsumerStatefulWidget {
  const BridgeConnectionScreen({super.key});

  @override
  ConsumerState<BridgeConnectionScreen> createState() =>
      _BridgeConnectionScreenState();
}

class _BridgeConnectionScreenState
    extends ConsumerState<BridgeConnectionScreen> {
  List<Map<String, String>> _interfaces = [];
  String _primaryIp = '127.0.0.1';
  bool _isLoadingIps = true;

  @override
  void initState() {
    super.initState();
    _refreshIpAddresses();
    // Automatically start the server if not already running
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bridgeServiceProvider).startServer();
    });
  }

  Future<void> _refreshIpAddresses() async {
    setState(() => _isLoadingIps = true);
    final List<Map<String, String>> found = [];
    String chosenIp = '127.0.0.1';

    try {
      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final NetworkInterface iface in interfaces) {
        for (final InternetAddress addr in iface.addresses) {
          found.add({'name': iface.name, 'ip': addr.address});
          // Prioritise wlan (Wi-Fi) or rndis/usb (USB tethering)
          if (iface.name.toLowerCase().contains('wlan') ||
              iface.name.toLowerCase().contains('rndis') ||
              iface.name.toLowerCase().contains('usb') ||
              chosenIp == '127.0.0.1') {
            chosenIp = addr.address;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _interfaces = found;
        _primaryIp = chosenIp;
        _isLoadingIps = false;
      });
    }
  }

  String get _webSocketUri => 'ws://$_primaryIp:$kBridgePort';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<BridgeConnectionState> stateAsync =
        ref.watch(bridgeConnectionStateProvider);

    final BridgeConnectionState state = stateAsync.when(
      data: (BridgeConnectionState s) => s,
      loading: () => BridgeConnectionState.searching,
      error: (_, __) => BridgeConnectionState.error,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Kit Bridge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Network Interfaces',
            onPressed: _refreshIpAddresses,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server status & controls
          PanelCard(
            title: 'Server Status',
            icon: Icons.router_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow(state),
                const SizedBox(height: 12),
                Text(
                  'The phone hosts the offline WebSocket bridge on port $kBridgePort. '
                  'Connect the SignBridge Windows Dashboard over the same Wi-Fi or USB tether.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: state == BridgeConnectionState.connected ||
                                state == BridgeConnectionState.searching
                            ? null
                            : () =>
                                ref.read(bridgeServiceProvider).startServer(),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Server'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state == BridgeConnectionState.disconnected
                            ? null
                            : () =>
                                ref.read(bridgeServiceProvider).stopServer(),
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop Server'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // QR Code Card
          PanelCard(
            title: 'Scan or Connect',
            icon: Icons.qr_code_rounded,
            child: Column(
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _webSocketUri,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          _webSocketUri,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy WebSocket URL',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _webSocketUri));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bridge URI copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Network Interfaces Details
          PanelCard(
            title: 'Detected Network IP Addresses',
            icon: Icons.lan_rounded,
            child: _isLoadingIps
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _interfaces.isEmpty
                    ? Text(
                        'No Wi-Fi or USB network interface detected. Connect to Wi-Fi hotspot or enable USB tethering.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.statusError,
                        ),
                      )
                    : Column(
                        children: _interfaces.map((Map<String, String> iface) {
                          final bool isSelected = iface['ip'] == _primaryIp;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              iface['name']!.toLowerCase().contains('wlan')
                                  ? Icons.wifi_rounded
                                  : Icons.usb_rounded,
                              color: isSelected
                                  ? AppTheme.statusConnected
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            ),
                            title: Text(
                              '${iface['name']}: ${iface['ip']}',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const StatusChip(
                                    label: 'Active',
                                    color: AppTheme.statusConnected,
                                  )
                                : TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _primaryIp = iface['ip']!;
                                      });
                                    },
                                    child: const Text('Select'),
                                  ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 16),

          // USB Tethering Fallback Guide
          PanelCard(
            title: 'USB Tethering Fallback',
            icon: Icons.usb_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If Wi-Fi is unavailable or blocked by enterprise policies:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Connect phone to laptop with a USB cable.\n'
                  '2. On phone: Settings → Network & Internet → Hotspot & tethering → Enable "USB tethering".\n'
                  '3. Tap "Refresh" above to get the rndis0/usb0 IP (usually 192.168.42.129).\n'
                  '4. Alternatively, use ADB reverse forwarding:\n'
                  '   adb forward tcp:8765 tcp:8765\n'
                  '   and connect the dashboard to ws://127.0.0.1:8765.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BridgeConnectionState state) => Row(
        children: [
          switch (state) {
            BridgeConnectionState.connected => const StatusChip(
                label: 'Dashboard Connected',
                color: AppTheme.statusConnected,
                icon: Icons.check_circle_rounded,
              ),
            BridgeConnectionState.searching => const StatusChip(
                label: 'Server Listening on Port 8765',
                color: AppTheme.statusSearching,
                animate: true,
              ),
            BridgeConnectionState.connecting => const StatusChip(
                label: 'Client Connecting…',
                color: AppTheme.statusSearching,
                animate: true,
              ),
            BridgeConnectionState.error => const StatusChip(
                label: 'Server Error',
                color: AppTheme.statusError,
              ),
            BridgeConnectionState.disconnected => const StatusChip(
                label: 'Server Stopped',
                color: AppTheme.statusDisconnected,
              ),
          },
        ],
      );
}
