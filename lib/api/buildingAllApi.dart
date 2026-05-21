import 'dart:collection';
import 'dart:convert';
import 'package:admin/config.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../APIMODELS/buildingAll.dart';
import '../GPS.dart';
import '../SharedPreferenceHelper.dart';
import '../navigationTools.dart';
import 'RefreshTokenAPI.dart';

class buildingAllApi {
  final String baseUrl = "${AppConfig.baseUrl}/secured/building/all";
  String accessToken = "";
  static String selectedBuildingID="69e88519412aec622fc75536";
  static String selectedBuildingName="AIGHospital";
  static String selectedVenue="AIGHospital";
  static Map<String,g.LatLng> allBuildingID = {};
  static String outdoorID = "";
  static bool isGlobalAnnotation=false;

  static void setSelectedBuildingID(String value)async{
    print("inside inside set id $value");
    selectedBuildingID = value;
    return;
  }

  static Future<void> saveBid(String bid) async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getString('selectedBid')!=null){
      if(prefs.getString('selectedBid')!=bid)
        {
          await prefs.remove('selectedBid');
        }
    }
    await prefs.setString('selectedBid', bid);
  }


  static Future<String?> getBid()async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedBid');
  }

  Future<List<buildingAll>> fetchBuildingAllData() async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    accessToken=await prefs.getMap("signin")!["accessToken"];
    final response = await http.post(
      Uri.parse(baseUrl),
      headers:{
        'Content-Type': 'application/json',
        'x-access-token': accessToken
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> responseBody = json.decode(response.body);
      print("reponsee:${responseBody}");
      List<buildingAll> buildingList = responseBody
          .where((data) => data['initialBuildingName'] != null)
          .map((data) => buildingAll.fromJson(data))
          .toList();
      await findNearbyBuilding(buildingList);
      print("buildinglist ${buildingList}");
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
    print("userposition:${userPosition.latitude} ${userPosition.longitude}");
    double d = double.infinity;
    for (var building in buildings){
      print("${building.buildingName}   <>    ${building.coordinates}");
      double distance = tools.calculateAerialDist(userPosition.latitude, userPosition.longitude, building.coordinates![0], building.coordinates![1]);
      if(distance<d){
        print("selecting building ${building.sId!} ${building.buildingName} ${building.venueName!}");
        // selectedBuildingID = building.sId!;
        // selectedBuildingName = building.buildingName!;
        // selectedVenue = building.venueName!;
        d = distance;
      }
    }
  }
  
}