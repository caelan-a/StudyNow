import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  static Future<void> setCameraZoneInformation(
      String cameraPath,
      int chairsPresent,
      double markerScale,
      double markerLocationX,
      double markerLocationY) async {
    Firestore.instance.document(cameraPath).setData({
      "chairs_present": chairsPresent,
      "marker_scale": markerScale,
      "marker_position_on_image_x": markerLocationX,
      "marker_position_on_image_y": markerLocationY
    }, merge: true);
  }
}
