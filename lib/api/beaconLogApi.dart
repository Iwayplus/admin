import 'dart:convert';

import 'package:admin/API/buildingAllApi.dart';
import 'package:flutter/foundation.dart';

import '../API/RefreshTokenAPI.dart';
import '../APIMODELS/beaconlog.dart';
import '../SharedPreferenceHelper.dart';
import 'package:http/http.dart' as http;

class Beaconlogapi{

  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/admin/get-beacons/" : "https://dev.iwayplus.in/admin/get-beacons/";
  String accessToken = "";
  Future<BeaconLog?> fetchBeaconLogData() async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];
    final response = await http.get(
      Uri.parse(baseUrl+buildingAllApi.selectedVenue),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      if(json.decode(response.body) == null){
        return null;
      }
      print("responseBody:${responseBody}");
      return BeaconLog.fromJson(responseBody);
    }else if (response.statusCode == 403) {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchBeaconLogData();
    } else {
      print(response.body);
      throw Exception('Failed to load Beacon data');
    }
  }
}