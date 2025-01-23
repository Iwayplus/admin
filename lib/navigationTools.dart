import 'dart:collection';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:collection/collection.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'APIMODELS/beaconData.dart';
import 'APIMODELS/landmark.dart';
import 'APIMODELS/patchDataModel.dart' as PDM;
import 'API/PatchApi.dart';
import 'APIMODELS/patchDataModel.dart';
import 'APIMODELS/polylinedata.dart';


class tools {

  static double calculateAerialDist(double lat1, double lon1, double lat2, double lon2) {
    const double metersPerDegree = 111320;
    double latDifference = lat2 - lat1;
    double lonDifference = lon2 - lon1;
    double distanceDegrees = sqrt(pow(latDifference, 2) + pow(lonDifference, 2));
    double distanceMeters = distanceDegrees * metersPerDegree;
    return distanceMeters;
  }

  static double calculateDistance(List<int> p1, List<int> p2) {
    return sqrt(pow(p1[0] - p2[0], 2) + pow(p1[1] - p2[1], 2));
  }

  static String numericalToAlphabetical(int number) {
    switch (number) {
      case 0:
        return 'ground';
      case 1:
        return 'first';
      case 2:
        return 'second';
      case 3:
        return 'third';
      case 4:
        return 'fourth';
      case 5:
        return 'fifth';
      case 6:
        return 'sixth';
      case 7:
        return 'seventh';
      case 8:
        return 'eighth';
      case 9:
        return 'ninth';
      case 10:
        return 'tenth';
      default:
        return 'Invalid number';
    }
  }

  static int alphabeticalToNumerical(String word) {
    switch (word) {
      case 'ground':
        return 0;
      case 'first':
        return 1;
      case 'second':
        return 2;
      case 'third':
        return 3;
      case 'fourth':
        return 4;
      case 'fifth':
        return 5;
      case 'sixth':
        return 6;
      case 'seventh':
        return 7;
      case 'eighth':
        return 8;
      case 'ninth':
        return 9;
      case 'tenth':
        return 10;
      default:
        return -1; // Using -1 to indicate an invalid input
    }
  }

}
