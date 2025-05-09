import 'dart:async';

import 'package:admin/fingerprinting/pannels/finger_printing_pannel_controller.dart';
import 'package:admin/modes.dart';
import 'package:admin/patchController.dart';
import 'package:admin/polygonController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'APIMODELS/FingerPrintData.dart';
import 'APIMODELS/polylinedata.dart' as poly;
import 'GPS.dart';
import 'api/buildingAllApi.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'api/fingerPrintGet.dart';
import 'beaconController.dart';
import 'fingerprinting/fingerprinting.dart';

class googleMap extends StatefulWidget {
  const googleMap({super.key});

  @override
  State<googleMap> createState() => _googleMapState();
}

class _googleMapState extends State<googleMap> {
  GPS gps = GPS();
  late GoogleMapController _googleMapController;
  PolygonController polygonController = PolygonController();
  BeaconController beaconController = BeaconController();
  PatchController patchController = PatchController();
  final _initialCameraPosition = const CameraPosition(
    target: LatLng(60.543833319119475, 77.18729871127312),
    zoom: 0,
  );
  Set<Polygon> polygons = Set();
  Set<Polyline> polylines = Set();

  Fingerprinting fingerprinting = Fingerprinting();

  availableModes modes = availableModes();

  @override
  void initState() {
    super.initState();
    fingerprinting.context = context;
    fingerprinting.updateMarkers = updateMarkers;
  }

  Future<void> goToUser() async {
    Position userPosition = await gps.getCurrentCoordinates();
    _googleMapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(userPosition.latitude, userPosition.longitude),
        22, // Specify your custom zoom level here
      ),
    );
  }

  Future<void> createRooms() async {
    buildingAllApi buildingController = buildingAllApi();
    await buildingController.fetchBuildingAllData();
    await patchController.createPatch();
    fitPolygonInScreen(patchController.polygons.first);
    await polygonController.renderRooms(0);
    await beaconController.getBeacons();

    setState(() {});
  }

  void fitPolygonInScreen(Polygon polygon) {

    List<LatLng> getPolygonPoints(Polygon polygon) {
      List<LatLng> polygonPoints = [];
      for (var point in polygon.points) {
        polygonPoints.add(LatLng(point.latitude, point.longitude));
      }
      return polygonPoints;
    }

    List<LatLng> polygonPoints = getPolygonPoints(polygon);
    double minLat = polygonPoints[0].latitude;
    double maxLat = polygonPoints[0].latitude;
    double minLng = polygonPoints[0].longitude;
    double maxLng = polygonPoints[0].longitude;

    for (LatLng point in polygonPoints) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }
      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }
      if (point.longitude < minLng) {
        minLng = point.longitude;
      }
      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 0))
        .then((value) {
      return;
    });
  }
  
  void updateMarkers(){
    print("updating");
    setState(() {});
  }

  Color buttonColor=Colors.red;
  String nearesPoint="";
  Timer? _strtTimer;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _googleMapController = controller;
              createRooms();
              goToUser();
            },
            zoomControlsEnabled: false,
            polygons: polygonController.polygons.union(patchController.polygons),
            polylines: polygonController.polylines,
            markers: fingerprinting.getMarkers(),
            buildingsEnabled: false,
            compassEnabled: false,
          ),
          Positioned(
            right: 16,
            bottom: 150,
            child: Column(
              children: [

                Text("${nearesPoint}"),
                SpeedDial(
                  activeIcon: Icons.close,
                  backgroundColor: Colors.white,
                  children: List.generate(
                    polygonController.numberOfFloors.length,
                        (int i) {
                      //
                      List<int> floorList = polygonController.numberOfFloors;
                      List<int> revfloorList = floorList;
                      revfloorList.sort();

                      return SpeedDialChild(
                        child: Semantics(
                          label: "${revfloorList[i]}",
                          child: Text(
                            revfloorList[i] == 0
                                ? 'G'
                                : '${revfloorList[i]}',
                            style: const TextStyle(
                              fontFamily: "Roboto",
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 19 / 16,
                            ),
                          ),
                        ),
                        backgroundColor: Colors.white,
                        onTap: () {
                          fingerprinting.disableFingerprinting();
                          setState(() {
                            polygonController.renderRooms(revfloorList[i]);
                          });
                        },
                      );
                    },
                  ),
                  child: Text(
                  polygonController.floor.toString(),
                    style: const TextStyle(
                      fontFamily: "Roboto",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff24b9b0),
                      height: 19 / 16,

                    ),
                  ),
                ),
                SizedBox(height: 12,),
                SpeedDial(
                  direction: SpeedDialDirection.left,
                  activeIcon: Icons.close,
                  backgroundColor: Colors.white,
                  children: [
                    SpeedDialChild(
                    child: Icon(Icons.bluetooth_connected),
                    backgroundColor: Colors.white,
                    onTap: () {
                      setState(() {
                        print("enabling");
                        fingerprinting.enableFingerprinting(polygonController,beaconController);
                      });
                    },
                  )],
                  child: Icon(Icons.code_off),
                ),
                SizedBox(height: 20,),
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: () async {
                  fingerprinting.collectSensorDataEverySecond();

                },child: Icon(Icons.account_balance),),
                SizedBox(height: 20,),
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    fingerprinting.stopCollectingRealData();
                    _strtTimer?.cancel();
                  },child: Icon(Icons.account_balance),),
                SizedBox(height: 25,),
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () async {
            _strtTimer=Timer.periodic(Duration(seconds: 5), (_) async {
              nearesPoint=fingerprinting.findBestMatchingLocationHybrid();
              List<String> vals=nearesPoint.split(',');
              List<poly.Nodes> waypoints = await polygonController.extractWaypoints();
              for (var point in waypoints){
                if(vals[0]==point.coordx.toString() && vals[1]==point.coordy.toString())
                {
                  fingerprinting.addMarker(LatLng(point.lat!, point.lon!));
                  return;
                }
              }
              setState(() {
                updateMarkers();
                nearesPoint;
              });
            });

                  },child: Icon(Icons.person),)
              ],
            ),
          ),
          SafeArea(child: fingerprinting.FingerPrintingPannel.getPanelWidget(context))
        ],
      ),
    );
  }
}
