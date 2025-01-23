
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/services.dart';

import '../APIMODELS/beaconData.dart';
import 'BluetoothDevice.dart';

class BluetoothScanAndroidClass{
  static const methodChannel = MethodChannel('com.example.bluetooth/scan');
  static const eventChannel = EventChannel('com.example.bluetooth/scanUpdates');
  List<BluetoothDevice> devices = [];
  bool isScanning = false;
  bool EM_isScanning = false;
  static StreamSubscription? _scanSubscription; // Variable to hold the subscription
  int count = 0;

  Map<String, String> deviceNames = {};
  Map<String, List<int>> rssiValues = {};
  Map<String, double> distances = {};
  String closestDeviceDetails = "";
  String closestrssiDevice = "";
  String closestRSSI = "";
  Map<String, double> sumMapCallBack = {};
  Map<String, double> rssiAverage = {};
  Map<String, List<double>> rssiWeight = {};

  Map<String, List<double>> newList = {};

  String EM_NEAREST_BEACON = "";
  beacon EM_NEAREST_BEACON_VALUE = beacon();
  static Map<String, List<int>> EM_RSSI_VALUES = {};





  Future<void> startScan() async {
    try{
      await methodChannel.invokeMethod('startScan');
      isScanning = true;
    } on PlatformException catch(e){
      print("Failed to start scan: ${e.message}");
    }
  }

  Future<void> stopScan() async {
    try {
      await methodChannel.invokeMethod('stopScan');
      isScanning = false;
    } on PlatformException catch (e) {
      print("Failed to stop scan: ${e.message}");
    }
  }


  BluetoothDevice parseDeviceDetails(String response) {
    final deviceRegex = RegExp(
      r'Device Name: (.+?)\n.*?Address: (.+?)\n.*?RSSI: (-?\d+)',
      dotAll: true,
    );

    final match = deviceRegex.firstMatch(response);

    if (match != null) {
      final deviceName = match.group(1) ?? 'Unknown';
      final deviceAddress = match.group(2) ?? 'Unknown';
      final deviceRssi = match.group(3) ?? '0';

      return BluetoothDevice(
        DeviceName: deviceName,
        DeviceAddress: deviceAddress,
        DeviceRssi: deviceRssi,
      );
    } else {
      throw Exception('Invalid device details string');
    }
  }


  List<String> nearestBeaconList = [];
  static Map<String, String> EM_DEVICE_NAME = {};
  static Map<String, List<double>> EM_RSSI_WEIGHT = {};
  static Map<String, double> EM_RSSI_AVERAGE = {};




  void listenToScanUpdates(HashMap<String, beacon> apibeaconmap) {
    startScan();
    print("listenToScanUpdates");

    Map<String, List<int>> rssiValues = {};
    String deviceMacId = "";
    // Start listening to the stream continuously
    _scanSubscription = eventChannel.receiveBroadcastStream().listen((deviceDetail) {
      BluetoothDevice deviceDetails = parseDeviceDetails(deviceDetail);
      if(apibeaconmap.containsKey(deviceDetails.DeviceName)) {
        deviceMacId = deviceDetails.DeviceAddress;
        print("iffffff");
        print(deviceDetails.DeviceName);
        deviceNames[deviceDetails.DeviceAddress] = deviceDetails.DeviceName;

        rssiValues.putIfAbsent(deviceDetails.DeviceAddress, () => []);
        rssiWeight.putIfAbsent(deviceDetails.DeviceAddress, () => []);


        rssiValues[deviceDetails.DeviceAddress]!.add(int.parse(deviceDetails.DeviceRssi));
        print("deviceDetails.DeviceRssi");
        print(deviceDetails.DeviceRssi);

        rssiWeight[deviceDetails.DeviceAddress]!.add(getWeight(getBinNumber(int.parse(deviceDetails.DeviceRssi).abs())));

        if (rssiValues[deviceDetails.DeviceAddress]!.length > 7) {
          rssiValues[deviceDetails.DeviceAddress]!.removeAt(0);
        }

        if(rssiWeight[deviceDetails.DeviceAddress]!.length > 7){
          rssiWeight[deviceDetails.DeviceAddress]!.removeAt(0);
        }


        rssiAverage = calculateAverageFromRssi(rssiValues,deviceNames,rssiWeight);

        print("rssiAverage");
        print(rssiAverage);

        closestDeviceDetails = findLowestRssiDevice(rssiAverage);

        print("closestDeviceDetails");
        print(closestDeviceDetails);

        //addtoBin(deviceDetails.DeviceAddress, int.parse(deviceDetails.DeviceRssi));
      }else{

      }
    }, onError: (error) {
      print('Error receiving device updates: $error');
    });

    if(isScanning) {
      Timer.periodic(Duration(seconds: 2), (timer) {
        if (rssiValues.isNotEmpty) {
          rssiValues.forEach((key, value) {
            if (deviceMacId != key) {
              if (value.isNotEmpty) value.removeAt(0);
            }
          });
        }

        if (rssiWeight.isNotEmpty) {
          rssiWeight.forEach((key, value) {
            if (deviceMacId != key) {
              if (value.isNotEmpty) value.removeAt(0);
            }
          });
        }
        // Calculate average RSSI values
        Map<String, double> sumMap = calculateAverage();
        // Sort the map by value (e.g., strongest signal first)
        Map<String, double> sortedSumMap = sortMapByValue(sumMap);
        sumMapCallBack = sortedSumMap;
        print("SortedSumMap: $sortedSumMap");

      });

    }

  }



  Map<String, List<double>> giveSumMapCallBack(){
    print("newList");

    print(newList);
    return newList;
  }

  String giveClosestDeviceCallBAck(){
    return closestrssiDevice;
  }
  String giveRssiMapCallBAck(){
    return closestrssiDevice;
  }
  String giveRssiCallBAck(){
    return closestRSSI;
  }

  Map<String, double> calculateAverageFromRssi(
      Map<String, List<int>> rssiValues,
      Map<String, String> deviceList,
      Map<String, List<double>> rssiWeight) {
    Map<String, double> averagedRssiValues = {};

    rssiWeight.forEach((address, rssiList) {
      if (rssiList.isNotEmpty) {
        // Calculate average if the list is not empty
        double average = rssiList.reduce((a, b) => a + b) / rssiList.length;
        int beaconBinNumber = getBinNumber(average.toInt());

        // Update the newList for debugging or other purposes
        newList[deviceList[address]!] = rssiList;

        print("deviceList[address]");
        print(average);
        print(newList);

        // Add the average to the map
        averagedRssiValues[deviceList[address]!] = average;
      } else {
        print("Warning: RSSI list for $address is empty.");
      }
    });

    // Sort by the average RSSI values in descending order
    var sortedEntries = averagedRssiValues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return the sorted map
    return Map.fromEntries(sortedEntries);
  }


  Map<String, double> sortMapByValue(Map<String, double> map) {
    var sortedEntries = map.entries.toList()
      ..sort(
              (a, b) => b.value.compareTo(a.value)); // Sorting in descending order

    return Map.fromEntries(sortedEntries);
  }

  Map<String, double> calculateAverage(){
    //HelperClass.showToast("Bin ${BIN} \n number $numberOfSample");
    Map<String, double> sumMap = {};
    // Iterate over each inner map and accumulate the values for each string key
    BIN.values.forEach((innerMap) {
      innerMap.forEach((key, value) {
        sumMap[key] = (sumMap[key] ?? 0.0) + value;
      });
    });
    // Divide the sum by the number of values for each string key
    sumMap.forEach((key, sum) {
      int count = numberOfSample[key]!;
      sumMap[key] = sum / count;
    });

    BIN = HashMap();
    numberOfSample.clear();
    startbin();

    return sumMap;
  }


  double calculateDistance(double rssi) {
    const int txPower = -64; // Adjust based on the reference RSSI at 1 meter
    const double environmentalFactor = 1; // Adjust based on your environment
    return pow(10, (txPower - rssi) / (10 * environmentalFactor))
        .toDouble(); // Cast to double
  }

  String findLowestRssiDevice(Map<String, double> rssiAverage) {
    String? lowestKey;
    double? lowestValue;

    rssiAverage.forEach((key, value) {
      if (lowestValue == null || value > lowestValue!) {
        lowestValue = value;
        lowestKey = key;
      }
    });
    closestRSSI = lowestValue.toString();
    print("findLowestRssiDevice");
    print(lowestValue);

    return lowestKey ?? "No devices found";
  }

  String EM_findLowestRssiDevice(Map<String, double> rssiAverage) {
    String? lowestKey;
    double? lowestValue = 3;
print("rssiAverage");
print(rssiAverage);
    rssiAverage.forEach((key, value) {

      if (lowestValue == null || value > lowestValue!) {
        lowestValue = value;
        lowestKey = key;
      }
    });
    closestRSSI = lowestValue.toString();
    print("findLowestRssiDevice");
    print(lowestValue);
    print(lowestKey);

    return lowestKey ?? "No devices found";
  }


  HashMap<int, HashMap<String, double>> BIN = HashMap();
  HashMap<String,int> numberOfSample = HashMap();
  HashMap<String,List<int>> rs = HashMap();
  HashMap<int, double> weight = HashMap();

  int getBinNumber(int Rssi){
    if (Rssi <= 65) {
      print("getBinNumber0");
      return 0;
    } else if (Rssi <= 75) {
      print("getBinNumber1");
      return 1;
    } else if (Rssi <= 80) {
      print("getBinNumber2");
      return 2;
    } else if (Rssi <= 85) {
      return 3;
    } else if (Rssi <= 90) {
      return 4;
    } else if (Rssi <= 95) {
      return 5;
    } else {
      return 6;
    }
  }


  double getWeight(int num){
    switch(num) {
      case 0:
        return 12.0;
      case 1:
        return 6.0;
      case 2:
        return 4.0;
      case 3:
        return 0.5;
      case 4:
        return 0.25;
      case 5:
        return 0.15;
      case 6:
        return 0.1;
      default:
        return 0.0;
    }
  }


  void addtoBin(String MacId, int rssi) {

    int binnumber = 0;
    int Rssi = rssi * -1;
    if(numberOfSample[MacId] == null){
      numberOfSample[MacId] = 0;
      rs[MacId] = [];
    }
    numberOfSample[MacId] = numberOfSample[MacId]! + 1;
    rs[MacId]!.add(rssi);



    //print("of beacon ${rs}");


    if (Rssi <= 65) {
      binnumber = 0;
    } else if (Rssi <= 75) {
      binnumber = 1;
    } else if (Rssi <= 80) {
      binnumber = 2;
    } else if (Rssi <= 85) {
      binnumber = 3;
    } else if (Rssi <= 90) {
      binnumber = 4;
    } else if (Rssi <= 95) {
      binnumber = 5;
    } else {
      binnumber = 6;
    }

    if(BIN[binnumber]==null){
      startbin();
    }

    if (BIN[binnumber]!.containsKey(MacId)) {
      BIN[binnumber]![MacId] = BIN[binnumber]![MacId]! + weight[binnumber]!;
    } else {
      BIN[binnumber]![MacId] = 1 * weight[binnumber]!;
    }
    //print("number of sample---${numberOfSample[MacId]}");
  }

  void startbin() {
    BIN[0] = HashMap<String, double>();
    BIN[1] = HashMap<String, double>();
    BIN[2] = HashMap<String, double>();
    BIN[3] = HashMap<String, double>();
    BIN[4] = HashMap<String, double>();
    BIN[5] = HashMap<String, double>();
    BIN[6] = HashMap<String, double>();

    weight[0] = 12.0;
    weight[1] = 6.0;
    weight[2] = 4.0;
    weight[3] = 0.5;
    weight[4] = 0.25;
    weight[5] = 0.15;
    weight[6] = 0.1;
  }

  void emptyBin() {
    for (int i = 0; i < BIN.length; i++) {
      BIN[i]!.clear();
    }
    numberOfSample.clear();
    rs.clear();
  }
}