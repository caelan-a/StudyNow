import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'screen_home.dart';

void main() => runApp(Main());

class Main extends StatelessWidget {
  static final GlobalKey<NavigatorState> _rootNavKey =
      GlobalKey<NavigatorState>();

  // FirebaseFirestore firestore = FirebaseFirestore.getInstance();
  // FirebaseFirestoreSettings settings = new FirebaseFirestoreSettings.Builder()
  //     .setTimestampsInSnapshotsEnabled(true)
  //     .build();
  // firestore.setFirestoreSettings(settings);

  static GlobalKey<NavigatorState> getRootNavKey() {
    return _rootNavKey;
  }

  static void toScreen(BuildContext context, Widget screen) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => screen));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorKey: _rootNavKey,
      theme: ThemeData(
        // fontFamily: 'Pridi',
        primarySwatch: Colors.blue,
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        }),
      ),
      home: HomePage(title: 'StudyNow Installer'),
    );
  }
}
