import 'dart:async';

import 'package:signbridge_dashboard/core/models/activity_log_entry.dart';
import 'package:signbridge_dashboard/services/activity_log_service.dart';

/// In-memory mock [ActivityLogService] for the dashboard.
class MockActivityLogService implements ActivityLogService {
  final List<ActivityLogEntry> _entries = [];
  final StreamController<ActivityLogEntry> _controller =
      StreamController<ActivityLogEntry>.broadcast();

  @override
  Future<void> log(EventType eventType, String details) async {
    final ActivityLogEntry entry = ActivityLogEntry(
      timestamp: DateTime.now().toUtc(),
      eventType: eventType,
      details: details,
    );
    _entries.insert(0, entry);
    _controller.add(entry);
  }

  @override
  Future<List<ActivityLogEntry>> getAll() async =>
      List<ActivityLogEntry>.unmodifiable(_entries);

  @override
  Future<List<ActivityLogEntry>> getRecent(int limit) async =>
      _entries.take(limit).toList();

  @override
  Stream<ActivityLogEntry> get logStream => _controller.stream;

  @override
  Future<void> clearAll() async => _entries.clear();
}
