import 'package:flutter/material.dart';
import 'main.dart';
import 'screen_settings.dart';
import 'screen_stream_image.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(40.0),
            ),
            Text(
              "StudyNow",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 40.0,
                  fontWeight: FontWeight.normal),
            ),
            Text(
              "Image Streamer",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20.0,
                  fontWeight: FontWeight.normal),
            ),
            Container(
                padding: EdgeInsets.fromLTRB(40.0, 40.0, 40.0, 0.0),
                child: Icon(Icons.photo_camera, color: Theme.of(context).primaryColor, size: 120.0,)),
            Container(
              padding: EdgeInsets.all(60.0),
              child: RaisedButton(
                textColor: Colors.white,
                child: Text("Start"),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  Main.toScreen(context, StreamImageScreen(timeInterval: 20,));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
