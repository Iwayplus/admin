import 'dart:convert';
import 'package:admin/config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../SharedPreferenceHelper.dart';

class RefreshTokenAPI {

  static String baseUrl ="${AppConfig.baseUrl}/api/refreshToken";

  static Future<String> refresh() async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    String refreshToken = await prefs.getMap("signin")!["refreshToken"];
    final Map<String, dynamic> data = {
      "refreshToken": refreshToken,
    };
    final response = await http.post(
      Uri.parse(baseUrl), body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      final newAccessToken = responseBody["accessToken"];
      final newRefreshToken = responseBody["refreshToken"];
      Map<String, dynamic> signin = await prefs.getMap("signin")!;
      signin["refreshToken"] = newRefreshToken;
      signin["accessToken"] = newAccessToken;
      await prefs.saveMap("signin", signin);
      return newAccessToken;
    } else if (response.statusCode == 400) {
      print(response.body);
      throw Exception('Failed to refresh tokens');
    } else {
      print(response.body);
      throw Exception('Failed to refresh tokens');
    }
  }
}
