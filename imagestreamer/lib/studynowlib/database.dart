import 'package:flutter/material.dart';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as imageutil;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Database {
  static var httpClient = new HttpClient();
  static Future<File> _downloadFile(String url, File file) async {

    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);

    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<dynamic> downloadFile(String url, Function(File) onComplete,
      String fileName, bool checkLocal) async {
    Directory tempDir = await getTemporaryDirectory();
    String localPath = '${tempDir.path}/$fileName';
    final File file = File(localPath);

    if (await file.exists() && checkLocal) {
      print("$localPath exists\nRetrieving locally..");
      return onComplete(file);
    } else {
      print("$localPath does not exists\nDownloading from Firebase Storage..");

      return _downloadFile(url, file).then((file) {
        print("Downloaded successfully");
        return onComplete(file);
      });
    }
  }

  //  Download file from firebase and store locally or retrieve local if already present
  static Future<dynamic> downloadFBStorageFile(
      String fbsPath, Function(File) onComplete, bool checkLocal) async {
    Directory tempDir = await getTemporaryDirectory();
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
