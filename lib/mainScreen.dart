import 'dart:async';

import 'package:admin/api/RefreshTokenAPI.dart';
import 'package:admin/fingerprinting/fingerprinting.dart';
import 'package:admin/mapDemoScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization_engine/localization_engine.dart';

import 'API/buildingAllApi.dart';
import 'LOGIN SIGNUP/SignIn.dart';
import 'SharedPreferenceHelper.dart';
import 'beaconGraphScreen.dart';
import 'buildingInfoScreen.dart';
import 'navigationTools.dart';

class BeaconFingerprintScreen extends StatefulWidget {
  const BeaconFingerprintScreen({Key? key}) : super(key: key);

  @override
  State<BeaconFingerprintScreen> createState() => _BeaconFingerprintScreenState();
}

class _BeaconFingerprintScreenState extends State<BeaconFingerprintScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  final Fingerprinting _fingerprinting = Fingerprinting();

  @override
  void initState() {
    super.initState();
    isUserValid().then((value) {
      if (!value) {
        callBuildings();
      }
    });

  }

  Future<bool> isUserValid() async {
    try {
      String refreshToken1 = await RefreshTokenAPI.refresh();
      if (refreshToken1 == "400") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignIn()),
              (route) => false,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  callBuildings() async {
    buildingAllApi buildingController = buildingAllApi();
    await buildingController.fetchBuildingAllData().then((value) {
      if (value.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // _latestScan();
      }
      LocalizationEngine.startScanning(
        immediateEmit: true,
        venueName: buildingAllApi.selectedVenue,
      );
    });
  }

  // ─── Pages ───────────────────────────────────────────────────────────────
  final List<BeaconData> _topBeacons = [];
  bool scanStatus=true;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  // Color(0xFF34d399)
  Widget _dashboardPage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _isSearching
                ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Search beacon...",
                      hintStyle: TextStyle(color: Color(0xFF94a3b8)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF34d399)),
                      ),
                    ),
                    onChanged: (value) {
                      final filterBeacon= _topBeacons.where((b) => b.name.toLowerCase().contains(value));
                      print("filterBeacons:${filterBeacon.first.name}");
                    },
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                    'Admin',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${buildingAllApi.selectedVenue} · Floor ${_fingerprinting.floor ?? 0}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (scanStatus) {
                          _topBeacons.clear();
                          beaconHistory.value.clear();
                          LocalizationEngine.stopScanning();
                        } else {
                          LocalizationEngine.startScanning(
                              venueName: buildingAllApi.selectedVenue,
                              immediateEmit: true);
                        }
                        setState(() {
                          scanStatus = !scanStatus;
                        });
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(
                            scanStatus
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: scanStatus
                                ? const Color(0xFF34d399)
                                : const Color(0xff83837b),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(Icons.search, color: Color(0xff83837b)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Stat Cards 2x2
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: ValueListenableBuilder(
                    valueListenable: _searchController,
                    builder: (context, _, __) {
                      final query = _searchController.text.toLowerCase();

                      return StreamBuilder<BeaconData>(
                        stream: beaconStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          final data = snapshot.data!;

                          // update beacon list
                          final index =
                          _topBeacons.indexWhere((b) => b.name == data.name);

                          if (index != -1) {
                            _topBeacons[index] = data;
                          } else {
                            _topBeacons.add(data);
                          }

                          if (data.name == "IW25090385") {
                            print("dtaaaa:${data.rssi}");
                          }

                          updateGraphHistory(data.name, data.rssi);

                          /// 🔎 SEARCH FILTER
                          final filteredBeacons = _topBeacons
                              .where((b) =>
                              b.name.toLowerCase().contains(query))
                              .take(20)
                              .toList();

                          return Wrap(
                            spacing: 12,
                            runSpacing: 5,
                            children: filteredBeacons.asMap().entries.map((entry) {
                              final i = entry.key;
                              final b = entry.value;

                              return KeyedSubtree(
                                key: ValueKey(b.name),
                                child: _statCard(
                                  i,
                                  b.rssi.toString(),
                                  b.name,
                                  b.manufacturerHex,
                                  const Color(0xFF34d399),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
               SizedBox(height: 12),
              // const Text(
              //   'RSSI HISTORY',
              //   style: TextStyle(
              //     fontSize: 11,
              //     fontWeight: FontWeight.w600,
              //     letterSpacing: 1.2,
              //     color: Color(0xFF475569),
              //   ),
              // ),
              //
              // const SizedBox(height: 16),
              //
              // SizedBox(
              //   height: 150,
              //   child: _rssiLineChart(),
              // ),

            ],
          ],
        ),
    );
  }
  ValueNotifier<Map<String, List<int>>> beaconHistory = ValueNotifier({});
  ValueNotifier<Map<String, List<RssiPoint>>> graphHistory=ValueNotifier({});
  final int maxHistory = 15;
  String? selectedBeacon;


  void updateGraphHistory(String beaconName, int rssi) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final map = Map<String, List<RssiPoint>>.from(graphHistory.value);

      final history = List<RssiPoint>.from(map[beaconName] ?? []);

      if (history.length >= maxHistory) {
        history.removeAt(0);
      }

      history.add(RssiPoint(rssi, DateTime.now()));

      map[beaconName] = history;

      graphHistory.value = map;
    });
  }

  Stream<BeaconData> get beaconStream {
    return LocalizationEngine.rawBluetoothScanResults
        .where((event) => event != null)
        .map((event) => event!)
        .where((event) =>
    event['name']?.toString().toLowerCase().contains('iw') ?? false)
        .map((event) => BeaconData(
      name: event['name'],
      rssi: event['rssi'],
      manufacturerHex: event['manufacturerHex'],
    ));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  String? expandedBeacon;
  Widget _statCard(
      int index,
      String value,
      String label,
      String hex,
      Color color,
      ) {
    var bytes = tools.hexToBytes(hex);

    double? batteryVoltage;
    double? fwVersion;
    int? txPower;
    int? advInterval;
    String? tag;

    if (bytes.length >= 7) {
      batteryVoltage = bytes[0] * 0.03125;
      fwVersion = bytes[1] / 10.0;
      txPower = bytes[2].toSigned(8);
      advInterval = (bytes[3] << 8) | bytes[4];

      if (bytes.length >= 3) {
        tag = String.fromCharCodes(bytes.sublist(bytes.length - 3));
      }
    }

    final bool isExpanded = expandedBeacon == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          expandedBeacon = isExpanded ? null : label;
        });
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// RSSI
            Text(
              "$value dBm",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            /// Beacon name
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),

            /// READ MORE BUTTON
            if (!isExpanded) ...[
              const SizedBox(height: 6),
              const Text(
                "Read more",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF38bdf8),
                ),
              )
            ],

            /// EXPANDED CONTENT
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white10),
              const SizedBox(height: 10),

              _infoRow("Battery",
                  batteryVoltage != null ? "${batteryVoltage.toStringAsFixed(2)} V" : "--"),

              _infoRow("FW",
                  fwVersion != null ? fwVersion.toString() : "--"),

              _infoRow("TX Power",
                  txPower != null ? "$txPower dBm" : "--"),

              _infoRow("Interval",
                  advInterval != null ? "$advInterval ms" : "--"),

              if (tag != null) _infoRow("Tag", tag),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Show less",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF38bdf8),
                    ),
                  ),
                  InkWell(
                    onTap: (){
                      selectedBeacon=label;
                      graphHistory.value = {};

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BeaconGraphScreen(
                            beaconName: label,
                            historyNotifier: graphHistory,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "More",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF38bdf8),
                      ),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94a3b8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── Tab tap handler ──────────────────────────────────────────────────────

  void _onTabTapped(int index) {
    if (index == 1) {
      // Beacon Log — push directly, don't change tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuildingInfoScreen(frmMainScreen: "BEACON"),
        ),
      );
      return;
    }
    if (index == 2) {
      // Fingerprinting — push directly
      print("buildingAllApi.isGlobalAnnotation:${buildingAllApi.isGlobalAnnotation}");
      if(buildingAllApi.isGlobalAnnotation){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MapDemoScreen(fingerprinting: _fingerprinting),
          ),
        );
      }else{
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuildingInfoScreen(frmMainScreen: "FINGERPRINTING"),
          ),
        );
      }

      return;
    }
    LocalizationEngine.stopScanning();
    _topBeacons.clear();
    setState(() => _currentIndex = index);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0f1117), Color(0xFF1a1f2e)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _dashboardPage(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0d1117),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _tabItem(0, Icons.grid_view_rounded, 'Dashboard',
                    const Color(0xFF38bdf8)),
                _tabItem(1, Icons.radar_rounded, 'Beacon Log',
                    const Color(0xFF38bdf8)),
                _tabItem(2, Icons.fingerprint_rounded, 'Fingerprinting',
                    const Color(0xFF818cf8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, String label, Color color) {
    final bool isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 22,
                color: isActive ? color : const Color(0xFF475569)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? color : const Color(0xFF475569))),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class BeaconData {
  final String name;
  final int rssi;
  final String manufacturerHex;

  BeaconData({
    required this.name,
    required this.rssi,
    required this.manufacturerHex,
  });
}