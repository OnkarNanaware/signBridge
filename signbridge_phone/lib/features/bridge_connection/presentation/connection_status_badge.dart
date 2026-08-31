import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Animated bridge connection status badge.
///
/// Shows one of four states: disconnected, searching (pulsing), connected,
/// or error — each with a distinct colour and label.
class ConnectionStatusBadge extends ConsumerWidget {
  const ConnectionStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BridgeConnectionState> stateAsync =
        ref.watch(bridgeConnectionStateProvider);

    final BridgeConnectionState state = stateAsync.when(
      data: (BridgeConnectionState s) => s,
      loading: () => BridgeConnectionState.searching,
      error: (_, __) => BridgeConnectionState.error,
    );

    return switch (state) {
      BridgeConnectionState.connected => const StatusChip(
          label: 'Dashboard Connected',
          color: AppTheme.statusConnected,
          icon: Icons.laptop_rounded,
        ),
      BridgeConnectionState.searching => const StatusChip(
          label: 'Searching…',
          color: AppTheme.statusSearching,
          icon: Icons.wifi_find_rounded,
          animate: true,
        ),
      BridgeConnectionState.connecting => const StatusChip(
          label: 'Connecting…',
          color: AppTheme.statusSearching,
          icon: Icons.sync_rounded,
          animate: true,
        ),
      BridgeConnectionState.error => const StatusChip(
          label: 'Bridge Error',
          color: AppTheme.statusError,
          icon: Icons.error_outline_rounded,
        ),
      BridgeConnectionState.disconnected => const StatusChip(
          label: 'Not Connected',
          color: AppTheme.statusError,
          icon: Icons.link_off_rounded,
        ),
    };
  }
}
