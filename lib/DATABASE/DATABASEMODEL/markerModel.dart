import 'package:hive/hive.dart';
part 'markerModel.g.dart';


@HiveType(typeId: 0)
class MarkerModel extends HiveObject {
  @HiveField(0)
  final String markerId;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final String iconPath;

  @HiveField(4)
  final DateTime savedAt; // 🕒 New field

  MarkerModel({
    required this.markerId,
    required this.latitude,
    required this.longitude,
    required this.iconPath,
    required this.savedAt,
  });
}
