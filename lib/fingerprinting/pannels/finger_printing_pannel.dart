import 'package:action_slider/action_slider.dart';
import 'package:admin/api/buildingAllApi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../APIMODELS/landmark.dart';
import '../fingerprinting.dart';

class pinLandmark extends StatefulWidget {
  late Fingerprinting fingerprinting;

  pinLandmark({required this.fingerprinting, Key? key}) : super(key: key);

  @override
  _pinLandmarkState createState() => _pinLandmarkState();
}

class _pinLandmarkState extends State<pinLandmark> {
  late FixedExtentScrollController _controller;

  List<bool> isSelected = [true, false, false, false];
  int selectedTimeInSeconds = 10; // Default to 10 seconds

  void _updateSelectedTime(int index) {
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = i == index;
      }

      // Update selectedTimeInSeconds based on the index
      switch (index) {
        case 0:
          selectedTimeInSeconds = 10;
          break;
        case 1:
          selectedTimeInSeconds = 60;
          break;
        case 2:
          selectedTimeInSeconds = 90;
          break;
        case 3:
          selectedTimeInSeconds = 120;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Landmarks? _previousPinedLandmark;

  void setPickerIndex(int index) {
    // Dynamically change the selected index
    _controller.animateToItem(
      index,
      duration: Duration(milliseconds: 200), // Animation duration
      curve: Curves.easeInOut, // Animation curve
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: (){widget.fingerprinting.disableFingerprinting();}, icon: Icon(Icons.cancel)),
        Card(
          child: Container(
            width: screenWidth-32,
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Position: (${widget.fingerprinting.userPosition?.coordx},${widget.fingerprinting.userPosition?.coordy})"),
                    Text("Floor: ${widget.fingerprinting.floor}"),
                    Text("Building: ${buildingAllApi.selectedBuildingName}"),
                    Text("Venue: ${buildingAllApi.selectedVenue}"),
                  ],
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 60,
                          width: 60,
                          child: SvgPicture.asset("assets/dot.svg")),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        SizedBox(height: 12,),
        ToggleButtons(
          borderRadius: BorderRadius.circular(8.0),
          selectedColor: Colors.white,
          fillColor: Colors.blue,
          color: Colors.black,
          borderColor: Colors.grey,
          selectedBorderColor: Colors.blue,
          isSelected: isSelected,
          onPressed: _updateSelectedTime,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("10 sec"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("1 min"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("1.5 min"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("2 min"),
            ),
          ],
        ),
        SizedBox(height: 12,),
        ActionSlider.standard(
          child: const Text('Slide to capture'),
          action: (controller) async {
            widget.fingerprinting.collectSensorDataEverySecond();
            controller.loading(); //starts loading animation
            await Future.delayed(Duration(seconds: selectedTimeInSeconds));
            bool success = await widget.fingerprinting.stopCollectingData();
            if(success){
              controller.failure();
              await Future.delayed(Duration(seconds: 10));
              controller.reset();
            }else{
              controller.success();
              await Future.delayed(Duration(seconds: 10));
              controller.reset();
            }
          },
        ),
      ],
    );
  }
}
