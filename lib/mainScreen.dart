import 'package:admin/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

import 'API/buildingAllApi.dart';
import 'MasterGraphMap.dart';
import 'SharedPreferenceHelper.dart';
import 'UserLog.dart';
import 'buildingInfoScreen.dart';

class BeaconFingerprintScreen extends StatefulWidget {
  const BeaconFingerprintScreen({Key? key}) : super(key: key);

  @override
  State<BeaconFingerprintScreen> createState() => _BeaconFingerprintScreenState();
}

class _BeaconFingerprintScreenState extends State<BeaconFingerprintScreen> {
  bool _isLoading = true;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    callBuildings();
  }
  callBuildings() async {
    buildingAllApi buildingController = buildingAllApi();
    await buildingController.fetchBuildingAllData().then((value){
      if(value.isNotEmpty){
        setState(() {
          _isLoading=false;
        });
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Button Container
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child:(!_isLoading)?
                  Column(
                    children: [
                      // Beacon Log Button
                      SizedBox(
                        width: double.infinity,
                        height: 75,
                        child: ElevatedButton(
                          onPressed:(){
                            print("got inside here");
                            Navigator.push(context, MaterialPageRoute<void>(
                              builder: (BuildContext context) => BuildingInfoScreen(frmMainScreen: "BEACON",)
                            ),);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFFff6b6b).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFff6b6b), Color(0xFFff8e8e)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                'BEACON LOG',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fingerprinting Button
                      SizedBox(
                        width: double.infinity,
                        height: 75,
                        child: ElevatedButton(
                          onPressed:(){
                            Navigator.push(context, MaterialPageRoute<void>(
                                builder: (BuildContext context) => BuildingInfoScreen(frmMainScreen: "FINGERPRINTING",)
                            ),);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFF4ecdc4).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ecdc4), Color(0xFF44a08d)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                'FINGERPRINTING',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ):Center(child: CircularProgressIndicator(),),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 75,
                  child: ElevatedButton(
                    onPressed:(){
                      print("got inside here");
                      Navigator.push(context, MaterialPageRoute<void>(
                          builder: (BuildContext context) => Mastergraphmap(venueName: 'Ashoka University',)
                      ),);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.green.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Color(0xFFff8e8e)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'DISCONNECTED PATH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Usage example - Add this to your main.dart or wherever you want to use it
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beacon Fingerprint App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BeaconFingerprintScreen(),
    );
  }
}