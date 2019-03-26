import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as imageutil;
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'studynowlib/database.dart';
import 'studynowlib/markable_map.dart';
import 'studynowlib/library_info.dart';
import 'studynowlib/widget_percentage_indicator.dart';

import 'package:flutter/foundation.dart';

class MapScreen extends StatefulWidget {
  final String libraryCollectionPath;
  final String libraryTitle;
  final String initialFloorID;
  final String initialFSFloorPath;

  MapScreen(
      {@required this.libraryCollectionPath,
      this.libraryTitle = "Library",
      this.initialFloorID,
      this.initialFSFloorPath});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showMap = false;
  LibraryInfo _libraryInfo;
  String _currentFloorID;
  String _fsCurrentFloorPath;
  MarkableMapController _markableMapController;

  void showFloor(String floorID) async {
    _showMap = false;
    _currentFloorID = floorID;
    _fsCurrentFloorPath = _libraryInfo.floors[_currentFloorID].fsPath;
    _libraryInfo.floors[_currentFloorID].floorPlan =
        await _libraryInfo.floors[_currentFloorID].getFloorPlan();
    print("IMAGE LOADED:" +
        _libraryInfo.floors[_currentFloorID].floorPlan.imageLoaded.toString());
    setState(() {
      print("Show map");
      _markableMapController = MarkableMapController(
          initialMapScale: 0.45,
          minMapScale: 0.45,
          maxMapScale: 0.5,
          cameraZoneFSPaths:
              _libraryInfo.floors[_currentFloorID].getCameraZoneFSPaths());

      _showMap = true;
      print("SHOW MAP NOW");
    });
  }

  void initLibrary() async {
    _libraryInfo = LibraryInfo(fsPath: widget.libraryCollectionPath);
    _libraryInfo.floors =
        await LibraryInfo.getFloors(widget.libraryCollectionPath);
    showFloor(widget.initialFloorID);
  }

  @override
  void initState() {
    _fsCurrentFloorPath = widget.initialFSFloorPath;
    initLibrary();
    super.initState();
  }

  Widget _buildStreamPercentageIndicator(String fsFloorPath) {
    return StreamBuilder(
        stream: Firestore.instance.document(fsFloorPath).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LinearPercentIndicator(
              width: 200.0,
              percent: 0.0,
            );
          } else {
            var data = snapshot.data;
            int peoplePresent = data['people_present'];
            int chairsPresent = data['chairs_present'];
            int percentageFull = 100 * peoplePresent ~/ chairsPresent;
            return LinearPercentIndicator(
              width: 200.0,
              progressColor: PercentageIndicator.getColor(percentageFull),
              percent: percentageFull / 100.0,
            );
          }
        });
  }

  void _select(String floorID) {
    setState(() {
      showFloor(floorID);
      print("Current floor: $_currentFloorID");
    });
  }

  Widget _buildFloorsMenu() {
    return PopupMenuButton<String>(
      offset: Offset(0.0, -MediaQuery.of(context).size.height / 5.0),
      icon: Icon(Icons.clear_all),
      initialValue: _currentFloorID,
      onCanceled: () => print("Tapped off menu"),
      onSelected: _select,
      itemBuilder: (BuildContext context) {
        return _libraryInfo.floors.values.map((floor) {
          return PopupMenuItem<String>(
            enabled: true,
            value: floor.floorID,
            child: Text(floor.title),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Container(
              padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
              height: 50.0,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(_showMap ? widget.libraryTitle : "",
                          style: TextStyle(
                              fontSize: 14.0, fontWeight: FontWeight.bold)),
                      Padding(
                        padding: EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
                      ),
                      Text(
                          _showMap
                              ? _libraryInfo.floors[_currentFloorID].title
                              : "",
                          style: TextStyle(
                            fontSize: 14.0,
                          ))
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(3.0),
                  ),
                  _showMap
                      ? _buildStreamPercentageIndicator(
                          _libraryInfo.floors[_currentFloorID].fsPath)
                      : LinearPercentIndicator(
                          width: 200.0,
                          percent: 0.0,
                        ),
                ],
              ),
            ),
            _showMap
                ? _buildFloorsMenu()
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
                controller: _markableMapController,
                imageFile:
                    _libraryInfo.floors[_currentFloorID].floorPlan.imageFile,
                imageSize:
                    _libraryInfo.floors[_currentFloorID].floorPlan.imageSize,
                editable: false,
                screenSize: MediaQuery.of(context).size,
              )
            : CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
      ),
    );
  }
}
