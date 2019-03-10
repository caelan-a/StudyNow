import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'database.dart';
import 'package:installer/screen_choose_zone.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

const double DIST_TO_DELETE =
    20.0; // pixel distance from touch when a marker should be deleted
const Offset TOUCH_SCREEN_OFFSET = Offset(-20, -100.0);

class CountChairsScreen extends StatefulWidget {
  String firebaseImagePath;
  String firebaseFloorplanPath;

  Function(int) onComplete;

  CountChairsScreen({this.firebaseImagePath, this.onComplete, this.firebaseFloorplanPath});

  @override
  _CountChairsScreenState createState() => _CountChairsScreenState();
}

class _CountChairsScreenState extends State<CountChairsScreen> {
  bool _imageLoaded = false;
  bool shouldShowDialog = true;
  File _imageFile;

  List<Offset> _chairMarkers;

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
        if (shouldShowDialog) {
          showInstructionDialog();
          shouldShowDialog = false;
        }
      });
    });

    return file;
  }

  void refreshImage() {
    setState(() {
      _chairMarkers = [];
      _imageLoaded = false;
    });
    downloadFile(widget.firebaseImagePath);
  }

  @override
  void initState() {
    _chairMarkers = [];
    downloadFile(widget.firebaseImagePath);
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

  void showInstructionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 00.0),
          titlePadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          title: Text(
            "Chairs Present",
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

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];

    if (_imageLoaded) {
      stackChildren.add(Image.file(_imageFile, fit: BoxFit.fitWidth));

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
      floatingActionButton: FloatingActionButton.extended(
        elevation: 10.0,
        icon: const Icon(Icons.arrow_forward),
        label: const Text(
          'Next',
          style: TextStyle(fontSize: 16.0),
        ),
        onPressed: () {
          widget.onComplete(_chairMarkers.length);
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => ChooseZoneScreen(firebaseImagePath: widget.firebaseFloorplanPath,)));
        },
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
