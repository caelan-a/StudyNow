import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as imageutil;

import 'studynowlib/database.dart';
import 'studynowlib/markable_map.dart';
import 'studynowlib/library_info.dart';
import 'studynowlib/widget_percentage_indicator.dart';

class MapScreen extends StatefulWidget {
  final String libraryCollectionPath;
  final String libraryTitle;
  final String initialFloorID;

  MapScreen(
      {@required this.libraryCollectionPath,
      this.libraryTitle = "Library",
      this.initialFloorID});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showMap = false;
  LibraryInfo _libraryInfo;
  String _currentFloorID;

  @override
  void initState() {
    _currentFloorID = widget.initialFloorID;
    _libraryInfo = LibraryInfo(fsPath: widget.libraryCollectionPath);
    _libraryInfo.init(widget.libraryCollectionPath).then((success) {
      setState(() {
        print(_libraryInfo.floors['mez'].title);
        _libraryInfo.floors[_currentFloorID].getFloorPlan().then((void result) {
          _showMap = true;
        });
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Floor currentFloor = _libraryInfo.floors[_currentFloorID];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).canvasColor,
        shape: CircleBorder(),
        elevation: 5.0,
        label: PercentageIndicator(
          totalPeople: 5,
          totalSeats: 14,
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
            Text(widget.libraryTitle,
                style: TextStyle(
                  fontSize: 14.0,
                )),
            Padding(
              padding: EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 0.0),
            ),
            Text(_libraryInfo.floors[_currentFloorID].title,
                style: TextStyle(
                  fontSize: 14.0,
                )),
            _showMap
                ? PopupMenuButton<String>(
                    offset:
                        Offset(0.0, -MediaQuery.of(context).size.height / 5.0),
                    icon: Icon(Icons.clear_all),
                    initialValue: _currentFloorID,
                    onCanceled: () => print("Tapped outside the menu"),
                    onSelected: (floorID) {
                      setState(() {
                        _currentFloorID = floorID;
                        print("Current floor: $_currentFloorID");
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return _libraryInfo.floors.values.map((floor) {
                        return PopupMenuItem<String>(
                          enabled: true,
                          value: floor.floorID,
                          child: Text(floor.title),
                        );
                      }).toList();
                    },
                  )
                : IconButton(
                    icon: Icon(Icons.clear_all),
                    onPressed: () {
                      // Navigator.pop(context);
                    },
                  ),
          ],
        ),
      ),
      body: Center(
        child: _showMap
            ? MarkableMap(
                imageFile: currentFloor.floorPlanImage,
                imageSize: currentFloor.floorPlanImageSize,
                editable: false,
                screenSize: MediaQuery.of(context).size,
              )
            : CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
      ),
    );
  }
}
