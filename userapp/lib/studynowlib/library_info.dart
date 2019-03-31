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

  FloorPlan({this.fbsPath, this.imageSize});
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

  Future<Size> getImageSize(File file) async {
    //  Get image properties when file is retrived
    print("Getting image size");
    List<int> imageBytes = await file.readAsBytes();
    imageutil.Image image = imageutil.decodePng(imageBytes);
    print("Successfully read image size");
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Future<FloorPlan> getFloorPlan() async {
    if (floorPlan == null) {
      String fbsFloorplanPath = fsPath + '/floor_plan.png';
      FloorPlan newFloorPlan = FloorPlan(fbsPath: fbsFloorplanPath);

      await Database.downloadFile(fbsFloorplanPath, (File file) async {
        newFloorPlan.imageSize = await getImageSize(file);

        newFloorPlan.imageFile = file;
        newFloorPlan.imageLoaded = true;
      }, true);
      return newFloorPlan;
    } else if (floorPlan.imageLoaded == false) {
      await Database.downloadFile(floorPlan.fbsPath, (File file) async {
        floorPlan.imageFile = file;
        floorPlan.imageLoaded = true;
      }, true);
      return floorPlan;
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

  Floor(this.fsPath, this.title, this.floorPlan) {
    this.fsPath = fsPath;
    print(fsPath);
  }
}

class LibraryInfo {
  String fsPath;
  Map<String, Floor> floors;

  static Future<Map<String, Floor>> getFloors(String fsLibraryPath) async {
    print("Getting floor information from firebase for $fsLibraryPath");
    Map<String, Floor> floors;
    floors = await Firestore.instance
        .collection(fsLibraryPath + '/floors')
        .snapshots()
        .first
        .then((snapshot) async {
      floors = {};

      int numFLoors = snapshot.documents.length;
      print("$numFLoors floor(s)");

      for (DocumentSnapshot floorDoc in snapshot.documents) {
        String floorID = floorDoc.documentID.toString();
        String floorTitle = floorDoc['title'].toString();

        print("Getting info for floor [$floorID] $floorTitle");

        // double floorPlanImageWidth = floorDoc['floor_plan_image_width'].toDouble();
        // double floorPlanImageHeight = floorDoc['floor_plan_image_height'].toDouble();

        double floorPlanImageWidth = 725.0;
        double floorPlanImageHeight = 2000.0;


        String fsFloorPath = fsLibraryPath + '/floors/' + floorID;
        Floor floor = Floor(
          fsFloorPath,
          floorTitle,
          FloorPlan(fbsPath: fsFloorPath + '/floor_plan.png', imageSize: Size(floorPlanImageWidth,floorPlanImageHeight))
        );
        await floor.init();
        floors.putIfAbsent(floorID, () => floor);
      }

      print("Floor information successfully retrieved");
      return floors;
    });
    return floors;
  }

  LibraryInfo({this.fsPath});
}
