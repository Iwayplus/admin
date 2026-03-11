import 'dart:convert';
import 'package:admin/config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/FingerPrintData.dart';
import '../fingerprinting/SensorFingerprint.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';
class fingerPrintingGetApi {
  final String baseUrl = "${AppConfig.baseUrl}/admin/get-fingerprints/";
  String accessToken = "";
  Future<FingerPrintData?> Finger_Printing_GET_API(String building_ID,String floor) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];
    print("buidlding id:${building_ID} ${floor}");
    final response = await http.get(
      Uri.parse(baseUrl+building_ID+"/${floor}"),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );
    print("response ${response.statusCode}  ${response.body}");
    if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        if(json.decode(response.body) == null){
          return null;
        }
        return FingerPrintData.fromJson(responseBody);

    }else if(response.statusCode == 403){
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return Finger_Printing_GET_API(building_ID,floor);
    } else {
      print(response.body);
      throw Exception('Failed to load Finger_Printing_GET_API data');
    }
  }
}
