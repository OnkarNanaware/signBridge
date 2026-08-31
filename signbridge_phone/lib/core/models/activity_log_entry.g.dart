// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityLogEntryAdapter extends TypeAdapter<ActivityLogEntry> {
  @override
  final int typeId = 1;

  @override
  ActivityLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
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
  final int typeId = 3;

  @override
  EventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EventType.cameraActivated;
      case 1:
        return EventType.cameraDeactivated;
      case 2:
        return EventType.micActivated;
      case 3:
        return EventType.micDeactivated;
      case 4:
        return EventType.dtwMatchRun;
      case 5:
        return EventType.dtwMatchResult;
      case 6:
        return EventType.bridgeMessageSent;
      case 7:
        return EventType.bridgeMessageReceived;
      case 8:
        return EventType.bridgeConnected;
      case 9:
        return EventType.bridgeDisconnected;
      case 10:
        return EventType.asrTranscript;
      case 11:
        return EventType.ttsSpeak;
      case 12:
        return EventType.signRecorded;
      case 13:
        return EventType.sessionStarted;
      case 14:
        return EventType.sessionEnded;
      default:
        return EventType.error;
    }
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    switch (obj) {
      case EventType.cameraActivated:
        writer.writeByte(0);
      case EventType.cameraDeactivated:
        writer.writeByte(1);
      case EventType.micActivated:
        writer.writeByte(2);
      case EventType.micDeactivated:
        writer.writeByte(3);
      case EventType.dtwMatchRun:
        writer.writeByte(4);
      case EventType.dtwMatchResult:
        writer.writeByte(5);
      case EventType.bridgeMessageSent:
        writer.writeByte(6);
      case EventType.bridgeMessageReceived:
        writer.writeByte(7);
      case EventType.bridgeConnected:
        writer.writeByte(8);
      case EventType.bridgeDisconnected:
        writer.writeByte(9);
      case EventType.asrTranscript:
        writer.writeByte(10);
      case EventType.ttsSpeak:
        writer.writeByte(11);
      case EventType.signRecorded:
        writer.writeByte(12);
      case EventType.sessionStarted:
        writer.writeByte(13);
      case EventType.sessionEnded:
        writer.writeByte(14);
      case EventType.error:
        writer.writeByte(15);
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
