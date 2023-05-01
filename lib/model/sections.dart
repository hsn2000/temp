import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';
part 'sections.g.dart';

@HiveType(typeId: 0)
class studentSections {
  @HiveField(0)
  String className;

  @HiveField(1)
  String section;

  studentSections({required this.className, required this.section});
}
