import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:installer/screen_count_chairs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';
import 'main.dart';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class InitialiseCameraScreen extends StatefulWidget {
  final String library;
  final String floor;
  final String cameraZone;
  final GlobalKey<ScaffoldState>
      prevScaffoldKey; //  Passed from previous screen to trigger snackbar upon intialisation complete

  InitialiseCameraScreen(
      {@required this.library,
      @required this.floor,
      @required this.cameraZone,
      @required this.prevScaffoldKey});

  _InitialiseCameraScreenState createState() => _InitialiseCameraScreenState();
}

class _InitialiseCameraScreenState extends State<InitialiseCameraScreen> {
  String _cameraName;
  String _firebaseImagePath;
  String _firebaseFloorplanPath;

  int _numChairsPresent;

  void setNumChairsPresent(int count) {
    _numChairsPresent = count;
  }

  void submitInfo() {
    widget.prevScaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).accentColor,
      content: Text('$_cameraName successfully calibrated'),
      duration: Duration(seconds: 5),
    ));
    Navigator.pop(context);
    Database.setCameraZoneInformation(_firebaseImagePath, _numChairsPresent)
        .then((onValue) {});
  }

  // Future<File> downloadFile(String fileName) async {
  //   print("Downloading image: $fileName from FirebaseStorage..");
  //   Directory tempDir = Directory.systemTemp;
  //   final File file = File('${tempDir.path}/$fileName');

  // final StorageReference ref = FirebaseStorage.instance.ref().child(fileName);
  //   final StorageFileDownloadTask downloadTask = ref.writeToFile(file);

  //   downloadTask.future.then((snapshot) {
  //     setState(() {
  //       _remoteImage = file;
  //       _imageLoaded = true;
  //       if (shouldShowDialog) {
  //         showInstructionDialog();
  //         shouldShowDialog = false;
  //       }
  //     });
  //   });

  //   return file;
  // }

  @override
  void initState() {
    _cameraName = "Camera " + widget.cameraZone;
    _firebaseImagePath = "/libraries/" +
        widget.library +
        "/floors" +
        "/" +
        widget.floor +
        "/camera_zones" +
        "/" +
        widget.cameraZone +
        "/" +
        "image.jpg" +
        "";

    _firebaseFloorplanPath = "/libraries/" +
        widget.library +
        "/floors" +
        "/" +
        widget.floor +
        "/floor_plan.png";

    print(_firebaseImagePath);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(
            title: const Text('Initialise Camera'),
            centerTitle: true,
            actions: <Widget>[],
          );

    Main.appBarHeight = appBar.preferredSize.height;
    Main.appBarHeight = 0.0;

    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          body: Navigator(onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(builder: (context) {
              return CountChairsScreen(
                  firebaseImagePath: _firebaseImagePath,
                  onComplete: setNumChairsPresent,
                  firebaseFloorplanPath: _firebaseFloorplanPath);
            });
          }),
        ));
  }
}
