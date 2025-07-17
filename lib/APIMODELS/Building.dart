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
  Null? deeplinkUrl;
  Null? appId;
  Null? appStoreId;
  List<Null>? adminIds;
  String? sId;
  String? initialBuildingName;
  String? initialVenueName;
  String? buildingName;
  String? venueName;
  String? venueCategory;
  String? buildingCategory;
  List<double>? coordinates;
  List<Null>? pickupCoords;
  String? address;
  bool? liveStatus;
  bool? geofencing;
  Null? description;
  List<Null>? features;
  String? phone;
  Null? website;
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
      this.deeplinkUrl,
      this.appId,
      this.appStoreId,
      this.adminIds,
      this.sId,
      this.initialBuildingName,
      this.initialVenueName,
      this.buildingName,
      this.venueName,
      this.venueCategory,
      this.buildingCategory,
      this.coordinates,
      this.pickupCoords,
      this.address,
      this.liveStatus,
      this.geofencing,
      this.description,
      this.features,
      this.phone,
      this.website,
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
    deeplinkUrl = json['deeplinkUrl'];
    appId = json['appId'];
    appStoreId = json['appStoreId'];
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
    description = json['description'];
    phone = json['phone'];
    website = json['website'];
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
    data['deeplinkUrl'] = this.deeplinkUrl;
    data['appId'] = this.appId;
    data['appStoreId'] = this.appStoreId;
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
    data['description'] = this.description;
    data['phone'] = this.phone;
    data['website'] = this.website;
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
  Null? deeplinkUrl;
  Null? appId;
  Null? appStoreId;
  List<Null>? adminIds;
  String? sId;
  String? initialBuildingName;
  String? initialVenueName;
  String? buildingName;
  String? venueName;
  Null? venueCategory;
  Null? buildingCategory;
  List<double>? coordinates;
  List<Null>? pickupCoords;
  String? address;
  bool? liveStatus;
  bool? geofencing;
  Null? description;
  List<Null>? features;
  Null? phone;
  Null? website;
  Null? venuePhoto;
  Null? buildingPhoto;
  bool? locked;
  List<Null>? workingDays;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<Null>? contributorIds;
  Null? ownerId;
  List<List>? boundary;

  Campus(
      {this.globalAnnotation,
      this.deeplinkUrl,
      this.appId,
      this.appStoreId,
      this.adminIds,
      this.sId,
      this.initialBuildingName,
      this.initialVenueName,
      this.buildingName,
      this.venueName,
      this.venueCategory,
      this.buildingCategory,
      this.coordinates,
      this.pickupCoords,
      this.address,
      this.liveStatus,
      this.geofencing,
      this.description,
      this.features,
      this.phone,
      this.website,
      this.venuePhoto,
      this.buildingPhoto,
      this.locked,
      this.workingDays,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.contributorIds,
      this.ownerId,
      this.boundary});

  Campus.fromJson(Map<String, dynamic> json) {
    globalAnnotation = json['globalAnnotation'];
    deeplinkUrl = json['deeplinkUrl'];
    appId = json['appId'];
    appStoreId = json['appStoreId'];
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
    description = json['description'];
    phone = json['phone'];
    website = json['website'];
    venuePhoto = json['venuePhoto'];
    buildingPhoto = json['buildingPhoto'];
    locked = json['locked'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    ownerId = json['ownerId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['globalAnnotation'] = this.globalAnnotation;
    data['deeplinkUrl'] = this.deeplinkUrl;
    data['appId'] = this.appId;
    data['appStoreId'] = this.appStoreId;
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
    data['description'] = this.description;
    data['phone'] = this.phone;
    data['website'] = this.website;
    data['venuePhoto'] = this.venuePhoto;
    data['buildingPhoto'] = this.buildingPhoto;
    data['locked'] = this.locked;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['ownerId'] = this.ownerId;
    return data;
  }
}
