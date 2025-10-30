import 'package:admin/patchController.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'API/PatchApi.dart';
import 'APIMODELS/Buildingbyvenue.dart';
import 'api/GlobalAnnotationapi.dart';
import 'api/buildingByVenueAPI.dart';
import 'navigationTools.dart';

class Mastergraphmap extends StatefulWidget {
  String venueName ;
  Mastergraphmap({super.key, required this.venueName});

  @override
  State<Mastergraphmap> createState() => _MastergraphmapState();
}

class _MastergraphmapState extends State<Mastergraphmap> {

  CampusData? allBuildings;

  Map<String, PatchController> patchForBuildings = {};
  Set<Polyline> graphPolyline = Set();
  final _initialCameraPosition = const CameraPosition(
    target: LatLng( 28.94783320391921, 77.10093630757262),
    zoom:22,
  );
  late GoogleMapController _googleMapController;

  Future<void> loadGraph(String campusID) async {
    var globalData = await GlobalAnnotation().fetchGlobalAnnotationData(campusID);
    drawGraph(globalData.pathNetwork!.masterGraph!);
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

  Set<Polyline> _polylines = {};
  int polylineIdCounter = 0;

  List<int> extractCoordinates(String node) {
    var parts = node.split(',');
    return parts.sublist(1).map(int.parse).toList();
  }

  String extractBid(String node) {
    var parts = node.split(',');
    return parts[0];
  }

  void drawGraph(Map<String, List<dynamic>> graph) {
    String campusId = allBuildings!.campus.id;
    final Set<String> drawnEdges = {};

    graph.forEach((from, connections) {
      for (var to in connections) {
        if(to == null) continue;
        // Create a unique key for undirected edges
        final edgeKey = [from, to]..sort();
        final edgeId = edgeKey.join('-');

        if (drawnEdges.contains(edgeId)) continue;

        List<int> fromCoords = extractCoordinates(from);
        String fromBid = extractBid(from);

        List<int> toCoords = extractCoordinates(to);
        String toBid = extractBid(from);

        if(fromCoords[2] != 0 || toCoords[2] != 0) continue;
        if(fromBid != "6803481c7009e40640246ec6" || toBid != "6803481c7009e40640246ec6") continue;

        List<double> svalue = tools.localtoglobal(fromCoords[0], fromCoords[1], patchForBuildings[fromBid]!.data);
        List<double> dvalue = tools.localtoglobal(toCoords[0], toCoords[1], patchForBuildings[toBid]!.data);

        final points = [LatLng(svalue[0], svalue[1]), LatLng(dvalue[0], dvalue[1])];

        _polylines.add(
          Polyline(
            polylineId: PolylineId('edge_${polylineIdCounter++}'),
            points: points,
            color: Color(0xffC0C0C0),
            width: 1,
            onTap: () {},
          ),
        );

        drawnEdges.add(edgeId);
      }
    });

  }

  Future<void> loadBuildings() async {
    allBuildings = await Buildingbyvenueapi().fetchBuildingIDS(widget.venueName);
    for (var element in allBuildings!.buildings){
      var patchController = PatchController();
      patchController.createPatch(element.id);
      patchForBuildings[element.id] = patchController;
    }
    var patchController = PatchController();
    patchController.createPatch(allBuildings!.campus.id);
    patchForBuildings[allBuildings!.campus.id] = patchController;
    print("patchForBuildings $patchForBuildings");
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: (controller) async {
        _googleMapController = controller;
        await loadBuildings();
        loadGraph(allBuildings!.campus.id);
      },
      polylines: _polylines,
      zoomControlsEnabled: false,
      buildingsEnabled: false,
      compassEnabled: false,
    );
  }
}
