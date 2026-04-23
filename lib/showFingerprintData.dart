import 'package:flutter/material.dart';
import '../APIMODELS/FingerPrintData.dart';
import 'api/fingerPrintGet.dart';
import 'api/fingerprintDelete.dart';

class FingerprintListScreen extends StatefulWidget {
  final String buildingId;
  final int floor;

  const FingerprintListScreen({
    Key? key,
    required this.buildingId,
    required this.floor,
  }) : super(key: key);

  @override
  State<FingerprintListScreen> createState() => _FingerprintListScreenState();
}

class _FingerprintListScreenState extends State<FingerprintListScreen> {
  List<String> _locationStrings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final Set<String> _deletingLocations = {};

  @override
  void initState() {
    super.initState();
    _loadFingerprintData();
  }

  Future<void> _loadFingerprintData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await fingerPrintingGetApi().Finger_Printing_GET_API(
        widget.buildingId,
        widget.floor.toString(),
      );
      setState(() {
        _locationStrings = _extractLocationStrings(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  /// Same structure as _extractLocalPoints — pulls entry.location strings
  List<String> _extractLocationStrings(FingerPrintData? fingerPrintData) {
    if (fingerPrintData?.data == null) return [];
    return fingerPrintData!.data!
        .map((entry) => entry.location)
        .whereType<String>()
        .where((loc) => loc.trim().isNotEmpty)
        .toList();
  }

  /// Parses a raw location string into a display-friendly structure
  _LocationDisplay _parseLocation(String location) {
    final parts = location.split(',');

    if (parts.length >= 6) {
      // Index 0 is skipped; 1=x, 2=y, 3=floor, 4=lng, 5=lat
      final labeled = [
        _LabeledPart('X',     parts[1].trim()),
        _LabeledPart('Y',     parts[2].trim()),
        _LabeledPart('Floor', parts[3].trim()),
        _LabeledPart('Lng',   parts[4].trim()),
        _LabeledPart('Lat',   parts[5].trim()),
      ];
      return _LocationDisplay(
        icon: Icons.public_rounded,
        iconColor: Colors.green.shade600,
        labeledParts: labeled,
      );
    }

    if (parts.length >= 2) {
      return _LocationDisplay(
        icon: Icons.grid_on_rounded,
        iconColor: Colors.blue.shade600,
        labeledParts: parts
            .asMap()
            .entries
            .map((e) => _LabeledPart('[${e.key}]', e.value.trim()))
            .toList(),
      );
    }

    return _LocationDisplay(
      icon: Icons.location_on_rounded,
      iconColor: Colors.orange.shade600,
      labeledParts: [_LabeledPart('raw', location)],
    );
  }

  Future<void> _confirmAndDelete(String location) async {
    final display = _parseLocation(location);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 26),
            const SizedBox(width: 8),
            const Text('Delete Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('Are you sure you want to delete this fingerprint location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingLocations.add(location));

    try {
      final success = await fingerPrintingDeleteApi()
          .Finger_Printing_DELETE_API(widget.buildingId, location);

      if (success) {
        setState(() {
          _deletingLocations.remove(location);
          _locationStrings.remove(location);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Location deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      } else {
        setState(() => _deletingLocations.remove(location));
        _showErrorSnackbar('Failed to delete. Please try again.');
      }
    } catch (e) {
      setState(() => _deletingLocations.remove(location));
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fingerprint Locations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              'Building: ${widget.buildingId}  |  Floor: ${widget.floor}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadFingerprintData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading fingerprint data...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Failed to load data',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadFingerprintData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_locationStrings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No fingerprint data found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('No locations recorded for this floor.',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Count summary bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pin_drop_rounded,
                        size: 15, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${_locationStrings.length} location${_locationStrings.length != 1 ? 's' : ''}',
                      style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.shade100, height: 1),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFingerprintData,
            child: ListView.separated(
              padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: _locationStrings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final locationStr = _locationStrings[index];
                final display = _parseLocation(locationStr);
                final isDeleting = _deletingLocations.contains(locationStr);

                return AnimatedOpacity(
                  opacity: isDeleting ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.fromLTRB(14, 8, 8, 8),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: display.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(display.icon,
                            color: display.iconColor, size: 20),
                      ),
                      title: Text(
                        '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          // Named labeled chips
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: display.labeledParts
                                .map((part) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${part.label}: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    TextSpan(
                                      text: part.value,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                      trailing: isDeleting
                          ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.red.shade400,
                          ),
                        ),
                      )
                          : IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.red.shade400, size: 22),
                        tooltip: 'Delete',
                        onPressed: () => _confirmAndDelete(locationStr),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledPart {
  final String label;
  final String value;
  _LabeledPart(this.label, this.value);
}

class _LocationDisplay {
  final IconData icon;
  final Color iconColor;
  final List<_LabeledPart> labeledParts;

  _LocationDisplay({
    required this.icon,
    required this.iconColor,
    required this.labeledParts,
  });
}