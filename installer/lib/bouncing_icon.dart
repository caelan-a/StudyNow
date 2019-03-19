import 'package:flutter/material.dart';
import 'main.dart';
import 'package:installer/screen_count_chairs.dart';
import 'package:installer/screen_choose_camera.dart';
import 'package:vector_math/vector_math.dart' show radians;
import 'bouncing_icon.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class BouncingIcon extends StatefulWidget {
  final Offset touchCoords;
  BouncingIcon(Offset touchCoords) :touchCoords=touchCoords;
  @override
  createState(){ 
    
    print("the touchcoords are $touchCoords");
    return _BouncingIconState();
    }
}

class _BouncingIconState extends State<BouncingIcon>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: Duration(milliseconds: 900), vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BouncingAnimation(controller: controller);
  }
}

class BouncingAnimation extends StatelessWidget {
  BouncingAnimation({Key key, this.controller}) : 
    scale = Tween<double>(
      begin:1,
      end:0,
    ).animate(CurvedAnimation(
      parent:controller,
      curve: Curves.bounceInOut,
    )),
    // translation = Tween<double>(
    //   begin: 0,
    //   end: 100,
    // ).animate(CurvedAnimation(
    //   parent:controller,
    //   curve: Curves.bounceInOut,
    // )),
  super(key: key);

  final AnimationController controller;
  final Animation<double> scale;
  // final Animation<double> translation;

  build(context) {
    return AnimatedBuilder(
        animation: controller, 
        builder: (context, builder) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[

              Transform.scale(
                scale:scale.value - 0.1,
                child: FloatingActionButton(
                  child: Icon(FontAwesomeIcons.timesCircle),
                  onPressed: _close,
                  backgroundColor: Colors.red,
                ),
              ),

              // Transform.translate(
              //   offset: ,
              //   child: FloatingActionButton(
              //     child: Icon(FontAwesomeIcons.timesCircle),
              //     onPressed: _close,
              //     backgroundColor: Colors.red,
              //   ),
              // )

              Transform.scale(
                scale: scale.value,
                child: FloatingActionButton(
                  child: Icon(FontAwesomeIcons.solidDotCircle),
                  onPressed: _open,
                ),
              )
            ],
          );

        });
  }

  _open(){
    controller.forward();
  }

  _close(){
    controller.reverse();
  }
}
