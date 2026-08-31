import 'package:hive/hive.dart';

part 'activity_log_entry.g.dart';

/// Types of loggable events in SignBridge.
///
/// Every camera activation, mic activation, DTW match run, and bridge message
/// must be logged — required for hackathon device-usage scoring.
@HiveType(typeId: 3)
enum EventType {
  @HiveField(0)
  cameraActivated,

  @HiveField(1)
  cameraDeactivated,

  @HiveField(2)
  micActivated,

  @HiveField(3)
  micDeactivated,

  @HiveField(4)
  dtwMatchRun,

  @HiveField(5)
  dtwMatchResult,

  @HiveField(6)
  bridgeMessageSent,

  @HiveField(7)
  bridgeMessageReceived,

  @HiveField(8)
  bridgeConnected,

  @HiveField(9)
  bridgeDisconnected,

  @HiveField(10)
  asrTranscript,

  @HiveField(11)
  ttsSpeak,

  @HiveField(12)
  signRecorded,

  @HiveField(13)
  sessionStarted,

  @HiveField(14)
  sessionEnded,

  @HiveField(15)
  error,
}

/// A single activity log entry stored in the local Hive box.
@HiveType(typeId: 1)
class ActivityLogEntry extends HiveObject {
  ActivityLogEntry({
    required this.timestamp,
    required this.eventType,
    required this.details,
  });

  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final EventType eventType;

  /// Human-readable details (e.g. matched sign name, bridge IP, error message).
  @HiveField(2)
  final String details;

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${eventType.name}: $details';
}
