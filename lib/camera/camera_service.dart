// Crate Camera Service class 
import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:three_dish_double_scanner/ble/ble_service.dart';

class CameraNotFoundExeption implements Exception {}

class CameraService {
  final int _photosPerScanRound = 4;
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

  Future<CameraDescription> _getCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final cameras = await availableCameras();
      log('Camera obtained: ${cameras.first}');
      return cameras.first;
    } catch (e) {
      log('Camera Exeption Line 65 scan_list_view');
      throw CameraNotFoundExeption();
    }
  }

  Future<void> initializeCamera() async {
    _camera = await _getCamera();
    _cameraController = CameraController(
      _camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    _cameraController.lockCaptureOrientation(DeviceOrientation.landscapeRight);

    _initializeControllerFuture = _cameraController.initialize();
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
    stopScan = false; // In case there is a disconnection off scan reset the var

    final BluetoothService bluetoothService = BluetoothService.instance;
    //await bluetoothService.signalkitScanning(true);
    try {
      int photosTaken = 0;
      do {
        //First check if photo can be taken
        String? rotate = await bluetoothService.getRotateCharatristic();
        log('ROTATE: $rotate');
        if (rotate == "1") {
          await Future.delayed(const Duration(milliseconds: 500));
          await takePhotoToAppDirectory();

          await flash();

          onUpdateProgress?.call((photosTaken + 1) / _photosPerScanRound);

          if (_stopScan) {
            break;
          }

          photosTaken++;
          if (photosTaken < _photosPerScanRound) {
            //Signal the kit to rotate if it is not the last photo of a round
            await bluetoothService.signalkitRotate();
            await Future.delayed(const Duration(milliseconds: 500));
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
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/${DateTime.now()}.png';
    await image.saveTo(imagePath);
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
