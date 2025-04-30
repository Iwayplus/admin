import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g;
import 'package:http/http.dart' as http;

import '../APIMODELS/buildingAll.dart';
import '../GPS.dart';
import '../SharedPreferenceHelper.dart';
import '../navigationTools.dart';
import 'RefreshTokenAPI.dart';

class buildingAllApi {
  final String baseUrl = kDebugMode? "https://dev.iwayplus.in/secured/building/all" : "https://maps.iwayplus.in/secured/building/all";
  String accessToken = "";
  static String selectedBuildingID="";
  static String selectedBuildingName="";
  static String selectedVenue="";
  static Map<String,g.LatLng> allBuildingID = {};
  static String outdoorID = "";

  
  Future<List<buildingAll>> fetchBuildingAllData() async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> responseBody = json.decode(response.body);
      List<buildingAll> buildingList = responseBody
          .where((data) => data['initialBuildingName'] != null)
          .map((data) => buildingAll.fromJson(data))
          .toList();
      await findNearbyBuilding(buildingList);
      return buildingList;

    }else if(response.statusCode == 403){
      String newAccessToken = await RefreshTokenAPI.refresh();
      accessToken = newAccessToken;
      return fetchBuildingAllData();
    } else {
      throw Exception('Failed to load data');
    }
  }
  
  Future<void> findNearbyBuilding(List<buildingAll> buildings) async {
    GPS gps = GPS();
    Position userPosition = await gps.getCurrentCoordinates();
    double d = double.infinity;
    for (var building in buildings) {
      double distance = tools.calculateAerialDist(userPosition.latitude, userPosition.longitude, building.coordinates![0], building.coordinates![1]);
      if(distance<d){
        selectedBuildingID = building.sId!;
        selectedBuildingName = building.buildingName!;
        selectedVenue = building.venueName!;
        d = distance;
      }
    }
  }
  
}