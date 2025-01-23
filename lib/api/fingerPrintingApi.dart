import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../fingerprinting/SensorFingerprint.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';


class fingerPrintingApi {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/admin/add-fingerprinting-data" : "https://maps.iwayplus.in/admin/add-fingerprinting-data";
  String accessToken = "";

  Future<void> Finger_Printing_API(String building_ID, Data fingerPrint) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];

    final Map<String, dynamic> data = {
      "building_ID": building_ID,
      "fingerPrintData": {fingerPrint.position:fingerPrint.sensorFingerprint}
    };

    final response = await http.post(
      Uri.parse(baseUrl), body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );

    if (response.statusCode == 200) {
      return ;
    }else if(response.statusCode == 403){
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return Finger_Printing_API(building_ID,fingerPrint);
    } else {
      throw Exception('Failed to load Finger_Printing_API data');
    }
  }
}
