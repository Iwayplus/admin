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
      final outlierMap = <String, List<Map<String, dynamic>>>{};

      for (var data in sensorDataList) {
        for (var beacon in data.beacons!) {
          if (beacon.beaconRssi! >= -95) {
            beaconMap.putIfAbsent(beacon.beaconMacId!, () => []).add(beacon.beaconRssi!);
          } else {
            outlierMap.putIfAbsent(beacon.beaconMacId!, () => []).add({
              'value': beacon.beaconRssi,
              'outlierType': 'weak_signal',
            });
          }
        }
      }

      final beaconStats = beaconMap.map((macId, rssiList) {
        final mean = rssiList.reduce((a, b) => a + b) / rssiList.length;
        final variance = rssiList.fold(0.0, (sum, val) => sum + pow(val - mean, 2)) / rssiList.length;
        final stdDev = sqrt(variance);

        return MapEntry(macId, {
          'mean': mean,
          'stdDev': stdDev,
          'outliers': outlierMap[macId] ?? [],
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
    final outlierMap = <String, List<Map<String, dynamic>>>{};

    for (var data in realtimeSensorData) {
      for (var beacon in data.beacons!) {
        if (beacon.beaconRssi! >= -95) {
          beaconMap.putIfAbsent(beacon.beaconMacId!, () => []).add(beacon.beaconRssi!);
        } else {
          outlierMap.putIfAbsent(beacon.beaconMacId!, () => []).add({
            'value': beacon.beaconRssi,
            'outlierType': 'weak_signal',
          });
        }
      }
    }

    final beaconStats = beaconMap.map((macId, rssiList) {
      final mean = rssiList.reduce((a, b) => a + b) / rssiList.length;
      final variance = rssiList.fold(0.0, (sum, val) => sum + pow(val - mean, 2)) / rssiList.length;
      final stdDev = sqrt(variance);

      return MapEntry(macId,{
        'mean': mean,
        'stdDev': stdDev,
        'outliers': outlierMap[macId] ?? [],
      });
    });

    result['realtime'] = {
      'beacons': beaconStats,
    };

    print("realtime data:${result}");

    return result;
  }


  String findBestMatchingLocation() {
    final realtimeBeacons = realTimeData['realtime']?['beacons'] as Map<String, dynamic>;

    // Step 1: Determine max overlapping beacons count
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

    // Step 2: Filter locations with max overlap
    String? nearestLocation;
    double minDistance = double.infinity;

    locationOverlapMap.forEach((locationKey, overlap) {
      if (overlap == maxOverlap) {
        final preBeacons = preProcessedData[locationKey]['beacons'] as Map<String, dynamic>;
        double distance = 0;

        for (final macId in realtimeBeacons.keys) {
          if (preBeacons.containsKey(macId)) {
            final realMean = realtimeBeacons[macId]['mean'] as double;
            final preMean = preBeacons[macId]['mean'] as double;

            distance += pow(preMean - realMean, 2);
          }
        }

        distance = sqrt(distance);
        if (distance < minDistance) {
          minDistance = distance;
          nearestLocation = locationKey;
        }
      }
    });

    print("nearestPOint:${nearestLocation}");

    realTimeData.clear();
    locationOverlapMap.clear();
    minDistance=double.infinity;
    return nearestLocation ?? 'unknown';
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
   realTimeData= computeRealtimeBeaconStats(data!.sensorFingerprint!);

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