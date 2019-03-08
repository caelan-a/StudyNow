import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'screen_home.dart';

void main() => runApp(Main());

class Main extends StatelessWidget {
  static void toScreen(BuildContext context, Widget screen) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => screen));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'StudyNow Installer'),
    );
  }
}
