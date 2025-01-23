import 'SensorFingerprint.dart';

class SensorFingerprintBuilder {
  List<Beacon>? beacons;
  GpsData? gpsData;
  MagnetometerData? magnetometerData;
  AccelerometerData? accelerometerData;
  double? altitude;
  double? lux;

  SensorFingerprintBuilder();

  SensorFingerprintBuilder setBeacons(List<Beacon>? beacons) {
    beacons = beacons;
    return this;
  }

  SensorFingerprintBuilder setGpsData({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double altitude
  }) {
    gpsData = GpsData(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude
    );
    return this;
  }

  SensorFingerprintBuilder setMagnetometerData({
    required double value
  }) {
    magnetometerData = MagnetometerData(value: value);
    return this;
  }

  SensorFingerprintBuilder setAccelerometerData({
    required double x,
    required double y,
    required double z,
  }) {
    accelerometerData = AccelerometerData(x: x, y: y, z: z);
    return this;
  }

  SensorFingerprintBuilder setLux(double value) {
    lux = value;
    return this;
  }

  SensorFingerprint build() {
    return SensorFingerprint(
      beacons: beacons,
      gpsData: gpsData,
      magnetometerData: magnetometerData,
      accelerometerData: accelerometerData,
      lux: lux,
    );
  }
}
