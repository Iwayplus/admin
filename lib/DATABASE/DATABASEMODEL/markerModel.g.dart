// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markerModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MarkerModelAdapter extends TypeAdapter<MarkerModel> {
  @override
  final int typeId = 0;

  @override
  MarkerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarkerModel(
      markerId: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      iconPath: fields[3] as String,
      savedAt: fields[4] as DateTime,
      markerName: fields[5] as String,
      markerBName: fields[6] as String,
      markerBFloor: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MarkerModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.markerId)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.iconPath)
      ..writeByte(4)
      ..write(obj.savedAt)
      ..writeByte(5)
      ..write(obj.markerName)
      ..writeByte(6)
      ..write(obj.markerBName)
      ..writeByte(7)
      ..write(obj.markerBFloor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
