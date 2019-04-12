import 'package:flutter/material.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';

import 'widget_percentage_indicator.dart';
import 'pulsating_marker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  double maxMarkerCount;
  double initialMarkerScale;
  double currentMarkerScale;
  List<Marker> markers;
  Widget Function(double, Offset) currentWidgetBuilder;

  State<MarkableMap> state;

  double initialMapScale;
  double minMapScale;
  double maxMapScale;

  List<String> cameraZoneFsIDs;

  MarkableMapController(
      {this.initialMarkerScale = 0.25,
      this.deleteRadius = 20,
      this.maxMarkerSize = 100.0,
      this.currentWidgetBuilder,
      this.maxMarkerCount,
      this.initialMapScale = 1.0,
      this.minMapScale = 0.2,
      this.maxMapScale = 1.5,
      this.cameraZoneFsIDs}) {
    if (currentWidgetBuilder == null) {
      currentWidgetBuilder = (double size, Offset position) => Positioned(
            left: position.dx,
            top: position.dy,
            width: size,
            height: size,
            child: Icon(Icons.crop_square),
          );
    }
    currentMarkerScale = initialMarkerScale;
    markers = [];
  }

  int markerCount() {
    return markers.length;
  }

  void reset() {
    state.setState(() {
      currentMarkerScale = initialMarkerScale;
      markers = [];
      // currentWidgetBuilder.dispose();
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

  final Function(int markerCount) onMarkersChanged;

  MarkableMapController controller;

  MarkableMap(
      {Key key,
      @required this.imageFile,
      @required this.imageSize,
      @required this.screenSize,
      this.controller,
      this.sizeableMarkers = false,
      this.editable = false,
      this.appBarHeight = 0.0,
      this.onMarkersChanged})
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

    _scale = widget.controller.initialMapScale;
    _imageTranslation = _photoViewController.initial.position ?? Offset(0, 0);

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
      if (widget.controller.maxMarkerCount == null ||
          widget.controller.markerCount() < widget.controller.maxMarkerCount) {
        widget.controller.markers
            .add(Marker(widgetBuilder, positionOnImage, scale));
      } else {
        widget.controller.markers.last =
            Marker(widgetBuilder, positionOnImage, scale);
      }
    });
  }

  Widget _buildMarker(Marker marker) {
    Offset screenCoords = convertToScreenCoords(marker.positionOnImage);
    double size = _scale * widget.controller.maxMarkerSize * marker.scale;
    print("Size: $size");
    print("Screen Position: $screenCoords");
    // print(": $size");
    return marker.widgetBuilder(size, screenCoords);
  }

  Widget _buildStreamMarker(String fsCameraZonePath) {
    return StreamBuilder(
        stream: Firestore.instance.document(fsCameraZonePath).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          } else {
            var data = snapshot.data;
            double markerX = data['marker_position_on_image_x'].toDouble();
            double markerY = data['marker_position_on_image_y'].toDouble();
            double markerScale = data['marker_scale'].toDouble();
            int chairsPresent = data['chairs_present'];
            int peoplePresent = data['people_present'];
            int percentageFull = 100 * peoplePresent ~/ chairsPresent;

            print("$fsCameraZonePath");
            Color color = PercentageIndicator.getColor(percentageFull);

            Offset screenCoords =
                convertToScreenCoords(Offset(markerX, markerY));
            print(screenCoords);
            double size =
                _scale * widget.controller.maxMarkerSize * markerScale;
            print(size);

            // Text percentageTextWidget = Text("$percentageFull%", style: TextStyle(color: Colors.white),),

            return Stack(children: <Widget>[
              Positioned(
                left: screenCoords.dx,
                top: screenCoords.dy,
                child: PulsatingMarker(
                  color: color,
                  maxOpacity: 0.25,
                  screenPosition: Offset(0, 0),
                  radius: size,
                ),
              ),
              Positioned(
                  left: screenCoords.dx - (50.0 / 2.0) * _scale,
                  top: screenCoords.dy - (50.0 / 2.0) * _scale,
                  child: Container(
                    width: 50.0*_scale,
                    height: 50.0*_scale,
                    child: Center(
                      child: Text(
                        "$percentageFull%",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 24.0 * _scale),
                      ),
                    ),
                  )

                  // PercentageIndicator(
                  //   showPercentage: false,
                  //   fontSize: 16.0 * _scale,
                  //   textColor: Colors.white,
                  //   inactiveColor: Colors.white,
                  //   radius: _scale * indicatorRadius,
                  //   lineWidth: _scale * indicatorLineWidth,
                  //   totalPeople: peoplePresent,
                  //   totalSeats: chairsPresent,
                  // ),
                  ),
            ]);
          }
        });
  }

  void _onSliderValueChanged(double value) {
    setState(() {
      widget.controller.currentMarkerScale = value;

      //  Change scale of most recent marker
      if (widget.controller.markers.isNotEmpty) {
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
    if (!shouldDeleteMarkers(details)) {
      addMarker(details.globalPosition, widget.controller.currentWidgetBuilder,
          widget.controller.currentMarkerScale);
    }
    //  Run callback if
    if (widget.onMarkersChanged != null) {
      widget.onMarkersChanged(widget.controller.markerCount());
    }
  }

  bool shouldDeleteMarkers(TapUpDetails details) {
    Offset tapLocation = details.globalPosition;

    for (Marker marker in widget.controller.markers) {
      Offset markerScreenLocation =
          convertToScreenCoords(marker.positionOnImage);
      if ((markerScreenLocation - tapLocation).distance <
          widget.controller.deleteRadius) {
        widget.controller.markers.remove(marker);
        setState(() {});
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    PhotoView image = PhotoView(
      controller: _photoViewController,
      backgroundDecoration: BoxDecoration(color: Colors.white),
      imageProvider: FileImage(widget.imageFile),
      minScale: widget.controller.minMapScale,
      maxScale: widget.controller.maxMapScale,
      initialScale: widget.controller.initialMapScale,
    );

    List<Widget> markerWidgets = widget.controller.markers
        .map((Marker marker) => _buildMarker(marker))
        .toList();

    children.add(image);
    children.addAll(markerWidgets);

    if (widget.editable && widget.sizeableMarkers) {
      children.add(_buildMarkerSizeSlider());
    }

    //  Add any widgets from stream
    if (widget.controller.cameraZoneFsIDs != null) {
      List<Widget> streamMarkerWidgets = widget.controller.cameraZoneFsIDs
          .map(
              (String cameraZoneFsID) => _buildStreamMarker("camera_zones/" + cameraZoneFsID))
          .toList();
      children.addAll(streamMarkerWidgets);
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
