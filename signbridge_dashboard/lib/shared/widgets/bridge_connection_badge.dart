import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_dashboard/core/di/providers.dart';
import 'package:signbridge_dashboard/core/theme/app_theme.dart';
import 'package:signbridge_dashboard/services/office_kit_client_service.dart';
import 'package:signbridge_dashboard/shared/widgets/status_chip.dart';

/// Reusable connection status badge for the Windows Desktop dashboard.
class BridgeConnectionBadge extends ConsumerWidget {
  const BridgeConnectionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ClientConnectionState> state =
        ref.watch(clientConnectionStateProvider);

    final ClientConnectionState clientState =
        state.valueOrNull ?? ClientConnectionState.disconnected;

    return switch (clientState) {
      ClientConnectionState.connected => const StatusChip(
          label: 'Phone Connected',
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
          label: 'Error',
          color: AppTheme.statusError,
        ),
      ClientConnectionState.disconnected => const StatusChip(
          label: 'Not Connected',
          color: AppTheme.statusError,
        ),
    };
  }
}
