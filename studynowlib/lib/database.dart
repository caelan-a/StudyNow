import 'package:flutter/material.dart';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as imageutil;

class Database {
  //  Download file from firebase and store locally
  static Future<void> downloadFile(String firebasePath, String localPath,
      Function(dynamic) onDownloadComplete) async {
    String fileName = firebasePath.split('/').last;
    var floor = int.parse(firebasePath.split('/')[4]);

    print("looking for the firebase info $firebasePath on floor $floor");
    // print("Downloading image: $fileName from FirebaseStorage..");
    Directory tempDir = Directory.systemTemp;
    final File file = File('${tempDir.path}/' + localPath);

    // print(fileName);

    final StorageReference ref =
        FirebaseStorage.instance.ref().child(firebasePath);
    final StorageFileDownloadTask downloadTask = ref.writeToFile(file);

    downloadTask.future.then((snapshot) => onDownloadComplete(snapshot));
  }
}
