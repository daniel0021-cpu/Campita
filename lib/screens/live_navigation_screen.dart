import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LiveNavigationScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final LatLng destination;
  final String transportMode; // foot, bicycle, car, bus

  const LiveNavigationScreen({
    super.key,
    required this.routePoints,
    required this.destination,
    required this.transportMode,
  });

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  StreamSubscription<Position>? _posSub;
  double? _remainingDistance;
  double? _etaSeconds;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      _posSub = Geolocator.getPositionStream().listen((p) {
        final loc = LatLng(p.latitude, p.longitude);
        setState(() => _currentLocation = loc);
        _updateStats();
        _mapController.move(loc, _mapController.camera.zoom);
      });
      _updateStats();
    } catch (_) {}
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  void _updateStats() {
    if (_currentLocation == null) return;
    // Remaining distance: from current to destination straight-line + along route basic estimate
    double dist = 0;
    LatLng prev = _currentLocation!;
    for (final p in widget.routePoints) {
      dist += const Distance().distance(prev, p);
      prev = p;
    }
    dist += const Distance().distance(prev, widget.destination);
    _remainingDistance = dist;
    // Simple ETA by mode
    final speed = _modeSpeed(widget.transportMode);
    _etaSeconds = dist / speed;
    setState(() {});
  }

  double _modeSpeed(String mode) {
    // m/s
    switch (mode) {
      case 'bicycle': return 4.2; // 15km/h
      case 'car':
      case 'bus': return 8.3; // 30km/h
      default: return 1.4; // walking 5km/h
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters/1000).toStringAsFixed(1)} km';
  }

  String _formatEta(double seconds) {
    final mins = (seconds/60).ceil();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60; final m = mins % 60; return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_etaSeconds != null ? '${_formatEta(_etaSeconds!)} • ${_remainingDistance != null ? _formatDistance(_remainingDistance!) : ''}' : 'Navigating'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text('Stop', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.routePoints.isNotEmpty ? widget.routePoints.first : widget.destination,
              initialZoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_navigation',
              ),
              if (widget.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      color: AppColors.routeColor,
                      strokeWidth: 6,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    )
                  ],
                ),
              MarkerLayer(markers: [
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Icon(Icons.circle, color: Colors.white, size: 14)),
                    ),
                  ),
                Marker(point: widget.destination, width: 36, height: 36, child: const Icon(Icons.place, color: Colors.red, size: 28)),
              ])
            ],
          ),

          // Instruction placeholder
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Material(
              elevation: 6,
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.turn_right, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Head to destination. Turn-by-turn guidance will improve with more OSM data.',
                        style: GoogleFonts.notoSans(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
