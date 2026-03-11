import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../API/buildingAllApi.dart';
import '../APIMODELS/Building.dart';
import '../HelperClass.dart';
import '../SharedPreferenceHelper.dart';
import '../config.dart';

import 'RefreshTokenAPI.dart';


class BuildingAPI {
  final String baseUrl = "${AppConfig.baseUrl}/secured/building/get/venue";
  String accessToken = "";


  Future<BuildingData?> fetchBuildData() async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];
    print("buildingAllApi.selectedVenue:${buildingAllApi.selectedVenue}");
    final Map<String, dynamic> data = {
      "venueName": buildingAllApi.selectedVenue,
      "campusIncludes":true
    };
    final response = await http.post(
      Uri.parse(baseUrl),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );
    print("response code:${response.statusCode}");
    if (response.statusCode == 200) {
      final responseList = json.decode(response.body);
        final building = BuildingData.fromJson(responseList as Map<String, dynamic>);
        print("buildingss:${building}");
        return building;
    } else if (response.statusCode == 403) {
      print('BUILDING DATA API in error 403');
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;

      final response = await http.post(
        Uri.parse(baseUrl),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': accessToken
        },
      );

      if (response.statusCode == 200) {
        final responseList = json.decode(response.body);
          final building = BuildingData.fromJson(responseList as Map<String, dynamic>);
          print("buildingss:${building}");
          return building;
      } else {
        print('BUILDING DATA EMPTY FROM API AFTER 403');
        return null;
      }
    } else {
      HelperClass.showToast("MishorError in Building API");
      throw Exception('Failed to load data');
    }
  }

}

