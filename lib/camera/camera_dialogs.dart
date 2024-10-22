import 'package:flutter/material.dart';

Future<void> showDeviceDisconnected(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Kit desconectou'),
        content: const Text(
            'O kit foi desconectado, conecte-o para poder continuar a escanear'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Ok'),
          ),
        ],
      );
    },
  );
}
