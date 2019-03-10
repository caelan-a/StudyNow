import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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
            title: const Text('Libraries'),
            centerTitle: true,
            actions: <Widget>[],
          ),
          body: Navigator(onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(builder: (context) {
              return _buildFirebaseList(_collectionToDisplayPath);
            });
          }),
        ));
  }

  Widget _buildFirebaseList(collectionPath) {
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
                            _chosenLibrary = document.documentID;

                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => MapScreen(
                                      library: _chosenLibrary,
                                      libraryTitle: document['title'],
                                    ),
                              ),
                            );
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
