import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';
import 'dart:async';
import 'screen_settings.dart';

class StreamImageScreen extends StatefulWidget {
  int timeInterval; 

  StreamImageScreen({Key key, this.timeInterval}) : super(key: key);

  @override
  _StreamImageScreenState createState() => _StreamImageScreenState();
}

class _StreamImageScreenState extends State<StreamImageScreen> {
  static const oneSec = const Duration(seconds:1);
  int _timeElapsed = 0; 

  Timer timer;

  @override
  void initState() {
    timer = startTimeout(300);
    super.initState();
  }

  void captureImageSeries() {
    
  }

  startTimeout([int milliseconds]) {
     timer =  Timer.periodic(oneSec, (Timer t) {
       if(_timeElapsed < 30) {
         _timeElapsed++;
       } else {
         _timeElapsed = 0;
       }
     });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Stream Image"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.settings,
            ),
            onPressed: () async {
              bool settingsChanged =
                  await Main.toScreen(context, SettingsScreen());
              print(settingsChanged);
              if (settingsChanged == true) {
                print("CHANGE");
              }
            },
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          Center(
              child: CircularProgressIndicator(
            value: timer.tick.toDouble(),
          ))
        ],
      ),
    );
  }
}
