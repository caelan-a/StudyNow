import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';

const double DIST_TO_DELETE =
    20.0; // pixel distance from touch when a marker should be deleted
const Offset TOUCH_SCREEN_OFFSET = Offset(-20, -100.0);

class ChooseZoneScreen extends StatefulWidget {
  final String firebaseImagePath;
  ChooseZoneScreen({@required this.firebaseImagePath});

  @override
  _ChooseZoneScreenState createState() => _ChooseZoneScreenState();
}

class _ChooseZoneScreenState extends State<ChooseZoneScreen> {
  File _imageFile;
  bool _shouldShowDialog = true;
  bool _imageLoaded = false;

  @override
  void initState() {
    downloadFile(widget.firebaseImagePath);
    super.initState();
  }

  Future<File> downloadFile(String firebasePath) async {
    String fileName = firebasePath.split('/').last;

    print("Downloading image: $fileName from FirebaseStorage..");
    Directory tempDir = Directory.systemTemp;
    final File file = File('${tempDir.path}/$fileName');

    print(fileName);

    final StorageReference ref =
        FirebaseStorage.instance.ref().child(firebasePath);
    final StorageFileDownloadTask downloadTask = ref.writeToFile(file);

    downloadTask.future.then((snapshot) {
      setState(() {
        _imageFile = file;
        _imageLoaded = true;
        if (_shouldShowDialog) {
          showInstructionDialog();
          _shouldShowDialog = false;
        }
      });
    });

    return file;
  }

  void showInstructionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 00.0),
          titlePadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          title: Text(
            "Create Zone",
            textAlign: TextAlign.center,
          ),
          content: Text(
            "Mark points on the map to show what area the camera covers",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            FlatButton(
              child: new Text("Ok"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];

    if (_imageLoaded) {
      stackChildren.add(new Container(
          child: new PhotoView(
            backgroundDecoration: BoxDecoration(color: Colors.white),
        imageProvider: FileImage(_imageFile),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: 4.0,
      )));
    }

    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          elevation: 10.0,
          icon: const Icon(Icons.check),
          label: const Text(
            'Done',
            style: TextStyle(fontSize: 16.0),
          ),
          onPressed: () {},
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          notchMargin: 4.0,
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                child: Text(
                  "",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 20.0),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {},
              )
            ],
          ),
        ),
        body: !_imageLoaded
            ? Center(
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
              ))
            : GestureDetector(
                onTapUp: (detail) {},
                child: Stack(children: stackChildren),
              ));
  }
}
