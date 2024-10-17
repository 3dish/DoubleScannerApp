import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Blutoothprovider extends ChangeNotifier {
  DiscoveredDevice? _device;
  DiscoveredDevice? get device => _device;

  void setDevice(DiscoveredDevice? device) {
    _device = device;
    notifyListeners();
    log("Device Was Changed In Provider");
  }
}
