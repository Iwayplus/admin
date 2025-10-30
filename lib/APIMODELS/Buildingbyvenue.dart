class CampusData {
  final List<Building> buildings;
  final Campus campus;

  CampusData({required this.buildings, required this.campus});

  factory CampusData.fromJson(Map<String, dynamic> json) {
    return CampusData(
      buildings: (json['buildings'] as List<dynamic>)
          .map((b) => Building.fromJson(b))
          .toList(),
      campus: Campus.fromJson(json['campus']),
    );
  }

  Map<String, dynamic> toJson() => {
    'buildings': buildings.map((b) => b.toJson()).toList(),
    'campus': campus.toJson(),
  };
}

class Building {
  final String id;
  final String initialBuildingName;
  final String initialVenueName;
  final String buildingName;
  final String venueName;
  final List<double> coordinates;
  final List<dynamic> pickupCoords;
  final String address;
  final bool liveStatus;
  final bool geofencing;
  final bool globalAnnotation;
  final List<List<double>> boundary;
  final String? venueCategory;
  final String? buildingCategory;
  final String? description;
  final List<dynamic> features;
  final String? phone;
  final String? website;
  final String? venuePhoto;
  final String? buildingPhoto;
  final bool locked;
  final String? deeplinkUrl;
  final String? appId;
  final String? appStoreId;
  final List<dynamic> adminIds;
  final List<dynamic> workingDays;
  final String createdAt;
  final String updatedAt;
  final int v;

  Building({
    required this.id,
    required this.initialBuildingName,
    required this.initialVenueName,
    required this.buildingName,
    required this.venueName,
    required this.coordinates,
    required this.pickupCoords,
    required this.address,
    required this.liveStatus,
    required this.geofencing,
    required this.globalAnnotation,
    required this.boundary,
    this.venueCategory,
    this.buildingCategory,
    this.description,
    required this.features,
    this.phone,
    this.website,
    this.venuePhoto,
    this.buildingPhoto,
    required this.locked,
    this.deeplinkUrl,
    this.appId,
    this.appStoreId,
    required this.adminIds,
    required this.workingDays,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['_id'],
      initialBuildingName: json['initialBuildingName'],
      initialVenueName: json['initialVenueName'],
      buildingName: json['buildingName'],
      venueName: json['venueName'],
      coordinates: List<double>.from(json['coordinates']),
      pickupCoords: json['pickupCoords'],
      address: json['address'],
      liveStatus: json['liveStatus'],
      geofencing: json['geofencing'],
      globalAnnotation: json['globalAnnotation'],
      boundary: (json['boundary'] as List)
          .map((coord) => List<double>.from(coord))
          .toList(),
      venueCategory: json['venueCategory'],
      buildingCategory: json['buildingCategory'],
      description: json['description'],
      features: json['features'],
      phone: json['phone'],
      website: json['website'],
      venuePhoto: json['venuePhoto'],
      buildingPhoto: json['buildingPhoto'],
      locked: json['locked'],
      deeplinkUrl: json['deeplinkUrl'],
      appId: json['appId'],
      appStoreId: json['appStoreId'],
      adminIds: json['adminIds'],
      workingDays: json['workingDays'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'initialBuildingName': initialBuildingName,
    'initialVenueName': initialVenueName,
    'buildingName': buildingName,
    'venueName': venueName,
    'coordinates': coordinates,
    'pickupCoords': pickupCoords,
    'address': address,
    'liveStatus': liveStatus,
    'geofencing': geofencing,
    'globalAnnotation': globalAnnotation,
    'boundary': boundary,
    'venueCategory': venueCategory,
    'buildingCategory': buildingCategory,
    'description': description,
    'features': features,
    'phone': phone,
    'website': website,
    'venuePhoto': venuePhoto,
    'buildingPhoto': buildingPhoto,
    'locked': locked,
    'deeplinkUrl': deeplinkUrl,
    'appId': appId,
    'appStoreId': appStoreId,
    'adminIds': adminIds,
    'workingDays': workingDays,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

class Campus {
  final String id;
  final String initialBuildingName;
  final String initialVenueName;
  final String buildingName;
  final String venueName;
  final List<double> coordinates;
  final List<dynamic> pickupCoords;
  final String address;
  final bool liveStatus;
  final bool geofencing;
  final bool globalAnnotation;
  final List<List<double>> boundary;
  final String? description;
  final List<dynamic> features;
  final String? phone;
  final String? website;
  final String? venuePhoto;
  final String? buildingPhoto;
  final bool locked;
  final String? deeplinkUrl;
  final String? appId;
  final String? appStoreId;
  final List<dynamic> adminIds;
  final List<dynamic> workingDays;
  final String createdAt;
  final String updatedAt;
  final int v;

  Campus({
    required this.id,
    required this.initialBuildingName,
    required this.initialVenueName,
    required this.buildingName,
    required this.venueName,
    required this.coordinates,
    required this.pickupCoords,
    required this.address,
    required this.liveStatus,
    required this.geofencing,
    required this.globalAnnotation,
    required this.boundary,
    this.description,
    required this.features,
    this.phone,
    this.website,
    this.venuePhoto,
    this.buildingPhoto,
    required this.locked,
    this.deeplinkUrl,
    this.appId,
    this.appStoreId,
    required this.adminIds,
    required this.workingDays,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Campus.fromJson(Map<String, dynamic> json) {
    return Campus(
      id: json['_id'],
      initialBuildingName: json['initialBuildingName'],
      initialVenueName: json['initialVenueName'],
      buildingName: json['buildingName'],
      venueName: json['venueName'],
      coordinates: List<double>.from(json['coordinates']),
      pickupCoords: json['pickupCoords'],
      address: json['address'],
      liveStatus: json['liveStatus'],
      geofencing: json['geofencing'],
      globalAnnotation: json['globalAnnotation'],
      boundary: (json['boundary'] as List)
          .map((coord) => List<double>.from(coord))
          .toList(),
      description: json['description'],
      features: json['features'],
      phone: json['phone'],
      website: json['website'],
      venuePhoto: json['venuePhoto'],
      buildingPhoto: json['buildingPhoto'],
      locked: json['locked'],
      deeplinkUrl: json['deeplinkUrl'],
      appId: json['appId'],
      appStoreId: json['appStoreId'],
      adminIds: json['adminIds'],
      workingDays: json['workingDays'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'initialBuildingName': initialBuildingName,
    'initialVenueName': initialVenueName,
    'buildingName': buildingName,
    'venueName': venueName,
    'coordinates': coordinates,
    'pickupCoords': pickupCoords,
    'address': address,
    'liveStatus': liveStatus,
    'geofencing': geofencing,
    'globalAnnotation': globalAnnotation,
    'boundary': boundary,
    'description': description,
    'features': features,
    'phone': phone,
    'website': website,
    'venuePhoto': venuePhoto,
    'buildingPhoto': buildingPhoto,
    'locked': locked,
    'deeplinkUrl': deeplinkUrl,
    'appId': appId,
    'appStoreId': appStoreId,
    'adminIds': adminIds,
    'workingDays': workingDays,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}
