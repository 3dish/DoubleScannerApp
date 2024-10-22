import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Blutoothprovider extends ChangeNotifier {
  DiscoveredDevice? _device;
  DiscoveredDevice? get device => _device;
  bool _startScan = false;
  bool get startScan => _startScan;

  void setStartScan(bool startscan){
    bool lastValue = _startScan; 
    _startScan = startscan;
    if(lastValue != startScan){
      notifyListeners();
      log("Listners Changed In SETSTARTSCAN");
    }
    
  }

  void setDevice(DiscoveredDevice? device) {
    _device = device;
    notifyListeners();
  }
}
