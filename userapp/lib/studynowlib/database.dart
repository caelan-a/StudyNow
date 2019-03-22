import 'package:flutter/material.dart';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as imageutil;

class Database {
  //  Download file from firebase and store locally or retrieve local if already present
  static Future<void> downloadFile(
      String fbsPath, Function(File) onComplete) async {
    Directory tempDir = Directory.systemTemp;
    String localPath = '${tempDir.path} $fbsPath';
    final File file = File(localPath);

    if (await file.exists()) {
      print("$localPath exists\nRetrieving locally..");
      return onComplete(file);
    } else {
      print("$localPath does not exists\nDownloading from Firebase Storage..");
      final StorageReference ref =
          FirebaseStorage.instance.ref().child(fbsPath);
      final StorageFileDownloadTask downloadTask = ref.writeToFile(file);
      downloadTask.future.then((snapshot) {
        print("Downloaded successfully");
        return onComplete(file);
      });
    }
  }
}
