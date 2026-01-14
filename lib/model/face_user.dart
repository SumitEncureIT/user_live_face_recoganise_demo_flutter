import 'package:hive/hive.dart';
part 'face_user.g.dart';

@HiveType(typeId: 1)
class FaceUser extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<double> embedding;

  @HiveField(2)
  String imagePath;

  FaceUser({
    required this.name,
    required this.embedding,
    required this.imagePath,
  });
}
