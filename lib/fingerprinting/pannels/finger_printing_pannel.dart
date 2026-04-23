import 'dart:async';

import 'package:action_slider/action_slider.dart';
import '../../api/buildingAllApi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../APIMODELS/landmark.dart';
import '../fingerprinting.dart';

class pinLandmark extends StatefulWidget {
  late Fingerprinting fingerprinting;
  final dynamic mapController;

  pinLandmark({required this.fingerprinting, Key? key, this.mapController}) : super(key: key);

  @override
  _pinLandmarkState createState() => _pinLandmarkState();
}

class _pinLandmarkState extends State<pinLandmark> {
  late FixedExtentScrollController _controller;

  List<bool> isSelected = [true, false, false, false, false];
  int selectedTimeInSeconds = 11; // Default to 10 seconds
  ValueNotifier<int> remainingTime = ValueNotifier<int>(0);
  Timer? countdownTimer;

  void _updateSelectedTime(int index) {
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = i == index;
      }
      // Update selectedTimeInSeconds based on the index
      switch (index) {
        case 0:
          selectedTimeInSeconds = 6;
          break;
        case 1:
          selectedTimeInSeconds = 11;
          break;
        case 2:
          selectedTimeInSeconds = 31;
          break;
        case 3:
          selectedTimeInSeconds = 61;
          break;
        case 4:
          selectedTimeInSeconds = 91;
          break;
      }
    });
  }
  void startCountdown() {
    remainingTime.value = selectedTimeInSeconds;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.value > 0) {
        remainingTime.value -= 1;
      } else {
        timer.cancel();
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
        IconButton(onPressed: (){
          widget.fingerprinting.stopFingerprinting();
          widget.mapController.removeMarker(widget.mapController.);
          }, icon: Icon(Icons.cancel)),
        Card(
          child: Container(
            width: screenWidth-32,
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
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
                ),
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
              child: Text("5 sec"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("10 sec"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("30 sec"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("1 min"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("1.5 min"),
            ),
          ],
        ),
        SizedBox(height: 12,),
        ValueListenableBuilder<int>(
          valueListenable: remainingTime,
          builder:(context, value, child) {
            return Text(
              "Time left: ${value}s",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            );
          },
        ),
        SizedBox(height: 12,),
        ActionSlider.standard(
          child: const Text('Slide to capture'),
          action: (controller)async{
            widget.fingerprinting.collectSensorDataEverySecond();
            startCountdown();
            controller.loading(); //starts loading animation
            await Future.delayed(Duration(seconds: selectedTimeInSeconds));
            bool success = await widget.fingerprinting.stopCollectingData();
            if(success){
              controller.success();
              await Future.delayed(Duration(seconds:5));
              controller.reset();
              widget.fingerprinting.updateMarker(markerId:  MarkerId('${widget.fingerprinting.userPosition!.coordx},${widget.fingerprinting.userPosition!.coordy}'), position: LatLng(widget.fingerprinting.userPosition!.lat!, widget.fingerprinting.userPosition!.lon!));
              widget.fingerprinting.stopFingerprinting();
            }else{
              controller.failure();
              await Future.delayed(Duration(seconds: 5));
              controller.reset();
              widget.fingerprinting.stopFingerprinting();
              _showErrorDialog(context);

            }
          },
        ),
      ],
    );
  }
  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error Occurred"),
          content: Text("Please take fingerprinting data again at that point."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        );
      },
    );
  }

}
