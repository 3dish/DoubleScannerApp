import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:three_dish_double_scanner/ble/ble_provider.dart';
import 'package:three_dish_double_scanner/ble/ble_service.dart';
import 'package:three_dish_double_scanner/camera/camera_dialogs.dart';
import 'package:three_dish_double_scanner/camera/camera_porvider.dart';
import 'package:three_dish_double_scanner/camera/camera_service.dart';
import 'package:three_dish_double_scanner/routes.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraService cameraService;
  late BluetoothService bluetoothService;
  bool _callbackSet = false;
  bool _isCamerainitialized = false;
  late Blutoothprovider provider;
  late CameraProvider cameraProvider;

  @override
  void initState() {
    super.initState();
    cameraService = CameraService();
    bluetoothService = BluetoothService.instance;
    initializeCameraService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = Provider.of<Blutoothprovider>(context, listen: false);
      provider.addListener(_bluetoothDeviceListener);
      cameraProvider = Provider.of<CameraProvider>(context, listen: false);
      cameraProvider.addListener(_scanCompleteListener);
      setUpCallbacks(cameraProvider);
      
    });
  }

  void _scanCompleteListener() async {
    if (cameraProvider.isScanCompleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text('Scan completed!'),
          ),
          duration: Duration(seconds: 5),
        ),
      );
      provider.setStartScan(false);
      cameraProvider.resetScanCompleted();
      bluetoothService.listenForCharacteristicChanges();
    }
    
  }

  //If the kit is not connected or it disconnects shouw a dialog and pop the Navigator
  void _bluetoothDeviceListener() async {
    if (provider.device == null) {
      cameraService.stopScan = true;
      await showDeviceDisconnected(context);
      Navigator.of(context).pushReplacementNamed(bleViewRoute);
    }
    
    if(provider.startScan == true){
      cameraProvider.toggleScanUi();
      await cameraService.takePicturesSemiAuto();
    }
  }

  void initializeCameraService() {
    cameraService.initializeCamera().then((_) {
      if (!mounted) return;
      setState(() {
        _isCamerainitialized = true;
      });
    }).catchError((error) {
      // Handle initialization error (e.g., camera not available)
    });
  }

  void setUpCallbacks(CameraProvider cameraProvider) {
    if (!_callbackSet) {
      cameraService.onShowOverlay = cameraProvider.setShowoverlay;
      cameraService.onToogleUi = cameraProvider.toggleScanUi;
      cameraService.onUpdateProgress = cameraProvider.setScanProgress;
      cameraService.onScanCompleted = cameraProvider.setScanCompleted;
      _callbackSet = true;
    }
  }

  @override
  void dispose() {
    provider.removeListener(_bluetoothDeviceListener);
    cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isCamerainitialized
          ? FutureBuilder<void>(
              future: cameraService.initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return OrientationBuilder(
                    builder: (context, orientation) {
                      if (orientation == Orientation.portrait) {
                        // If in portrait mode, display a black screen
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.white),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Rotate phone to start scanning',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            )
                          ],
                        );
                      } else {
                        // If in landscape mode, display the camera preview and controls
                        return Stack(
                          children: [
                            
                            Container(
                              color: Colors.black,
                            ),
                            Center(
                              child: CameraPreview(cameraService.controller),
                            ),
                            if (context.watch<CameraProvider>().showOverlay)
                              Container(
                                color: Colors.black,
                              ),
                            Center(
                              child:
                                  NotScanningUi(cameraService: cameraService),
                            ),
                            ScaningUi(cameraService: cameraService),
                            Align(
                              alignment: Alignment.topLeft, 
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Text(
                                  context.watch<Blutoothprovider>().deviceNr.toString(),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 46.0, 
                                    fontWeight: FontWeight.bold, 
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class NotScanningUi extends StatelessWidget {
  const NotScanningUi({
    super.key,
    required this.cameraService,
  });

  final CameraService cameraService;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !context.watch<CameraProvider>().toogleScanUi,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
          ),
          ElevatedButton(
            onPressed: () async {
              await cameraService.startScan();
            },
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 20),
              minimumSize: const Size(180, 70),
              side: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera,
                  size: 30,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Start Scan',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScaningUi extends StatelessWidget {
  const ScaningUi({
    super.key,
    required this.cameraService,
  });
  final CameraService cameraService;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: context.watch<CameraProvider>().toogleScanUi,
      child: Positioned(
        bottom: 0, // Align at the bottom of the screen
        left: 0,
        right: 0,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(
                bottom: 8.0,
                left: 300,
              ),
              /*child: ElevatedButton(
                onPressed: () {
                  cameraService.stopScan = true;
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                  minimumSize: const Size(80, 40),
                  side: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.exit_to_app,
                      size: 30,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text('STOP')
                  ],
                ),
              ),*/
            ),
            Card(
              margin: const EdgeInsets.only(
                bottom: 30,
                left: 200,
                right: 200,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'Scaning(${((context.watch<CameraProvider>().scanProgress) * 100).toInt()}%)'),
                    LinearProgressIndicator(
                      value: context.watch<CameraProvider>().scanProgress,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraNotFoundExeption implements Exception {}