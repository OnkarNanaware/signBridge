import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_dashboard/core/di/providers.dart';
import 'package:signbridge_dashboard/core/theme/app_theme.dart';
import 'package:signbridge_dashboard/features/live_caption/presentation/live_caption_panel.dart';
import 'package:signbridge_dashboard/features/logs_history/presentation/logs_history_panel.dart';
import 'package:signbridge_dashboard/features/session_controls/presentation/session_controls_panel.dart';
import 'package:signbridge_dashboard/features/speech_playback/presentation/speech_playback_panel.dart';
import 'package:signbridge_dashboard/services/office_kit_client_service.dart';
import 'package:signbridge_dashboard/shared/widgets/status_chip.dart';

/// The main dashboard screen for the hearing participant's Windows desktop.
///
/// Layout (two-column on wide screens):
///   Left col  (60%): [LiveCaptionPanel] stacked full height
///   Right col (40%): [SessionControlsPanel] / [SpeechPlaybackPanel] / [LogsHistoryPanel]
///
/// A top app bar shows the bridge connection status and a demo mode banner.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<ClientConnectionState> stateAsync =
        ref.watch(clientConnectionStateProvider);

    final ClientConnectionState state = stateAsync.when(
      data: (ClientConnectionState s) => s,
      loading: () => ClientConnectionState.connecting,
      error: (_, __) => ClientConnectionState.error,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.sign_language_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text('SignBridge Dashboard'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _connectionBadge(state),
          ),
        ],
        bottom: useMockServices
            ? const PreferredSize(
                preferredSize: Size.fromHeight(34),
                child: _DemoModeBanner(),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Use two-column layout on screens wider than 800px.
              if (constraints.maxWidth >= 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left — live caption (60%)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          LiveCaptionPanel(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right — controls + playback + logs (40%)
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          children: const [
                            SessionControlsPanel(),
                            SizedBox(height: 8),
                            SpeechPlaybackPanel(),
                            SizedBox(height: 8),
                            LogsHistoryPanel(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              // Single-column fallback for narrow windows.
              return SingleChildScrollView(
                child: Column(
                  children: const [
                    LiveCaptionPanel(),
                    SizedBox(height: 8),
                    SessionControlsPanel(),
                    SizedBox(height: 8),
                    SpeechPlaybackPanel(),
                    SizedBox(height: 8),
                    LogsHistoryPanel(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _connectionBadge(ClientConnectionState state) => switch (state) {
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

class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.demoBannerBg,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_rounded,
              size: 16,
              color: AppTheme.demoBannerFg,
            ),
            SizedBox(width: 8),
            Text(
              'DEMO MODE — Mock services active. No bridge connection required.',
              style: TextStyle(
                color: AppTheme.demoBannerFg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
}
