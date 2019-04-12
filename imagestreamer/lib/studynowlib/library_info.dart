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
  String cameraZoneFsID;
  String title;

  int chairs_present;
  int people_present;

  Offset markerPosition;
  double markerScale;

  CameraZone({this.cameraZoneFsID, this.title});
}

class FloorPlan {
  bool imageLoaded = false;
  String downloadUrl; // FirebaseStorage floorplan path
  File imageFile;
  Size imageSize;

  FloorPlan({this.downloadUrl, this.imageSize});
}

class Floor {
  String libraryID;
  String floorFsID;
  String floorID; // firebase collection name of floor
  String title; // User friendly string

  FloorPlan floorPlan;

  Map<String, CameraZone> cameraZones;

  List<String> getCameraZoneFsIDs() {
    if (cameraZones != null) {
      return cameraZones.values
          .map((CameraZone cameraZone) => cameraZone.cameraZoneFsID)
          .toList();
    } else {
      return [];
    }
  }

  Future<FloorPlan> getFloorPlan() async {
    if (!floorPlan.imageLoaded) {
      await Database.downloadFile(floorPlan.downloadUrl, (File file) async {
        floorPlan.imageFile = file;
        floorPlan.imageLoaded = true;
      }, floorFsID + ".png", true);
      return floorPlan;
    } else {
      return floorPlan;
    }
  }

  Future<bool> init() {
    return Firestore.instance
        .collection('camera_zones')
        .where('library', isEqualTo: libraryID)
        .where('floor', isEqualTo: floorID)
        .snapshots()
        .first
        .then((snapshot) async {
      cameraZones = {};

      int numCameraZones = snapshot.documents.length;
      print("$numCameraZones camera zones in " + libraryID + '/' + floorID);

      for (DocumentSnapshot cameraZoneDoc in snapshot.documents) {
        String cameraZoneFsID = cameraZoneDoc.documentID;
        String cameraZoneTitle = cameraZoneDoc['title'];
        String cameraZoneId = cameraZoneDoc['id'];
        cameraZones.putIfAbsent(cameraZoneId,
            () => CameraZone(cameraZoneFsID: cameraZoneFsID, title: cameraZoneTitle));
      }
    });
  }

  Floor({this.libraryID, this.floorID, this.title, this.floorPlan, this.floorFsID,});
}

class LibraryInfo {
  String libraryID;
  Map<String, Floor> floors;

  static Future<Map<String, Floor>> getFloors(String libraryID) async {
    print("Getting floor information from firebase for $libraryID");
    Map<String, Floor> floors;
    floors = await Firestore.instance
        .collection('floors')
        .where('library', isEqualTo: libraryID)
        .snapshots()
        .first
        .then((snapshot) async {
      floors = {};

      int numFLoors = snapshot.documents.length;
      print("$numFLoors floor(s)");

      for (DocumentSnapshot floorDoc in snapshot.documents) {
        String floorFsID = floorDoc.documentID.toString();
        String floorID = floorDoc['id'].toString();
        String floorTitle = floorDoc['title'].toString();
        String floorPlanUrl = floorDoc['floor_plan_image_url'].toString();

        print("Getting info for floor [$floorFsID] $floorTitle");

        int floorPlanImageHeight = 2000;
        int floorPlanImageWidth = 968;

        if (floorDoc['floor_plan_image_width'] != null &&
            floorDoc['floor_plan_image_height'] != null) {
          floorPlanImageWidth =
              int.parse(floorDoc['floor_plan_image_width'].toString());
          floorPlanImageHeight =
              int.parse(floorDoc['floor_plan_image_height'].toString());
        }

        print(floorPlanImageWidth);

        Floor floor = Floor(
          libraryID: libraryID,
          floorID: floorID,
          title: floorTitle,
          floorFsID: floorFsID,
            floorPlan: FloorPlan(
                downloadUrl: floorPlanUrl,
                imageSize: Size(floorPlanImageWidth.toDouble(),
                    floorPlanImageHeight.toDouble())),
            );
        await floor.init();
        floors.putIfAbsent(floorID, () => floor);
      }

      print("Floor information successfully retrieved");
      return floors;
    });
    return floors;
  }

  LibraryInfo({this.libraryID});
}
