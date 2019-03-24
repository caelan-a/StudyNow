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

  void showFloor(String floorID) {
    _showMap = false;
    _currentFloorID = floorID;
    _fsCurrentFloorPath = _libraryInfo.floors[_currentFloorID].fsPath;
    _libraryInfo.floors[_currentFloorID].getFloorPlan().then((void result) {
      setState(() {
        print("Show map");
        _markableMapController = MarkableMapController(
            initialMapScale: 0.4,
            minMapScale: 0.4,
            maxMapScale: 0.5,
            cameraZoneFSPaths:
                _libraryInfo.floors[_currentFloorID].getCameraZoneFSPaths());

        _showMap = true;
      });
    });
  }

  @override
  void initState() {
    _fsCurrentFloorPath = widget.initialFSFloorPath;
    _libraryInfo = LibraryInfo(fsPath: widget.libraryCollectionPath);
    _libraryInfo.init(widget.libraryCollectionPath).then((success) {
      showFloor(widget.initialFloorID);
    });

    super.initState();
  }

  Widget _buildStreamPercentageIndicator(String fsFloorPath) {
    return StreamBuilder(
        stream: Firestore.instance.document(fsFloorPath).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return PercentageIndicator(
              totalPeople: 0,
              totalSeats: 10000,
            );
          } else {
            var data = snapshot.data;
            int peoplePresent = data['people_present'];
            int chairsPresent = data['chairs_present'];

            return PercentageIndicator(
              totalPeople: peoplePresent,
              totalSeats: chairsPresent,
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).canvasColor,
        shape: CircleBorder(),
        elevation: 5.0,
        label: _buildStreamPercentageIndicator(_fsCurrentFloorPath),
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
            Text(_showMap ? widget.libraryTitle : "",
                style: TextStyle(
                  fontSize: 14.0,
                )),
            Padding(
              padding: EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 0.0),
            ),
            Text(_showMap ? _libraryInfo.floors[_currentFloorID].title : "",
                style: TextStyle(
                  fontSize: 14.0,
                )),
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
                imageFile: _libraryInfo.floors[_currentFloorID].floorPlanImage,
                imageSize:
                    _libraryInfo.floors[_currentFloorID].floorPlanImageSize,
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
