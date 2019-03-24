import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as imageutil;
import 'database.dart';
import 'pulsating_marker.dart';
import 'markable_map.dart';

class CameraZone {
  String fsPath;
  String title;

  int chairs_present;
  int people_present;

  Offset markerPosition;
  double markerScale;

  CameraZone({this.fsPath, this.title});
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
      imageutil.Image image = imageutil.decodePng(imageBytes);
      floorPlanImageSize =
          Size(image.width.toDouble(), image.height.toDouble());
      floorPlanImage = file;
      imageLoaded = true;
    }, true);
  }

  List<String> getCameraZoneFSPaths() {
    if(cameraZones != null) {
      return cameraZones.values.map((CameraZone cameraZone) => cameraZone.fsPath).toList();
    } else {
      return [];
    }
  }

  Future<bool> _init() {
    return Firestore.instance
        .collection(fsPath + '/camera_zones')
        .snapshots()
        .first
        .then((snapshot) {
      cameraZones = {};

      int numCameraZones = snapshot.documents.length;
      print("$numCameraZones camera zones in " + fsPath + '/camera_zones');

      for (DocumentSnapshot cameraZoneDoc in snapshot.documents) {
        String cameraZoneID = cameraZoneDoc.documentID;
        String cameraZoneTitle = cameraZoneDoc['title'];
        String fsCameraZonePath = fsPath + '/camera_zones/' + cameraZoneID;
        cameraZones.putIfAbsent(cameraZoneID,
            () => CameraZone(fsPath: fsCameraZonePath, title: cameraZoneTitle));
      }
    });
  }

  Floor({this.fsPath, this.title}) {
    fbsFloorplanPath = fsPath + '/floor_plan.png';
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
        String floorTitle = floorDoc['title'].toString();
        print(floorID + " : " + floorTitle);
        String fsFloorPath = fsLibraryPath + '/floors/' + floorID;
        floors.putIfAbsent(
            floorID, () => Floor(fsPath: fsFloorPath, title: floorTitle));
      }
    });
  }

  LibraryInfo({this.fsPath});
}
