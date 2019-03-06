import 'package:flutter/material.dart';

class ImageScreen extends StatefulWidget {
  ImageScreen({Key key}) : super(key: key);


  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  bool _imageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: null,
            body: Center(
              child: !_imageLoaded
        ? Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text("Fetching image from camera\n\n",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 16.0),
),            
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
            ],
          ))
        : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[],
              ),
            ),
          );
  }
}
