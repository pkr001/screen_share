import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';

import 'screens/startPage.dart';



void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initForegroundTask();
  await Firebase.initializeApp();
  await initForegroundService();
  runApp(const MyApp());
}

  Future<bool> initForegroundService() async {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'App name',
      notificationText: 'Screen sharing is in progress',
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon: AndroidResource(
        name: 'ic_launcher_foreground',
        defType: 'drawable'),
    );
   return FlutterBackground.initialize(androidConfig: androidConfig);
}


//.............
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StartPage(),
    );
  }
}
