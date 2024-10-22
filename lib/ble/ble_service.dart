import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothService {
  DiscoveredDevice? myDevice;
  Function(DiscoveredDevice?)? onChangeMydevice;
  Function(bool)? onStartScan;
  StreamSubscription? connectionSubscription;
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  final FlutterReactiveBle ble = FlutterReactiveBle();
  final serviceUuid = Uuid.parse('a50982ce-e27b-4afa-a0bd-cedac40bbfe0');
  QualifiedCharacteristic? scaningCharacteristic;
    QualifiedCharacteristic? rotateCharacteristic;

  BluetoothService._internal();

  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() => _instance;
  static BluetoothService get instance => _instance;

  void scanForDevicesAndConnect() {
    scanSubscription = ble.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) async {
      log('Device found: ${device.name}');
      // Optionally, you can check additional conditions here, like device name or RSSI

      // Stop scanning as we found the device we were looking for
      await scanSubscription?.cancel();

      // Attempt to connect to the found device
      bool isConnected = await connectToDevice(device);
      if (isConnected) {
        log('Successfully connected to ${device.name}');
        // You can proceed with further operations on the connected device
      } else {
        log('Failed to connect to ${device.name}');
        // Handle connection failure (retry, notify user, etc.)
      }
    }, onError: (error) {
      log('Error occurred during Bluetooth device scan: $error');
    });
  }

  Future<void> dispose() async {
    await scanSubscription?.cancel();
  }

  //! I think the compeler isn´t doing anything ...
  // Method to connect to a device.
  Future<bool> connectToDevice(DiscoveredDevice device) async {
    Completer<bool> completer = Completer();

    myDevice = device;

    connectionSubscription?.cancel();
    connectionSubscription =
        ble.connectToDevice(id: device.id).listen((connectionState) async {
      log('KIT CONNECTION STATE ${connectionState.connectionState}');
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        if (!completer.isCompleted) {
          onChangeMydevice?.call(myDevice);
          completer.complete(true);

          // Here i assign the charatristics
          scaningCharacteristic = QualifiedCharacteristic(
            serviceId: serviceUuid,
            characteristicId:
                Uuid.parse("bd6715f2-e389-4340-a154-6f7124b5066e"),
            deviceId: myDevice!.id,
          );
          rotateCharacteristic = QualifiedCharacteristic(
            serviceId: serviceUuid,
            characteristicId:
                Uuid.parse("a0656831-9041-455d-a409-6e2ff6129e37"),
            deviceId: myDevice!.id,
          );
          await Future.delayed(Duration(seconds: 2));
          //todo Should go to init of camera view 
          listenForCharacteristicChanges();
        }
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        disconnectFromDevice();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    }, onError: (dynamic error) {
      log('Error occurred when trying to connect: $error');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  void listenForCharacteristicChanges() async {
    try {
      // Infinite loop to read the characteristic value every xtime (adjust interval as needed)
      while (true) {
        await Future.delayed(Duration(milliseconds: 100)); 

        // Read the characteristic value
        final value = await ble.readCharacteristic(scaningCharacteristic!);
        
        log('Characteristic value: ${utf8.decode(value)}');

        // Check if the value is "1" (adjust the check according to your data format)
        //! Should only enter if there is no scan is in progress
        if (utf8.decode(value) == "1") {
          onStartScan?.call(true);
          break;
        }

        //TODO Break the loop if Disconnect
        // if (someExitCondition) break;
      }
    } catch (e) {
      log('Error occurred while reading characteristic: $e');
    }
  }
  // Method to disconnect from a device.
  Future<void> disconnectFromDevice() async {
    myDevice = null;
    onChangeMydevice?.call(myDevice);
    await connectionSubscription?.cancel();
  }
  
  // If scan is true, it will signal the kit to start the scan process else stop
  Future<void> signalkitRotate() async {
    if (myDevice == null) {
      log('Attempted to send a signal Rotete to ESP32 before connecting to the device.');
      return;
    }
    try {
      await ble.writeCharacteristicWithResponse(
        rotateCharacteristic!,
        value: utf8.encode('0'),
      );
      log('Signal to Rotate was sent (0)');
    } catch (e) {
      log('Error sending signal Rotate to ESP32: $e');
    }
  }
  Future<String?> getRotateCharatristic() async {
    if (myDevice != null) {
      try {
        // This timeout was put in place because of a bug when disconnecting
        // in the middle of a platform rotation
        final strf = await ble
            .readCharacteristic(rotateCharacteristic!)
            .timeout(const Duration(
              seconds: 2,
            ));
        return utf8.decode(strf);
      } catch (e) {
        log(e.toString());
      }
    }
    return null;
  }

  // If scan is true, it will signal the kit to start the scan process else stop
  Future<void> signalkitScanning(bool scan) async {
    if (myDevice == null) {
      log('Attempted to send a signal Scanning to ESP32 before connecting to the device.');
      return;
    }
    try {
      await ble.writeCharacteristicWithResponse(
        scaningCharacteristic!,
        value: scan ? utf8.encode('1') : utf8.encode('0'),
      );
    } catch (e) {
      log('Error sending signal Scanning to ESP32: $e');
    }
  }

}
