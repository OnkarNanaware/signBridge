import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_dashboard/core/constants/app_constants.dart';
import 'package:signbridge_dashboard/core/di/providers.dart';
import 'package:signbridge_dashboard/core/models/bridge_message.dart';
import 'package:signbridge_dashboard/core/theme/app_theme.dart';
import 'package:signbridge_dashboard/services/office_kit_client_service.dart';
import 'package:signbridge_dashboard/shared/widgets/panel_card.dart';
import 'package:signbridge_dashboard/shared/widgets/status_chip.dart';

/// Session controls and settings panel.
///
/// Allows the hearing participant to:
///   - Connect to the phone by IP address + port
///   - Start / stop the session
///   - See current connection status
class SessionControlsPanel extends ConsumerStatefulWidget {
  const SessionControlsPanel({super.key});

  @override
  ConsumerState<SessionControlsPanel> createState() =>
      _SessionControlsPanelState();
}

class _SessionControlsPanelState extends ConsumerState<SessionControlsPanel> {
  final TextEditingController _hostController =
      TextEditingController(text: kDefaultBridgeHost);
  final TextEditingController _portController =
      TextEditingController(text: kBridgePort.toString());

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final String host = _hostController.text.trim();
    final int port =
        int.tryParse(_portController.text.trim()) ?? kBridgePort;
    await ref.read(clientServiceProvider).connect(host, port);
  }

  Future<void> _disconnect() async {
    await ref.read(clientServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<ClientConnectionState> stateAsync =
        ref.watch(clientConnectionStateProvider);

    final ClientConnectionState state = stateAsync.when(
      data: (ClientConnectionState s) => s,
      loading: () => ClientConnectionState.connecting,
      error: (_, __) => ClientConnectionState.error,
    );

    final bool isConnected = state == ClientConnectionState.connected;
    final bool isConnecting = state == ClientConnectionState.connecting;

    return PanelCard(
      title: 'Session Controls',
      icon: Icons.settings_remote_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status badge
          _currentStatusBadge(state),
          const SizedBox(height: 14),
          // Host field
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _hostController,
                  enabled: !isConnected,
                  decoration: const InputDecoration(
                    labelText: 'Phone IP Address',
                    prefixIcon: Icon(Icons.phone_android_rounded, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _portController,
                  enabled: !isConnected,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Connect / Disconnect buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isConnected || isConnecting ? null : _connect,
                  icon: isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link_rounded),
                  label: Text(isConnecting ? 'Connecting…' : 'Connect'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isConnected ? _disconnect : null,
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('Disconnect'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Send test message (demo)
          if (isConnected)
            TextButton.icon(
              onPressed: () => ref.read(clientServiceProvider).sendMessage(
                    BridgeMessage.control('ping'),
                  ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Test Ping'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _currentStatusBadge(ClientConnectionState state) => switch (state) {
        ClientConnectionState.connected => const StatusChip(
            label: 'Connected to Phone',
            color: AppTheme.statusConnected,
            icon: Icons.phone_android_rounded,
          ),
        ClientConnectionState.connecting => const StatusChip(
            label: 'Connecting…',
            color: AppTheme.statusSearching,
            animate: true,
          ),
        ClientConnectionState.reconnecting => const StatusChip(
            label: 'Reconnecting…',
            color: AppTheme.statusSearching,
            animate: true,
          ),
        ClientConnectionState.error => const StatusChip(
            label: 'Connection Error',
            color: AppTheme.statusError,
          ),
        ClientConnectionState.disconnected => const StatusChip(
            label: 'Not Connected',
            color: AppTheme.statusError,
          ),
      };
}
