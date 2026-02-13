import 'dart:convert';
import 'package:admin/config.dart';
import 'package:http/http.dart' as http;
class SignUpAPI{

  final String baseUrl = "${AppConfig.baseUrl}/auth/get-admin-access";

  Future<bool> signUP(String username,String name, String password,String OTP,String confirmPassword) async {
    final Map<String, dynamic> data = {
      "username": username,
      "name": name,
      "password": password,
      "otp": "",
      "appId":"cms",
      "confirmPassword":confirmPassword,
      "email":username
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      if (responseData['status']) {
        return true;
      }
    }
    return false;
  }
}