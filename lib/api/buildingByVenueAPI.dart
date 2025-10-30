import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/Buildingbyvenue.dart';
import '../SharedPreferenceHelper.dart';
import '/API/buildingAllApi.dart';
import '../config.dart';
import 'RefreshTokenAPI.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g;


class Buildingbyvenueapi {
  final String baseUrl = "${AppConfig.baseUrl}/secured/building/get/venue";


  Future<CampusData> fetchBuildingIDS(String id) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    String accessToken = await prefs.getMap("signin")!["accessToken"];

    final Map<String, dynamic> data = {
      "venueName": id, //venue Name
      "campusIncludes" : true
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken,
      },
    );

    print(" fetchBuildingIDS ${response.statusCode} ${response.body}");
    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      return CampusData.fromJson(responseBody);

    } else if (response.statusCode == 403) {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchBuildingIDS(id);
    } else {
      print("else ${response.body}");
      print(response.body);
      throw Exception('Failed to load landmark data');
    }
  }

}