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

  static patchDataModel globalData = patchDataModel();
  static bool gotBhart = false;
  static List<double> localtoglobal(int x, int y,PDM.patchDataModel? patchData) {
    x = x - 0;
    y = y - 0;
    ////
    PDM.patchDataModel Data = PDM.patchDataModel();
    if (patchData != null) {
      Data = patchData;
      if(patchData.patchData!.fileName == "004ef3cf-9294-4171-adc0-1554759d5400_IITCampus-BhartiSchool-ground_ground.png"){
        gotBhart = true;
      }

    } else {
      Data = globalData;
    }
    int floor = 0;

    List<double> diff = [
      0,
      0,
      0,
    ];
    // {"coordinates" : patchDataApi().fetchedPatchData!.patchData!.coordinates! } ;
    List<Map<String, double>> ref = [
      {
        "lat": double.parse(Data.patchData!.coordinates![2].globalRef!.lat!),
        "lon": double.parse(Data.patchData!.coordinates![2].globalRef!.lng!),
        "localx": double.parse(Data.patchData!.coordinates![2].localRef!.lng!),
        "localy": double.parse(Data.patchData!.coordinates![2].localRef!.lat!),
      },
      {
        "lat": double.parse(Data.patchData!.coordinates![1].globalRef!.lat!),
        "lon": double.parse(Data.patchData!.coordinates![1].globalRef!.lng!),
        "localx": double.parse(Data.patchData!.coordinates![1].localRef!.lng!),
        "localy": double.parse(Data.patchData!.coordinates![1].localRef!.lat!),
      },
      {
        "lat": double.parse(Data.patchData!.coordinates![0].globalRef!.lat!),
        "lon": double.parse(Data.patchData!.coordinates![0].globalRef!.lng!),
        "localx": double.parse(Data.patchData!.coordinates![0].localRef!.lng!),
        "localy": double.parse(Data.patchData!.coordinates![0].localRef!.lat!),
      },
      {
        "lat": double.parse(Data.patchData!.coordinates![3].globalRef!.lat!),
        "lon": double.parse(Data.patchData!.coordinates![3].globalRef!.lng!),
        "localx": double.parse(Data.patchData!.coordinates![3].localRef!.lng!),
        "localy": double.parse(Data.patchData!.coordinates![3].localRef!.lat!),
      },
    ];

    int leastLat = 0;
    for (int i = 0; i < ref.length; i++) {
      if (ref[i]["lat"] == ref[leastLat]["lat"]) {
        if (ref[i]["lon"]! > ref[leastLat]["lon"]!) {
          leastLat = i;
        }
      } else if (ref[i]["lat"]! < ref[leastLat]["lat"]!) {
        leastLat = i;
      }
    }

    int c1 = (leastLat == 3) ? 0 : (leastLat + 1);
    int c2 = (leastLat == 0) ? 3 : (leastLat - 1);
    int highLon = (ref[c1]["lon"]! > ref[c2]["lon"]!) ? c1 : c2;

    List<double> lengths = [];
    for (int i = 0; i < ref.length; i++) {
      double temp1;
      if (i == ref.length - 1) {
        temp1 = getHaversineDistance(ref[i], ref[0]);
      } else {
        temp1 = getHaversineDistance(ref[i], ref[i + 1]);
      }
      lengths.add(temp1);
    }

    double b = getHaversineDistance(ref[leastLat], ref[highLon]);
    Map<String, double> horizontal = obtainCoordinates(ref[leastLat], 0, b);

    double c = getHaversineDistance(ref[leastLat], horizontal);
    double a = getHaversineDistance(ref[highLon], horizontal);

    double out = acos((b * b + c * c - a * a) / (2 * b * c)) * 180 / pi;

    Map<String, double> localRef = {"localx": 0, "localy": 0};

    if (diff != null && diff.length > 1) {
      List<double> test = diff.where((d) => d == floor).toList();
      if (test.isNotEmpty) {
        localRef["localx"] = x - test[0];
        localRef["localy"] = y - test[1];
      } else {
        localRef["localx"] = x as double;
        localRef["localy"] = y as double;
      }
    } else {
      localRef["localx"] = x as double;
      localRef["localy"] = y as double;
    }

    double l = distance(ref[leastLat], ref[highLon]);
    double m = distance(localRef, ref[highLon]);
    double n = distance(ref[leastLat], localRef);

    double theta = acos((l * l + n * n - m * m) / (2 * l * n)) * 180 / pi;

    if (((l * l + n * n - m * m) / (2 * l * n) > 1) || m == 0 || n == 0) {
      theta = 0;
    }

    double ang = theta + out;
    double dist =
        distance(ref[leastLat], localRef) * 0.3048; // to convert to meter

    double ver = dist * sin(ang * pi / 180.0);
    double hor = dist * cos(ang * pi / 180.0);

    Map<String, double> finalCoords =
    obtainCoordinates(ref[leastLat], ver, hor);

    return [finalCoords["lat"]!, finalCoords["lon"]!];
  }

  static double getHaversineDistance(
      Map<String, double> firstLocation, Map<String, double> secondLocation) {
    const earthRadius = 6371; // km
    double diffLat =
        ((secondLocation["lat"]! - firstLocation["lat"]!) * pi) / 180;
    double difflon =
        ((secondLocation["lon"]! - firstLocation["lon"]!) * pi) / 180;
    double arc = cos((firstLocation["lat"]! * pi) / 180) *
        cos((secondLocation["lat"]! * pi) / 180) *
        sin(difflon / 2) *
        sin(difflon / 2) +
        sin(diffLat / 2) * sin(diffLat / 2);
    double line = 2 * atan2(sqrt(arc), sqrt(1 - arc));
    double distance = earthRadius * line * 1000;
    return distance;
  }

  static Map<String, double> obtainCoordinates(
      Map<String, double> reference, double vertical, double horizontal) {
    const double R = 6378137; // Earth’s radius, sphere
    double dLat = vertical / R;
    double dLon = horizontal / (R * cos((pi * reference["lat"]!) / 180));
    double latA = reference["lat"]! + (dLat * 180) / pi;
    double lonA = reference["lon"]! + (dLon * 180) / pi;
    return {"lat": latA, "lon": lonA};
  }




  static double distance(
      Map<String, double> first, Map<String, double> second) {
    double dist1 = pow((second["localy"]! - first["localy"]!), 2) as double;
    double dist2 = pow((second["localx"]! - first["localx"]!), 2) as double;
    double dist = dist1 + dist2;
    //  pow((second["localy"] - first["localy"]), 2) as double + pow((second["localx"] - first["localx"]), 2) as double ;
    return sqrt(dist);
  }

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

 static List<int> globalToLocalPoints({required PDM.patchDataModel? patchData, required double lat, required double lng}) {
    final coords = patchData?.patchData?.coordinates;

    Map<String, double> globalRef(int index) => {
      'lat': double.parse(coords![index].globalRef!.lat.toString()),
      'lng': double.parse(coords![index].globalRef!.lng.toString()),
    };

    final xperp = findPerpendicularPointAndDistance(
      globalRef(0),
      globalRef(1),
      {'lat': lat, 'lng': lng},
    );

    final yperp = findPerpendicularPointAndDistance(
      globalRef(0),
      globalRef(3),
      {'lat': lat, 'lng': lng},
    );

    return [
      (xperp['distance'] as double).round(),
      (yperp['distance'] as double).round(),
    ];
  }


  static Map<String, dynamic> findPerpendicularPointAndDistance(
      Map<String, double> a,
      Map<String, double> b,
      Map<String, double> c,
      ) {
    const double earthRadiusFeet = 20925646.3;

    double toRadians(double degrees) => degrees * pi / 180;
    double toDegrees(double radians) => radians * 180 / pi;

    Map<String, double> toCartesian(Map<String, double> point) {
      final latRad = toRadians(point['lat']!);
      final lngRad = toRadians(point['lng']!);
      return {
        'x': cos(latRad) * cos(lngRad),
        'y': cos(latRad) * sin(lngRad),
        'z': sin(latRad),
      };
    }

    Map<String, double> toLatLng(Map<String, double> cart) {
      return {
        'lat': toDegrees(atan2(cart['z']!, sqrt(cart['x']! * cart['x']! + cart['y']! * cart['y']!))),
        'lng': toDegrees(atan2(cart['y']!, cart['x']!)),
      };
    }

    Map<String, double> vectorBetween(Map<String, double> p1, Map<String, double> p2) => {
      'x': p2['x']! - p1['x']!,
      'y': p2['y']! - p1['y']!,
      'z': p2['z']! - p1['z']!,
    };

    double dot(Map<String, double> v1, Map<String, double> v2) =>
        v1['x']! * v2['x']! + v1['y']! * v2['y']! + v1['z']! * v2['z']!;

    Map<String, double> scaleVec(Map<String, double> v, double scalar) => {
      'x': v['x']! * scalar,
      'y': v['y']! * scalar,
      'z': v['z']! * scalar,
    };

    Map<String, double> addVec(Map<String, double> v1, Map<String, double> v2) => {
      'x': v1['x']! + v2['x']!,
      'y': v1['y']! + v2['y']!,
      'z': v1['z']! + v2['z']!,
    };

    final aCart = toCartesian(a);
    final bCart = toCartesian(b);
    final cCart = toCartesian(c);

    final ab = vectorBetween(aCart, bCart);
    final ac = vectorBetween(aCart, cCart);

    final t = dot(ac, ab) / dot(ab, ab);
    final dCart = addVec(aCart, scaleVec(ab, t));

    final d = toLatLng(dCart);

    final cdVector = vectorBetween(dCart, cCart);
    final magnitudeCD = sqrt(dot(cdVector, cdVector));
    final distanceCD = asin(magnitudeCD) * earthRadiusFeet;

    return {
      'distance': distanceCD,
      'pointD': d,
    };
  }


  static List<int> hexToBytes(String hex) {
    hex = hex.replaceAll("0x", "").replaceAll(" ", "");
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  // static Map<String, double>? globalToLocalPoints(
  //     {required PDM.patchDataModel? patchData,
  //      required double lat,
  //       required double lng,
  //     }
  // ) {
  //
  //   lat = lat - 0;
  //   lng = lng - 0;
  //   ////
  //   PDM.patchDataModel Data = PDM.patchDataModel();
  //   if (patchData != null) {
  //     Data = patchData;
  //     if(patchData.patchData!.fileName == "004ef3cf-9294-4171-adc0-1554759d5400_IITCampus-BhartiSchool-ground_ground.png"){
  //       gotBhart = true;
  //     }
  //
  //   } else {
  //     Data = globalData;
  //   }
  //   List<Map<String, double>> ref = [
  //     {
  //       "lat": double.parse(Data.patchData!.coordinates![2].globalRef!.lat!),
  //       "lon": double.parse(Data.patchData!.coordinates![2].globalRef!.lng!),
  //       "localx": double.parse(Data.patchData!.coordinates![2].localRef!.lng!),
  //       "localy": double.parse(Data.patchData!.coordinates![2].localRef!.lat!),
  //     },
  //     {
  //       "lat": double.parse(Data.patchData!.coordinates![1].globalRef!.lat!),
  //       "lon": double.parse(Data.patchData!.coordinates![1].globalRef!.lng!),
  //       "localx": double.parse(Data.patchData!.coordinates![1].localRef!.lng!),
  //       "localy": double.parse(Data.patchData!.coordinates![1].localRef!.lat!),
  //     },
  //     {
  //       "lat": double.parse(Data.patchData!.coordinates![0].globalRef!.lat!),
  //       "lon": double.parse(Data.patchData!.coordinates![0].globalRef!.lng!),
  //       "localx": double.parse(Data.patchData!.coordinates![0].localRef!.lng!),
  //       "localy": double.parse(Data.patchData!.coordinates![0].localRef!.lat!),
  //     },
  //     {
  //       "lat": double.parse(Data.patchData!.coordinates![3].globalRef!.lat!),
  //       "lon": double.parse(Data.patchData!.coordinates![3].globalRef!.lng!),
  //       "localx": double.parse(Data.patchData!.coordinates![3].localRef!.lng!),
  //       "localy": double.parse(Data.patchData!.coordinates![3].localRef!.lat!),
  //     },
  //   ];
  //
  // int d1 = (getHaversineDistance2(ref[0]['lat']!, ref[0]['lon']!, lat, lng) * 3).toInt();
  // int d2 = (getHaversineDistance2(ref[1]['lat']!, ref[1]['lon']!, lat, lng) * 3).toInt();
  // int d3 = (getHaversineDistance2(ref[2]['lat']!, ref[2]['lon']!, lat, lng) * 3).toInt();
  //
  // Circle circle1 = Circle(
  // localx: ref[0]['localx']!,
  // localy: ref[0]['localy']!,
  // distance: d1,
  // );
  //
  // Circle circle2 = Circle(
  //   localx: ref[1]['localx']!,
  //   localy: ref[1]['localy']!,
  // distance: d2,
  // );
  //
  // Circle circle3 = Circle(
  //   localx: ref[2]['localx']!,
  //   localy: ref[2]['localy']!,
  // distance: d3,
  // );
  //
  // return circleIntersection(circle1, circle2, circle3);
  // }
  //
  // static double getHaversineDistance2(
  // double firstLat,
  // double firstLng,
  // double secondLat,
  // double secondLng,
  // ) {
  // const double earthRadius = 6371; // km
  //
  // final double diffLat = ((secondLat - firstLat) * pi) / 180;
  // final double diffLng = ((secondLng - firstLng) * pi) / 180;
  //
  // final double arc = cos((firstLat * pi) / 180) *
  // cos((secondLat * pi) / 180) *
  // sin(diffLng / 2) *
  // sin(diffLng / 2) +
  // sin(diffLat / 2) * sin(diffLat / 2);
  //
  // final double line = 2 * atan2(sqrt(arc), sqrt(1 - arc));
  // final double distance = earthRadius * line * 1000;
  //
  // return distance;
  // }
  //
  // static Map<String, double>? circleIntersection(
  // Circle circle1,
  // Circle circle2,
  // Circle circle3,
  // ) {
  // // Extract parameters for each circle
  // final double x1 = circle1.localx;
  // final double y1 = circle1.localy;
  // final double r1 = circle1.distance.toDouble();
  //
  // final double x2 = circle2.localx;
  // final double y2 = circle2.localy;
  // final double r2 = circle2.distance.toDouble();
  //
  // final double x3 = circle3.localx;
  // final double y3 = circle3.localy;
  // final double r3 = circle3.distance.toDouble();
  //
  // // Calculate distances between centers of circles
  // final double d12 = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  // final double d23 = sqrt(pow(x3 - x2, 2) + pow(y3 - y2, 2));
  // final double d31 = sqrt(pow(x1 - x3, 2) + pow(y1 - y3, 2));
  //
  // // Check if any circle is fully contained within another circle
  // if (d12 < r1 + r2 && d23 < r2 + r3 && d31 < r3 + r1) {
  // print("Circles are fully contained within each other. Infinite intersections.");
  // return null;
  // }
  //
  // // Check for no intersection cases
  // if (d12 > r1 + r2 && d23 > r2 + r3 && d31 > r3 + r1) {
  // print("Circles do not intersect.");
  // return null;
  // }
  //
  // // Calculate intersection points
  // final double A = 2 * (x2 - x1);
  // final double B = 2 * (y2 - y1);
  // final double C = (pow(r1, 2) - pow(r2, 2) - pow(x1, 2) + pow(x2, 2) - pow(y1, 2) + pow(y2, 2)).toDouble();
  // final double D = 2 * (x3 - x2);
  // final double E = 2 * (y3 - y2);
  // final double F = (pow(r2, 2) - pow(r3, 2) - pow(x2, 2) + pow(x3, 2) - pow(y2, 2) + pow(y3, 2)).toDouble();
  //
  // // Calculate intersection coordinates
  // final double x = (C * E - F * B) / (E * A - B * D);
  // final double y = (C * D - A * F) / (B * D - A * E);
  //
  // return {'x': x, 'y': y};
  // }

}
class RefPoint {
  final double lat;
  final double lng;
  final double localx;
  final double localy;

  RefPoint({
    required this.lat,
    required this.lng,
    required this.localx,
    required this.localy,
  });
}

class Circle {
  final double localx;
  final double localy;
  final int distance;

  Circle({
    required this.localx,
    required this.localy,
    required this.distance,
  });
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}
