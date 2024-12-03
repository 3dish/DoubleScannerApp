import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothService {
  DiscoveredDevice? myDevice;
  Function(DiscoveredDevice?)? onChangeMydevice;
  Function(bool)? onStartScan;
  Function(int)? onDeviceNr;
  StreamSubscription? connectionSubscription;
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  FlutterReactiveBle ble = FlutterReactiveBle();
  final serviceUuid = Uuid.parse('a50982ce-e27b-4afa-a0bd-cedac40bbfe0');
  QualifiedCharacteristic? scaningCharacteristic;
  QualifiedCharacteristic? rotate_1_Characteristic;
  QualifiedCharacteristic? rotate_2_Characteristic;
  QualifiedCharacteristic? deviceCharacteristic;

  BluetoothService._internal();

  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() => _instance;
  static BluetoothService get instance => _instance;

  int? _deviceNr;

  DiscoveredDevice? myDeviceFromMemory;

  void scanForDevicesAndConnect() async {
    
    await connectionSubscription?.cancel();
    connectionSubscription = null;
    log("Scanning devices...");
    bool? isConnected;
    if(myDeviceFromMemory != null){
      isConnected = await connectToDevice(myDeviceFromMemory!);
      _setDeviceNr();
    }else{
      scanSubscription = ble.scanForDevices(
        withServices: [serviceUuid],
        scanMode: ScanMode.lowLatency,
      ).listen((device) async {
        log('Device found: ${device.name}');
        myDeviceFromMemory = device;
        // Stop scanning as we found the device we were looking for
        await scanSubscription?.cancel();

        // Attempt to connect to the found device
        isConnected = await connectToDevice(device);
        _setDeviceNr();

      }, onError: (error) {
        log('Error occurred during Bluetooth device scan: $error');
      });
    }
    if (isConnected == true) {
      log('Successfully connected from memory to ${myDeviceFromMemory!.name}');
      _setDeviceNr();
    } else {
      log('Failed to connect to ${myDeviceFromMemory!.name}');
    }
  }
  void _setDeviceNr() async{
    if (_deviceNr == null){
      String? d = await getDeviceCharatristic();
      _deviceNr = int.parse(d!);
      log("Device Nr: $d");
      onDeviceNr?.call(int.parse(d!));
    }
  }

  Future<void> dispose() async {
    await scanSubscription?.cancel();
    scanSubscription = null;

    
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
          rotate_1_Characteristic = QualifiedCharacteristic(
            serviceId: serviceUuid,
            characteristicId:
                Uuid.parse("a0656831-9041-455d-a409-6e2ff6129e37"),
            deviceId: myDevice!.id,
          );
          rotate_2_Characteristic = QualifiedCharacteristic(
            serviceId: serviceUuid,
            characteristicId:
                Uuid.parse("a0656831-9041-455d-a409-6e2ff6129e34"),
            deviceId: myDevice!.id,
          );
          deviceCharacteristic = QualifiedCharacteristic(
            serviceId: serviceUuid,
            characteristicId:
                Uuid.parse("a0656831-9041-455d-a409-6e2ff6129e30"),
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
      // Infinite loop to read the characteristic value every xtime 
      while (true) {
        await Future.delayed(Duration(milliseconds: 100)); 

        // Read the characteristic value
        final value = await ble.readCharacteristic(scaningCharacteristic!);

        // Check if the value is "1" 
        //! Should only enter if there is no scan is in progress
        if (utf8.decode(value) == "1") {
          onStartScan?.call(true);
          break;
        }
        log("Loop listen for Charactristic changes");

        //TODO Break the loop if Disconnect
        // if (someExitCondition) break;
      }
    } catch (e) {
      log('Error occurred while reading characteristic: $e');
    }
  }
  // Method to disconnect from a device.
  Future<void> disconnectFromDevice() async {
    log("Disconnected from device");
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
      //Adds 1, when the 2 phone signal the value will be 2 meaning the 2 phone taken the photo

      await ble.writeCharacteristicWithResponse(
        _deviceNr==1?rotate_1_Characteristic!:rotate_2_Characteristic!,
        value: utf8.encode('1'),
      );
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
            .readCharacteristic(_deviceNr==1?rotate_1_Characteristic!:rotate_2_Characteristic!)
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
    Future<String?> getDeviceCharatristic() async {
    if (myDevice != null) {
      try {
        // This timeout was put in place because of a bug when disconnecting
        // in the middle of a platform rotation
        final strf = await ble
            .readCharacteristic(deviceCharacteristic!)
            .timeout(const Duration(
              seconds: 2,
            ));
        log(utf8.decode(strf));
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
