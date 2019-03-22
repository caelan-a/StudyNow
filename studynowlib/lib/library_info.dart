import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as imageutil;
import 'database.dart';

class CameraZone {
  String fsCameraZonePath;

  int chairs_present;
  int people_present;

  Offset markerPosition;
  double markerScale;

  CameraZone();

  Widget _buildCameraZoneMarker() {
    return Container();
  }
}

class Floor {
  String fsFloorPath;
  String floorID; // firebase collection name of floor
  String title; // User friendly string

  List<CameraZone> cameraZones;

  String fsFloorplanPath; // FirebaseStorage floorplan path
  File floorPlanImage;
  int imageWidth;
  int imageHeight;


  /* Get floorplan either from firebase or local storage if it exists */
  // Future<bool> getFloorplan() {

  // }

  Floor();
}

class LibraryInfo {
  String fsLibraryPath;
  List<Floor> floors;

  static void toSString() {
    print("hello");
  }


  Future<bool> _initFloors(String fsLibraryPath) {
    Firestore.instance.collection(fsLibraryPath+'/floors').snapshots().first.then((snapshot){
      snapshot.documents.map((document){
        print(document.documentID);
      });
      return true;
    });
  }

  Future<bool> initialise(String fsLibraryPath) {
    this.fsLibraryPath = fsLibraryPath;
    print("Initialising library..");
  }

  LibraryInfo({this.fsLibraryPath}) {
    print("INIT");
  }
}
