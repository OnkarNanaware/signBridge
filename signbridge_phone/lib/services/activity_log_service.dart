import 'package:signbridge_phone/core/models/activity_log_entry.dart';

/// Abstract interface for the device-usage activity log.
///
/// Every camera activation, mic activation, DTW match run, and bridge
/// message MUST be logged here — required for hackathon device-usage
/// scoring. Backed by Hive on both phone and desktop.
abstract class ActivityLogService {
  /// Appends a new log entry with the given [eventType] and [details].
  ///
  /// This call must be non-blocking — log writes happen asynchronously.
  Future<void> log(EventType eventType, String details);

  /// Returns all log entries, newest first.
  Future<List<ActivityLogEntry>> getAll();

  /// Returns the most recent [limit] log entries, newest first.
  Future<List<ActivityLogEntry>> getRecent(int limit);

  /// A broadcast stream that emits new [ActivityLogEntry] events as they
  /// are logged. Useful for live log viewers in the UI.
  Stream<ActivityLogEntry> get logStream;

  /// Deletes all log entries.
  Future<void> clearAll();
}
