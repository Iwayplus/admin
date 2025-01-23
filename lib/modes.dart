import 'package:flutter/material.dart';

class Mode{
  IconData icon;
  String name;

  Mode({required this.name,required this.icon});
}

class availableModes{
  List<Mode> modes = [Mode(name: "Off", icon: Icons.code_off_outlined)];
  int selected = 0;

  availableModes(){
    addFingerPrinting();
  }

  addFingerPrinting(){
    var mode = Mode(name: "FingerPrinting", icon: Icons.snowshoeing);
    this.modes.add(mode);
  }

}