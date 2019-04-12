import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'studynowlib/widget_percentage_indicator.dart';
import 'screen_map_view.dart';
import 'main.dart';
import 'dart:io';

class ChooseLibraryScreen extends StatefulWidget {
  ChooseLibraryScreen({Key key}) : super(key: key);

  @override
  _ChooseLibraryScreenState createState() => _ChooseLibraryScreenState();
}

class _ChooseLibraryScreenState extends State<ChooseLibraryScreen> {
  Color titleColor;

  //  Filled upon user selections
  String _chosenLibrary = "";

  //  path Firebase collection to display in list
  String _collectionToDisplayPath;

  @override
  void initState() {
    titleColor = Colors.grey[700];

    _collectionToDisplayPath = "/libraries";

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).canvasColor,
            title: const Text(
              'Libraries',
              style: TextStyle(color: Color(0xFF717171), fontSize: 20.0),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.home),
              color: Colors.grey,
              onPressed: () => Navigator.pop(context),
            ),
            actions: <Widget>[],
          ),
          body: Navigator(onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(builder: (context) {
              return _buildFirebaseList(_collectionToDisplayPath);
            });
          }),
        ));
  }

  Widget _buildLibraryTile(String libraryTitle, String libraryID,
      int totalSeats, int totalPeople, int tileIndex) {
    int percentageFull = 100 * totalPeople ~/ totalSeats;

    return Container(
      padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(3.0),
          child: Image.asset(
            "assets/library.jpeg",
            fit: BoxFit.cover,
            height: 60.0,
            width: 100.0,
          ),
        ),
        title: Text(
          libraryTitle,
          style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 24.0,
              color: Colors.grey[600]),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("$totalSeats seats",
                style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14.0,
                    color: Colors.grey[600])),
            LinearPercentIndicator(
              padding: EdgeInsets.all(5.0),
              animation: true,
              animateFromLastPercent: true,
              width: 150.0,
              progressColor: PercentageIndicator.getColor(percentageFull),
              percent: percentageFull / 100.0,
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 20.0,
        ),
        onTap: () {
          //  Store selection info
          _chosenLibrary = libraryID;

          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => MapScreen(
                    libraryID: _chosenLibrary,
                    libraryTitle: libraryTitle,
                    initialFloorID: "1",
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFirebaseList(collectionPath) {
    int tileCount = 0;
    return WillPopScope(
        onWillPop: () async {
          print("pop");
          return true;
        },
        child: Scaffold(
            body: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection(collectionPath).snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  ],
                ));
              default:
                return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        _buildLibraryTile(
                            document['title'],
                            document.documentID,
                            document['chairs_present'],
                            document['people_present'],
                            0),
                      ],
                    );
                  }).toList(),
                );
            }
          },
        )));
  }
}
