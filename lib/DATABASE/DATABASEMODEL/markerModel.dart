import 'package:hive/hive.dart';

part 'markerModel.g.dart'; // Required for code generation

@HiveType(typeId: 0)
class MarkerModel extends HiveObject {
  @HiveField(0)
  String markerId;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  @HiveField(3)
  String iconPath;

  @HiveField(4)
  DateTime savedAt;

  @HiveField(5)
  String markerName;

  @HiveField(6)
  String markerBName;

  @HiveField(7)
  String markerBFloor;// ✅ New field

  MarkerModel({
    required this.markerId,
    required this.latitude,
    required this.longitude,
    required this.iconPath,
    required this.savedAt,
    required this.markerName,
    required this.markerBName,
    required this.markerBFloor,// ✅ Add to constructor
  });
}
