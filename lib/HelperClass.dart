import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'Bluetooth/BluetoothDevice.dart';

class HelperClass {
  static void showToast(String mssg) {
    Fluttertoast.showToast(
      msg: mssg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  BluetoothDevice parseDeviceDetails(String response) {
    final deviceRegex = RegExp(
      r'Device Name: (.+?)\n.*?Address: (.+?)\n.*?RSSI: (-?\d+).*?Raw Data: ([0-9A-Fa-f\-]+)',
      dotAll: true,
    );

    final match = deviceRegex.firstMatch(response);

    if (match != null) {
      final deviceName = match.group(1) ?? 'Unknown';
      final deviceAddress = match.group(2) ?? 'Unknown';
      final deviceRssi = match.group(3) ?? '0';
      final rawData = match.group(4) ?? '';

      return BluetoothDevice(
        DeviceName: deviceName,
        DeviceAddress: deviceAddress,
        DeviceRssi: deviceRssi,
        rawData: rawData,
      );
    } else {
      throw Exception('Invalid device details string');
    }
  }

  double getBinWeight(int rssi){
    if (rssi <= 55) {
      return 25.0;
    }else if (rssi <= 65) {
      return 12.0;
    } else if (rssi <= 75) {
      return 6.0;
    } else if (rssi <= 80) {
      return 4.0;
    } else if (rssi <= 85) {
      return 0.5;
    } else if (rssi <= 90) {
      return 0.25;
    } else if (rssi <= 95) {
      return 0.15;
    } else {
      return 0.1;
    }
  }

}
