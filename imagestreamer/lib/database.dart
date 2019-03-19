import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class Database {
  static createCameraZoneInFirebase(
      String libraryID, String floorID, String cameraZoneID) {}

  static sendImages(List<File> imageFiles, String firebasePath) {
    for (var i = 0; i < imageFiles.length; i++) {
      File imageFile = imageFiles[i];
      final StorageReference firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child(firebasePath + "image_" + i.toString() + ".jpg");
      final StorageUploadTask task = firebaseStorageRef.putFile(imageFile);
    }
  }
}
