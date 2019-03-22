import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as imageutil;
import 'database.dart';

class CameraZone {
  String fsPath;

  int chairs_present;
  int people_present;

  Offset markerPosition;
  double markerScale;

  CameraZone({this.fsPath});

  Widget _buildBusynessMarker() {
    return null;
  }
}

class Floor {
  String fsPath;
  String floorID; // firebase collection name of floor
  String title; // User friendly string

  Map<String, CameraZone> cameraZones;

  bool imageLoaded = false;
  String fbsFloorplanPath; // FirebaseStorage floorplan path
  File floorPlanImage;
  Size floorPlanImageSize;

  Future<void> getFloorPlan() async {
    return Database.downloadFile(fbsFloorplanPath, (File file) async {
      //  Get image properties when file is retrived
      List<int> imageBytes = await file.readAsBytes();
      imageutil.Image image = imageutil.decodeJpg(imageBytes);
      floorPlanImageSize =
          Size(image.width.toDouble(), image.height.toDouble());
      floorPlanImage = file;
      imageLoaded = true;
    });
  }

  Future<bool> _init() {
    Firestore.instance
        .collection(fsPath + '/camera_zones')
        .snapshots()
        .first
        .then((snapshot) {
      cameraZones = {};

      int numCameraZones = snapshot.documents.length;
      print("$numCameraZones camera zones in " + fsPath + '/camera_zones');

      for (DocumentSnapshot cameraZoneDoc in snapshot.documents) {
        String cameraZoneID = cameraZoneDoc.documentID;
        String fsCameraZonePath = fsPath + '/camera_zones/' + cameraZoneID;
        cameraZones.putIfAbsent(
            cameraZoneID, () => CameraZone(fsPath: fsCameraZonePath));
      }
    });
  }

  Widget _buildBusynessMarker() {
    return null;
  }

  Floor({this.fsPath, this.title}) {
    fbsFloorplanPath = fsPath + '/image.jpg';
    _init();
  }
}

class LibraryInfo {
  String fsPath;
  Map<String, Floor> floors;

  Future<bool> init(String fsLibraryPath) {
    print("Initialising floors..");
    return Firestore.instance
        .collection(fsLibraryPath + '/floors')
        .snapshots()
        .first
        .then((snapshot) {
      floors = {};

      int numFLoors = snapshot.documents.length;
      print("$numFLoors floors in " + fsLibraryPath + '/floors');

      for (DocumentSnapshot floorDoc in snapshot.documents) {
        String floorID = floorDoc.documentID.toString();
        String floorTitle = floorDoc['next_collection'].toString();
        print(floorID + " : " + floorTitle);
        String fsFloorPath = fsLibraryPath + '/floors/' + floorID;
        floors.putIfAbsent(floorID, () => Floor(fsPath: fsFloorPath, title:floorTitle));
      }
    });
  }

  LibraryInfo({this.fsPath});
}
