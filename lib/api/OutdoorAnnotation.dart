import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import '../APIMODELS/GlobalAnnotation.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';


class GlobalAnnotation {

  String baseUrl = "https://dev.iwayplus.in/secured/get-global-annotation/";
  String accessToken = "";

  Future<MainModel> fetchGlobalAnnotationData(id) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];

    final response = await http.get(
      Uri.parse(baseUrl+id),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );
    if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final completeData = MainModel.fromJson(jsonData);
        return completeData;

    }else if (response.statusCode == 403) {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchGlobalAnnotationData(id);
    }else {
      print(response.body);
      throw Exception('Failed to load Outdoor data');
    }
  }
}