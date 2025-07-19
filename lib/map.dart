import 'dart:async';
import 'package:admin/APIMODELS/waypoint.dart';
import 'package:admin/BluetoothManager/BLEManager.dart';
import 'package:admin/api/waypoint.dart';
import 'package:admin/fingerprinting/pannels/finger_printing_pannel_controller.dart';
import 'package:admin/modes.dart';
import 'package:admin/patchController.dart';
import 'package:admin/point2d.dart';
import 'package:admin/polygonController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'APIMODELS/FingerPrintData.dart';
import 'APIMODELS/polylinedata.dart' as poly;
import 'GPS.dart';
import 'SharedPreferenceHelper.dart';
import 'UserLog.dart';
import 'api/buildingAllApi.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'api/fingerPrintGet.dart';
import 'beaconBottomPanel.dart';
import 'beaconController.dart';
import 'fingerprinting/fingerprinting.dart';
import 'navigationTools.dart';
import 'package:lottie/lottie.dart' as lott;

class googleMap extends StatefulWidget {
  final String fromPage;
  final String bid;
  const googleMap({super.key, required this.fromPage, required this.bid});

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
  wsocket ws = wsocket("com.iwayplus.rni");

  bool isLoading=false;


  @override
  void initState() {
    super.initState();
    fingerprinting.context = context;
    fingerprinting.updateMarkers = updateMarkers;
    checkPermissions();
    fetchWayPoints();
getUser();
    setState((){});
  }

  void checkPermissions() async {
    await requestLocationPermission();
    await requestBluetoothConnectPermission();
    //  await requestActivityPermission();
  }
  String user='';
  Future<void> getUser() async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    print("useriddvf:${user} ${await prefs.getMap("signin")!["payload"]["userId"]}");
    user = await prefs.getMap("signin")!["payload"]["userId"];
    wsocket.message["userId"]=user;
  }



  Future<void> requestBluetoothConnectPermission() async {
    final PermissionStatus permissionStatus = await Permission.bluetoothScan.request();
    if (permissionStatus.isGranted) {
      wsocket.message["deviceInfo"]["permissions"]["BLE"] = true;
      wsocket.message["deviceInfo"]["sensors"]["BLE"] = true;
      //widget.bluetoothGranted = true;
      // Permission granted, you can now perform Bluetooth operations
    } else {
      wsocket.message["deviceInfo"]["permissions"]["BLE"] = false;
      wsocket.message["deviceInfo"]["sensors"]["BLE"] = false;
      // Permission denied, handle accordingly
    }
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      wsocket.message["deviceInfo"]["permissions"]["location"] = true;
      wsocket.message["deviceInfo"]["sensors"]["location"] = true;
    } else {
      wsocket.message["deviceInfo"]["permissions"]["location"] = false;
      wsocket.message["deviceInfo"]["sensors"]["location"] = false;
    }
  }

  fetchWayPoints() async {
    SharedPreferenceHelper prefs = await SharedPreferenceHelper.getInstance();
    var waypointData = await waypointapi().fetchwaypoint(widget.bid);
    PolygonController.waypoint=waypointData as Map<String, List<PathModel>>;
    wsocket.message["userId"] = await prefs.getMap("signin")!["userId"];
     print("generateSampledPoints:${Point2D.generateSampledPointsFromWaypointGraph(PolygonController.waypoint)}");
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

  Future<void> createRooms(String bid) async {
    print("selected building id:${buildingAllApi.selectedBuildingID}");
    await patchController.createPatch(bid);
    fitPolygonInScreen(patchController.polygons.first);
    await polygonController.renderRooms(0, patchController.data,bid);
    await beaconController.getBeacons(bid);

    setState(() {
      isLoading=true;
    });
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
  BLEManager _bleManager=BLEManager();
  Color buttonColor=Colors.red;
  String nearesPoint="";
  Timer? _strtTimer;
  bool _isbeaconLogging=false;
  double _progressValue = 0.0;
  int totalBeacons=0;
  int scannedBeacons=0;
  void _updateProgress() {
    const onsec = const Duration(seconds: 1);
    Timer.periodic(onsec, (Timer t) {
      setState(() {
        _progressValue += 0.08;
        if (_progressValue.toStringAsFixed(1) == '1.0') {
          t.cancel();
          return;
        }
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _googleMapController.dispose();
    _messageTimer?.cancel();
  }
  void safeSendMessage() {
    if (!wsocket.isConnected) {
      print("Socket not connected. Will reconnect and send message once connected.");
      wsocket.sendmessg(); // internally waits and emits on reconnect
    } else {
      wsocket.sendmessg(); // safe to emit
    }
  }
  Timer? _messageTimer;
  Set<String> scannedBeaconIds = {};
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [

          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _googleMapController = controller;
              createRooms(widget.bid);
              goToUser();
              _updateProgress();

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
                          totalBeacons=0;
                          scannedBeacons=0;
                          scannedBeaconIds.clear();
                          fingerprinting.disableFingerprinting();
                          setState((){
                            polygonController.renderRooms(revfloorList[i], patchController.data,widget.bid);
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
                (widget.fromPage=="FINGERPRINTING")?
                SpeedDial(
                  direction: SpeedDialDirection.left,
                  activeIcon: Icons.close,
                  backgroundColor: Colors.white,
                  children: [
                    SpeedDialChild(
                    child: Icon(Icons.bluetooth_connected),
                    backgroundColor: Colors.white,
                    onTap:(){
                      setState((){
                        print("enabling");
                        fingerprinting.enableFingerprinting(patchController,polygonController,beaconController,widget.bid);
                      });
                    },
                  ),
                  ],
                  child: Icon(Icons.code_off),
                ):Container(),
                SizedBox(height: 20,),
                    FloatingActionButton(onPressed: (){
                      fingerprinting.clearMarkers();
                      fingerprinting.collectSensorDataEverySecond();
                      Future.delayed(Duration(seconds: 6)).then((_) async {
                        nearesPoint=fingerprinting.findBestMatchingLocationHybrid();
                        List<String> vals=nearesPoint.split(',');
                        List<double> value = tools.localtoglobal(
                         int.parse(vals[0]),
                          int.parse(vals[1]),
                          patchController.data,
                        );
                        print("nearestpoints:${vals}");
                        fingerprinting.timer?.cancel();
                        fingerprinting.stopCollectingRealData();
                        Map<String,Set<Point2D>> interpolatedWaypoints=await polygonController.fetchWayPoints(widget.bid);
                        fingerprinting.checkAndAddMarker(interpolatedWaypoints,polygonController.floor.toString(),value);
                        setState(() {
                          updateMarkers();
                          nearesPoint;
                        });
                      });
                    },child: Icon(Icons.account_balance),),
                SizedBox(height: 20,),
                (beaconController.apibeaconmap!=null && widget.fromPage!="FINGERPRINTING")?
                FloatingActionButton(
                  backgroundColor:(!_isbeaconLogging)? Colors.green:Colors.red,
                  onPressed: ()async{
                    if(!_isbeaconLogging){
                      print("buildingAllApi.selectedVenue ${buildingAllApi.selectedVenue} ${buildingAllApi.selectedBuildingID}");
                      getUser();
                      _messageTimer=Timer.periodic(Duration(seconds: 5),(timer){
                        wsocket.sendmessg();
                      });
                      fingerprinting.addBeaconMarkers(beaconController.apibeaconmap,patchController.data,polygonController.floor).then((value){
                        totalBeacons=value;
                        _bleManager.startScanning(bufferSize: 5, streamFrequency: 5);
                      });
                      _bleManager.bufferedDeviceStream.listen((device){
                        device.forEach((deviceName, deviceRssi) {
                          final rssiList = deviceRssi.values
                              .map((val) => int.tryParse(val.toString()))
                              .whereType<int>() // filters out nulls
                              .toList();
                          if (beaconController.apibeaconmap!.containsKey(deviceName) &&
                              beaconController.apibeaconmap![deviceName]!.floor == polygonController.floor) {

                            final beaconItem = beaconController.apibeaconmap![deviceName];

                            List<double> value = tools.localtoglobal(
                              beaconItem!.coordinateX!,
                              beaconItem.coordinateY!,
                              patchController.data,
                            );
                            LatLng currentLatLng = LatLng(value[0], value[1]);
                            String beaconKey = '${currentLatLng.latitude},${currentLatLng.longitude}';
                            // Only count if this beacon hasn't already been scanned
                            if (!scannedBeaconIds.contains(beaconKey)) {
                              scannedBeaconIds.add(beaconKey);     // track the beacon
                              scannedBeacons++;                    // count it once
                            }
                            // Update marker regardless (or conditionally if you want)
                            fingerprinting.updateMarker(
                              markerId: MarkerId(beaconKey),
                              position: currentLatLng,
                            );
                          }

                        });
                      });
                      setState(() {
                        _isbeaconLogging=true;
                      });
                    }
                    else{
                      _bleManager.stopScanning();
                      wsocket.disconnect();
                      _messageTimer!.cancel();
                      setState(() {
                        _isbeaconLogging=false;
                      });
                    }
                },child: Icon(CupertinoIcons.antenna_radiowaves_left_right,size: 30,fill:0.4,),):Container(),
                 SizedBox(height: 20,),

              ],
            ),
          ),
          SafeArea(child: fingerprinting.FingerPrintingPannel.getPanelWidget(context)),
          (!isLoading)? Container(
            height: screenHeight,
            width: screenWidth,
            color: Colors.white.withOpacity(0.8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                lott.Lottie.asset(
                  'assets/loding_animation.json', // Path to your Lottie animation
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 56, right: 56),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: Colors.grey,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                )
              ],
            ),
          ):Container(),
          (beaconController.apibeaconmap!=null && widget.fromPage!="FINGERPRINTING") ?Align(
        alignment: Alignment.bottomCenter,
        child: BeaconBottomPanel(
          totalBeacons: totalBeacons,
          scannedBeacons: scannedBeacons,
        )):Container(),
        ],
      ),
    );
  }
}
