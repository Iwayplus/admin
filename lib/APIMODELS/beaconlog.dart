class BeaconLog {
  List<ScannedBeacons>? scannedBeacons;
  List<UnScannedBeacons>? unScannedBeacons;

  BeaconLog({this.scannedBeacons, this.unScannedBeacons});

  BeaconLog.fromJson(Map<String, dynamic> json) {
    if (json['scannedBeacons'] != null) {
      scannedBeacons = <ScannedBeacons>[];
      json['scannedBeacons'].forEach((v) {
        scannedBeacons!.add(new ScannedBeacons.fromJson(v));
      });
    }
    if (json['unScannedBeacons'] != null) {
      unScannedBeacons = <UnScannedBeacons>[];
      json['unScannedBeacons'].forEach((v) {
        unScannedBeacons!.add(new UnScannedBeacons.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.scannedBeacons != null) {
      data['scannedBeacons'] =
          this.scannedBeacons!.map((v) => v.toJson()).toList();
    }
    if (this.unScannedBeacons != null) {
      data['unScannedBeacons'] =
          this.unScannedBeacons!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ScannedBeacons {
  String? sId;
  Null? macId;
  String? beaconName;
  String? buildingName;
  String? buildingID;
  int? floor;
  int? lastRecordedRssi;
  int? battery;
  int? txPower;
  int? advertisementInterval;
  int? localizedOnCount;
  String? lastScannedBy;
  String? createdAt;
  String? updatedAt;
  int? iV;

  ScannedBeacons(
      {this.sId,
        this.macId,
        this.beaconName,
        this.buildingName,
        this.buildingID,
        this.floor,
        this.lastRecordedRssi,
        this.battery,
        this.txPower,
        this.advertisementInterval,
        this.localizedOnCount,
        this.lastScannedBy,
        this.createdAt,
        this.updatedAt,
        this.iV});

  ScannedBeacons.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    macId = json['macId'];
    beaconName = json['beaconName'];
    buildingName = json['buildingName'];
    buildingID = json['building_ID'];
    floor = json['floor'];
    lastRecordedRssi = json['lastRecordedRssi'];
    battery = json['battery'];
    txPower = json['txPower'];
    advertisementInterval = json['advertisementInterval'];
    localizedOnCount = json['localizedOnCount'];
    lastScannedBy = json['lastScannedBy'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['macId'] = this.macId;
    data['beaconName'] = this.beaconName;
    data['buildingName'] = this.buildingName;
    data['building_ID'] = this.buildingID;
    data['floor'] = this.floor;
    data['lastRecordedRssi'] = this.lastRecordedRssi;
    data['battery'] = this.battery;
    data['txPower'] = this.txPower;
    data['advertisementInterval'] = this.advertisementInterval;
    data['localizedOnCount'] = this.localizedOnCount;
    data['lastScannedBy'] = this.lastScannedBy;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class UnScannedBeacons {
  String? buildingName;
  String? beaconName;
  String? buildingID;
  int? floor;

  UnScannedBeacons(
      {this.buildingName, this.beaconName, this.buildingID, this.floor});

  UnScannedBeacons.fromJson(Map<String, dynamic> json) {
    buildingName = json['buildingName'];
    beaconName = json['beaconName'];
    buildingID = json['building_ID'];
    floor = json['floor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['buildingName'] = this.buildingName;
    data['beaconName'] = this.beaconName;
    data['building_ID'] = this.buildingID;
    data['floor'] = this.floor;
    return data;
  }
}
