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
  Using photo_view creates a mapo that user can place markers on which move around 
*/
class MarkableMap extends StatefulWidget {
  bool editable;
  Icon marker;

  MarkableMap(
      {Key key,
      this.editable = false,
      this.marker = const Icon(Icons.crop_square)})
      : super(key: key);

  @override
  _MarkableMapState createState() => _MarkableMapState();
}

class _MarkableMapState extends State<MarkableMap> {
  PhotoViewController _photoViewController;

  int _imageWidth; // pixels
  int _imageHeight; // pixels

  @override
  void initState() {
    _photoViewController = PhotoViewController();
    
    //  Set state of this widget to update icons when user scales or translates image
    _photoViewController.outputStateStream.listen((onData) {
      setState(() {
        print("Set state");
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return null;
  }
}
