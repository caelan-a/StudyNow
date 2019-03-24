import 'package:flutter/material.dart';
import 'screen_choose_library.dart';
import 'main.dart';

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
      backgroundColor: Theme.of(context).primaryColor,
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
                  color: Theme.of(context).canvasColor,
                  fontSize: 40.0,
                  fontWeight: FontWeight.normal),
            ),
            Container(
                padding: EdgeInsets.fromLTRB(40.0, 40.0, 40.0, 0.0),
                child: Image.asset('assets/studynow.png',
                    scale: 2.0, color: Theme.of(context).canvasColor)),
            Container(
              padding: EdgeInsets.all(60.0),
              width: 220.0,
              child: RaisedButton(
                elevation: 5.0,
                
                child: Text("Start", style: TextStyle(fontSize: 16.0),),
                color: Colors.white,
                onPressed: () {
                  print("go");
                  Main.toScreen(context, ChooseLibraryScreen());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
