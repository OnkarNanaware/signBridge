// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SignEntryAdapter extends TypeAdapter<SignEntry> {
  @override
  final int typeId = 0;

  @override
  SignEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SignEntry(
      signName: fields[0] as String,
      landmarkSequence: (fields[1] as List)
          .map((dynamic e) => (e as List).cast<LandmarkPoint>())
          .toList(),
      dateRecorded: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SignEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.signName)
      ..writeByte(1)
      ..write(obj.landmarkSequence)
      ..writeByte(2)
      ..write(obj.dateRecorded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
