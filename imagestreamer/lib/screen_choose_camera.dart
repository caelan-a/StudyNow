import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'screen_stream_image.dart';

class ChooseCameraScreen extends StatefulWidget {
  ChooseCameraScreen({Key key}) : super(key: key);

  @override
  _ChooseCameraScreenState createState() => _ChooseCameraScreenState();
}

class _ChooseCameraScreenState extends State<ChooseCameraScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<
      ScaffoldState>(); //  Passed to next screen to display snackbar upon return

  //  lowercase name of the firebase collection currently being viewed
  String _currentCollectionType = "";

  //  Filled upon user selections
  String _chosenLibrary = "";
  String _chosenFloor = "";
  String _chosenCameraZone = "";

  @override
  void initState() {
    _currentCollectionType = "libraries";

    super.initState();
  }

  GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  getPreviousCollectionType(String collectionType) {
    if(collectionType == "camera_zones") {
      return "floors";
    } else if(collectionType == "floors") {
      return "libraries";
    } else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (await navKey.currentState.maybePop()) {
            _currentCollectionType = getPreviousCollectionType(_currentCollectionType);
            print("NEST BACK");
            setState(() {
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
                print("root build");
                return MaterialPageRoute(builder: (context) {
                  return _buildFirebaseList(
                      getFirebaseStream(_currentCollectionType, "", ""),
                      _scaffoldKey,
                      _currentCollectionType);
                });
              }),
        ));
  }

  void showNewCollection(String type, String libraryID, String floorID) {
    _currentCollectionType = type;
    Stream firebaseStream = getFirebaseStream(type, libraryID, floorID);

    if (firebaseStream != null) {
      //  Push a new collection
      navKey.currentState.push(MaterialPageRoute(
          builder: (context) =>
              _buildFirebaseList(firebaseStream, _scaffoldKey, type)));
    } else {
      print("Requested collection contains nothing");
    }
  }

  getFirebaseStream(String collectionType, String libraryID, String floorID) {
    if (collectionType == "libraries") {
      return Firestore.instance.collection("libraries").snapshots();
    } else if (collectionType == "floors") {
      return Firestore.instance
          .collection("floors")
          .where('library', isEqualTo: libraryID)
          .snapshots();
    } else if (collectionType == "camera_zones") {

      print("Camerazones");
      return Firestore.instance
          .collection("camera_zones")
          .where('library', isEqualTo: libraryID)
          .where('floor', isEqualTo: floorID)
          .snapshots();
    }
  }

  ListTile getListTile(String collectionType, DocumentSnapshot document) {
    return ListTile(
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

        print("Collection Type: $collectionType");
        String _nextCollectionType = "";

        //  Store selection info
        if (collectionType == "libraries") {
          _chosenLibrary = document.documentID;
          print("Chose library: $_chosenLibrary" );

          _nextCollectionType = "floors";
        } else if (collectionType == "floors") {
          _chosenFloor = document['id'];
          print("Chose floor: $_chosenFloor" );


          _nextCollectionType = "camera_zones";
          print(_nextCollectionType);
        } else if (collectionType == "camera_zones") {
          _chosenCameraZone = document.documentID;
        }

        //  Check if need to search more collections or all information is retreieved
        if (collectionType != "camera_zones") {
          showNewCollection(_nextCollectionType, _chosenLibrary, _chosenFloor);
        } else {
          print("No more");
          //  No more collections to search
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (context) {
              return StreamImageScreen(
                  timeInterval: document['stream_time_interval'], cameraZoneFsID: _chosenCameraZone, streaming: document['streaming']);
            }),
          );
        }
      },
    );
  }

  Widget _buildFirebaseList(stream, scaffoldKey, collectionType) {
    return Scaffold(
        body: StreamBuilder<QuerySnapshot>(
      stream: stream,
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
                    print(document['title']);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    getListTile(collectionType, document),
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
