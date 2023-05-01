// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sections.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class studentSectionsAdapter extends TypeAdapter<studentSections> {
  @override
  final int typeId = 0;

  @override
  studentSections read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return studentSections(
      className: fields[0] as String,
      section: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, studentSections obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.className)
      ..writeByte(1)
      ..write(obj.section);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is studentSectionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
