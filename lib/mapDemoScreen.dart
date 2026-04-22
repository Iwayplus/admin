// lib/screens/map_demo_screen.dart

import 'dart:async';

import 'package:admin/config.dart';
import 'package:admin/fingerprinting/fingerprinting.dart';
import 'package:admin/patchController.dart';
import 'package:flutter/material.dart';
import 'package:localization_engine/localization_engine.dart';
import 'package:unified_map_view/unified_map_view.dart';
import 'package:mappls_gl/mappls_gl.dart';

import 'API/buildingAllApi.dart';
import 'APIMODELS/FingerPrintData.dart';
import 'APIMODELS/polylinedata.dart';
import 'api/fingerPrintGet.dart';
import 'navigationTools.dart';

/// Main screen that initializes and displays the GeoJSON map
class MapDemoScreen extends StatefulWidget {
  Fingerprinting fingerprinting;
  MapDemoScreen({required this.fingerprinting, Key? key}) : super(key: key);

  @override
  State<MapDemoScreen> createState() => _MapDemoScreenState();
}

class _MapDemoScreenState extends State<MapDemoScreen> {
  late UnifiedMapController _mapController;
  bool _isMapReady = false;
  PatchController patchController = PatchController();

  Future<void> createRooms(String bid) async {
    print("selected building id:${buildingAllApi.selectedBuildingID} ${bid}");

    // buildingAllApi.selectedBuildingID = bid;
    await patchController.createPatch(bid);
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
    widget.fingerprinting.context = context;
  }

  Future<void> _loadFingerprintData(String bid, int floor) async {
    // Mock data - replace with your API call
    _mapController.clearMarkers();
    var fingerPrintData = await fingerPrintingGetApi().Finger_Printing_GET_API(
        bid, floor.toString());
    if (fingerPrintData != null) {
      _extractLocalPoints(fingerPrintData);
      _mapController.addMarkersAtLocations(_localPoints);
      print("_extractLocalPoints:${_localPoints}");
    }
  }

  List<MapLocation> _localPoints = [];

  void _extractLocalPoints(FingerPrintData? fingerPrintData) {
    if (fingerPrintData?.data == null) return;

    _localPoints = fingerPrintData!.data!
        .map((entry) {
      final parts = entry.location?.split(',');
      if (parts == null || parts.length < 2) return null;

      // If 6 parts, lat/lng are directly in parts[4] and parts[5]
      if (parts.length >= 6) {
        final lng = double.tryParse(parts[4].trim());
        final lat = double.tryParse(parts[5].trim());
        if (lat == null || lng == null) return null;
        print("localtoglobal:${lat}--${lng}");
        return MapLocation(latitude: lat, longitude: lng);
      }

      // Default: 2-3 parts — use local x,y → convert to global
      final x = int.tryParse(parts[0].trim());
      final y = int.tryParse(parts[1].trim());
      if (x == null || y == null) return null;


      final List<double> latLng = tools.localtoglobal(
        x,
        y,
        patchController.data,
      );

      return MapLocation(latitude: latLng[0], longitude: latLng[1]);
    })
        .whereType<MapLocation>()
        .toList();
  }

  /// Initialize the map controller with configuration
  void _initializeMap() {
    _mapController = UnifiedMapController(
      initialProvider: MapProvider.mappls,
      venueName: buildingAllApi.selectedVenue,
      initialLocation: UnifiedCameraPosition(
        mapLocation: MapLocation(
          latitude: 28.6139,
          longitude: 77.2090,
        ),
        zoom: 12.0,
        bearing: 0.0,
        // tilt: 0.0,
      ),
      url: AppConfig.baseUrl,
    );
    // buildingAllApi.selectedBuildingName=_mapController.focusedBuildingName;
    //     buildingAllApi.selectedBuildingName=_mapController.focusedVenueName;
    // Set custom map style if needed
    _mapController.setMapStyle("assets/mapstyle.json");
    print("_mapController.focusedBuilding:${_mapController.focusedBuilding}");

    // Mark map as ready
    setState(() {
      _isMapReady = true;
    });

    // Optional: Load GeoJSON data after a delay
    Future.delayed(const Duration(seconds: 1), () {
      _loadMapData();
    });
  }

  /// Load GeoJSON data and add markers
  Future<void> _loadMapData() async {
    try {
      if (_mapController.focusedBuilding != null) {
        buildingAllApi.saveBid(_mapController.focusedBuilding!);
        createRooms(_mapController.focusedBuilding!);
        _loadFingerprintData(_mapController.focusedBuilding!, 0);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map data loaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading map: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() {

    });
  }

  /// Switch between map providers
  void _switchToGoogle() {
    _mapController.switchProvider(MapProvider.google);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switched to Google Maps'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _switchToMappls() {
    _mapController.switchProvider(MapProvider.mappls);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Switched to Mappls'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isMapReady
          ? Stack(
        children: [
          // Main map widget
          UnifiedMapWidget(controller: _mapController,
            enablePinDrop: true,
            onPinDropped: _handleIfPinDropped,),
          // Floor speed dial (bottom right)
          Positioned(
            bottom: 150,
            right: 16,
            child: FloorSpeedDial(
              controller: _mapController, onFloorChanged: (int? floor) {
              print("floor changed to:${floor}");
              if (floor != null) {
                loadFingerprintingData(floor!);
              }
            },),
          ),
          Positioned(
            bottom: 200,
            right: 16,
            child: Text(buildingAllApi.selectedBuildingID),
          ),
          SafeArea(
              child: widget.fingerprinting.FingerPrintingPannel.getPanelWidget(
                  context)),
        ],
      )
          : const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing map...'),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: (){
      //     widget.fingerprinting.startScanning();
      //   },
      //   icon: const Icon(Icons.refresh),
      //   label: const Text('Reload'),
      // )
    );
  }

  Future<void> loadFingerprintingData(int floor) async {
    await _loadFingerprintData(_mapController.focusedBuilding!, floor);
  }

  _handleIfPinDropped(MapLocation? location) {
    if (location != null) {
      List<int>? localCoords = tools.globalToLocalPoints(
          patchData: patchController.data!,
          lat: location.latitude,
          lng: location.longitude);
      print("localCoords:${localCoords} ${location.latitude} ${location
          .longitude}");
      if (localCoords != null) {
        Nodes point = Nodes(coordx: localCoords[0].toInt(),
            coordy: localCoords[1]!.toInt(),
            lat: location.latitude,
            lon: location.longitude,
            indexNode: "0",
            sId: "default-ID${DateTime
                .now()
                .millisecondsSinceEpoch}");
        widget.fingerprinting.userPosition = point;
        widget.fingerprinting.floor =
            _mapController.focusBuildingSelectedFloor ?? 0;
        print("widget.fingerprinting.floor:${widget.fingerprinting.floor}");
        widget.fingerprinting.FingerPrintingPannel.showPanel();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
  }

}