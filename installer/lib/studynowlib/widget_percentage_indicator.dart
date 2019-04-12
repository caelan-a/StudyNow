import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PercentageIndicator extends StatelessWidget {
  final int totalSeats;
  final int totalPeople;
  final int offsetFactor;
  final double radius;
  final double lineWidth;
  final double fontSize;
  final bool showPercentage;

  final Color inactiveColor;
  final Color textColor;

  PercentageIndicator(
      {this.totalSeats,
      this.showPercentage = true,
      this.offsetFactor = 0,
      this.totalPeople,
      this.textColor = Colors.black,
      this.inactiveColor = const Color(0xFFB8C7CB),
      this.radius = 70.0,
      this.lineWidth = 6.0,
      this.fontSize = 16.0});

  static Color getColor(int percentageFull) {
    return percentageFull < 25
        ? Colors.green
        : percentageFull < 50
            ? Colors.yellow
            : percentageFull < 75 ? Colors.orange : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    const int offsetMagnitude = 75;
    int percentageFull = (100 * (totalPeople / totalSeats)).toInt();
    Color color = getColor(percentageFull);
    // Color color = Theme.of(context).primaryColor;

    return Stack(children: <Widget>[
      CircularPercentIndicator(
        animation: true,
        animationDuration: 400 + offsetFactor * offsetMagnitude,
        startAngle: 270.0,
        animateFromLastPercent: true,
        circularStrokeCap: CircularStrokeCap.round,
        radius: radius,
        backgroundColor: inactiveColor ?? inactiveColor,
        
        lineWidth: lineWidth,
        percent: percentageFull / 100.0,
        center: showPercentage ? new Text(
          "$percentageFull%",
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.normal, color: textColor),
        ) : Container(),
        progressColor: color,
      )
    ]);
  }
}
