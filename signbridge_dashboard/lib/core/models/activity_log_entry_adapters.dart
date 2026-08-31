import 'package:hive/hive.dart';
import 'package:signbridge_dashboard/core/models/activity_log_entry.dart';

class ActivityLogEntryAdapter extends TypeAdapter<ActivityLogEntry> {
  @override
  final int typeId = 1;

  @override
  ActivityLogEntry read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLogEntry(
      timestamp: fields[0] as DateTime,
      eventType: fields[1] as EventType,
      details: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLogEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.eventType)
      ..writeByte(2)
      ..write(obj.details);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventTypeAdapter extends TypeAdapter<EventType> {
  @override
  final int typeId = 2;

  @override
  EventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EventType.sessionStarted;
      case 1:
        return EventType.sessionEnded;
      case 2:
        return EventType.captionReceived;
      case 3:
        return EventType.speechReceived;
      case 4:
        return EventType.bridgeConnected;
      case 5:
        return EventType.bridgeDisconnected;
      case 6:
        return EventType.controlSent;
      default:
        return EventType.error;
    }
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    switch (obj) {
      case EventType.sessionStarted:
        writer.writeByte(0);
      case EventType.sessionEnded:
        writer.writeByte(1);
      case EventType.captionReceived:
        writer.writeByte(2);
      case EventType.speechReceived:
        writer.writeByte(3);
      case EventType.bridgeConnected:
        writer.writeByte(4);
      case EventType.bridgeDisconnected:
        writer.writeByte(5);
      case EventType.controlSent:
        writer.writeByte(6);
      case EventType.error:
        writer.writeByte(7);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
