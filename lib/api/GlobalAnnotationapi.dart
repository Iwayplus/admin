import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../APIMODELS/GlobalAnnotationModel.dart';
import '../HelperClass.dart';
import '../SharedPreferenceHelper.dart';
import '../config.dart';
import 'RefreshTokenAPI.dart';


class GlobalAnnotation {

  String baseUrl = "${AppConfig.baseUrl}/secured/get-global-annotation/";
  String token = "";

  Future<GlobalModel> fetchGlobalAnnotationData(id, {String? newaccesstoken}) async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    String accessToken = await prefs.getMap("signin")!["accessToken"];
    final response = await http.get(
      Uri.parse(baseUrl+id),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token':accessToken
      },
    );
    print("globalannotation data ${response.body}");
    print("globalannotation data ${response.statusCode}");
    if (response.statusCode == 200) {
      print("GLOBALANNOTATION API DATA FROM API");

      final jsonData = json.decode(response.body);
      final completeData = GlobalModel.fromJson(jsonData);
      print("globalannotation data $jsonData");
      Map<String,dynamic> responseBody = json.decode(response.body);
      return completeData;

    }else if (response.statusCode == 403) {
      print("globalannotation data  IN 403");
      String newAccessToken = await RefreshTokenAPI.refresh();
      print('Refresh done');
      accessToken = newAccessToken;
      return fetchGlobalAnnotationData(id,newaccesstoken: newAccessToken);
    }else {
      if(kDebugMode) {
        HelperClass.showToast("MishorError in globalannotation data ");
      }
      print("API Exception ${response.body}");
      print(response.statusCode);
      throw Exception('Failed to load data');
    }
  }
}