import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:three_dish_double_scanner/ble/ble_provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:three_dish_double_scanner/ble/ble_service.dart';
import 'package:provider/provider.dart';
import 'package:three_dish_double_scanner/routes.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
    late Blutoothprovider provider;

    @override
  void initState() {
    super.initState();
    // Add a listener to check if the kit is connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = Provider.of<Blutoothprovider>(context, listen: false);
      log("Listener was added");
      provider.addListener(_bluetoothDeviceListener);
    });
  }


  //If the kit is connected go to camera view
  void _bluetoothDeviceListener() async {
    if (provider.device == null) {
      log("Called Navigator");
      Navigator.of(context).pushReplacementNamed(bleViewRoute);
      
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Camera App'),
      ),
      body: const Center(
        child: Column(
          children: [ Text("Hello World")],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>{},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), 
    );
  }
}