/// Activity log event types for the dashboard.
enum EventType {
  sessionStarted,
  sessionEnded,
  captionReceived,
  speechReceived,
  bridgeConnected,
  bridgeDisconnected,
  controlSent,
  error,
}

/// A single activity log entry for the dashboard.
class ActivityLogEntry {
  ActivityLogEntry({
    required this.timestamp,
    required this.eventType,
    required this.details,
  });

  final DateTime timestamp;
  final EventType eventType;
  final String details;

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${eventType.name}: $details';
}
