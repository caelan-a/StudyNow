import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ImageScreen extends StatefulWidget {
  String imageFileName;

  ImageScreen(this.imageFileName);

  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  bool _imageLoaded = false;
  File _remoteImage;

  Future<File> downloadFile(String fileName) async {
    print("Downloading image: $fileName from FirebaseStorage..");
    Directory tempDir = Directory.systemTemp;
    final File file = File('${tempDir.path}/$fileName');

    final StorageReference ref = FirebaseStorage.instance.ref().child(fileName);
    final StorageFileDownloadTask downloadTask = ref.writeToFile(file);

    downloadTask.future.then((snapshot) {
      setState(() {
        _remoteImage = file;
        _imageLoaded = true;
      });
    });

    return file;
  }

  @override
  void initState() {
    downloadFile(widget.imageFileName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return !_imageLoaded
        ? Scaffold(
            appBar: null,
            body: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Fetching image from camera\n\n",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 16.0),
                ),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
              ],
            )))
        : Image.file(_remoteImage, fit: BoxFit.fitHeight);
  }
}
