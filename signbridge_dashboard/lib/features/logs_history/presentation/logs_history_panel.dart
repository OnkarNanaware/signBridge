import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_dashboard/core/di/providers.dart';
import 'package:signbridge_dashboard/core/models/activity_log_entry.dart';
import 'package:signbridge_dashboard/shared/widgets/panel_card.dart';

/// Logs & history panel — live-updating list of activity log entries.
///
/// Subscribes to the [activityLogStreamProvider] and prepends new entries
/// to the top of the list. Supports clearing the log.
class LogsHistoryPanel extends ConsumerStatefulWidget {
  const LogsHistoryPanel({super.key});

  @override
  ConsumerState<LogsHistoryPanel> createState() => _LogsHistoryPanelState();
}

class _LogsHistoryPanelState extends ConsumerState<LogsHistoryPanel> {
  final List<ActivityLogEntry> _entries = [];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    ref.listen<AsyncValue<ActivityLogEntry>>(activityLogStreamProvider,
        (_, next) {
      next.whenData((ActivityLogEntry e) {
        if (mounted) setState(() => _entries.insert(0, e));
      });
    });

    return PanelCard(
      title: 'Logs & History',
      icon: Icons.history_rounded,
      trailing: _entries.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              tooltip: 'Clear logs',
              onPressed: () {
                setState(() => _entries.clear());
                ref.read(activityLogServiceProvider).clearAll();
              },
            )
          : null,
      child: SizedBox(
        height: 220,
        child: _entries.isEmpty
            ? Center(
                child: Text(
                  'No events yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _entries.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.dividerColor,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final ActivityLogEntry e = _entries[index];
                  return ListTile(
                    dense: true,
                    leading: _eventIcon(e.eventType, theme),
                    title: Text(
                      e.details,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatTs(e.timestamp),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _eventIcon(EventType type, ThemeData theme) {
    final (IconData icon, Color color) = switch (type) {
      EventType.captionReceived => (Icons.sign_language_rounded, theme.colorScheme.primary),
      EventType.speechReceived => (Icons.mic_rounded, theme.colorScheme.secondary),
      EventType.bridgeConnected => (Icons.link_rounded, const Color(0xFF3FB950)),
      EventType.bridgeDisconnected => (Icons.link_off_rounded, const Color(0xFFF85149)),
      EventType.sessionStarted => (Icons.play_circle_outline_rounded, const Color(0xFF3FB950)),
      EventType.sessionEnded => (Icons.stop_circle_outlined, const Color(0xFFD29922)),
      EventType.controlSent => (Icons.send_rounded, theme.colorScheme.secondary),
      EventType.error => (Icons.error_outline_rounded, const Color(0xFFF85149)),
    };
    return Icon(icon, size: 16, color: color);
  }

  String _formatTs(DateTime dt) {
    final DateTime local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}
