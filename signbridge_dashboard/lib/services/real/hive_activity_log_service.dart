import 'dart:async';
import 'package:hive/hive.dart';
import 'package:signbridge_dashboard/core/constants/app_constants.dart';
import 'package:signbridge_dashboard/core/models/activity_log_entry.dart';
import 'package:signbridge_dashboard/services/activity_log_service.dart';

/// Real [ActivityLogService] for the dashboard backed by Hive.
///
/// Persists all incoming and outgoing bridge messages and session events
/// so that the Logs & History panel shows complete session history.
class HiveActivityLogService implements ActivityLogService {
  HiveActivityLogService()
      : _box = Hive.box<ActivityLogEntry>(kActivityLogBox),
        _logStreamController = StreamController<ActivityLogEntry>.broadcast();

  final Box<ActivityLogEntry> _box;
  final StreamController<ActivityLogEntry> _logStreamController;

  @override
  Future<void> log(EventType eventType, String details) async {
    final ActivityLogEntry entry = ActivityLogEntry(
      timestamp: DateTime.now().toUtc(),
      eventType: eventType,
      details: details,
    );

    if (!_logStreamController.isClosed) {
      _logStreamController.add(entry);
    }

    await _box.add(entry);
  }

  @override
  Future<List<ActivityLogEntry>> getAll() async =>
      _box.values.toList().reversed.toList();

  @override
  Future<List<ActivityLogEntry>> getRecent(int limit) async {
    final List<ActivityLogEntry> all = _box.values.toList();
    if (all.length <= limit) {
      return all.reversed.toList();
    }
    return all.sublist(all.length - limit).reversed.toList();
  }

  @override
  Stream<ActivityLogEntry> get logStream => _logStreamController.stream;

  @override
  Future<void> clearAll() async => _box.clear();

  /// Closes the stream controller when service is disposed.
  Future<void> dispose() async {
    await _logStreamController.close();
  }
}
