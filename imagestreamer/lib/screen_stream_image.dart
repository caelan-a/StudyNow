import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart';
import 'dart:async';
import 'screen_settings.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:battery/battery.dart';

class Capture {
  String localPath;
  String name;

  Capture({this.localPath, this.name});
}

class StreamImageScreen extends StatefulWidget {
  int timeInterval;

  StreamImageScreen({Key key, this.timeInterval}) : super(key: key);

  @override
  _StreamImageScreenState createState() => _StreamImageScreenState();
}

class _StreamImageScreenState extends State<StreamImageScreen>
    with SingleTickerProviderStateMixin {
  bool _timerPaused = true;
  bool _readyToStream = false;
  bool _capturing = false;
  List<CameraDescription> cameras;
  CameraController controller;

  static const oneSec = const Duration(seconds: 1);
  int _timeElapsed = 0;
  int _numCapturesPerInterval = 1;

  List<Capture> _captures;

  Timer timer;

  Future<CameraController> getCameraController() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    return controller.initialize().then((_) {
      if (!mounted) {
        return null;
      }
      setState(() {});
      return controller;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  var battery = Battery();
  
  @override
  void initState() {
    // Instantiate it
    // Be informed when the state (full, charging, discharging) changes
    battery.onBatteryStateChanged.listen((BatteryState state) {
          Firestore.instance.document(fsCameraZonePath).setData({
      ""
          "capture_urls": {captureName: fbsCaptureUrl},
    }, merge: true);
    });

    getCameraController().then((c) {
      controller = c;
    });
    super.initState();
  }

  Future<void> setCaptureUrl(
      String captureName, String fbsCaptureUrl, String fsCameraZonePath) async {
    Firestore.instance.document(fsCameraZonePath).setData({
      ""
          "capture_urls": {captureName: fbsCaptureUrl},
    }, merge: true);
  }

  Future<void> sendImagesToFirebase() async {
    final StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(Main.cameraZone.getFirebasePath());

    for (Capture capture in _captures) {
      print("Uploading ${capture.name}");
      File file = File(capture.localPath);
      final StorageUploadTask task =
          firebaseStorageRef.child(capture.name).putFile(file);
      await task.onComplete.then((result) async {
        //  Set url for download in firestore
        await setCaptureUrl(capture.name, await result.ref.getDownloadURL(),
            Main.cameraZone.getFirebasePath());
        print("Uploaded ${capture.name} successfully");
      });
    }

    _capturing = false;
  }

  Future<void> captureImageSeries() async {
    _capturing = true;
    Directory tempDir = await getTemporaryDirectory();

    _captures = [];
    for (var i = 0; i < Main.cameraZone.numCapturesPerInterval; i++) {
      print("Taking picture number $i");
      String localPath = '${tempDir.path}/image_$i.png';
      if (await File(localPath).exists()) {
        await File(localPath).delete();
      }

      await controller.takePicture(localPath).then((void v) {
        _captures.add(Capture(localPath: localPath, name: 'image_$i.png'));
      });
    }
  }

  void onTimeIntervalComplete() {
    _timeElapsed = 0;
    timer.cancel();
    captureImageSeries().then((void v) {
      sendImagesToFirebase().then((v) {
        startTimeout();
        print("Captures successfully uploaded\nRestarting timer");
      });
    });
  }

  //  Check if we need to reset actual timer so it doesnt reach int limit
  startTimeout([int milliseconds]) {
    timer = Timer.periodic(oneSec, (Timer t) {
      print(_timeElapsed);
      setState(() {
        if (_timeElapsed < Main.cameraZone.timeInterval) {
          if (!_capturing) {
            _timeElapsed++;
          }
        } else {
          onTimeIntervalComplete();
        }
      });
    });
  }

  _pauseTimer() {
    print("pause timer");
    _timerPaused = true;
    timer.cancel();
  }

  _resumeTimer() {
    print("resume timer");
    _timerPaused = false;
    startTimeout();
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
              _pauseTimer();
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
          Positioned(
            bottom: 40.0,
            left: 20.0,
            child: Center(
                child: Container(
              child: Text("Streaming to ${Main.cameraZone.getFirebasePath()}"),
            )),
          ),
          Positioned(
            bottom: 120.0,
            left: MediaQuery.of(context).size.width / 2.0 - 30.0,
            child: Center(
                child: Container(
                    child: IconButton(
              iconSize: 50.0,
              icon: Icon(
                _timerPaused ? Icons.play_arrow : Icons.pause,
                size: 50.0,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                setState(() {
                  if (!_timerPaused) {
                    _pauseTimer();
                  } else {
                    _resumeTimer();
                  }
                });
              },
            ))),
          ),
          Positioned(
            bottom: 20.0,
            left: 20.0,
            child: Center(
                child: Container(
              child: Text(
                  "Capturing ${Main.cameraZone.numCapturesPerInterval} image(s) per time interval"),
            )),
          ),
          Center(
              child: !_capturing
                  ? CircularPercentIndicator(
                      circularStrokeCap: CircularStrokeCap.round,
                      center: _timeElapsed != 0
                          ? Text(
                              "$_timeElapsed",
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            )
                          : Container(),
                      animationDuration: 100,
                      radius: 100.0,
                      lineWidth: 6.0,
                      animateFromLastPercent: true,
                      progressColor: Theme.of(context).primaryColor,
                      percent: (_timeElapsed / Main.cameraZone.timeInterval)
                          .toDouble(),
                    )
                  : LinearProgressIndicator())
        ],
      ),
    );
  }
}
