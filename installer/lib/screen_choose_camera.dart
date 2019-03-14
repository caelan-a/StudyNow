import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:installer/screen_initialise_camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class ChooseCameraScreen extends StatefulWidget {
  ChooseCameraScreen({Key key}) : super(key: key);

  @override
  _ChooseCameraScreenState createState() => _ChooseCameraScreenState();
}

class _ChooseCameraScreenState extends State<ChooseCameraScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<
      ScaffoldState>(); //  Passed to next screen to display snackbar upon return

  //  lowercase name of the firebase collection currently being viewed
  String _currentCollectionName = "";

  //  Filled upon user selections
  String _chosenLibrary = "";
  String _chosenFloor = "";
  String _chosenCameraZone = "";

  //  path Firebase collection to display in list
  String _collectionToDisplayPath;

  //  Get path to previous collection in Firebase based on current collection path
  String getPreviousCollection(String currentCollection) {
    List<String> splitPath = currentCollection.split("/");
    String collectionPath = "";

    if (splitPath.length >= 3) {
      for (var i = 0; i < splitPath.length - 2; i++) {
        collectionPath += splitPath[i];
        if (i < splitPath.length - 3) {
          collectionPath += "/";
        }
      }
    } else {
      collectionPath = currentCollection;
    }
    print(collectionPath);
    return collectionPath;
  }

  @override
  void initState() {
    _currentCollectionName = "libraries";
    _collectionToDisplayPath = "/libraries";

    super.initState();
  }

  GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (await navKey.currentState.maybePop()) {
            print("NEST BACK");
            setState(() {
              _collectionToDisplayPath =
                  getPreviousCollection(_collectionToDisplayPath);
              _currentCollectionName = _collectionToDisplayPath.split('/').last;
            });
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Choose Camera'),
            centerTitle: true,
            actions: <Widget>[],
            leading: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: Navigator(
              key: navKey,
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute(builder: (context) {
                  return _buildFirebaseList(
                      _collectionToDisplayPath, _scaffoldKey);
                });
              }),
        ));
  }

  Widget _buildFirebaseList(collectionPath, scaffoldKey) {
    return Scaffold(
        body: StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection(collectionPath).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                    ListTile(
                      // dense: true,
                      // padding: EdgeInsets.all(20.0),
                      // color: index % 2 == 0 ? Colors.grey[200] : Colors.grey[0],
                      title: Text(
                        document['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 20.0,
                            color: Colors.grey[600]),
                      ),
                      onTap: () {
                        //  Store selection info
                        if (_currentCollectionName == "libraries") {
                          _chosenLibrary = document.documentID;
                        } else if (_currentCollectionName == "floors") {
                          _chosenFloor = document.documentID;
                        } else if (_currentCollectionName == "camera_zones") {
                          _chosenCameraZone = document.documentID;
                        }

                        //  Check if need to search more collections or all information is retreieved
                        if (_currentCollectionName != "camera_zones") {
                          String nextCollectionPath = collectionPath +
                              "/" +
                              document.documentID +
                              "/" +
                              document['nextCollection'];
                          _collectionToDisplayPath = nextCollectionPath;

                          //  Push a new collection
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => _buildFirebaseList(
                                  nextCollectionPath, _scaffoldKey)));
                          _currentCollectionName = document['nextCollection'];
                        } else {
                          //  No more collections to search
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) => InitialiseCameraScreen(
                                    library: _chosenLibrary,
                                    floor: _chosenFloor,
                                    cameraZone: _chosenCameraZone,
                                    prevScaffoldKey: scaffoldKey,
                                  ),
                            ),
                          );
                        }
                      },
                    ),
                    Divider(),
                  ],
                );
              }).toList(),
            );
        }
      },
    ));
  }
}
