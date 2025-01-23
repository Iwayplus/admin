import 'package:admin/fingerprinting/pannels/finger_printing_pannel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../fingerprinting.dart';


class fingerprintingPannel {
  final PanelController _panelController = PanelController();
  late Fingerprinting fingerprinting;

  fingerprintingPannel({required this.fingerprinting});


  // Method to show the panel
  void showPanel() {
    _panelController.open();
  }

  // Method to hide the panel
  void hidePanel() {
    _panelController.close();
  }

  bool isPanelOpened() {
    try {
      return _panelController.isPanelOpen;
    } catch (e) {
      return false;
    }
  }

  // Method to toggle panel visibility
  void togglePanel() {
    if (_panelController.isPanelOpen) {
      hidePanel();
    } else {
      showPanel();
    }
  }

  // Method to get the SlidingUpPanel widget
  Widget getPanelWidget(BuildContext context) {
    return SlidingUpPanel(
      controller: _panelController,
      panel: pinLandmark(fingerprinting: fingerprinting),
      minHeight: 0,
      maxHeight: 350, // Maximum height of the panel
      backdropOpacity: 0.5,
      isDraggable: false,
    );
  }
}
