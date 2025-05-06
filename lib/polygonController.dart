import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;

import 'APIMODELS/polylinedata.dart';
import 'api/PolyLineApi.dart';
import 'api/buildingAllApi.dart';
import 'navigationTools.dart';

class PolygonController{
  Set<Polygon> _polygons = Set();
  Set<gmap.Polyline> _polylines = Set();
  int _floor = 0;
  List<int> numberOfFloors = [0];
  polylinedata? data;

  Set<gmap.Polyline> get polylines => _polylines;

  set polylines(Set<gmap.Polyline> value) {
    _polylines = value;
  }

  Set<Polygon> get polygons => _polygons;

  set polygons(Set<Polygon> value) {
    _polygons = value;
  }


  int get floor => _floor;

  set floor(int value) {
    _floor = value;
  }

  Future<void> renderRooms(int fl) async {
    data ??= await PolyLineApi().fetchPolyData(buildingAllApi.selectedBuildingID);
    polygons.clear();
    polylines.clear();
     floor = fl;
    List<PolyArray>? FloorPolyArray = data!.polyline!.floors![0].polyArray;
    for (int j = 0; j < data!.polyline!.floors!.length; j++) {
      if(!numberOfFloors.contains(tools.alphabeticalToNumerical(data!.polyline!.floors![j].floor!))){
        numberOfFloors.add(tools.alphabeticalToNumerical(data!.polyline!.floors![j].floor!));
      }
      if (data!.polyline!.floors![j].floor == tools.numericalToAlphabetical(fl)) {
        FloorPolyArray = data!.polyline!.floors![j].polyArray;
      }
    }
      if (FloorPolyArray != null) {
        for (PolyArray polyArray in FloorPolyArray) {
          if (polyArray.visibilityType == "visible") {
            List<LatLng> coordinates = [];

            for (Nodes node in polyArray.nodes!) {
              coordinates.add(LatLng(node.lat!,node.lon!));
            }


            if (polyArray.polygonType == 'Wall' ||
                polyArray.polygonType == 'undefined') {
              if (coordinates.length >= 2) {
                _polylines.add(gmap.Polyline(
                    polylineId: PolylineId(
                        "${data!.polyline!.buildingID!} Line ${polyArray.id!}"),
                    points: coordinates,
                    color: polyArray.cubicleColor != null &&
                        polyArray.cubicleColor != "undefined"
                        ? Color(int.parse(
                        '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                        : Color(0xffC0C0C0),
                    width: 1,
                    onTap: () {}));
              }
            } else if (polyArray.polygonType == 'Room' ) {

              if(polyArray.name!.toLowerCase().contains('lr') || polyArray.name!.toLowerCase().contains('lab') || polyArray.name!.toLowerCase().contains('office') || polyArray.name!.toLowerCase().contains('pantry') || polyArray.name!.toLowerCase().contains('reception')) {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Room ${polyArray
                              .id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Color(0xffA38F9F),
                      fillColor: Color(0xffE8E3E7),
                      consumeTapEvents: true,
                  ));
                }
              }else if(polyArray.name!.toLowerCase().contains('atm') || polyArray.name!.toLowerCase().contains('health')) {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Room ${polyArray
                              .id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId
                      strokeColor: Color(0xffE99696),
                      fillColor: Color(0xffFBEAEA),
                      consumeTapEvents: true,
                  ));
                }
              } else{
                if (coordinates.length>2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Room ${polyArray
                              .id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Color(0xffA38F9F),
                      fillColor: Color(0xffE8E3E7),
                      consumeTapEvents: true,
                  ));
                }
              }
            } else if (polyArray.polygonType == 'Cubicle') {
              if (polyArray.cubicleName == "Green Area" ||
                  polyArray.cubicleName == "Green Area | Pots" || (polyArray.name??"").toLowerCase().contains('auditorium') || (polyArray.name??"").toLowerCase().contains('basketball') || (polyArray.name??"").toLowerCase().contains('cricket') || (polyArray.name??"").toLowerCase().contains('football') || (polyArray.name??"").toLowerCase().contains('gym') || (polyArray.name??"").toLowerCase().contains('swimming') || (polyArray.name??"").toLowerCase().contains('tennis')) {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Color(0xffADFA9E),
                      fillColor: Color(0xffE7FEE9),
                      onTap: () {

                      }));
                }
              } else if (polyArray.cubicleName!
                  .toLowerCase()
                  .contains("lift")) {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId
                      strokeColor: Color(0xffB5CCE3),
                      consumeTapEvents: true,
                      fillColor: Color(0xffDAE6F1),
                  ));
                }
              } else if (polyArray.cubicleName == "Male Washroom") {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId
                      consumeTapEvents: true,
                      strokeColor: Color(0xff6EBCF7),
                      fillColor: Color(0xFFE7F4FE),
                  ));
                }
              } else if (polyArray.cubicleName == "Female Washroom") {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId
                      consumeTapEvents: true,
                      strokeColor: Color(0xff6EBCF7),
                      fillColor: Color(0xFFE7F4FE),
                  ));
                }
              } else if (polyArray.cubicleName!
                  .toLowerCase()
                  .contains("fire")) {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Colors.black,
                      fillColor: polyArray.cubicleColor != null &&
                          polyArray.cubicleColor != "undefined"
                          ? Color(int.parse(
                          '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                          : Color(0xffF21D0D),
                      onTap: () {}));
                }
              } else if (polyArray.cubicleName!
                  .toLowerCase()
                  .contains("water")) {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Color(0xff6EBCF7),
                      fillColor: polyArray.cubicleColor != null &&
                          polyArray.cubicleColor != "undefined"
                          ? Color(int.parse(
                          '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                          : Color(0xffE7F4FE),
                      onTap: () {}));
                }
              } else if (polyArray.cubicleName!
                  .toLowerCase()
                  .contains("wall")) {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Color(0xffC0C0C0),
                      fillColor: polyArray.cubicleColor != null &&
                          polyArray.cubicleColor != "undefined"
                          ? Color(int.parse(
                          '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                          : Color(0xffffffff),
                      onTap: () {}));
                }
              } else if (polyArray.cubicleName == "Restricted Area") {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Color(0xffCCCCCC),
                      fillColor: polyArray.cubicleColor != null &&
                          polyArray.cubicleColor != "undefined"
                          ? Color(int.parse(
                          '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                          : Color(0xffE6E6E6),
                      onTap: () {}));
                }
              } else if (polyArray.cubicleName == "Non Walkable Area") {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                      polygonId: PolygonId(
                          "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                      points: coordinates,
                      strokeWidth: 1,
                      // Modify the color and opacity based on the selectedRoomId

                      strokeColor: Color(0xffcccccc),
                      fillColor: polyArray.cubicleColor != null &&
                          polyArray.cubicleColor != "undefined"
                          ? Color(int.parse(
                          '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                          : Color(0xffE6E6E6),
                      onTap: () {}));
                }
              } else {
                if (coordinates.length > 2) {
                  coordinates.add(coordinates.first);
                  _polygons!.add(Polygon(
                    polygonId: PolygonId(
                        "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                    points: coordinates,
                    strokeWidth: 1,
                    strokeColor: Color(0xffD3D3D3),
                    onTap: () {},
                    fillColor: polyArray.cubicleColor != null &&
                        polyArray.cubicleColor != "undefined"
                        ? Color(int.parse(
                        '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                        : Colors.white,
                  ));
                }
              }
            } else if (polyArray.polygonType == "Wall") {
              if (coordinates.length > 2) {
                coordinates.add(coordinates.first);
                _polygons!.add(Polygon(
                    polygonId: PolygonId(
                        "${data!.polyline!.buildingID!} Cubicle ${polyArray.id!}"),
                    points: coordinates,
                    strokeWidth: 1,
                    // Modify the color and opacity based on the selectedRoomId
                    strokeColor: Color(0xffD3D3D3),
                    fillColor: polyArray.cubicleColor != null &&
                        polyArray.cubicleColor != "undefined"
                        ? Color(int.parse(
                        '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                        : Colors.white,
                    consumeTapEvents: true,
                    onTap: () {}));
              }
            } else {
              _polylines.add(gmap.Polyline(
                  polylineId: PolylineId(polyArray.id!),
                  points: coordinates,
                  color: polyArray.cubicleColor != null &&
                      polyArray.cubicleColor != "undefined"
                      ? Color(int.parse(
                      '0xFF${(polyArray.cubicleColor)!.replaceAll('#', '')}'))
                      : Color(0xffE6E6E6),
                  width: 1,
                  onTap: () {}));
            }
          }
        }
      }


    return;
  }

  Future<List<Nodes>> extractWaypoints() async {
    print("called");
    data ??= await PolyLineApi().fetchPolyData(buildingAllApi.selectedBuildingID);
    List<Nodes> waypoints = [];
    for (var floors in data!.polyline!.floors!) {
      for (var polys in floors.polyArray!) {
        if (polys.polygonType == "Waypoints" && floor == tools.alphabeticalToNumerical(polys.floor!)) {
          for (var node in polys.nodes!) {
            // Check if node is at least 2 meters away from all nodes in waypoints
            bool isFarEnough = waypoints.every((existingNode) =>
            tools.calculateAerialDist(
                existingNode.lat!, existingNode.lon!, node.lat!, node.lon!) >= 2);

            if (isFarEnough) {
              waypoints.add(node);
            }
          }
        }
      }
    }
    print("waypoints ${waypoints.length}");
    return waypoints;
  }

}