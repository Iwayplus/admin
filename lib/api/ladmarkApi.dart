import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/landmark.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';



class landmarkApi {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/secured/landmarks-demo" : "https://maps.iwayplus.in/secured/landmarks";
  String accessToken = "";

  Future<land> fetchLandmarkData(String id, {bool outdoor = false}) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];

    final Map<String, dynamic> data = {
      "id": id,
      "outdoor": outdoor
    };
    final response = await http.post(
      Uri.parse(baseUrl),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken,
      },
    );
    if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        return land.fromJson(responseBody);
        
    } else if (response.statusCode == 403) {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchLandmarkData(id);
    } else {
      print(response.body);
      throw Exception('Failed to load landmark data');
    }
  }
}