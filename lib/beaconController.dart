import 'package:admin/api/buildingAllApi.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'APIMODELS/beaconData.dart';
import 'api/beaconapi.dart';

class BeaconController{
  List<beacon>? _beaconData;
  Map<String, beacon>? _apibeaconmap;

  Map<String, beacon>? get apibeaconmap => _apibeaconmap;

  set apibeaconmap(Map<String, beacon>? value) {
    _apibeaconmap = value;
  }

  List<beacon>? get beaconData => _beaconData;

  set beaconData(List<beacon>? value) {
    _beaconData = value;
  }

  Future<void> getBeacons() async {
    beaconData = await beaconapi().fetchBeaconData(buildingAllApi.selectedBuildingID);
    apibeaconmap ??={};
    for (var beacon in beaconData!) {
      if (beacon.name != null) {
        apibeaconmap![beacon.name!] = beacon;
      }
    }
  }
}