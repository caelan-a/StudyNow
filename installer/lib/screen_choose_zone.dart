import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'dart:math';
import 'database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as imageutil;

/*
TO IMPLEMENT
1. Animating marker to shrink, move then appear at next point and expand
2. Add slider in to set size of marker
3. Fix going back and nested navigation
*/

const int MAX_MARKER_SIZE = 650;

const double DIST_TO_DELETE =
    20.0; // pixel distance from touch when a marker should be deleted

class ChooseZoneScreen extends StatefulWidget {
  final String firebaseImagePath;
  ChooseZoneScreen({@required this.firebaseImagePath});

  @override
  _ChooseZoneScreenState createState() => _ChooseZoneScreenState();
}

class _ChooseZoneScreenState extends State<ChooseZoneScreen>
    with TickerProviderStateMixin {
  AnimationController _controller;

  File _imageFile;

  //  Pixels
  int imageWidth;
  int imageHeight;

  bool _shouldShowDialog = true;
  bool _imageLoaded = false;

  PhotoViewController _photoViewController;

  List<Offset> zoneMarkers = [];

  double _sizeSliderValue = 0.25;
  bool _highlightSlider = false;
  void _onSliderValueChanged(double value) {
    setState(() {
      _sizeSliderValue = value;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.repeat(
      period: Duration(seconds: 1),
    );
  }

  @override
  void initState() {
    _controller = new AnimationController(
      vsync: this,
    );
    _startAnimation();

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

    Offset screenCenterPoint = Offset(
        screenSize.width / 2, (screenSize.height / 2) - Main.appBarHeight);

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
    Offset screenCenterPoint = Offset(screenSize.width / 2,
        screenSize.height / 2); // Device pixels point of center
    Offset imageTranslation =
        controller.position; // Offset from center off image in photoview

    double x = screenCenterPoint.dx +
        controller.scale * (centerOffset.dx * imageWidth / 2.0) +
        imageTranslation.dx;
    double y = screenCenterPoint.dy +
        controller.scale * (centerOffset.dy * imageHeight / 2.0) +
        imageTranslation.dy;

    print("\nx: $x\ny: $y\nscale: ${controller.scale}");
    Offset screenCoords = Offset(x, y);
    return screenCoords;
  }

  void onTouch(TapUpDetails details) async {
    Offset touchPoint = details.globalPosition
        .translate(0.0, -Main.appBarHeight / 2); // Offset from top right corner

    zoneMarkers = [];
    zoneMarkers.add(convertToImageCoords(
        touchPoint, _photoViewController, imageWidth, imageHeight));
    setState(() {});
  }

  //  centerOffset is percentage of the way to each end from center of image
  Widget _buildMarker(Offset centerOffset) {
    Offset screenCoords = convertToScreenCoords(
        centerOffset, _photoViewController, imageWidth, imageHeight);

    double scale =
        _photoViewController.scale == null ? 0.27 : _photoViewController.scale;

    double size = 40* MAX_MARKER_SIZE * _sizeSliderValue;

    return CustomPaint(
      willChange: true,
      painter: new SpritePainter(
          _controller, Offset(screenCoords.dx, screenCoords.dy), size, scale),
      child: new SizedBox(

        width: size,
        height: 50.0,
      ),
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

      //  Add size slider
      stackChildren.add(
        Positioned(
          width: MediaQuery.of(context).size.width / 1.5,
          bottom: 30.0,
          left: MediaQuery.of(context).size.width / 2.0 -
              MediaQuery.of(context).size.width / 1.5 / 2.0,
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .primaryColor
                    .withAlpha(_highlightSlider ? 50 : 40),
                borderRadius: BorderRadius.circular(20.0)),
            alignment: Alignment.center,
            height: 30.0,
            child: Slider(
              label: "Area Size",
              value: _sizeSliderValue,
              onChanged: (value) => _onSliderValueChanged(value),
              onChangeStart: (value) {
                setState(() {
                  _highlightSlider = true;
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _highlightSlider = false;
                });
              },
            ),
          ),
        ),
      );

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
            : GestureDetector(
                onTapUp: (detail) {
                  onTouch(detail);
                },
                child: Stack(children: stackChildren),
              ));
  }
}

class SpritePainter extends CustomPainter {
  final Animation<double> _animation;
  final Offset offset;
  final width;
  final scale;

  SpritePainter(this._animation, this.offset, this.width, this.scale) : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 0.3);
    Color color = new Color.fromRGBO(0, 117, 151, opacity);

    double radius = scale*sqrt(width * value);

    final Paint paint = new Paint()..color = color;
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = new Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(SpritePainter oldDelegate) {
    return true;
  }
}
