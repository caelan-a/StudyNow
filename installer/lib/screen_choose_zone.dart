import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as imageutil;
import 'pulsating_marker.dart';
import 'markable_map.dart';
// import 'bouncing_icon.dart';

// /*
// TO IMPLEMENT
// 1. Animating marker to shrink, move then appear at next point and expand
// 2. Add slider in to set size of marker
// 3. Fix going back and nested navigation
// */


class ChooseZoneScreen extends StatefulWidget {
  final String firebaseImagePath;
  Function(double, Offset) onComplete;

  ChooseZoneScreen({@required this.firebaseImagePath, this.onComplete});

  @override
  _ChooseZoneScreenState createState() => _ChooseZoneScreenState();
}

class _ChooseZoneScreenState extends State<ChooseZoneScreen> {
  bool _shouldShowDialog = true;
  bool _imageLoaded = false;

  Size _imageSize;
  File _imageFile;

  MarkableMapController markableMapController;

  @override
  void initState() {
    markableMapController = MarkableMapController(
        maxMarkerCount: 1,
        maxMarkerSize: 150.0,
        currentWidgetBuilder: (size, position) => PulsatingMarker(
              screenPosition: position,
              radius: size,
            ));
        // currentWidgetBuilder:(size, position) => DropPin(size, position));

    downloadFile(widget.firebaseImagePath);
    super.initState();
  }

  //  Download file from firebase and store locally
  Future<File> downloadFile(String firebasePath) async {
    String fileName = firebasePath.split('/').last;

    print("Downloading image: $fileName from FirebaseStorage..");
    Directory tempDir = Directory.systemTemp;
    final File file = File('${tempDir.path}/$fileName');

    print(fileName);

    final StorageReference ref =
        FirebaseStorage.instance.ref().child(firebasePath);
    final StorageFileDownloadTask downloadTask = ref.writeToFile(file);

    downloadTask.future.then((snapshot) async {
      //  Get width and height data from image
      List<int> imageBytes = await file.readAsBytes();
      imageutil.Image image = imageutil.decodePng(imageBytes);
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

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
            "Please mark points on the map to show what area the camera covers",
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

  void refresh() {
    markableMapController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          elevation: 10.0,
          icon: const Icon(Icons.check),
          label: const Text(
            'Done',
            style: TextStyle(fontSize: 16.0),
          ),
          onPressed: () {
            // if (zoneMarkers.length < 1) {
            //   //  No marker placed
            //   showInstructionDialog();
            // } else {
            //   widget.onComplete(_sizeSliderValue, zoneMarkers[0]);
            // }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          notchMargin: 4.0,
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  refresh();
                },
              ),
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
            : MarkableMap(
                controller: markableMapController,
                screenSize: MediaQuery.of(context).size,
                imageFile: _imageFile,
                imageSize: _imageSize,
                editable: true,
                sizeableMarkers: true,
              ));
  }
}
