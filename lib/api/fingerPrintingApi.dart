import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../fingerprinting/SensorFingerprint.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';


class fingerPrintingApi {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/admin/add-fingerprinting-data" : "https://maps.iwayplus.in/admin/add-fingerprinting-data";
  String accessToken = "";

  Future<bool> Finger_Printing_API(String building_ID, Data fingerPrint) async {

    if(fingerPrint.sensorFingerprint == null){
      print("fail 1");
      return false;
    }

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

    print(response.body);

    if (response.statusCode == 200) {
      print("fail 2");
      return true;
    }else if(response.statusCode == 403){
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return Finger_Printing_API(building_ID,fingerPrint);
    } else {
      print("fail 3");
      return false;
      throw Exception('Failed to load Finger_Printing_API data');
    }
  }
}
