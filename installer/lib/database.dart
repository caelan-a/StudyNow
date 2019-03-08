import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  static Future<void> setCameraZoneInformation(
      String cameraPath, int chairsPresent) async {
    Firestore.instance
        .document(cameraPath)
        .setData({"chairs_present": chairsPresent}, merge: true);
  }
}
