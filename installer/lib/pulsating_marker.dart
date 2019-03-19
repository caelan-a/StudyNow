import 'package:flutter/material.dart';
import 'dart:math';

/*
  Using photo_view creates a map that user can place markers on which move around 
*/

const double BOX_HEIGHT = 10.0; // Sets height of icon in widget tree that draws painter. Set low so it doesnt interfere with touch events

class PulsatingMarker extends StatefulWidget {
  final Offset screenPosition;
  final Color color;
  final double radius;
  final double scale;

  PulsatingMarker({
    Key key,
    this.color = const Color(0xFF007597),
    this.radius = 150.0,
    this.scale = 1.0,
    @required this.screenPosition,
  });

  @override
  _PulsatingMarkerState createState() => _PulsatingMarkerState();
}

class _PulsatingMarkerState extends State<PulsatingMarker>
    with TickerProviderStateMixin {
  AnimationController _controller;
  AnimationController _dropController;
  var dropTheBass;

  @override
  void initState() {
    _controller = new AnimationController(
      vsync: this,
    );

    _dropController = new AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    dropTheBass = Tween<double>(
      begin:0,
      end:1.5,
    ).animate(CurvedAnimation(
        parent:_dropController,
        curve: Curves.bounceOut,
    ))
    ..addListener((){
      setState(() {
        
      });
    });

    _startAnimation();
    super.initState();
  }


  @override
  void dispose() {
    _controller.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    print("good boys");
    _controller.stop();
    _controller.reset();


    _dropController.stop();
    _dropController.reset();
    _dropController.forward();


    _controller.repeat(
      period: Duration(seconds: 1),
    );

  }

  @override
  Widget build(BuildContext context) {


    return CustomPaint(
      willChange: true,
      painter: PulsatingPainter(animation: _controller, screenPosition: widget.screenPosition, baseRadius: widget.radius, baseColor: widget.color, scale: dropTheBass.value), // controler.value*scale || widget.scale
      child: new SizedBox(
        width: widget.radius,
        height: BOX_HEIGHT,
      ),
    );
  }
}

class PulsatingPainter extends CustomPainter {
  final Offset screenPosition;

  final Animation<double> animation;
  final double baseRadius;
  final double scale;
  final Color baseColor;

  PulsatingPainter({@required this.animation, @required this.screenPosition, @required this.baseRadius, @required this.scale, @required this.baseColor})
      : super(repaint: animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 0.3);
    Color color = baseColor.withOpacity(opacity);

    double radius = scale * baseRadius *sqrt( value);
    final Paint paint = new Paint()..color = color;
    canvas.drawCircle(screenPosition, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = new Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + animation.value);
    }
  }

  @override
  bool shouldRepaint(PulsatingPainter oldDelegate) {
    return false;
  }
}
