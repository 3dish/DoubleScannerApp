import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:three_dish_double_scanner/ble/ble_provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:three_dish_double_scanner/ble/ble_service.dart';
import 'package:provider/provider.dart';
import 'package:three_dish_double_scanner/routes.dart';


class ConnectingView extends StatefulWidget {
  const ConnectingView({super.key});

  @override
  _ConnectingViewState createState() => _ConnectingViewState();

}

class _ConnectingViewState
    extends State<ConnectingView> {
  final BluetoothService bluetoothService = BluetoothService.instance;
  List<DiscoveredDevice> devices = [];
  StreamSubscription? bleStatusSubscription;
  late Blutoothprovider provider;


  @override
  void initState() {
    super.initState();

    provider = Provider.of<Blutoothprovider>(context, listen: false);
    bluetoothService.onChangeMydevice = provider.setDevice;

    initBluetoothOperations();
    
    // Add a listener to check if the kit is connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log("Listener was added");
      provider.addListener(_bluetoothDeviceListener);
    });
  }


  //If the kit is connected go to camera view
  void _bluetoothDeviceListener() async {
    if (provider.device != null) {
      log("Called Navigator");
      Navigator.of(context).pushReplacementNamed(cameraViewRoute);
      
    }
  }

  void initBluetoothOperations() {
    // Listen to the BLE status
    bleStatusSubscription = bluetoothService.ble.statusStream.listen(
      (status) {
        if (status == BleStatus.ready) {
          bluetoothService.scanForDevicesAndConnect();
          log('Call scan devices');
        } else {
          // Handle the case where Bluetooth is not ready or unavailable
          log('BLE is not ready. Current status: $status');
        }
      },
      onError: (error) {
        log('Error listening to BLE status: $error');
      },
    );
  }

  @override
  void dispose() {
    bleStatusSubscription?.cancel();
    bluetoothService.dispose();
    provider.removeListener(_bluetoothDeviceListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        "Scanning....",
        style: TextStyle(color: Colors.black87),
      )),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.beat(
              color: Colors.lightBlue,
              size: 200,
            ),
            const SizedBox(height: 50),
            const Text(
              'Connecte o kit á tomada',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}