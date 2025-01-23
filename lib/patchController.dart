import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'API/PatchApi.dart';
import 'APIMODELS/patchDataModel.dart';
import 'api/buildingAllApi.dart';

class PatchController{
  Set<Polygon> _polygons = Set();
  patchDataModel? data;
  
  Set<Polygon> get polygons => _polygons;

  set polygons(Set<Polygon> value) {
    _polygons = value;
  }

  Future<void> createPatch() async {
    data ??= await patchAPI().fetchPatchData(buildingAllApi.selectedBuildingID);
    if (data!.patchData!.coordinates!.isNotEmpty) {
      List<LatLng> polygonPoints = [];
      double latcenterofmap = 0.0;
      double lngcenterofmap = 0.0;

      for (int i = 0; i < 4; i++) {
        latcenterofmap = latcenterofmap +
            double.parse(data!.patchData!.coordinates![i].globalRef!.lat!);
        lngcenterofmap = lngcenterofmap +
            double.parse(data!.patchData!.coordinates![i].globalRef!.lng!);
      }
      latcenterofmap = latcenterofmap / 4;
      lngcenterofmap = lngcenterofmap / 4;

      Map<int, LatLng> coordinates = {};

      for (int i = 0; i < 4; i++) {
        coordinates[i] = LatLng(
            latcenterofmap +
                1.1 *
                    (double.parse(
                        data!.patchData!.coordinates![i].globalRef!.lat!) -
                        latcenterofmap),
            lngcenterofmap +
                1.1 *
                    (double.parse(
                        data!.patchData!.coordinates![i].globalRef!.lng!) -
                        lngcenterofmap));
        polygonPoints.add(LatLng(
            latcenterofmap +
                1.1 *
                    (double.parse(
                        data!.patchData!.coordinates![i].globalRef!.lat!) -
                        latcenterofmap),
            lngcenterofmap +
                1.1 *
                    (double.parse(
                        data!.patchData!.coordinates![i].globalRef!.lng!) -
                        lngcenterofmap)));
      }

      _polygons.add(
          Polygon(
              polygonId: PolygonId('patch'),
              points: polygonPoints,
              strokeWidth: 1,
              strokeColor: Color(0xffC0C0C0),
              fillColor: Color(0xffffffff),
              geodesic: false,
              consumeTapEvents: true,
              zIndex:-1),
        );
      
    }
  }

}