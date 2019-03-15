import 'package:flutter/material.dart';
import 'dart:math';

/*
  Using photo_view creates a mapo that user can place markers on which move around 
*/

const double BOX_HEIGHT =
    10.0; // Sets height of icon in widget tree that draws painter. Set low so it doesnt interfere with touch events

class PulsatingMarker extends StatefulWidget {
  final Offset screenPosition;
  final Color color;
  final double width;
  final double scale;

  PulsatingMarker({
    Key key,
    this.color = const Color(0xFF007597),
    this.width = 150.0,
    this.scale = 1.0,
    @required this.screenPosition,
  }) : super(key: key);

  @override
  _PulsatingMarkerState createState() => _PulsatingMarkerState();
}

class _PulsatingMarkerState extends State<PulsatingMarker>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    _controller = new AnimationController(
      vsync: this,
    );
    _startAnimation();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.repeat(
      period: Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      willChange: true,
      painter: PulsatingPainter(
          animation: _controller,
          screenPosition: widget.screenPosition,
          width: widget.width,
          baseColor: widget.color,
          scale: widget.scale),
      child: new SizedBox(
        width: widget.width,
        height: BOX_HEIGHT,
      ),
    );
  }
}

class PulsatingPainter extends CustomPainter {
  final Offset screenPosition;

  final Animation<double> animation;
  final double width;
  final double scale;
  final Color baseColor;

  PulsatingPainter(
      {@required this.animation,
      @required this.screenPosition,
      @required this.width,
      @required this.scale,
      @required this.baseColor})
      : super(repaint: animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 0.3);
    Color color = baseColor.withOpacity(opacity);

    double radius = scale * width * sqrt(value);

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
    return true;
  }
}
