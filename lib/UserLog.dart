import 'dart:ui';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'config.dart';

class wsocket {
  static String appId = "";
  static bool isConnected = false;

  static final io.Socket channel = io.io('https://dev.iwayplus.in', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  static Map message = {
    "appId": appId,
    "userId": "",
    "deviceInfo": {
      "sensors": {
        "BLE": false,
        "location": false,
        "activity": false,
        "compass": false
      },
      "permissions": {
        "BLE": false,
        "location": false,
        "activity": false,
        "compass": false
      },
      "deviceManufacturer": ""
    },
    "AppInitialization": {
      "BID": "",
      "buildingName": "",
      "bleScanResults": {},
      "nearByDevices": {},
      "localizedOn": ""
    },
    "userPosition": {
      "X": 0,
      "Y": 0,
      "floor": 0
    },
    "path": {
      "source": "",
      "destination": "",
      "didPathForm": false
    }
  };

  wsocket(String appid) {
    appId = appid;
    if (!channel.connected) {
      _initializeConnection();
    }
  }

  static void _initializeConnection() {
    // Clean any old handlers
    channel.off('connect');
    channel.off('disconnect');
    channel.off('error');
    // Add listeners once
    channel.on('connect', (_) {
      isConnected = true;
      print("WebSocket connected ✅");
    });

    channel.on('disconnect', (_) {
      isConnected = false;
      print("WebSocket disconnected ❌");
    });

    channel.on('error', (data) {
      print("WebSocket error: $data");
    });

    channel.connect();
  }

  static void sendmessg() {
    if (!channel.connected) {
      print("WebSocket not connected, trying to connect...");
      _initializeConnection();
      // Wait a bit before sending message
      channel.once('connect', (_) {
        print("Sending message after reconnect: $message");
        channel.emit("user-log-socket", message);
      });
    } else {
      print("Sending message: $message");
      channel.emit("user-log-socket", message);
    }
  }

  static void disconnect() {
    if (channel.connected) {
      print("Disconnecting WebSocket...");
      channel.disconnect();
      isConnected = false;
    } else {
      print("WebSocket already disconnected.");
    }
  }
}
