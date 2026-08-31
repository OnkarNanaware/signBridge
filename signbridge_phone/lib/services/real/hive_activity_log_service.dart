import 'dart:async';
import 'package:hive/hive.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';

/// Real [ActivityLogService] implementation backed by the local Hive box.
///
/// Ensures all device events (camera, mic, DTW matches, bridge activity)
/// are persisted on-device for session audit and hackathon device-usage scoring.
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

    // Broadcast immediately so UI doesn't lag
    if (!_logStreamController.isClosed) {
      _logStreamController.add(entry);
    }

    // Persist to Hive asynchronously
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
