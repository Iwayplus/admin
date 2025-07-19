class Building {
  List<Buildings>? buildings;
  Campus? campus;

  Building({this.buildings, this.campus});

  Building.fromJson(Map<String, dynamic> json) {
    if (json['buildings'] != null) {
      buildings = <Buildings>[];
      json['buildings'].forEach((v) {
        buildings!.add(new Buildings.fromJson(v));
      });
    }
    campus =
        json['campus'] != null ? new Campus.fromJson(json['campus']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.buildings != null) {
      data['buildings'] = this.buildings!.map((v) => v.toJson()).toList();
    }
    if (this.campus != null) {
      data['campus'] = this.campus!.toJson();
    }
    return data;
  }
}

class Buildings {
  bool? globalAnnotation;
  bool? locked;
  String? sId;
  String? initialBuildingName;
  String? initialVenueName;
  String? buildingName;
  String? venueName;
  String? venueCategory;
  String? buildingCategory;
  List<double>? coordinates;
  String? address;
  bool? liveStatus;
  bool? geofencing;
  String? phone;
  String? venuePhoto;
  String? buildingPhoto;
  List<WorkingDays>? workingDays;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<List>? boundary;

  Buildings(
      {this.globalAnnotation,
      this.locked,
      this.sId,
      this.initialBuildingName,
      this.initialVenueName,
      this.buildingName,
      this.venueName,
      this.venueCategory,
      this.buildingCategory,
      this.coordinates,
      this.address,
      this.liveStatus,
      this.geofencing,
      this.phone,
      this.venuePhoto,
      this.buildingPhoto,
      this.workingDays,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.boundary});
  Buildings.fromJson(Map<String, dynamic> json) {
    globalAnnotation = json['globalAnnotation'];
    locked = json['locked'];
    sId = json['_id'];
    initialBuildingName = json['initialBuildingName'];
    initialVenueName = json['initialVenueName'];
    buildingName = json['buildingName'];
    venueName = json['venueName'];
    venueCategory = json['venueCategory'];
    buildingCategory = json['buildingCategory'];
    coordinates = json['coordinates'].cast<double>();
    address = json['address'];
    liveStatus = json['liveStatus'];
    geofencing = json['geofencing'];
    phone = json['phone'];
    venuePhoto = json['venuePhoto'];
    buildingPhoto = json['buildingPhoto'];
    if (json['workingDays'] != null) {
      workingDays = <WorkingDays>[];
      json['workingDays'].forEach((v) {
        workingDays!.add(new WorkingDays.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['globalAnnotation'] = this.globalAnnotation;
    data['locked'] = this.locked;
    data['_id'] = this.sId;
    data['initialBuildingName'] = this.initialBuildingName;
    data['initialVenueName'] = this.initialVenueName;
    data['buildingName'] = this.buildingName;
    data['venueName'] = this.venueName;
    data['venueCategory'] = this.venueCategory;
    data['buildingCategory'] = this.buildingCategory;
    data['coordinates'] = this.coordinates;
    data['address'] = this.address;
    data['liveStatus'] = this.liveStatus;
    data['geofencing'] = this.geofencing;
    data['phone'] = this.phone;
    data['venuePhoto'] = this.venuePhoto;
    data['buildingPhoto'] = this.buildingPhoto;
    if (this.workingDays != null) {
      data['workingDays'] = this.workingDays!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class WorkingDays {
  String? day;
  String? openingTime;
  String? closingTime;
  String? sId;

  WorkingDays({this.day, this.openingTime, this.closingTime, this.sId});

  WorkingDays.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    openingTime = json['openingTime'];
    closingTime = json['closingTime'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['day'] = this.day;
    data['openingTime'] = this.openingTime;
    data['closingTime'] = this.closingTime;
    data['_id'] = this.sId;
    return data;
  }
}

class Campus {
  bool? globalAnnotation;
  String? sId;
  String? initialBuildingName;
  String? initialVenueName;
  String? buildingName;
  String? venueName;
  List<double>? coordinates;
  String? address;
  bool? liveStatus;
  bool? geofencing;
  bool? locked;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<List>? boundary;

  Campus(
      {this.globalAnnotation,
      this.sId,
      this.initialBuildingName,
      this.initialVenueName,
      this.buildingName,
      this.venueName,
      this.coordinates,
      this.address,
      this.liveStatus,
      this.geofencing,
      this.locked,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.boundary});

  Campus.fromJson(Map<String, dynamic> json) {
    globalAnnotation = json['globalAnnotation'];
    sId = json['_id'];
    initialBuildingName = json['initialBuildingName'];
    initialVenueName = json['initialVenueName'];
    buildingName = json['buildingName'];
    venueName = json['venueName'];
    coordinates = json['coordinates'].cast<double>();
    address = json['address'];
    liveStatus = json['liveStatus'];
    geofencing = json['geofencing'];
    locked = json['locked'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['globalAnnotation'] = this.globalAnnotation;
    data['_id'] = this.sId;
    data['initialBuildingName'] = this.initialBuildingName;
    data['initialVenueName'] = this.initialVenueName;
    data['buildingName'] = this.buildingName;
    data['venueName'] = this.venueName;
    data['coordinates'] = this.coordinates;
    data['address'] = this.address;
    data['liveStatus'] = this.liveStatus;
    data['geofencing'] = this.geofencing;
    data['locked'] = this.locked;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
