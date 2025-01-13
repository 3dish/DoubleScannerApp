// Crate Camera Service class 
import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:three_dish_double_scanner/ble/ble_service.dart';

class CameraNotFoundExeption implements Exception {}

enum CameraType{normal, wide}

class CameraService {
  final int _photosPerScanRound = 30;
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  late CameraDescription _camera;
  static final CameraService _instance = CameraService._internal();
  bool _stopScan = false;

  //CallBacks for provider
  Function(bool)? onShowOverlay;
  Function(double)? onUpdateProgress;
  VoidCallback? onToogleUi;
  VoidCallback? onScanCompleted;


  CameraController get controller => _cameraController;
  set stopScan(bool stopScan) => _stopScan = stopScan;
  Future<void> get initializeControllerFuture => _initializeControllerFuture;

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();
  

  Future<CameraDescription> _getCamera(CameraType cameraType) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final cameras = await availableCameras();
      log('Camera obtained: ${cameras[0]}');
      if(cameraType == CameraType.normal){
        return cameras[0];
      } else {
        return cameras[2];
      }
      
    } catch (e) {
      log('Camera Exeption Line 65 scan_list_view');
      throw CameraNotFoundExeption();
    }
  }
  CameraType? _currentCamera = null;
  CameraType? get currentCamera => _currentCamera;

  Future<void> initializeCamera() async {
    if (_currentCamera != null) {
      await _cameraController.dispose(); // Dispose of the current controller
    }
    CameraType nextCamera = _currentCamera == CameraType.normal ? CameraType.wide : CameraType.normal;
    _camera = await _getCamera(nextCamera);

    _cameraController = CameraController(
      _camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    _cameraController.lockCaptureOrientation(DeviceOrientation.landscapeRight);
    _initializeControllerFuture = _cameraController.initialize();
    _currentCamera = nextCamera;
    await _initializeControllerFuture;
  }

  //? Semi Auto variables
  List<String> photosSemiAuto = [];
  int currentRound = 1;

  Future<void> startScan() async{
    final BluetoothService bluetoothService = BluetoothService.instance;
    await bluetoothService.signalkitScanning(true);
  }

  Future<void> takePicturesSemiAuto() async {
    // TODO: to stop the scann i should probably se if the device disconnects...
    stopScan = false; 

    final BluetoothService bluetoothService = BluetoothService.instance;
    //await bluetoothService.signalkitScanning(true);
    try {
      int photosTaken = 0;
      do {
        //First check if photo can be taken
        String? rotate = await bluetoothService.getRotateCharatristic();
        log('ROTATE: $rotate');
        if (rotate == "0") {
          //await Future.delayed(const Duration(milliseconds: 500));
          await takePhotoToAppDirectory();

          await flash();

          onUpdateProgress?.call((photosTaken + 1) / _photosPerScanRound);
          //If kit Scanning is false (Means the other phone disconnected)
          String? scanning = await bluetoothService.getKitScanning();
          if (scanning == "0") _stopScan = true;
          
          if (_stopScan) {
            break;
          }
          

          photosTaken++;
          if (photosTaken < _photosPerScanRound) {
            //Signal the kit to rotate if it is not the last photo of a round
            await Future.delayed(const Duration(milliseconds: 750));
            await bluetoothService.signalkitRotate();
            await Future.delayed(const Duration(milliseconds: 750));
          }
        }
        if (_stopScan) {
          break;
        }
      } while (photosTaken < _photosPerScanRound);



      //!This Wait is bugging 
      await Future.delayed(const Duration(milliseconds: 1000)); // Adjust duration as needed
      await bluetoothService.signalkitScanning(false);
      onToogleUi?.call();
      onUpdateProgress?.call(0.0);
      
      if (_stopScan) {
        stopScan = false;
        log('SCAN WAS STOPPED');
      } else{
        onScanCompleted?.call();
        log('SCAN was completed');
      }
    } catch (e) {
      log(e.toString());
      throw Exception('Something went wrong while scanning');
    }
  }

  Future<void> takePhotoToAppDirectory() async {
    final image = await _cameraController.takePicture();

    await Gal.putImage(image.path);
    // Delete the original location ...
    final file = File(image.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> flash() async {
    onShowOverlay?.call(true);
    await Future.delayed(
        const Duration(milliseconds: 100)); 
    onShowOverlay?.call(false);
  }

  Future<void> dispose() async {
    await _cameraController.dispose();
  }
}
