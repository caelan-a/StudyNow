import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:imagestreamer/struct_camera_zone.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _settingsChanged = false;

  TextEditingController _libraryController;
  TextEditingController _floorController;
  TextEditingController _cameraZoneController;
  TextEditingController _numCapturesPerIntervalController;
  TextEditingController _timeIntervalController;

  @override
  void initState() {
    _libraryController = TextEditingController(text: Main.cameraZone.libraryID);
    _floorController = TextEditingController(text: Main.cameraZone.floorID);
    _cameraZoneController =
        TextEditingController(text: Main.cameraZone.cameraZoneID);
    _cameraZoneController =
        TextEditingController(text: Main.cameraZone.cameraZoneID);
    _numCapturesPerIntervalController = TextEditingController(
        text: Main.cameraZone.numCapturesPerInterval.toString());
    _timeIntervalController =
        TextEditingController(text: Main.cameraZone.timeInterval.toString());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Settings"),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 0.0),
            child: Text(
              "Change which camera zone this image streamer belongs to",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16.0,
              ),
            ),
          ),
          Container(
              padding: EdgeInsets.fromLTRB(20.0, 20.0, 100.0, 0.0),
              child: TextField(
                style: TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  labelText: 'Library ID',
                ),
                controller: _libraryController,
                onChanged: (t) => print(t),
              )),
          Container(
              padding: EdgeInsets.fromLTRB(20.0, 20.0, 100.0, 0.0),
              child: TextField(
                style: TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  labelText: 'Floor ID',
                ),
                controller: _floorController,
                onChanged: (t) => print(t),
              )),
          Container(
              padding: EdgeInsets.fromLTRB(20.0, 20.0, 100.0, 0.0),
              child: TextField(
                style: TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  labelText: 'Camera Zone ID',
                ),
                controller: _cameraZoneController,
                onChanged: (t) => print(t),
              )),
          Container(
              padding: EdgeInsets.fromLTRB(20.0, 20.0, 100.0, 0.0),
              child: TextField(
                style: TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  labelText: 'Captures per interval',
                ),
                controller: _numCapturesPerIntervalController,
                onChanged: (t) => print(t),
              )),
          Container(
              padding: EdgeInsets.fromLTRB(20.0, 20.0, 100.0, 0.0),
              child: TextField(
                style: TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  labelText: 'Time interval (s)',
                ),
                controller: _timeIntervalController,
                onChanged: (t) => print(t),
              )),
          Container(
            padding: EdgeInsets.all(40.0),
            child: RaisedButton(
                child: Text(
                  'Set',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  _settingsChanged = true;
                  Main.cameraZone.setCameraZone(
                      _libraryController.text,
                      _floorController.text,
                      _cameraZoneController.text,
                      _numCapturesPerIntervalController.text,
                      _timeIntervalController.text);
                  Navigator.pop(context, _settingsChanged);
                },
                color: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }
}
