import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';
import 'package:signbridge_phone/shared/widgets/panel_card.dart';
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Shows the Office Kit Bridge connection details and server controls.
class BridgeConnectionScreen extends ConsumerWidget {
  const BridgeConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<BridgeConnectionState> stateAsync =
        ref.watch(bridgeConnectionStateProvider);

    final BridgeConnectionState state = stateAsync.when(
      data: (BridgeConnectionState s) => s,
      loading: () => BridgeConnectionState.searching,
      error: (_, __) => BridgeConnectionState.error,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bridge Connection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PanelCard(
            title: 'Server Status',
            icon: Icons.router_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow(state),
                const SizedBox(height: 12),
                Text(
                  'The phone acts as the WebSocket server on port 8765. '
                  'Open the SignBridge Dashboard app on your Windows laptop '
                  'and enter this phone\'s IP address to connect.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(bridgeServiceProvider).startServer(),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Server'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
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
          const SizedBox(height: 12),
          PanelCard(
            title: 'Network Info',
            icon: Icons.info_outline_rounded,
            child: Column(
              children: [
                _infoRow(theme, 'Protocol', 'WebSocket (ws://)'),
                _infoRow(theme, 'Port', '8765'),
                _infoRow(theme, 'Network', 'Local Wi-Fi or USB only'),
                _infoRow(theme, 'Direction', 'Two-way (phone ↔ laptop)'),
                _infoRow(theme, 'Internet', 'Not required — fully offline'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BridgeConnectionState state) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            switch (state) {
              BridgeConnectionState.connected => const StatusChip(
                  label: 'Connected',
                  color: AppTheme.statusConnected,
                ),
              BridgeConnectionState.searching => const StatusChip(
                  label: 'Searching…',
                  color: AppTheme.statusSearching,
                  animate: true,
                ),
              BridgeConnectionState.connecting => const StatusChip(
                  label: 'Connecting…',
                  color: AppTheme.statusSearching,
                  animate: true,
                ),
              BridgeConnectionState.error => const StatusChip(
                  label: 'Error',
                  color: AppTheme.statusError,
                ),
              BridgeConnectionState.disconnected => const StatusChip(
                  label: 'Disconnected',
                  color: AppTheme.statusError,
                ),
            },
          ],
        ),
      );

  Widget _infoRow(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
