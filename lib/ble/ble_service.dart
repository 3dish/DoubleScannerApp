import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothService {
  DiscoveredDevice? myDevice;
  Function(DiscoveredDevice?)? onChangeMydevice;
  StreamSubscription? connectionSubscription;
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  final FlutterReactiveBle ble = FlutterReactiveBle();
  final serviceUuid = Uuid.parse('a50982ce-e27b-4afa-a0bd-cedac40bbfe0');
  QualifiedCharacteristic? scaningCharacteristic;
  QualifiedCharacteristic? rotateCharacteristic;
  QualifiedCharacteristic? armCharacteristic;

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
        ble.connectToDevice(id: device.id).listen((connectionState) {
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
          armCharacteristic = QualifiedCharacteristic(
            serviceId: serviceUuid,
            characteristicId:
                Uuid.parse("d1515737-3bcd-4ad5-8245-6a9218528e75"),
            deviceId: myDevice!.id,
          );
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

  // Method to disconnect from a device.
  Future<void> disconnectFromDevice() async {
    myDevice = null;
    onChangeMydevice?.call(myDevice);
    await connectionSubscription?.cancel();
  }

}
