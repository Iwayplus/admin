import 'dart:convert';
import 'package:device_information/device_information.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/patchDataModel.dart';
import '../SharedPreferenceHelper.dart';
import 'RefreshTokenAPI.dart';

class patchAPI {

  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/secured/patch/get" : "https://maps.iwayplus.in/secured/patch/get";
  String accessToken = "";

  Future<patchDataModel> fetchPatchData(String id) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken = await prefs.getMap("signin")!["accessToken"];
    String manufacturer = kIsWeb?"WEB":await DeviceInformation.deviceManufacturer;
    String deviceModel = kIsWeb?"WEB":await DeviceInformation.deviceModel;

    final Map<String, dynamic> data = {
      "id": id,
      "manufacturer":manufacturer,
      "devicemodel": deviceModel
    };

    final response = await http.post(
      Uri.parse(baseUrl), body: json.encode(data),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken,
      },
    );
    if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        return patchDataModel.fromJson(responseBody);

    }else if (response.statusCode == 403)  {
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchPatchData(id);
    } else {
      print(response.body);
      throw Exception('Failed to load Patch data');
    }
  }
}