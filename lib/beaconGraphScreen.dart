import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BeaconGraphScreen extends StatelessWidget {
  final String beaconName;
  final ValueNotifier<Map<String, List<RssiPoint>>> historyNotifier;

  const BeaconGraphScreen({
    super.key,
    required this.beaconName,
    required this.historyNotifier,
  });

  @override
  Widget build(BuildContext context) {
    print("beaconName:${beaconName} ${historyNotifier}");
    return Scaffold(
      appBar: AppBar(title: Text(beaconName)),
      body: SizedBox(
        height: MediaQuery.of(context).size.height/2,
        width: MediaQuery.of(context).size.width,
        child: ValueListenableBuilder(
          valueListenable: historyNotifier,
          builder: (_, map, __) {
            final history = map[beaconName] ?? [];

            final spots = List.generate(
              history.length,
                  (i) => FlSpot(
                history[i].time.millisecondsSinceEpoch.toDouble(),
                history[i].rssi.toDouble(),
              ),
            );

            return Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  minY: -100,
                  maxY: -60,
                  // minX: spots.first.x,
                  // maxX: spots.last.x,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 2,
                      dotData: FlDotData(show: true), // DOT GRAPH
                    ),
                  ],
                  titlesData:  FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5, // show label every 5 points
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class RssiPoint {
  final int rssi;
  final DateTime time;

  RssiPoint(this.rssi, this.time);
}