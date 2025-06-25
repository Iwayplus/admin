import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/waypoint.dart';
import '../HelperClass.dart';
import '../SharedPreferenceHelper.dart';
import '/API/buildingAllApi.dart';
import '../config.dart';
import 'RefreshTokenAPI.dart';
class waypointapi {
  final String baseUrl = "${AppConfig.baseUrl}/secured/indoor-path-network";
  String token = "";
  String accessToken = "";
  Future<Map<String,List<PathModel>>> fetchwaypoint(id, {bool outdoor = false}) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];
    final Map<String, dynamic> data = {
      "building_ID": "65d887a5db333f89457145f6",
      "outdoor": outdoor
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );

    if (response.statusCode == 200) {
      print("WAYPOINT DATA FROM API");

      List<dynamic> jsonData = json.decode(response.body);

      List<PathModel> wayPointList = jsonData
          .map((data) => PathModel.fromJson(data as Map<String, dynamic>))
          .toList();

      // Example: Grouping by `floor` assuming it is a String property
      Map<String, List<PathModel>> groupedMap = {};

      for (var item in wayPointList) {
        String key = item.floor.toString(); // adjust this as per your model
        groupedMap.putIfAbsent(key, () => []);
        groupedMap[key]!.add(item);
      }

      print("groupedMap:${groupedMap}");

      return groupedMap;
    } else if (response.statusCode == 403) {
      print("WAYPOINT DATA FROM API IN 403");
      String newAccessToken = await RefreshTokenAPI.refresh();
      print('Refresh done');
      accessToken = newAccessToken;
      return fetchwaypoint(id, outdoor: outdoor);
    } else {
      if (kDebugMode) {
        HelperClass.showToast("MishorError in WAYPOINT API API");
      }
      print("API Exception");
      print(response.statusCode);
      throw Exception('Failed to load data');
    }
  }

}