import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/FingerPrintData.dart';
import '../fingerprinting/SensorFingerprint.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';
class fingerPrintingDeleteApi {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/admin/delete-fingerprint-location/" : "https://dev.iwayplus.in/admin/delete-fingerprint-location/";
  String accessToken = "";
  Future<bool> Finger_Printing_DELETE_API(String building_ID,String location) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];
    print("buidlding id:${building_ID}");
    final Map<String, dynamic> data = {
      "locationId": location.split(',').last,
    };
    final response = await http.delete(
      Uri.parse(baseUrl+building_ID),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );
    print("response ${response.statusCode}  ${response.body}");
    if (response.statusCode == 200) {
      return true;
    }else if(response.statusCode == 403){
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return Finger_Printing_DELETE_API(building_ID,location);
    } else {
      print(response.body);
      return false;
      throw Exception('Failed to load Finger_Printing_GET_API data');

    }
  }
}
