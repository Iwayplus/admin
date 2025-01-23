import 'dart:convert';
import 'package:http/http.dart' as http;
class SignUpAPI{

  final String baseUrl = "https://maps.iwayplus.in/auth/signup";

  Future<bool> signUP(String username,String name, String password,String OTP) async {
    final Map<String, dynamic> data = {
      "username": username,
      "name": name,
      "password": password,
      "otp": OTP,
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
      var responseData = json.decode(response.body);
      if (responseData['status']) {
        return true;
      }
    }
    return false;
  }
}