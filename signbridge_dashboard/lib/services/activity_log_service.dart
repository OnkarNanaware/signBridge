import 'package:signbridge_dashboard/core/models/activity_log_entry.dart';

/// Abstract interface for the dashboard activity log.
abstract class ActivityLogService {
  /// Appends a new log entry.
  Future<void> log(EventType eventType, String details);

  /// Returns all entries, newest first.
  Future<List<ActivityLogEntry>> getAll();

  /// Returns the most recent [limit] entries.
  Future<List<ActivityLogEntry>> getRecent(int limit);

  /// Live broadcast stream of new entries.
  Stream<ActivityLogEntry> get logStream;

  /// Deletes all entries.
  Future<void> clearAll();
}
