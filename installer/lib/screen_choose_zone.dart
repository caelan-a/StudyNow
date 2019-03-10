import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as imageutil;

const double DIST_TO_DELETE =
    20.0; // pixel distance from touch when a marker should be deleted
const Offset TOUCH_SCREEN_OFFSET = Offset(20.0, 100.0);

class ChooseZoneScreen extends StatefulWidget {
  final String firebaseImagePath;
  ChooseZoneScreen({@required this.firebaseImagePath});

  @override
  _ChooseZoneScreenState createState() => _ChooseZoneScreenState();
}

class _ChooseZoneScreenState extends State<ChooseZoneScreen> {
  File _imageFile;

  //  Pixels
  int imageWidth;
  int imageHeight;

  bool _shouldShowDialog = true;
  bool _imageLoaded = false;

  PhotoViewController _photoViewController;

  List<Offset> zoneMarkers = [];

  @override
  void initState() {
    _photoViewController = PhotoViewController();

    //  Set state of this widget to update icons when user scales or translates image
    _photoViewController.outputStateStream.listen((onData) {
      setState(() {
        print("Set state");
      });
    });

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
      imageWidth = image.width;
      imageHeight = image.height;
      // print("w: $imageWidth, h: $imageHeight");

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

  //  Uses values from PhotoViewController to translate coordinates of screen touch to an offset in image space
  //  This offset describes the percentage of the way from the center to the right side of the image in the x
  //  and a percentage of the way from the center to the bottom side of the image in the y
  Offset convertToImageCoords(Offset touchPoint, PhotoViewController controller,
      int imageWidth, int imageHeight) {
    Size screenSize =
        MediaQuery.of(context).size; // pixel size of device screen
    Offset imageOffsetFromCenter = controller.position; // Offset from center
    double scale = controller.scale; // scale image has been dilated by

    Offset screenCenterPoint =
        Offset(screenSize.width / 2, screenSize.height / 2);

    Offset touchOffsetFromCenter = touchPoint - screenCenterPoint;
    Offset touchOffsetFromCenterOfImage =
        touchOffsetFromCenter - imageOffsetFromCenter;

    double xPercentageFromCenter =
        touchOffsetFromCenterOfImage.dx / scale / (imageWidth / 2.0);
    double yPercentageFromCenter =
        touchOffsetFromCenterOfImage.dy / scale / (imageHeight / 2.0);

    print("\nxPerc: $xPercentageFromCenter\nyPerc: $yPercentageFromCenter");

    return Offset(xPercentageFromCenter, yPercentageFromCenter);
  }

  //  Uses values from PhotoViewController to translate coordinates of image space to screen coords
  //  Inverse function of convertToImageCoords
  Offset convertToScreenCoords(Offset centerOffset,
      PhotoViewController controller, int imageWidth, int imageHeight) {
    Size screenSize =
        MediaQuery.of(context).size; // pixel size of device screen
    Offset screenCenterPoint =
        Offset(screenSize.width / 2, screenSize.height / 2);
    Offset imageOffsetFromCenter = controller.position; // Offset from center

    double x = screenCenterPoint.dx + centerOffset.dx * (controller.scale * imageWidth / 2.0);
    x += (imageOffsetFromCenter.dx);

    double y = screenCenterPoint.dy + (controller.scale * (centerOffset.dy * (imageHeight/ 2.0)));
    y += ( controller.scale*imageOffsetFromCenter.dy);

    print("\nx: $x\ny: $y\nscale: ${controller.scale}");
    print("imageOffset: $imageOffsetFromCenter");
    Offset screenCoords = Offset(x, y);
    return screenCoords;
  }

  void onTouch(TapUpDetails details) async {
    Offset touchPoint = details.globalPosition; // Offset from top right corner

    zoneMarkers = [];
    zoneMarkers.add(convertToImageCoords(touchPoint, _photoViewController, imageWidth, imageHeight));
    setState(() {});
  }

  //  centerOffset is percentage of the way to each end from center of image
  Widget _buildMarker(Offset centerOffset) {
    Offset screenCoords = convertToScreenCoords(
        centerOffset, _photoViewController, imageWidth, imageHeight);

    // print("\nImageCoords: $centerOffset\nScreenCoords: $screenCoords");
    return Positioned(
      left: screenCoords.dx,
      top: screenCoords.dy,
      child: Icon(Icons.crop_square),
    );
  }

  void refresh() {
    setState(() {
      zoneMarkers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    //  Populate stack to allow overlaying of location icons
    List<Widget> stackChildren = [];
    if (_imageLoaded) {
      stackChildren.add(new Container(
          child: new PhotoView(
        controller: _photoViewController,
        backgroundDecoration: BoxDecoration(color: Colors.white),
        imageProvider: FileImage(_imageFile),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: 4.0,
      )));

      stackChildren
          .addAll(zoneMarkers.map((Offset o) => _buildMarker(o)).toList());
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
                onPressed: () {
                  refresh();
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
                  onTouch(detail);
                },
                child: Stack(children: stackChildren),
              ));
  }
}
