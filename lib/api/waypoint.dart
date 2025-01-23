import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/waypoint.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';


class waypointapi {

  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/secured/indoor-path-network" : "https://maps.iwayplus.in/secured/indoor-path-network";
  String accessToken = "";

  Future<List<PathModel>> fetchwaypoint(String id,{bool outdoor = false}) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];

    final Map<String, dynamic> data = {
      "building_ID": id,
      "outdoor": outdoor
    };


    final response = await http.post(
      Uri.parse(baseUrl), body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken,
      },
    );
    if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => PathModel.fromJson(data as Map<String, dynamic>)).toList();


    }else if (response.statusCode == 403) {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchwaypoint(id);
    }else {
      print(response.body);
      throw Exception('Failed to load waypoint data');
    }
  }
}