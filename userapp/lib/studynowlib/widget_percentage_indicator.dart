import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PercentageIndicator extends StatelessWidget {
  final int totalSeats;
  final int totalPeople;
  final int offsetFactor;

  final Color textColor;

  PercentageIndicator({this.totalSeats, this.offsetFactor = 0, this.totalPeople, this.textColor = Colors.black});

  @override
  Widget build(BuildContext context) {
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
}
