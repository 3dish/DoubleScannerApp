
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import 'package:three_dish_double_scanner/ble/ble_provider.dart';
import 'package:three_dish_double_scanner/ble/ble_service.dart';
import 'package:three_dish_double_scanner/camera/camera_porvider.dart';
import 'package:three_dish_double_scanner/camera/camera_view.dart';
import 'package:three_dish_double_scanner/ble/ble_view.dart';
import 'package:provider/provider.dart';
import 'package:three_dish_double_scanner/routes.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => Blutoothprovider(),
        ),
        ChangeNotifierProvider(
          create: (context) => CameraProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     return MaterialApp(
          restorationScopeId: 'app',

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), 
          ],


          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors
                  .lightBlue, 
            ),
          ),

          routes: {
            cameraViewRoute: (context) => const CameraView(),
            bleViewRoute: (context) => const ConnectingView(),
          },

          home: const ConnectingView(),
        );
  }
}
