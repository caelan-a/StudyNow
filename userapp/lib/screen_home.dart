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
      // backgroundColor: Theme.of(context).primaryColor,
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
              "STUDYNOW",

              
              textAlign: TextAlign.center,
              style: TextStyle(
                shadows: <Shadow>[Shadow(offset: Offset(2.0,2.0), blurRadius: 6.0, color: Colors.grey.withAlpha(150))],
                  color: Theme.of(context).primaryColor,
                  fontSize: 40.0,
                  fontWeight: FontWeight.normal),
            ),
            Container(
                padding: EdgeInsets.fromLTRB(40.0, 40.0, 40.0, 0.0),
                child: Image.asset('assets/studynow.png',
                    scale: 2.0, color: Theme.of(context).primaryColor)),
            Container(
              padding: EdgeInsets.all(60.0),
              width: 220.0,
              child: RaisedButton(
                elevation: 5.0,
                
                child: Text("START", style: TextStyle(fontSize: 16.0, color: Colors.grey[600],),),
                color: Theme.of(context).canvasColor,
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
