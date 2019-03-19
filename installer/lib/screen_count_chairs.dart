import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'database.dart';
import 'package:installer/screen_choose_zone.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as imageutil;
import 'markable_map.dart';

const double DIST_TO_DELETE =
    20.0; // pixel distance from touch when a marker should be deleted
const Offset TOUCH_SCREEN_OFFSET = Offset(-20, -100.0);

class CountChairsScreen extends StatefulWidget {
  String firebaseImagePath;
  String firebaseFloorplanPath;

  Function(int) onComplete;
  Function(double, Offset) onChooseZoneComplete;

  CountChairsScreen(
      {this.firebaseImagePath,
      this.onComplete,
      this.firebaseFloorplanPath,
      this.onChooseZoneComplete});

  @override
  _CountChairsScreenState createState() => _CountChairsScreenState();
}

class _CountChairsScreenState extends State<CountChairsScreen> {
  bool _imageLoaded = false;
  bool _shouldShowDialog = true;

  File _imageFile;
  Size _imageSize;

  MarkableMapController _markableMapController;

  int _markerCount = 0;

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
      imageutil.Image image = imageutil.decodeJpg(imageBytes);
      print("width: ${image.width}");
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

  void refreshImage() {
    setState(() {
      _markerCount = 0;
      _imageLoaded = false;
    });
    downloadFile(widget.firebaseImagePath);
  }

  @override
  void initState() {
    _markableMapController = MarkableMapController(
        maxMarkerSize: 50.0,
        initialMarkerScale: 1.0,
        currentWidgetBuilder: (size, position) => Positioned(
            left: position.dx - size / 2.0,
            top: position.dy - size / 2.0,
            child: Image.asset(
              'assets/chair_icon.png',
              width: size,
              height: size,
            )));

    downloadFile(widget.firebaseImagePath);
    print(widget.firebaseImagePath);
    super.initState();
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
            "Pan around the image and mark all chairs ",
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

  Widget _buildCountWidget() {
    return Positioned(
      width: MediaQuery.of(context).size.width / 8,
      top: 30.0,
      left: MediaQuery.of(context).size.width / 2.0 -
          MediaQuery.of(context).size.width / 8 / 2.0,
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(150),
            borderRadius: BorderRadius.circular(20.0)),
        alignment: Alignment.center,
        height: 30.0,
        child: Text(
          "${_markerCount}",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          elevation: 10.0,
          icon: const Icon(Icons.arrow_forward),
          label: const Text(
            'Next',
            style: TextStyle(fontSize: 16.0),
          ),
          onPressed: () {
            widget.onComplete(_markableMapController.markerCount());
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChooseZoneScreen(
                    firebaseImagePath: widget.firebaseFloorplanPath,
                    onComplete: widget.onChooseZoneComplete)));
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
                  _markableMapController.reset();
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
            : Stack(children: <Widget>[
                MarkableMap(
                  onMarkersChanged: (markerCount) =>
                      setState(() => _markerCount = markerCount),
                  editable: true,
                  controller: _markableMapController,
                  screenSize: MediaQuery.of(context).size,
                  imageSize: _imageSize,
                  imageFile: _imageFile,
                ),
                _buildCountWidget(),
              ]));
  }
}
