import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'screen_map_view.dart';
import 'main.dart';

class ChooseLibraryScreen extends StatefulWidget {
  ChooseLibraryScreen({Key key}) : super(key: key);

  @override
  _ChooseLibraryScreenState createState() => _ChooseLibraryScreenState();
}

class _ChooseLibraryScreenState extends State<ChooseLibraryScreen> {
  //  Filled upon user selections
  String _chosenLibrary = "";

  //  path Firebase collection to display in list
  String _collectionToDisplayPath;

  @override
  void initState() {
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
              style: TextStyle(color: Colors.grey, fontSize: 24.0),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
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

  Widget _buildPercentageWidget(int totalSeats, int totalPeople, int offsetFactor) {
    const int offsetMagnitude = 75;
    int percentageFull = (100 * (totalPeople / totalSeats)).toInt();
    Color color = percentageFull < 25
        ? Colors.green
        : percentageFull < 50
            ? Colors.yellow
            : percentageFull < 75 ? Colors.orange : Colors.red;
    // Color color = Theme.of(context).primaryColor;

    return Stack(children: <Widget>[
      CircularPercentIndicator(
        animation: true,
        animationDuration: 400 + offsetFactor * offsetMagnitude,
        startAngle: 270.0,
        animateFromLastPercent: true,
        circularStrokeCap: CircularStrokeCap.round,
        radius: 70.0,
        lineWidth: 6.0,
        percent: percentageFull / 100.0,
        center: new Text(
          "$percentageFull%",
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
        ),
        progressColor: color,
      )
    ]);
  }

  Widget _buildLibraryTile(
      String libraryTitle, String libraryID, int totalSeats, int totalPeople, int tileIndex) {
    return Container(
      padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
      child: Card(
        // margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
        elevation: 3.0,
        child: ListTile(
          contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          leading: _buildPercentageWidget(totalSeats, totalPeople, tileIndex),
          title: Text(
            libraryTitle,
            style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 36.0,
                color: Colors.grey[600]),
          ),
          subtitle: Text("$totalSeats seats",
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16.0,
                  color: Colors.grey[600])),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            //  Store selection info
            _chosenLibrary = libraryID;

            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => MapScreen(
                      library: _chosenLibrary,
                      libraryTitle: libraryTitle,
                    ),
              ),
            );
          },
        ),
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
                            document['title'], document.documentID, 400, 85, 0),
                        _buildLibraryTile(
                            "Giblin", document.documentID, 300, 100, 1),
                        _buildLibraryTile(
                            "Brownless", document.documentID, 220, 120, 2),
                        _buildLibraryTile(
                            "Arts", document.documentID, 557, 500, 3),
                      ],
                    );
                  }).toList(),
                );
            }
          },
        )));
  }
}
