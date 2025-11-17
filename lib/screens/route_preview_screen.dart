import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RoutePreviewScreen extends StatelessWidget {
  final List<LatLng> routePoints;
  final LatLng start;
  final LatLng end;
  final double distanceMeters;
  final double durationSeconds;
  final String transportMode; // foot, bicycle, car, bus

  const RoutePreviewScreen({
    super.key,
    required this.routePoints,
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.transportMode,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'bicycle': return Icons.directions_bike;
      case 'car': return Icons.directions_car;
      case 'bus': return Icons.directions_bus;
      default: return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds.fromPoints(routePoints.isNotEmpty ? routePoints : [start, end]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route preview'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                (bounds.north + bounds.south) / 2,
                (bounds.east + bounds.west) / 2,
              ),
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_navigation',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: AppColors.routeColor,
                      strokeWidth: 6,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(markers: [
                Marker(point: start, width: 36, height: 36, child: const Icon(Icons.circle, color: Colors.green, size: 18)),
                Marker(point: end, width: 36, height: 36, child: const Icon(Icons.place, color: Colors.red, size: 28)),
              ]),
            ],
          ),

          // Summary card
          Positioned(
            left: 12,
            right: 12,
            bottom: 100,
            child: Material(
              color: AppColors.cardBackground(context),
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_modeIcon(transportMode), color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_formatDistance(distanceMeters)} • ${_formatDuration(durationSeconds)}', style: GoogleFonts.notoSans(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Preview your route before starting', style: GoogleFonts.notoSans(color: AppColors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.map, color: AppColors.grey),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/live-navigation',
                            arguments: {
                              'points': routePoints,
                              'end': end,
                              'mode': transportMode,
                            },
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
