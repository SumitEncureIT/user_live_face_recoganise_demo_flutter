// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'face_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FaceUserAdapter extends TypeAdapter<FaceUser> {
  @override
  final int typeId = 1;

  @override
  FaceUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FaceUser(
      name: fields[0] as String,
      embedding: (fields[1] as List).cast<double>(),
      imagePath: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FaceUser obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.embedding)
      ..writeByte(2)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaceUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
