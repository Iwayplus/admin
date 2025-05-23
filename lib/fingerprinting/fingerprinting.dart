import 'dart:async';
import 'dart:typed_data';

import 'package:admin/api/buildingAllApi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:light/light.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../APIMODELS/FingerPrintData.dart' as fp;
import '../APIMODELS/polylinedata.dart' as poly;
import '../GPS.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../api/fingerPrintGet.dart';
import '../api/fingerPrintingApi.dart';
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

  Fingerprinting() {
    FingerPrintingPannel = fingerprintingPannel(fingerprinting: this);
  }


  set updateMarkers(Function value) {
    _updateMarkers = value;
  }

  set context(BuildContext value) {
    _context = value;
  }

  Future<void> enableFingerprinting(PolygonController polygonController) async {
    print("inside enabling");
    _dotMarkers.clear();
    floor = polygonController.floor;
    fingerPrintData = await fingerPrintingGetApi().Finger_Printing_GET_API(buildingAllApi.selectedBuildingID);
    List<poly.Nodes> waypoints = await polygonController.extractWaypoints();
    for (var point in waypoints) {
      await addDotMarker(point);
    }
    print("enabled");
  }

  void disableFingerprinting(){
    _dotMarkers.clear();
    _Markers.clear();
    userPosition = null;
    floor = null;
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

  Future<void> addDotMarker(poly.Nodes point) async {
    print("dotmarker");
    var svgIcon = await _svgToBitmapDescriptor('assets/dot.svg', Size(40, 40));
    if(fingerPrintData!.fingerPrintData["${point.coordx},${point.coordy},$floor"] != null){
      svgIcon = await _svgToBitmapDescriptor('assets/exitservice.svg', Size(40, 40));
    }

    _dotMarkers.add(
      Marker(
          markerId: MarkerId('${point.lat!},${point.lon!}'),
          position: LatLng(point.lat!, point.lon!),
          icon: svgIcon,
          onTap: (){
            _Markers.clear();
            FingerPrintingPannel.showPanel();
            userPosition = point;
            addMarker(LatLng(point.lat!, point.lon!));
          }
      ),
    );
    _updateMarkers();
  }

  Future<void> addMarker(LatLng _markerPosition) async {
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

    //turn on beacon stream

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
      var gpsData = await fetchGpsData();
      var magnetometerData = await fetchMagnetometerData();
      var accelerometerData = await fetchAccelerometerData();
      var lux = await fetchLux();

      var fingerprint = SensorFingerprint(
        beacons: beacons,
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

  void stopCollectingData(){
    timer?.cancel();

    //cancel beacon stream here
    fingerPrintingApi().Finger_Printing_API(buildingAllApi.selectedBuildingID, data!);
  }

  Future<List<Beacon>> fetchBeaconData() async {
    List<Beacon> beacons = [];

    //call this line for every beacon scanned using a for loop
    beacons.add(setBeacon(null,null,null));

    return beacons;
  }

  Beacon setBeacon(String? beaconMacId, String? beaconName, int? beaconRssi ){
    return Beacon(
        beaconMacId: beaconMacId, beaconName: beaconName, beaconRssi: beaconRssi
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

  Future<AccelerometerData> fetchAccelerometerData() async {
    return AccelerometerData(x: _x, y: _y, z: _z);
  }

  Future<double> fetchLux() async {
    return _lightValue.toDouble();
  }


}