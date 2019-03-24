import 'package:flutter/material.dart';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as imageutil;

class Database {
  //  Download file from firebase and store locally or retrieve local if already present
  static Future<void> downloadFile(
      String fbsPath, Function(File) onComplete, bool checkLocal) async {
    Directory tempDir = Directory.systemTemp;
    List<String> fbsPath_split = fbsPath.split('/');

    String localPath = '${tempDir.path}/floor_plan.png';
    final File file = File(localPath);

    if (await file.exists() && checkLocal) {
      print("$localPath exists\nRetrieving locally..");
      return onComplete(file);
    } else {
      print("$localPath does not exists\nDownloading from Firebase Storage..");
      final StorageReference ref =
          FirebaseStorage.instance.ref().child(fbsPath);
      final StorageFileDownloadTask downloadTask = ref.writeToFile(file);
      return downloadTask.future.then((snapshot) {
        print("Downloaded successfully");
        return onComplete(file);
      });
    }
  }
}
