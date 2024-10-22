import 'package:flutter/material.dart';

class CameraProvider extends ChangeNotifier {
  bool _toggleScanUI = false;
  bool _showOverlay = false;
  bool _isScanCompleted = false;
  double _scanprogress = 0.0;

  bool get showOverlay => _showOverlay;
  bool get toogleScanUi => _toggleScanUI;
  bool get isScanCompleted => _isScanCompleted;
  double get scanProgress => _scanprogress;


  void setShowoverlay(bool value) {
    _showOverlay = value;
    notifyListeners();
  }

  void setScanProgress(double value) {
    _scanprogress = value;
    notifyListeners();
  }

  void toggleScanUi() {
    _toggleScanUI = !_toggleScanUI;
    notifyListeners();
  }

  void setScanCompleted() {
    _isScanCompleted = true;
    notifyListeners();
  }

  void resetScanCompleted() {
    _isScanCompleted = false;
    notifyListeners();
  }

}
