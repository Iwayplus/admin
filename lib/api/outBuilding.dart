import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../APIMODELS/outdoormodel.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';


class outBuilding {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/secured/outdoor" : "https://maps.iwayplus.in/secured/outdoor";
  String accessToken = "";

  Future<outdoormodel?> outbuilding(List<String> ids) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];

    final Map<String, dynamic> data = {
      "buildingIds": ids
    };

    final response = await http.post(
      Uri.parse(baseUrl), body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      return outdoormodel.fromJson(responseBody);

    }else if(response.statusCode == 403){
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return outbuilding(ids);
    } else {
      print(response.body);
      throw Exception('Failed to load outBuilding data');
    }
  }
}
