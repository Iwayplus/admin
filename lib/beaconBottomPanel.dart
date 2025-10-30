import 'package:flutter/material.dart';

class BeaconBottomPanel extends StatelessWidget {
  final int totalBeacons;
  final int scannedBeacons;
  final Color backgroundColor;
  final Color textColor;
  final double height;

  const BeaconBottomPanel({
    Key? key,
    required this.totalBeacons,
    required this.scannedBeacons,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.height = 100.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                title: 'Total Beacons',
                value: totalBeacons.toString(),
                icon: Icons.radio_button_checked,
                color: Colors.blue,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              _buildStatCard(
                title: 'Scanned',
                value: scannedBeacons.toString(),
                icon: Icons.search,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


// Alternative implementation with progress indicator
class BeaconBottomPanelWithProgress extends StatelessWidget {
  final int totalBeacons;
  final int scannedBeacons;
  final Color backgroundColor;
  final Color textColor;
  final double height;

  const BeaconBottomPanelWithProgress({
    Key? key,
    required this.totalBeacons,
    required this.scannedBeacons,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.height = 100.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = totalBeacons > 0 ? scannedBeacons / totalBeacons : 0.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Total Beacons', totalBeacons.toString(), Colors.blue),
                  _buildStatColumn('Scanned', scannedBeacons.toString(), Colors.green),
                  _buildStatColumn('Progress', '${(progress * 100).toInt()}%', Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}