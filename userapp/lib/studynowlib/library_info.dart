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

import 'package:flutter/foundation.dart';
import 'dart:isolate';

class CameraZone {
  String fsPath;
  String title;

  int chairs_present;
  int people_present;

  Offset markerPosition;
  double markerScale;

  CameraZone({this.fsPath, this.title});
}

class FloorPlan {
  bool imageLoaded = false;
  String fbsPath; // FirebaseStorage floorplan path
  File imageFile;
  Size imageSize;

  FloorPlan({this.fbsPath});
}

class Floor {
  String fsPath;
  String floorID; // firebase collection name of floor
  String title; // User friendly string

  FloorPlan floorPlan;

  Map<String, CameraZone> cameraZones;

  List<String> getCameraZoneFSPaths() {
    if (cameraZones != null) {
      return cameraZones.values
          .map((CameraZone cameraZone) => cameraZone.fsPath)
          .toList();
    } else {
      return [];
    }
  }

  Future<FloorPlan> getFloorPlan() async {
    if (floorPlan == null) {
      String fbsFloorplanPath = fsPath + '/floor_plan.png';
      FloorPlan newFloorPlan = FloorPlan(fbsPath: fbsFloorplanPath);

      await Database.downloadFile(fbsFloorplanPath, (File file) async {
        //  Get image properties when file is retrived
        List<int> imageBytes = await file.readAsBytes();
        imageutil.Image image = imageutil.decodePng(imageBytes);
        newFloorPlan.imageSize =
            Size(image.width.toDouble(), image.height.toDouble());
        newFloorPlan.imageFile = file;
        newFloorPlan.imageLoaded = true;
      }, true);

      return newFloorPlan;
    } else {
      return floorPlan;
    }
  }

  Future<bool> init() {
    return Firestore.instance
        .collection(fsPath + '/camera_zones')
        .snapshots()
        .first
        .then((snapshot) async {
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

  Floor(this.fsPath, this.title) {
    this.fsPath = fsPath;
    print(fsPath);
  }
}

class LibraryInfo {
  String fsPath;
  Map<String, Floor> floors;

  static Future<Map<String, Floor>> getFloors(String fsLibraryPath) async {
    print("Initialising floors..");
    Map<String, Floor> floors;
    floors = await Firestore.instance
        .collection(fsLibraryPath + '/floors')
        .snapshots()
        .first
        .then((snapshot) async {
      floors = {};

      int numFLoors = snapshot.documents.length;
      print("$numFLoors floors in " + fsLibraryPath + '/floors');

      for (DocumentSnapshot floorDoc in snapshot.documents) {
        String floorID = floorDoc.documentID.toString();
        String floorTitle = floorDoc['title'].toString();
        print(floorID + " : " + floorTitle);
        String fsFloorPath = fsLibraryPath + '/floors/' + floorID;
        Floor floor = Floor(fsFloorPath, floorTitle);
        await floor.init();
        floors.putIfAbsent(floorID, () => floor);
      }
      return floors;
    });
    return floors;
  }

  LibraryInfo({this.fsPath});
}
