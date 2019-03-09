import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:installer/screen_image.dart';
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

  String _collectionToDisplayPath = "/libraries";

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Choose Camera'),
            centerTitle: true,
            actions: <Widget>[],
          ),
          body: Navigator(onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(builder: (context) {
              return _buildFirebaseList(_collectionToDisplayPath, _scaffoldKey);
            });
          }),
        ));
  }

  Widget _buildFirebaseList(collectionTitle, scaffoldKey) {
    return WillPopScope(
        onWillPop: () async {
          print("pop");
          return true;
        },
        child: Scaffold(
            body: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection(collectionTitle).snapshots(),
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
                            if (document['nextCollection'] != "none") {
                              String nextCollectionPath = collectionTitle +
                                  "/" +
                                  document.documentID +
                                  "/" +
                                  document['nextCollection'];
                              print(nextCollectionPath);
                              _collectionToDisplayPath = nextCollectionPath;
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => _buildFirebaseList(
                                      nextCollectionPath, _scaffoldKey)));
                            } else {
                              //  Reached end of tree. Get camera image file name
                              String cameraDocumentPath =
                                  collectionTitle + "/" + "1";
                              String imageFileName =
                                  document["image_file_name"];
                              print("Image File Name: $imageFileName");
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => ImageScreen(
                                        imageFileName: imageFileName,
                                        cameraDocumentPath: cameraDocumentPath,
                                        prevScaffoldKey: scaffoldKey,
                                        cameraName: document['title'],
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
        )));
  }
}
