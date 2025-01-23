import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../API/RefreshTokenAPI.dart';
import '../../../SharedPreferenceHelper.dart';
import '../../../config.dart';
import '../MODELS/SignInAPIModel.dart';

class SignInAPI{

  final String baseUrl = "${AppConfig.baseUrl}/auth/signin";

  Future<SignInApiModel?> signIN(String username, String password) async {

    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();

    final Map<String, dynamic> data = {
      "username": username,
      "password": password,
      "appId":"com.iwayplus.navigation"
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        Map<String, dynamic> responseBody = json.decode(response.body);
        SignInApiModel ss = new SignInApiModel();
        ss.accessToken = responseBody["accessToken"];
        ss.refreshToken = responseBody["refreshToken"];
        ss.payload?.userId = responseBody["payload"]["userId"];
        ss.payload?.roles = responseBody["payload"]["roles"];
        await prefs.saveMap("signin", responseBody);
        return ss;
      } catch (e) {
        throw Exception('Failed to parse data');
      }
    }
  }

  static Future<int> sendOtpForgetPassword(String user) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('https://maps.iwayplus.in/auth/otp/username'));
    request.body = json.encode({"username": "${user}", "digits":4,});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      return 1;
    } else {
      print("response.reasonPhrase");
      print(response.reasonPhrase);
      return 0;
    }
  }

  static Future<int> changePassword(String user, String pass, String otp) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('https://maps.iwayplus.in/auth/reset-password'));
    request.body = json.encode({
      "username": "$user",
      "password": "$pass",
      "otp": "$otp"
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      return 1;
    } else {
      print("response.reasonPhrase");
      print(response.reasonPhrase);
      return 0;
    }
  }

}