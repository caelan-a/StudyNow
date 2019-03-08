import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

const double DIST_TO_DELETE =
    20.0; // pixel distance from touch when a marker should be deleted
const Offset TOUCH_SCREEN_OFFSET = Offset(-20, -100.0);

class ImageScreen extends StatefulWidget {
  String imageFileName;

  ImageScreen(this.imageFileName);

  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  bool _imageLoaded = false;
  bool shouldShowDialog = true;
  File _remoteImage;

  List<Offset> _chairMarkers;

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
        if (shouldShowDialog) {
          showInstructionDialog();
          shouldShowDialog = false;
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
            "Calibrate",
            textAlign: TextAlign.center,
          ),
          content: Text(
            "Mark all chairs with a tap and then press done",
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

  void refreshImage() {
    setState(() {
      _chairMarkers = [];
      _imageLoaded = false;
    });
    downloadFile(widget.imageFileName);
  }

  @override
  void initState() {
    _chairMarkers = [];
    downloadFile(widget.imageFileName);
    super.initState();
  }

  void addChairMarker(TapUpDetails details) {
    _chairMarkers.add(details.globalPosition
        .translate(TOUCH_SCREEN_OFFSET.dx, TOUCH_SCREEN_OFFSET.dy));
    setState(() {});
  }

  bool shouldDeleteMarkers(TapUpDetails details) {
    Offset tapLocation = details.globalPosition
        .translate(TOUCH_SCREEN_OFFSET.dx, TOUCH_SCREEN_OFFSET.dy);

    for (var marker in _chairMarkers) {
      if ((marker - tapLocation).distance < DIST_TO_DELETE) {
        _chairMarkers.remove(marker);
        setState(() {});
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];

    if (_imageLoaded) {
      stackChildren.add(Image.file(_remoteImage, fit: BoxFit.fitWidth));

      stackChildren.addAll(_chairMarkers
          .map(
            (Offset offset) => Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: Image.asset(
                    'assets/chair_icon.png',
                    width: 40.0,
                    height: 40.0,
                  ),
                ),
          )
          .toList());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibrate'),
        centerTitle: true,
        actions: <Widget>[
          // action button
          // IconButton(
          //   icon: Icon(Icons.refresh),
          //   onPressed: () {
          //     //
          //   },
          // ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 10.0,
        icon: const Icon(Icons.check),
        label: const Text('Done'),
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
                "${_chairMarkers.length}",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 20.0),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                refreshImage();
              },
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
              onTapUp: (detail) {
                if (!shouldDeleteMarkers(detail)) {
                  addChairMarker(detail);
                }
              },
              child: Stack(children: stackChildren),
            ),
    );
  }
}
