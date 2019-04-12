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
import 'package:intl/intl.dart';

class Capture {
  String localPath;
  String name;
  bool streaming;

  Capture({
    this.localPath,
    this.name,
  });
}

class StreamImageScreen extends StatefulWidget {
  String cameraZoneFsID;
  bool streaming;

  int timeInterval;

  StreamImageScreen(
      {Key key, this.timeInterval, this.cameraZoneFsID, this.streaming})
      : super(key: key);

  @override
  _StreamImageScreenState createState() => _StreamImageScreenState();
}

class _StreamImageScreenState extends State<StreamImageScreen>
    with SingleTickerProviderStateMixin {
  List<CameraDescription> cameras;
  CameraController controller;

  static const oneSec = const Duration(seconds: 1);
  int _timeElapsed = 0;
  int _numCapturesPerInterval = 1;
  bool _timerPaused = true;
  bool _capturing = false;

  bool isStreaming;
  List<Capture> _captures;

  Timer timer;

  StreamSubscription firebaseDocSubscription;

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

  void listenToFireStore() {
    firebaseDocSubscription = Firestore.instance
        .collection('camera_zones')
        .document(widget.cameraZoneFsID)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      bool streaming = snapshot.data['streaming'];
      print("CHANGE: $streaming");
      // Hub has commanded camera to stop streaming
      if (streaming == true && _timerPaused == true) {
        _resumeTimer();
        widget.streaming = true;
      } else if (streaming == false && _timerPaused == false) {
        widget.streaming = false;
        _pauseTimer();
      }
    });
  }

  @override
  void initState() {
    //  Start streamer if firebase says to stream
    if (widget.streaming) {
      _resumeTimer();
    }

    listenToFireStore();

    // Instantiate it
    // Be informed when the state (full, charging, discharging) changes
    battery.onBatteryStateChanged.listen((BatteryState state) {
      print("Change battery for ${widget.cameraZoneFsID}");
      battery.batteryLevel.then((level) {
        Firestore.instance
            .document('camera_zones/' + widget.cameraZoneFsID)
            .setData({
          "battery_percentage": level,
        }, merge: true);
      });
    });

    getCameraController().then((c) {
      controller = c;
    });
    super.initState();
  }

  Future<void> setCaptureUrl(
      String captureName, String fbsCaptureUrl, String fsCameraZonePath) async {
    Firestore.instance.document(fsCameraZonePath).setData({
      "capture_urls": {captureName: fbsCaptureUrl},
      "last_streamed_at": DateTime.now().toString()
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
            'camera_zones/' + widget.cameraZoneFsID);
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
        if (widget.streaming) {
          startTimeout();
        }
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
