// lib/ar_native.dart - Native Dart AR with dots and turn arrows
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

class ARNativeScreen extends StatefulWidget {
  final LatLng destination;
  final List<LatLng> path;

  const ARNativeScreen({
    super.key,
    required this.destination,
    required this.path,
  });

  @override
  State<ARNativeScreen> createState() => _ARNativeScreenState();
}

class _ARNativeScreenState extends State<ARNativeScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  LatLng? _userPosition;
  double _userHeading = 0.0; // Device compass heading (0-360°)
  
  List<ARDot> _arDots = [];
  List<ARArrow> _turnArrows = [];
  
  bool _gpsActive = false;
  bool _compassActive = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAR();
  }

  Future<void> _initializeAR() async {
    // Request permissions
    await _requestPermissions();
    
    // Initialize camera
    await _initializeCamera();
    
    // Start GPS tracking
    _startGPSTracking();
    
    // Start compass tracking
    _startCompassTracking();
    
    // Generate AR markers
    _generateARMarkers();
  }

  Future<void> _requestPermissions() async {
    // On web, the camera plugin handles permission prompts automatically and
    // permission_handler has limited support. We only request location via geolocator.
    if (kIsWeb) {
      try {
        await Geolocator.requestPermission();
      } catch (e) {
        debugPrint('Web permission request error: $e');
      }
      return;
    }
    await Permission.camera.request();
    await Permission.location.request();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }
      
      // Use back camera for AR
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      // Use a lower resolution preset for web to improve performance
      final preset = kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high;

      _cameraController = CameraController(
        backCamera,
        preset,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startGPSTracking() {
    // Fallback: use path start if GPS unavailable (common on desktop Chrome)
    if (widget.path.isNotEmpty && _userPosition == null) {
      setState(() {
        _userPosition = widget.path.first;
        debugPrint('Using path start as fallback position: $_userPosition');
      });
    }
    
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
          _gpsActive = true;
        });
      }
    }, onError: (error) {
      debugPrint('GPS error: $error');
      setState(() => _gpsActive = false);
      // If GPS fails and we still have no position, use path start
      if (_userPosition == null && widget.path.isNotEmpty) {
        setState(() {
          _userPosition = widget.path.first;
          debugPrint('GPS failed, using path start: $_userPosition');
        });
      }
    });
  }

  void _startCompassTracking() {
    FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _userHeading = event.heading!;
          _compassActive = true;
        });
      }
    }, onError: (error) {
      debugPrint('Compass error: $error');
      setState(() => _compassActive = false);
    });
  }

  void _generateARMarkers() {
    if (widget.path.isEmpty) return;
    
    // Interpolate route into dots (every 3 meters)
    final dots = _interpolateRouteToDots(widget.path, spacingMeters: 3.0, maxDots: 180);
    _arDots = dots.map((coord) => ARDot(position: coord)).toList();
    
    // Detect turn points (bearing change > 25°)
    final turns = _detectTurnPoints(widget.path, thresholdDegrees: 25);
    _turnArrows = turns.map((turn) => ARArrow(
      position: turn.position,
      bearing: turn.bearing,
      isTurnRight: turn.isTurnRight,
    )).toList();
    
    setState(() {});
    debugPrint('Generated ${_arDots.length} dots and ${_turnArrows.length} arrows');
  }

  List<LatLng> _interpolateRouteToDots(List<LatLng> route, {required double spacingMeters, required int maxDots}) {
    if (route.length < 2) return route;
    
    final dots = <LatLng>[];
    const Distance distance = Distance();
    double carryover = 0.0;
    
    for (int i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];
      final segmentLength = distance(start, end);
      
      double distanceAlongSegment = carryover;
      
      while (distanceAlongSegment <= segmentLength) {
        final fraction = distanceAlongSegment / segmentLength;
        final lat = start.latitude + (end.latitude - start.latitude) * fraction;
        final lng = start.longitude + (end.longitude - start.longitude) * fraction;
        
        dots.add(LatLng(lat, lng));
        
        if (dots.length >= maxDots) return dots;
        
        distanceAlongSegment += spacingMeters;
      }
      
      carryover = distanceAlongSegment - segmentLength;
    }
    
    // Ensure destination is included
    if (dots.isEmpty || dots.last != route.last) {
      dots.add(route.last);
    }
    
    return dots;
  }

  List<TurnPoint> _detectTurnPoints(List<LatLng> route, {required double thresholdDegrees}) {
    if (route.length < 3) return [];
    
    final turns = <TurnPoint>[];
    
    for (int i = 1; i < route.length - 1; i++) {
      final prev = route[i - 1];
      final curr = route[i];
      final next = route[i + 1];
      
      final bearingIn = _calculateBearing(prev, curr);
      final bearingOut = _calculateBearing(curr, next);
      
      double bearingDiff = bearingOut - bearingIn;
      if (bearingDiff > 180) bearingDiff -= 360;
      if (bearingDiff < -180) bearingDiff += 360;
      
      if (bearingDiff.abs() > thresholdDegrees) {
        turns.add(TurnPoint(
          position: curr,
          bearing: bearingOut,
          isTurnRight: bearingDiff > 0,
        ));
      }
    }
    
    return turns;
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lng1 = from.longitudeInRad;
    final lat2 = to.latitudeInRad;
    final lng2 = to.longitudeInRad;
    
    final y = math.sin(lng2 - lng1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lng2 - lng1);
    
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance(from, to);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
  backgroundColor: Colors.black.withValues(alpha: 0.7),
        title: const Text('AR Navigation'),
        actions: [
          // Status indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(
                  _gpsActive ? Icons.gps_fixed : Icons.gps_off,
                  color: _gpsActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(
                  _compassActive ? Icons.explore : Icons.explore_off,
                  color: _compassActive ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          
          // AR overlay with dots and arrows
          if (_isCameraInitialized && _userPosition != null)
            Positioned.fill(
              child: CustomPaint(
                painter: AROverlayPainter(
                  userPosition: _userPosition!,
                  userHeading: _userHeading,
                  dots: _arDots,
                  arrows: _turnArrows,
                  screenSize: MediaQuery.of(context).size,
                ),
              ),
            ),
          
          // Debug overlay showing render status
          if (_isCameraInitialized && _userPosition == null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Waiting for GPS location...\n'
                  'Camera: OK | GPS: ${_gpsActive ? "Active" : "Waiting"}\n'
                  'Using fallback position from route start.',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Info panel at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Distance to destination
                  if (_userPosition != null)
                    Text(
                      'Distance: ${_calculateDistance(_userPosition!, widget.destination).toStringAsFixed(0)}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Marker counts and debug info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_arDots.length} dots',
                          style: const TextStyle(color: Colors.cyan),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_turnArrows.length} turns',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Render status
                  Text(
                    'Cam: ${_isCameraInitialized ? "✓" : "✗"} | GPS: ${_userPosition != null ? "✓" : "✗"} | Heading: ${_userHeading.toStringAsFixed(0)}°',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AR dots render on CAMERA view (not on map)',
                    style: TextStyle(color: Colors.yellow.withValues(alpha: 0.8), fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data models
class ARDot {
  final LatLng position;
  
  ARDot({required this.position});
}

class ARArrow {
  final LatLng position;
  final double bearing;
  final bool isTurnRight;
  
  ARArrow({
    required this.position,
    required this.bearing,
    required this.isTurnRight,
  });
}

class TurnPoint {
  final LatLng position;
  final double bearing;
  final bool isTurnRight;
  
  TurnPoint({
    required this.position,
    required this.bearing,
    required this.isTurnRight,
  });
}

// Custom painter for AR overlay
class AROverlayPainter extends CustomPainter {
  final LatLng userPosition;
  final double userHeading;
  final List<ARDot> dots;
  final List<ARArrow> arrows;
  final Size screenSize;
  
  AROverlayPainter({
    required this.userPosition,
    required this.userHeading,
    required this.dots,
    required this.arrows,
    required this.screenSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Camera FOV approximations (adjust based on device)
    const double horizontalFOV = 60.0; // degrees
    const double verticalFOV = 45.0; // degrees
    
    // Debug: Draw border to confirm CustomPaint is rendering
    final debugBorder = Paint()
  ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), debugBorder);
    
    // Debug: Draw text showing dot count
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AR Overlay Active\n${dots.length} dots to render',
        style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 20));
    
    // Draw dots with depth-based sizing (far = small, near = large)
    int renderedDots = 0;
    const Distance distance = Distance();
    
    for (final dot in dots) {
      final screenPos = _projectToScreen(dot.position, size, horizontalFOV, verticalFOV);
      if (screenPos != null) {
        renderedDots++;
        
        // Calculate distance for depth scaling
        final distMeters = distance(userPosition, dot.position);
        final depthScale = 1.0 - (distMeters / 50.0).clamp(0.0, 0.8); // 1.0 at 0m, 0.2 at 50m
        
        // Scale dot size based on distance
        final glowRadius = 12.0 * depthScale + 4.0; // 16px near, 4px far
        final dotRadius = 8.0 * depthScale + 3.0; // 11px near, 3px far
        final highlightRadius = 3.0 * depthScale + 1.0; // 4px near, 1px far
        
        // Scale opacity based on distance
        final opacity = (0.9 * depthScale + 0.3).clamp(0.3, 1.0); // 90% near, 30% far
        
        // Outer glow
        final glowPaint = Paint()
          ..color = Colors.cyan.withValues(alpha: opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(screenPos, glowRadius, glowPaint);
        
        // Main dot
        final dotPaint = Paint()
          ..color = Colors.cyan.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(screenPos, dotRadius, dotPaint);
        
        // White center highlight
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.7);
        canvas.drawCircle(screenPos, highlightRadius, highlightPaint);
      }
    }
    
    // Debug: Show how many dots were actually rendered on screen
    final renderedText = TextPainter(
      text: TextSpan(
        text: '$renderedDots dots visible in FOV',
        style: const TextStyle(color: Colors.yellow, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    renderedText.layout();
    renderedText.paint(canvas, Offset(20, size.height - 40));

    // Draw turn arrows
    for (final arrow in arrows) {
      final screenPos = _projectToScreen(arrow.position, size, horizontalFOV, verticalFOV);
      if (screenPos != null) {
        // Arrow color: right turn = orange, left turn = blue
        final color = arrow.isTurnRight ? Colors.orange : Colors.blue;
        final paint = Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;

        // Relative bearing between user heading and arrow bearing
        double relativeBearing = (arrow.bearing - userHeading);
        while (relativeBearing < -180) {
          relativeBearing += 360;
        }
        while (relativeBearing > 180) {
          relativeBearing -= 360;
        }
        final radians = relativeBearing * math.pi / 180.0;

        // Triangle arrow path
        const double arrowSize = 22.0;
        final path = ui.Path();
        path.moveTo(screenPos.dx, screenPos.dy - arrowSize * 0.6); // tip
        path.lineTo(screenPos.dx - arrowSize * 0.5, screenPos.dy + arrowSize * 0.4);
        path.lineTo(screenPos.dx + arrowSize * 0.5, screenPos.dy + arrowSize * 0.4);
        path.close();

        // Apply rotation about center
        final rotated = _rotatePath(path, screenPos, radians);
        canvas.drawPath(rotated, paint);
        canvas.drawPath(rotated, Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    }
  }

  // Rotate a path around a pivot
  ui.Path _rotatePath(ui.Path original, Offset center, double angleRad) {
    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angleRad)
      ..translate(-center.dx, -center.dy);
    return original.transform(matrix.storage);
  }

  // Projects a GPS point to screen coordinates relative to user position & heading.
  // Returns null if point is outside FOV or too far away.
  Offset? _projectToScreen(LatLng target, Size size, double hFov, double vFov) {
    const Distance distance = Distance();
    final distMeters = distance(userPosition, target);
    
    // Only show dots within 50 meters for clearer AR experience
    if (distMeters > 50) return null;
    
    // Bearing from user to target
    final bearingToTarget = _bearingBetween(userPosition, target);
    double relativeBearing = (bearingToTarget - userHeading);
    while (relativeBearing < -180) {
      relativeBearing += 360;
    }
    while (relativeBearing > 180) {
      relativeBearing -= 360;
    }

    // Only show dots in front of you (within 120° forward cone, not behind)
    if (relativeBearing.abs() > 90) return null;
    
    // Cull if outside horizontal FOV
    if (relativeBearing.abs() > hFov / 2) return null;

    // Horizontal position: map relativeBearing (-hFov/2..hFov/2) to screen width
    final x = (relativeBearing / (hFov / 2)) * (size.width / 2) + size.width / 2;

    // Distance for vertical placement (closer = lower on screen, further = higher)
    final clamped = distMeters.clamp(1, 50); // 1..50m
    final depthFactor = clamped / 50.0; // 0 near, 1 far
    final yBase = size.height * 0.75; // baseline for near dots (lower)
    final y = yBase - depthFactor * (size.height * 0.55); // far dots go higher

    return Offset(x, y);
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lon1 = from.longitudeInRad;
    final lat2 = to.latitudeInRad;
    final lon2 = to.longitudeInRad;
    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }

  @override
  bool shouldRepaint(covariant AROverlayPainter oldDelegate) {
    return oldDelegate.userPosition != userPosition ||
        oldDelegate.userHeading != userHeading ||
        oldDelegate.dots.length != dots.length ||
        oldDelegate.arrows.length != arrows.length;
  }
}