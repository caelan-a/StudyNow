import 'package:flutter/material.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';

/*
  Using photo_view creates a mapo that user can place markers on which move around 
*/

class Marker {
  Widget Function(double, Offset)
      widgetBuilder; // function to build child widget
  Offset positionOnImage;
  double scale;

  Marker(this.widgetBuilder, this.positionOnImage, this.scale);
}

class MarkableMapController {
  // Screen pixel radius within which a touch will lead to marker being deleted
  int deleteRadius;
  double maxMarkerSize;
  double currentMarkerScale;
  List<Marker> markers;
  Widget Function(double, Offset) currentWidgetBuilder;

  State<MarkableMap> state;

  MarkableMapController({
    this.currentMarkerScale = 0.25,
    this.deleteRadius = 20,
    this.maxMarkerSize = 100.0,
    this.currentWidgetBuilder,
  }) {
    if (currentWidgetBuilder == null) {
      currentWidgetBuilder = (double size, Offset position) => Positioned(
            left: position.dx,
            top: position.dy,
            width: size,
            height: size,
            child: Icon(Icons.crop_square),
          );
    }
    markers = [];
  }

  int markerCount() {
    return markers.length;
  }

  void reset() {
    state.setState(() {
      currentMarkerScale = 0.25;
      markers = [];
    });
  }
}

class MarkableMap extends StatefulWidget {
  final bool editable; //  Readonly or can users place markers
  final bool sizeableMarkers; // Able to adjust size of markers
  final double appBarHeight; // Used to get correct center of screen

  final File imageFile;
  final Size imageSize;
  final Size screenSize;

  MarkableMapController controller;

  MarkableMap(
      {Key key,
      @required this.imageFile,
      @required this.imageSize,
      @required this.screenSize,
      this.controller,
      this.sizeableMarkers = false,
      this.editable = false,
      this.appBarHeight = 0.0})
      : super(key: key) {
    if (controller == null) {
      controller = MarkableMapController();
    }
  }

  @override
  _MarkableMapState createState() {
    controller.state = _MarkableMapState();
    return controller.state;
  }
}

class _MarkableMapState extends State<MarkableMap> {
  PhotoViewController _photoViewController;

  double _scale; // current scaling of image from PhotoView
  Offset _imageTranslation; // Translation of image | units: Screen pixels
  Offset _screenCenter; // Center point of screen | units: Screen pixels

  @override
  void initState() {
    _screenCenter = Offset(widget.screenSize.width / 2.0,
        widget.screenSize.height / 2.0 - widget.appBarHeight);

    _photoViewController = PhotoViewController();

    _scale = _photoViewController.initial.scale;
    _imageTranslation = _photoViewController.initial.position;

    //  Set state of this widget to update icons when user scales or translates image
    _photoViewController.outputStateStream.listen((onData) {
      setState(() {
        _scale = onData.scale;
        _imageTranslation = onData.position;
      });
    });
    super.initState();
  }

  //  Uses values from PhotoViewController to translate coordinates of screen touch to an offset in image space
  //  This offset describes the percentage of the way from the center to the right side of the image in the x
  //  and a percentage of the way from the center to the bottom side of the image in the y
  Offset convertToImageCoords(Offset touchPoint) {
    Offset touchOffsetFromCenter = touchPoint - _screenCenter;
    Offset touchOffsetFromCenterOfImage =
        touchOffsetFromCenter - _imageTranslation;

    double xPercentageFromCenter = touchOffsetFromCenterOfImage.dx /
        _scale /
        (widget.imageSize.width / 2.0);
    double yPercentageFromCenter = touchOffsetFromCenterOfImage.dy /
        _scale /
        (widget.imageSize.height / 2.0);

    // print("\nxPerc: $xPercentageFromCenter\nyPerc: $yPercentageFromCenter");

    return Offset(xPercentageFromCenter, yPercentageFromCenter);
  }

  //  Uses values from PhotoViewController to translate coordinates of image space to screen coords
  //  Inverse function of convertToImageCoords
  Offset convertToScreenCoords(Offset positionOnImage) {
    double x = _screenCenter.dx +
        _scale * (positionOnImage.dx * widget.imageSize.width / 2.0) +
        _imageTranslation.dx;
    double y = _screenCenter.dy +
        _scale * (positionOnImage.dy * widget.imageSize.height / 2.0) +
        _imageTranslation.dy;

    // print("\nx: $x\ny: $y\nscale: ${scale}");
    return Offset(x, y);
  }

  void addMarker(Offset touchPosition, Function(double, Offset) widgetBuilder,
      double scale) {
    Offset positionOnImage = convertToImageCoords(touchPosition);

    setState(() {
      widget.controller.markers
          .add(Marker(widgetBuilder, positionOnImage, scale));
    });
  }

  Widget _buildMarker(Marker marker) {
    Offset screenCoords = convertToScreenCoords(marker.positionOnImage);
    double size = widget.controller.maxMarkerSize * marker.scale;

    return marker.widgetBuilder(size, screenCoords);
  }

  void _onSliderValueChanged(double value) {
    setState(() {
      widget.controller.currentMarkerScale = value;

      //  Change scale of most recent marker
      if (widget.controller.markers.isEmpty) {
        widget.controller.markers.last.scale =
            widget.controller.currentMarkerScale;
      }
    });
  }

  bool _highlightSlider = false;
  Widget _buildMarkerSizeSlider() {
    return Positioned(
      width: MediaQuery.of(context).size.width / 1.5,
      bottom: 30.0,
      left: MediaQuery.of(context).size.width / 2.0 -
          MediaQuery.of(context).size.width / 1.5 / 2.0,
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context)
                .primaryColor
                .withAlpha(_highlightSlider ? 40 : 30),
            borderRadius: BorderRadius.circular(20.0)),
        alignment: Alignment.center,
        height: 30.0,
        child: Slider(
          label: "Area Size",
          min: 0.1,
          value: widget.controller.currentMarkerScale,
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
    );
  }

  void onTap(TapUpDetails details) {
    addMarker(details.globalPosition, widget.controller.currentWidgetBuilder,
        widget.controller.currentMarkerScale);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    PhotoView image = PhotoView(
      controller: _photoViewController,
      backgroundDecoration: BoxDecoration(color: Colors.white),
      imageProvider: FileImage(widget.imageFile),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: 4.0,
    );

    List<Widget> markerWidgets = widget.controller.markers
        .map((Marker marker) => _buildMarker(marker))
        .toList();

    children.add(image);
    children.addAll(markerWidgets);

    if (widget.editable && widget.sizeableMarkers) {
      children.add(_buildMarkerSizeSlider());
    }

    return widget.editable
        ? GestureDetector(
            onTapUp: (detail) {
              onTap(detail);
            },
            child: Stack(
              children: children,
            ))
        : Stack(
            children: children,
          );
  }
}
