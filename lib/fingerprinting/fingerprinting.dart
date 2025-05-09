import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:admin/HelperClass.dart';
import 'package:admin/api/buildingAllApi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:light/light.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../APIMODELS/Building.dart';
import '../APIMODELS/FingerPrintData.dart' as fp;
import '../APIMODELS/beaconData.dart';
import '../APIMODELS/polylinedata.dart' as poly;
import '../Bluetooth/BluetoothScanAndroidClass.dart';
import '../GPS.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../api/beaconapi.dart';
import '../api/fingerPrintGet.dart';
import '../api/fingerPrintingApi.dart';
import '../beaconController.dart';
import 'SensorFingerprint.dart';
import 'pannels/finger_printing_pannel_controller.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../polygonController.dart';

class Fingerprinting{
  late BuildContext _context;
  Set<Marker> _dotMarkers = {};
  Set<Marker> _Markers = {};
  late fingerprintingPannel FingerPrintingPannel;
  fp.FingerPrintData? fingerPrintData;
  late Function _updateMarkers;
  Map<String, beacon>? apibeaconmap;
  poly.Nodes? userPosition;
  int? floor;
  GPS gps = GPS();
  Data? data;
  geo.Position? gpsPosition;
  double _x = 0.0, _y = 0.0, _z = 0.0;
  double theta = 0.0;
  int _lightValue = 0;
  Light _light = Light();
  StreamSubscription? _Lightsubscription;
  final DateFormat dateFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");
  Timer? timer;
  BluetoothScanAndroidClass bluetoothScanAndroidClass = BluetoothScanAndroidClass();

  List<WiFiAccessPoint> accessPoints = [];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;

  Fingerprinting() {
    FingerPrintingPannel = fingerprintingPannel(fingerprinting: this);
  }


  set updateMarkers(Function value) {
    _updateMarkers = value;
  }

  set context(BuildContext value) {
    _context = value;
  }

  Map<String,dynamic> preProcessedData={};
  Map<String,dynamic> realTimeData={};

  Future<void> enableFingerprinting(PolygonController polygonController, BeaconController beaconController) async {
    print("inside enabling");
    _dotMarkers.clear();
    floor = polygonController.floor;
    apibeaconmap = beaconController.apibeaconmap;
    var fingerPrintData = await fingerPrintingGetApi().Finger_Printing_GET_API(buildingAllApi.selectedBuildingID);
    print("fingerprint data:${fingerPrintData!.fingerPrintData}");
    preProcessedData=computeBeaconStats(fingerPrintData!.fingerPrintData);
    List<poly.Nodes> waypoints = await polygonController.extractWaypoints();
    for (var point in waypoints) {
      await addDotMarker(point, fingerPrintData);
    }
    print("enabled");
  }

  void disableFingerprinting(){
    _dotMarkers.clear();
    _Markers.clear();
    accessPoints = [];
    subscription = null;
    userPosition = null;
    floor = null;
    apibeaconmap = null;
    gps = GPS(); // Reinitialize GPS object if required
    data = null;
    gpsPosition = null;
    _x = 0.0;
    _y = 0.0;
    _z = 0.0;
    theta = 0.0;
    _lightValue = 0;

    // Cancel any active subscriptions and reset
    _Lightsubscription?.cancel();
    _Lightsubscription = null;

    // Cancel the timer if active
    timer?.cancel();
    timer = null;
    FingerPrintingPannel.hidePanel();
    _updateMarkers();
  }

  Future<void> addDotMarker(poly.Nodes point, fp.FingerPrintData? fingerPrintData) async {
    print("dotmarker");
    var svgIcon = await _svgToBitmapDescriptor('assets/dot.svg', Size(40, 40));
    if(fingerPrintData != null && fingerPrintData.fingerPrintData["${point.coordx},${point.coordy},$floor"] != null){
      svgIcon = await _svgToBitmapDescriptor('assets/exitservice.svg', Size(40, 40));
    }

    _dotMarkers.add(
      Marker(
          markerId: MarkerId('${point.lat!},${point.lon!}'),
          position: LatLng(point.lat!, point.lon!),
          icon: svgIcon,
          onTap:(){
            _Markers.clear();
            FingerPrintingPannel.showPanel();
            userPosition = point;
            addMarker(LatLng(point.lat!, point.lon!));
          }
      ),
    );
    _updateMarkers();
  }





  Map<String, dynamic> computeBeaconStats(Map<String, List<fp.SensorData>> locationSensorData) {
    final result = <String, dynamic>{};

    locationSensorData.forEach((locationKey, sensorDataList) {
      final beaconMap = <String, List<int>>{};
      final weakOutlierMap = <String, List<Map<String, dynamic>>>{};
      final deviationOutlierMap = <String, List<Map<String, dynamic>>>{};

      // Step 1: Collect all valid RSSI readings
      for (var data in sensorDataList) {
        for (var beacon in data.beacons ?? []) {
          final macId = beacon.beaconMacId;
          final rssi = beacon.beaconRssi;

          if (macId == null || rssi == null) continue;

          if (rssi >= -95) {
            beaconMap.putIfAbsent(macId, () => []).add(rssi);
          } else {
            weakOutlierMap.putIfAbsent(macId, () => []).add({
              'value': rssi,
              'outlierType': 'weak_signal',
            });
          }
        }
      }

      // Step 2: Compute stats + deviation outliers
      final beaconStats = beaconMap.map((macId, rssiList) {
        final mean = rssiList.reduce((a, b) => a + b) / rssiList.length;
        final variance = rssiList.fold(0.0, (sum, val) => sum + pow(val - mean, 2)) / rssiList.length;
        final stdDev = sqrt(variance);

        final cleanedRssiList = <int>[];
        for (var rssi in rssiList) {
          if (stdDev == 0 || (rssi >= mean - 2 * stdDev && rssi <= mean + 2 * stdDev)) {
            cleanedRssiList.add(rssi);
          } else {
            deviationOutlierMap.putIfAbsent(macId, () => []).add({
              'value': rssi,
              'outlierType': 'deviation_outlier',
            });
          }
        }

        // Recalculate mean and std dev after removing deviation outliers
        final finalMean = cleanedRssiList.isNotEmpty
            ? cleanedRssiList.reduce((a, b) => a + b) / cleanedRssiList.length
            : 0.0;
        final finalVariance = cleanedRssiList.isNotEmpty
            ? cleanedRssiList.fold(0.0, (sum, val) => sum + pow(val - finalMean, 2)) / cleanedRssiList.length
            : 0.0;
        final finalStdDev = sqrt(finalVariance);

        final allOutliers = [
          ...?weakOutlierMap[macId],
          ...?deviationOutlierMap[macId],
        ];

        return MapEntry(macId, {
          'mean': finalMean,
          'stdDev': finalStdDev,
          'outliers': allOutliers,
        });
      });

      result[locationKey] = {
        'beacons': beaconStats,
      };
    });

    return result;
  }


  Map<String, dynamic> computeRealtimeBeaconStats(List<SensorFingerprint> realtimeSensorData) {
    final result = <String, dynamic>{};
    final beaconMap = <String, List<int>>{};
    final weakOutlierMap = <String, List<Map<String, dynamic>>>{};
    final deviationOutlierMap = <String, List<Map<String, dynamic>>>{};

    // Step 1: Collect RSSI values and weak signal outliers
    for (var data in realtimeSensorData) {
      for (var beacon in data.beacons ?? []) {
        final macId = beacon.beaconMacId;
        final rssi = beacon.beaconRssi;
        if (macId == null || rssi == null) continue;
        if (rssi >= -95) {
          beaconMap.putIfAbsent(macId, () => []).add(rssi);
        } else {
          weakOutlierMap.putIfAbsent(macId, () => []).add({
            'value': rssi,
            'outlierType': 'weak_signal',
          });
        }
      }
    }
    // Step 2: Compute stats and flag deviation outliers
    final beaconStats = beaconMap.map((macId, rssiList) {
      final mean = rssiList.reduce((a, b) => a + b) / rssiList.length;
      final variance = rssiList.fold(0.0, (sum, val) => sum + pow(val - mean, 2)) / rssiList.length;
      final stdDev = sqrt(variance);

      final cleanedRssiList = <int>[];
      for (var rssi in rssiList) {
        if (stdDev == 0 || (rssi >= mean - 2 * stdDev && rssi <= mean + 2 * stdDev)) {
          cleanedRssiList.add(rssi);
        } else {
          deviationOutlierMap.putIfAbsent(macId, () => []).add({
            'value': rssi,
            'outlierType': 'deviation_outlier',
          });
        }
      }

      final finalMean = cleanedRssiList.isNotEmpty
          ? cleanedRssiList.reduce((a, b) => a + b) / cleanedRssiList.length
          : 0.0;
      final finalVariance = cleanedRssiList.isNotEmpty
          ? cleanedRssiList.fold(0.0, (sum, val) => sum + pow(val - finalMean, 2)) / cleanedRssiList.length
          : 0.0;
      final finalStdDev = sqrt(finalVariance);

      final allOutliers = [
        ...?weakOutlierMap[macId],
        ...?deviationOutlierMap[macId],
      ];

      return MapEntry(macId, {
        'mean': finalMean,
        'stdDev': finalStdDev,
        'outliers': allOutliers,
      });
    });

    result['realtime'] = {
      'beacons': beaconStats,
    };

    print("realtime data: $result");

    return result;
  }



  // String findBestMatchingLocationWithCosine() {
  //   final realtimeBeacons = realTimeData['realtime']?['beacons'] as Map<String, dynamic>;
  //   if (realtimeBeacons.isEmpty) return 'unknown';
  //
  //   int maxOverlap = 0;
  //   final Map<String, int> locationOverlapMap = {};
  //
  //   // Step 1: Calculate overlaps
  //   preProcessedData.forEach((locationKey, data) {
  //     final preBeacons = data['beacons'] as Map<String, dynamic>;
  //     final overlapCount = preBeacons.keys
  //         .where((macId) => realtimeBeacons.containsKey(macId))
  //         .length;
  //
  //     locationOverlapMap[locationKey] = overlapCount;
  //     if (overlapCount > maxOverlap) {
  //       maxOverlap = overlapCount;
  //     }
  //   });
  //
  //   // Step 2: Use cosine similarity for locations with max overlap
  //   String? bestLocation;
  //   double? highestSimilarity = -1;
  //
  //   locationOverlapMap.forEach((locationKey, overlap) {
  //     if (overlap == maxOverlap) {
  //       final preBeacons = preProcessedData[locationKey]['beacons'] as Map<String, dynamic>;
  //
  //       double dotProduct = 0;
  //       double magnitudeA = 0;
  //       double magnitudeB = 0;
  //
  //       for (final macId in realtimeBeacons.keys) {
  //         if (preBeacons.containsKey(macId)) {
  //           final realMean = realtimeBeacons[macId]['mean'] as double;
  //           final preMean = preBeacons[macId]['mean'] as double;
  //
  //           dotProduct += realMean * preMean;
  //           magnitudeA += pow(realMean, 2);
  //           magnitudeB += pow(preMean, 2);
  //         }
  //       }
  //
  //       final denominator = sqrt(magnitudeA) * sqrt(magnitudeB);
  //       final double similarity = denominator == 0 ? 0 : dotProduct / denominator;
  //
  //       if (similarity > highestSimilarity!) {
  //         highestSimilarity = similarity;
  //         bestLocation = locationKey;
  //       }
  //     }
  //   });
  //
  //   print("Best match (cosine): $bestLocation");
  //
  //   realTimeData.clear();
  //   locationOverlapMap.clear();
  //   bestLocation=null;
  //
  //   return bestLocation ?? 'unknown';
  // }


  // String findBestMatchingLocationHybrid({double weightCosine = 0.6, double weightDistance = 0.4}) {
  //   final realtimeBeacons = realTimeData['realtime']?['beacons'] as Map<String, dynamic>;
  //   if (realtimeBeacons.isEmpty) return 'unknown';
  //
  //   int maxOverlap = 0;
  //   final Map<String, int> locationOverlapMap = {};
  //
  //   // Step 1: Compute overlaps
  //   preProcessedData.forEach((locationKey, data) {
  //     final preBeacons = data['beacons'] as Map<String, dynamic>;
  //     final overlapCount = preBeacons.keys
  //         .where((macId) => realtimeBeacons.containsKey(macId))
  //         .length;
  //
  //     locationOverlapMap[locationKey] = overlapCount;
  //     if (overlapCount > maxOverlap) {
  //       maxOverlap = overlapCount;
  //     }
  //   });
  //
  //   String? bestLocation;
  //   double bestScore = -1;
  //
  //   locationOverlapMap.forEach((locationKey, overlap) {
  //     if (overlap == maxOverlap) {
  //       final preBeacons = preProcessedData[locationKey]['beacons'] as Map<String, dynamic>;
  //
  //       double dotProduct = 0;
  //       double magnitudeA = 0;
  //       double magnitudeB = 0;
  //       double distanceSum = 0;
  //
  //       for (final macId in realtimeBeacons.keys) {
  //         if (preBeacons.containsKey(macId)) {
  //           final realMean = realtimeBeacons[macId]['mean'] as double;
  //           final preMean = preBeacons[macId]['mean'] as double;
  //           dotProduct += realMean * preMean;
  //           magnitudeA += pow(realMean, 2);
  //           magnitudeB += pow(preMean, 2);
  //
  //           distanceSum += pow(preMean - realMean, 2);
  //         }
  //       }
  //
  //       final cosineDenominator = sqrt(magnitudeA) * sqrt(magnitudeB);
  //       final cosineSim = cosineDenominator == 0 ? 0 : dotProduct / cosineDenominator;
  //
  //       final euclideanDistance = sqrt(distanceSum);
  //       final invDistanceScore = euclideanDistance == 0 ? 1 : 1 / euclideanDistance; // normalize
  //
  //       final hybridScore = (cosineSim * weightCosine) + (invDistanceScore * weightDistance);
  //
  //       if (hybridScore > bestScore) {
  //         bestScore = hybridScore;
  //         bestLocation = locationKey;
  //       }
  //     }
  //   });
  //
  //   print("Best location (hybrid): $bestLocation");
  //
  //   realTimeData.clear();
  //   locationOverlapMap.clear();
  //   bestScore=-1;
  //   realtimeBeacons.clear();
  //
  //
  //   return bestLocation ?? 'unknown';
  // }



  List<String> predictionHistory = [];

  String findBestMatchingLocationHybrid({
    int historyLimit = 7,
    double cosineWeight = 0.4,
    double distanceWeight = 0.6,
    double confidenceThreshold = 0.4,
  }) {
    realTimeData = computeRealtimeBeaconStats(data!.sensorFingerprint!);
    final realtimeBeacons = realTimeData['realtime']?['beacons'] as Map<String, dynamic>;

    // Step 1: Determine max overlapping beacons
    int maxOverlap = 0;
    final Map<String, int> locationOverlapMap = {};

    preProcessedData.forEach((locationKey, data) {
      final preBeacons = data['beacons'] as Map<String, dynamic>;
      final overlapCount = preBeacons.keys
          .where((macId) => realtimeBeacons.containsKey(macId))
          .length;

      locationOverlapMap[locationKey] = overlapCount;
      if (overlapCount > maxOverlap) {
        maxOverlap = overlapCount;
      }
    });

    // Step 2: Compare cosine + distance for locations with max overlap
    String? bestLocation;
    double bestScore = -double.infinity;

    locationOverlapMap.forEach((locationKey, overlap) {
      if (overlap == maxOverlap) {
        final preBeacons = preProcessedData[locationKey]['beacons'] as Map<String, dynamic>;

        final List<double> realtimeVector = [];
        final List<double> preprocessedVector = [];

        double distance = 0;

        for (final macId in realtimeBeacons.keys) {
          if (preBeacons.containsKey(macId)) {
            final realMean = realtimeBeacons[macId]['mean'] as double;
            final preMean = preBeacons[macId]['mean'] as double;

            realtimeVector.add(realMean);
            preprocessedVector.add(preMean);

            distance += pow(preMean - realMean, 2);
          }
        }

        distance = sqrt(distance);
        final cosineSimilarity = computeCosineSimilarity(realtimeVector, preprocessedVector);

        // Combine into score
        final similarityScore =
            (cosineSimilarity * cosineWeight) + ((1 / (1 + distance)) * distanceWeight);

        if (similarityScore > bestScore) {
          bestScore = similarityScore;
          bestLocation = locationKey;
        }
      }
    });

    print("Best location (raw): $bestLocation with score: $bestScore");

    // === History logic with weighting and filtering ===
    if (bestLocation != null && bestScore >= confidenceThreshold) {
      // If a major change occurs, reset history
      if (!predictionHistory.contains(bestLocation)) {
        predictionHistory.clear();
      }

      predictionHistory.add(bestLocation!);
      if (predictionHistory.length > historyLimit) {
        predictionHistory.removeAt(0);
      }

      // Weighted voting: newer predictions carry more weight
      final Map<String, double> weightedCounts = {};
      for (int i = 0; i < predictionHistory.length; i++) {
        final loc = predictionHistory[i];
        final weight = (i + 1) / predictionHistory.length;
        weightedCounts[loc] = (weightedCounts[loc] ?? 0) + weight;
      }

      final smoothed = weightedCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      print("smoothed values:${smoothed},${predictionHistory}");
      return smoothed;
    }

    return bestLocation ?? 'unknown';
  }



  double computeCosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;

    double dotProduct = 0, normA = 0, normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return (normA == 0 || normB == 0) ? 0 : dotProduct / (sqrt(normA) * sqrt(normB));
  }



  Future<void> addMarker(LatLng _markerPosition) async {
    print("latlng:${_markerPosition.latitude},${_markerPosition.longitude}");
      _Markers.add(
        Marker(
            markerId: MarkerId('${_markerPosition.latitude},${_markerPosition.longitude}'),
            position: _markerPosition,
            onTap: (){
              print("on dot marker");
            }
        ),
      );
      _updateMarkers();
  }

  Future<BitmapDescriptor> _svgToBitmapDescriptor(String svgAsset, Size size,) async {
    // Load SVG data
    String svgString = await DefaultAssetBundle.of(_context).loadString(svgAsset);

    // Render SVG to picture
    DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);
    final picture = svgDrawableRoot.toPicture(
      size: size, // Define the size of the SVG
    );

    // Convert to image
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  Set<Marker> getMarkers(){
    return _dotMarkers.union(_Markers);
  }


  Future<void> collectSensorDataEverySecond() async {
    if(apibeaconmap != null){
      bluetoothScanAndroidClass.listenToScanUpdates(apibeaconmap!);
    }else{
      HelperClass.showToast("Getting beacon data!!");
    }

    _startListeningToScannedResults();

    data = Data(position: "${userPosition?.coordx},${userPosition?.coordy},$floor");

    gps.startGpsUpdates();
    gps.positionStream.listen((position){
      gpsPosition = position;
    });

    accelerometerEvents.listen((AccelerometerEvent event) {
      _x = event.x;
      _y = event.y;
      _z = event.z;
    });


    FlutterCompass.events!.listen((event){
      theta = event.heading!;
    });

    _Lightsubscription = _light.lightSensorStream.listen((value){
      _lightValue = value;
    });

    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      List<Beacon> beacons = await fetchBeaconData();
      print(beacons);
      var gpsData = await fetchGpsData();
      var wifi = await fetchWifiData();
      var magnetometerData = await fetchMagnetometerData();
      var accelerometerData = await fetchAccelerometerData();
      var lux = await fetchLux();

      var fingerprint = SensorFingerprint(
        beacons: beacons,
        wifi: wifi,
        gpsData: gpsData,
        magnetometerData: magnetometerData,
        accelerometerData: accelerometerData,
        lux: lux,
        timeStamp: dateFormat.format(DateTime.now().toUtc())
      );
      data?.sensorFingerprint ??= [];
      data?.sensorFingerprint?.add(fingerprint);
      print("data.toJson() ${data?.toJson()}");
    });

  }

  Future<bool> stopCollectingData() async {
    timer?.cancel();
    bluetoothScanAndroidClass.stopScan();
    //cancel beacon stream here
    return await fingerPrintingApi().Finger_Printing_API(buildingAllApi.selectedBuildingID, data!);
  }

  Future<bool> stopCollectingRealData() async {
    timer?.cancel();
    bluetoothScanAndroidClass.stopScan();
    //cancel beacon stream here


    return true;
  }

  void _startListeningToScannedResults() async {
    // check platform support and necessary requirements
    final can = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if(can == CanGetScannedResults.yes){
      subscription = WiFiScan.instance.onScannedResultsAvailable.listen((results) {
        accessPoints = results;
      });
    }
  }

  Future<List<Beacon>> fetchBeaconData() async {
    Map<String, List<int>> beaconvalues = await bluetoothScanAndroidClass.getDeviceWithRssi();
    Map<String, double> averageValue = await bluetoothScanAndroidClass.getDeviceWithAverage();
    Map<String, String> deviceNames = await bluetoothScanAndroidClass.getDeviceName();

    List<Beacon> beacons = [];
    beaconvalues.forEach((key,value){
      if(apibeaconmap != null && apibeaconmap![key] != null){
        Position position = Position(x:(apibeaconmap![key]!.coordinateX??apibeaconmap![key]!.doorX!).toDouble(),y:(apibeaconmap![key]!.coordinateY??apibeaconmap![key]!.doorY!).toDouble());
        beacons.add(setBeacon(key, deviceNames[key], value.last,position,apibeaconmap![key]!.floor!.toString(),apibeaconmap![key]!.buildingID));
      }
    });

    print("beaconvalues $beaconvalues");
    //call this line for every beacon scanned using a for loop
    // beacons.add(setBeacon(null,null,null));

    return beacons;
  }

  Beacon setBeacon(String? beaconMacId, String? beaconName, int? beaconRssi, Position? beaconPosition,   String? beaconFloor,   String? buildingId){
    return Beacon(
        beaconMacId: beaconMacId, beaconName: beaconName, beaconRssi: beaconRssi, beaconPosition: beaconPosition,beaconFloor:beaconFloor,buildingId:buildingId
    );
  }

  Future<GpsData> fetchGpsData() async {
    if(gpsPosition == null){
      return GpsData(latitude: null, longitude: null, accuracy: null, altitude: null);
    }
    return GpsData(latitude: gpsPosition!.latitude, longitude: gpsPosition!.longitude, accuracy: gpsPosition!.accuracy,altitude: gpsPosition!.altitude);
  }

  Future<MagnetometerData> fetchMagnetometerData() async {
    return MagnetometerData(value: theta);
  }

  Future<List<Wifi>> fetchWifiData() async {
    List<Wifi> wifilist = [];
    for (var wifi in accessPoints) {
      wifilist.add(Wifi(wifiName: wifi.bssid, wifiStrength: wifi.level));
    }
    return wifilist;
  }


  Future<AccelerometerData> fetchAccelerometerData() async {
    return AccelerometerData(x: _x, y: _y, z: _z);
  }

  Future<double> fetchLux() async {
    return _lightValue.toDouble();
  }


}