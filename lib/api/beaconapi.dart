import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import '../APIMODELS/beaconData.dart';

import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';


class beaconapi {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/secured/building/beacons" : "https://maps.iwayplus.in/secured/building/beacons";
  String accessToken = "";

  Future<List<beacon>> fetchBeaconData(String id) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];

    final Map<String, dynamic> data = {
      "buildingId": id,
    };
    final response = await http.post(
      Uri.parse(baseUrl),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': await prefs.getMap("signin")!["accessToken"],
      },
    );

    if (response.statusCode == 200) {
      try{
        List<dynamic> responseBody = json.decode(response.body);
        List<beacon> beaconList = responseBody.map((data) => beacon.fromJson(data)).toList();
        return beaconList;
      }catch(e){
          return [];
     }
    }else if (response.statusCode == 403) {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchBeaconData(id);
    } else {
      print(response.body);
      throw Exception('Failed to load Beacon data');
    }
  }
}