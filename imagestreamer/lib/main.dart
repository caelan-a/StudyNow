import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'screen_home.dart';
import 'package:imagestreamer/struct_camera_zone.dart';

void main() {
  runApp(Main());
}

class Main extends StatelessWidget {
  static CameraZone cameraZone = CameraZone(libraryID: "baileuu", floorID: "1", cameraZoneID: "1");

  static Future<dynamic> toScreen(BuildContext context, Widget screen) {
    Future<dynamic> result = Navigator.push(context, CupertinoPageRoute(builder: (context) => screen));
    return result;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        }),
      ),
      home: HomePage(title: 'StudyNow ImageStreamer'),
    );
  }
}
