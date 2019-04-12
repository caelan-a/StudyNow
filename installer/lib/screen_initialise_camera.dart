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
  String _firebaseZonePath;
  String _firebaseImagePath;
  String _firebaseFloorplanPath;

  int _numChairsPresent;
  double _markerSize;
  Offset _markerLocation;

  void setNumChairsPresent(int count) {
    _numChairsPresent = count;
  }

  void setMarkerInfo(double scale, Offset location) {
    _markerSize = scale;
    _markerLocation = location;
  }

  void onChooseZoneComplete(double scale, Offset location) {
    setMarkerInfo(scale, location);
    submitInfo();
  }

  void submitInfo() {
    widget.prevScaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).accentColor,
      content: Text('$_cameraName successfully calibrated'),
      duration: Duration(seconds: 5),
    ));
    Navigator.pop(context);
    Navigator.pop(context);
    Database.setCameraZoneInformation(_firebaseZonePath, _numChairsPresent, _markerSize, _markerLocation.dx, _markerLocation.dy)
        .then((onValue) {});
  }

  @override
  void initState() {
    _cameraName = "Camera " + widget.cameraZone;
    _firebaseZonePath = "/libraries/" +
        widget.library +
        "/floors/" +
        widget.floor +
        "/camera_zones" +
        "/" +
        widget.cameraZone;
    _firebaseImagePath = _firebaseZonePath + "/" +
        "image_0.png" +
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
            body: CountChairsScreen(
                firebaseImagePath: _firebaseImagePath,
                onComplete: setNumChairsPresent,
                onChooseZoneComplete: onChooseZoneComplete,
                firebaseFloorplanPath: _firebaseFloorplanPath)));
  }
}
