import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../APIMODELS/polylinedata.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';

class PolyLineApi {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/secured/polyline" : "https://maps.iwayplus.in/secured/polyline";
  String accessToken = "";

  Future<polylinedata> fetchPolyData(String id, {bool outdoor = false}) async {
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
        return polylinedata.fromJson(responseBody);
    }else if (response.statusCode == 403) {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchPolyData(id);
    }
    else {
      print(response.body);
      throw Exception('Failed to load Polyline data');
    }
  }
}