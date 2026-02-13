import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class PDRCalibrationScreen extends StatefulWidget {
  const PDRCalibrationScreen({Key? key}) : super(key: key);

  @override
  State<PDRCalibrationScreen> createState() => _PDRCalibrationScreenState();
}

class _PDRCalibrationScreenState extends State<PDRCalibrationScreen>
    with SingleTickerProviderStateMixin {
  // Calibration state
  bool isCalibrating = false;
  int remainingSeconds = 30;
  final int calibrationDuration = 30;

  // Calibration results
  String calibrationQuality = "";
  bool showResults = false;

  // PDR parameters
  double peakThreshold = 11.0;
  double valleyThreshold = -11.0;
  double oldPeakThreshold = 11.0;
  double oldValleyThreshold = -11.0;

  // Raw magnitude collection during calibration
  List<double> magnitudeList = [];

  // Gap-finding result info (for results card)
  int detectedPeakCount = 0;
  double detectedGapSize = 0.0;

  // For filtering
  double filteredX = 0, filteredY = 0, filteredZ = 0;
  double alpha = 0.8;

  // Timers and subscriptions
  Timer? countdownTimer;
  StreamSubscription<AccelerometerEvent>? accelSubscription;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCalibration();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    accelSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      peakThreshold = prefs.getDouble('peakThreshold') ?? 11.0;
      valleyThreshold = prefs.getDouble('valleyThreshold') ?? -11.0;
      oldPeakThreshold = peakThreshold;
      oldValleyThreshold = valleyThreshold;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('PDR Calibration'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            if (!isCalibrating && !showResults) _buildInstructionsCard(),
            if (isCalibrating) _buildCalibrationCard(),
            if (showResults) _buildResultsCard(),
            const SizedBox(height: 20),
            _buildCurrentSettingsCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_walk, size: 60, color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            'Step Detection Calibration',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optimize accuracy for your device',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  // ─── INSTRUCTIONS ────────────────────────────────────────────────────────

  Widget _buildInstructionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.info_outline, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              const Text('How It Works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep('1', 'Walk normally for 30 seconds', Icons.timer),
          _buildInstructionStep('2', 'We record your movement data silently', Icons.timeline),
          _buildInstructionStep('3', 'Threshold is auto-detected from the data', Icons.tune),
          _buildInstructionStep('4', 'Settings save automatically', Icons.save),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Walk at your normal pace in a straight line',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  // ─── CALIBRATION IN-PROGRESS CARD ───────────────────────────────────────

  Widget _buildCalibrationCard() {
    double progress = 1 - (remainingSeconds / calibrationDuration);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.directions_walk, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'WALK NOW!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep walking at normal pace',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 24),

          // Circular countdown
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$remainingSeconds',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'seconds',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Samples collected live counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timeline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Samples: ${magnitudeList.length}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── RESULTS CARD ────────────────────────────────────────────────────────

  Widget _buildResultsCard() {
    Color resultColor = _getResultColor();
    IconData resultIcon = _getResultIcon();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: resultColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(resultIcon, size: 50, color: resultColor),
          ),
          const SizedBox(height: 16),
          Text(
            calibrationQuality,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: resultColor),
          ),
          const SizedBox(height: 24),

          _buildResultRow('Samples Collected', '${magnitudeList.length}', Icons.timeline),
          _buildResultRow('Est. Steps Detected', '$detectedPeakCount', Icons.directions_walk),
          _buildResultRow('Gap Size Found', detectedGapSize.toStringAsFixed(2), Icons.height),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          Text(
            'Threshold Adjustments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),

          _buildThresholdChange('Peak', oldPeakThreshold, peakThreshold),
          _buildThresholdChange('Valley', oldValleyThreshold, valleyThreshold),

          // Warn if the gap was suspiciously small (noisy / bad walk)
          if (detectedGapSize < 0.5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gap was very small — consider recalibrating on a flatter surface',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo.shade400),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildThresholdChange(String type, double oldValue, double newValue) {
    double change = newValue - oldValue;
    bool increased = change > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(type, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  oldValue.toStringAsFixed(2),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough),
                ),
                const SizedBox(width: 8),
                Icon(
                  increased ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: increased ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  newValue.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CURRENT SETTINGS CARD ───────────────────────────────────────────────

  Widget _buildCurrentSettingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text('Current Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingRow('Peak Threshold', peakThreshold.toStringAsFixed(2)),
          _buildSettingRow('Valley Threshold', valleyThreshold.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (!isCalibrating && !showResults)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _startCalibration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Start Calibration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),

          if (isCalibrating)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _cancelCalibration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),

          if (showResults) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveAndExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _recalibrate,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.indigo, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Recalibrate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── RESULT COLOUR / ICON (based on gap quality) ────────────────────────

  Color _getResultColor() {
    if (detectedGapSize >= 1.0) return Colors.green;
    if (detectedGapSize >= 0.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getResultIcon() {
    if (detectedGapSize >= 1.0) return Icons.check_circle;
    if (detectedGapSize >= 0.5) return Icons.warning;
    return Icons.error;
  }

  // ─── CORE CALIBRATION LOGIC ─────────────────────────────────────────────

  void _startCalibration() async {
    setState(() {
      isCalibrating = true;
      showResults = false;
      magnitudeList = [];
      remainingSeconds = calibrationDuration;
      oldPeakThreshold = peakThreshold;
      oldValleyThreshold = valleyThreshold;
      // reset filter state so stale values don't bleed in
      filteredX = 0;
      filteredY = 0;
      filteredZ = 0;
    });

    await _showCountdown();
    if (!isCalibrating) return;

    // Start collecting raw magnitudes
    _startCollecting();

    // Countdown tick
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
      });
      if (remainingSeconds <= 0) {
        _finishCalibration();
      }
    });
  }

  Future<void> _showCountdown() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted || !isCalibrating) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            i == 1 ? 'START WALKING NOW!' : 'Get ready... $i',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          duration: const Duration(milliseconds: 900),
          backgroundColor: i == 1 ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Just collect filtered magnitudes — no threshold, no step counting.
  void _startCollecting() {
    accelSubscription = accelerometerEvents.listen((event) {
      if (!isCalibrating) return;

      filteredX = alpha * filteredX + (1 - alpha) * event.x;
      filteredY = alpha * filteredY + (1 - alpha) * event.y;
      filteredZ = alpha * filteredZ + (1 - alpha) * event.z;

      double magnitude = sqrt(filteredX * filteredX + filteredY * filteredY + filteredZ * filteredZ);
      magnitudeList.add(magnitude);

      // Rebuild only the samples counter (cheap)
      setState(() {});
    });
  }

  void _finishCalibration() {
    countdownTimer?.cancel();
    accelSubscription?.cancel();
    setState(() {
      isCalibrating = false;
    });
    _calculateThresholdFromClusters();
  }



  /// Sort magnitudes descending, find the largest gap in a safe window
  /// around the expected number of peaks, and set the threshold at that gap.
  void _calculateThresholdFromClusters() {
    if (magnitudeList.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough data collected. Try again.'), backgroundColor: Colors.red),
      );
      return;
    }

    double minVal = magnitudeList.reduce(min);
    double maxVal = magnitudeList.reduce(max);

    // If phone didn't really move
    if (maxVal - minVal < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough movement detected. Try again.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Split the range into e.g. 50 bins
    int numBins = 50;
    double binWidth = (maxVal - minVal) / numBins;
    List<int> binCounts = List.filled(numBins, 0);

    // Count how many samples fall into each bin
    for (double mag in magnitudeList) {
      int binIndex = ((mag - minVal) / binWidth).toInt();
      binIndex = binIndex.clamp(0, numBins - 1);
      binCounts[binIndex]++;
    }

    // Find the two densest bins
    // First: find the densest bin overall
    int firstPeakBin = 0;
    for (int i = 1; i < numBins; i++) {
      if (binCounts[i] > binCounts[firstPeakBin]) {
        firstPeakBin = i;
      }
    }

    // Second: find the densest bin that is far enough away from the first
    // (at least 20% of the range away, so we don't just pick a neighbour)
    int minDistance = (numBins * 0.2).toInt();
    int secondPeakBin = -1;
    for (int i = 0; i < numBins; i++) {
      if ((i - firstPeakBin).abs() < minDistance) continue; // too close, skip
      if (secondPeakBin == -1 || binCounts[i] > binCounts[secondPeakBin]) {
        secondPeakBin = i;
      }
    }

    print("bin value:${firstPeakBin} ${secondPeakBin} ${binCounts}");

    // If we couldn't find a second cluster, data is bad
    if (secondPeakBin == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find two distinct clusters. Try again.'), backgroundColor: Colors.red),
      );
      return;
    }

    // The threshold is the midpoint between the centres of the two bins
    double cluster1Centre = minVal + (firstPeakBin + 0.5) * binWidth;
    double cluster2Centre = minVal + (secondPeakBin + 0.5) * binWidth;

    print("cluster1Centre:${cluster1Centre} cluster2Centre:${cluster2Centre}");

    // Make sure peak threshold is the higher one
    double higherCluster = max(cluster1Centre, cluster2Centre);
    double lowerCluster = min(cluster1Centre, cluster2Centre);
    double newPeak = (higherCluster + lowerCluster) / 2.0;
    double separation = higherCluster - lowerCluster;

    print("higherCluster:${higherCluster} lowerCluster:${lowerCluster} newPeak:${newPeak}");

    // Validate the threshold - realistic walking values are typically 9-20 m/s²
    const double maxRealisticPeak = 15.0;
    const double minRealisticPeak = 9.0;
    const double defaultPeak = 11.0;

    if (newPeak > maxRealisticPeak || newPeak < minRealisticPeak) {
      String reason = newPeak > maxRealisticPeak ? 'too high (noise)' : 'too low (insufficient movement)';
      print("WARNING: Detected peak ${newPeak} is ${reason}. Falling back to default.");

      setState(() {
        peakThreshold = defaultPeak;
        valleyThreshold = -defaultPeak;
        detectedGapSize = separation;
        detectedPeakCount = binCounts[firstPeakBin] + binCounts[secondPeakBin];
        calibrationQuality = 'Invalid Data - Using Default';
        showResults = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Calibration failed (threshold ${reason}). Using default.'),
            backgroundColor: Colors.orange
        ),
      );
      return;
    }

    setState(() {
      peakThreshold = newPeak;
      valleyThreshold = -newPeak;
      detectedGapSize = separation;
      detectedPeakCount = binCounts[firstPeakBin] + binCounts[secondPeakBin];

      if (separation >= 2.0) {
        calibrationQuality = 'Well Calibrated!';
      } else if (separation >= 1.0) {
        calibrationQuality = 'Acceptable';
      } else {
        calibrationQuality = 'Needs Recalibration';
      }
      showResults = true;
    });
  }

  void _cancelCalibration() {
    countdownTimer?.cancel();
    accelSubscription?.cancel();
    setState(() {
      isCalibrating = false;
      magnitudeList = [];
      remainingSeconds = calibrationDuration;
    });
  }

  void _recalibrate() {
    setState(() { showResults = false; });
    _startCalibration();
  }

  Future<void> _saveAndExit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('peakThreshold', peakThreshold);
    await prefs.setDouble('valleyThreshold', valleyThreshold);
    await prefs.setBool('isCalibrated', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibration saved successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, {
        'peakThreshold': peakThreshold,
        'valleyThreshold': valleyThreshold,
      });
    }
  }
}