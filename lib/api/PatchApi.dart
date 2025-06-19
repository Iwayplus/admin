import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
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
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String deviceManufacturer = "Unknown";
    String deviceModel = "Unknown";

    if (kIsWeb) {
      deviceManufacturer = "WEB";
      deviceModel = "WEB";
    } else {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceManufacturer = androidInfo.manufacturer ?? "Unknown";
        deviceModel = androidInfo.model ?? "Unknown";
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceManufacturer = "Apple"; // iPhones are always manufactured by Apple
        deviceModel = iosInfo.utsname.machine ?? "Unknown";
      } else {
        // Handle other platforms if needed (macOS, Windows, Linux)
        deviceManufacturer = "Unknown Platform";
        deviceModel = "Unknown Platform";
      }
    }

    final Map<String, dynamic> data = {
      "id": id,
      "manufacturer":deviceManufacturer,
      "devicemodel": deviceModel
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