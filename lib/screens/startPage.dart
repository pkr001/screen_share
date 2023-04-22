import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:screen_share/screens/homePage.dart';


class Xss extends StatelessWidget {
  const Xss({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: () {
          FlutterBackground.enableBackgroundExecution();
          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>const HomePage()));
        }, child:const Text('Toch Me')),
      ),
    );
  }
}
