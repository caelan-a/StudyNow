import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  static Future<void> setCameraZoneInformation(
      String cameraPath,
      int chairsPresent,
      double markerSize,
      double markerLocationX,
      double markerLocationY) async {
    Firestore.instance.document(cameraPath).setData({
      "chairs_present": chairsPresent,
      "markerLocationX": markerLocationX,
      "markerLocationY": markerLocationY
    }, merge: true);
  }
}
