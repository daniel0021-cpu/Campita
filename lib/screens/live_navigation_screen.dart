import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/campus_building.dart';
import '../widgets/animated_success_card.dart';

class LiveNavigationScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final LatLng destination;
  final String transportMode;
  final CampusBuilding? destinationBuilding;

  const LiveNavigationScreen({
    super.key,
    required this.routePoints,
    required this.destination,
    required this.transportMode,
    this.destinationBuilding,
  });

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _musicSearchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  LatLng? _currentLocation;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;
  double? _remainingDistance;
  double _etaSeconds = 0;
  double _userHeading = 0.0; // Device compass heading in degrees
  double _mapBearing = 0.0; // Map rotation angle
  
  // Navigation features
  bool _is3DView = false;
  bool _ttsEnabled = false;
  String _nextInstruction = '';
  final int _currentRouteIndex = 0;
  Timer? _instructionTimer;
  
  // Building info sheet
  AnimationController? _infoSheetController;
  late Animation<double> _infoSheetAnimation;
  bool _isInfoSheetExpanded = false;
  final double _collapsedSheetHeight = 8.0; // Just the handle
  final double _expandedSheetHeight = 400.0; // Full info card
  
  // Music player
  AnimationController? _musicController;
  late Animation<double> _musicExpandAnimation;
  bool _musicExpanded = false;
  bool _musicPlaying = false;
  String _currentSong = '';
  String _currentArtist = '';
  List<Map<String, String>> _searchResults = [];
  final String _currentLocationName = 'Your Location';
  bool _isNearDestination = false;
  
  // Arrival state
  bool _hasShownArrivalDialog = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initCompass();
    _initializeTTS();
    _startInstructionUpdates();
    
    _infoSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _infoSheetAnimation = CurvedAnimation(
      parent: _infoSheetController!,
      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
    );
    
    _musicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _musicExpandAnimation = CurvedAnimation(
      parent: _musicController!,
      curve: Curves.elasticOut,
    );
  }
  
  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _userHeading = event.heading!;
          // Auto-rotate map based on heading during navigation
          _mapBearing = _userHeading;
        });
        _mapController.rotate(_mapBearing);
      }
    });
  }
  
  Future<void> _initializeTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }
  
  void _startInstructionUpdates() {
    _instructionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _generateNextInstruction();
    });
  }
  
  void _generateNextInstruction() {
    if (_currentLocation == null || widget.routePoints.length < 2) return;
    
    if (_currentRouteIndex + 1 < widget.routePoints.length) {
      final nextPoint = widget.routePoints[_currentRouteIndex + 1];
      final distance = const Distance();
      final distToNext = distance.distance(_currentLocation!, nextPoint);
      
      setState(() {
        _nextInstruction = _getDirectionInstruction(distToNext);
      });
      
      if (_ttsEnabled) {
        _speakInstruction(_nextInstruction);
      }
    }
  }
  
  String _getDirectionInstruction(double distance) {
    if (distance < 10) {
      return "Arriving at destination in ${distance.toInt()} meters";
    } else if (distance < 50) {
      return "Continue straight for ${distance.toInt()} meters";
    } else if (distance < 100) {
      return "Turn right in ${distance.toInt()} meters";
    } else {
      return "Continue on current path";
    }
  }
  
  Future<void> _speakInstruction(String instruction) async {
    await _tts.speak(instruction);
  }
  
  void _checkForDestinationArrival() {
    if (_remainingDistance == null) return;
    
    // Smart audio management: lower music when within 200m
    if (_remainingDistance! < 200 && _remainingDistance! > 50) {
      if (!_isNearDestination) {
        _isNearDestination = true;
        _lowerMusicVolume();
        if (_ttsEnabled) {
          _tts.speak('You are getting closer to your destination');
        }
      }
    }
    
    // Show arrival dialog when within 10m
    if (_remainingDistance! < 10 && !_hasShownArrivalDialog) {
      _hasShownArrivalDialog = true;
      _showArrivalDialog();
      _pauseMusic();
    }
  }
  
  Future<void> _lowerMusicVolume() async {
    if (_musicPlaying) {
      await _audioPlayer.setVolume(0.5); // Max 50% volume
    }
  }
  
  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 12),
                  const Text('Arrived?'),
                ],
              ),
              content: Text(
                'Have you reached ${widget.destinationBuilding?.name ?? "your destination"}?',
                style: GoogleFonts.notoSans(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _hasShownArrivalDialog = false);
                    Navigator.pop(ctx);
                  },
                  child: Text('Not Yet', style: GoogleFonts.notoSans(color: AppColors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    showAnimatedSuccess(
                      context,
                      'Navigation completed! 🎉',
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Yes, Arrived', style: GoogleFonts.notoSans(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _toggleView() {
    setState(() {
      _is3DView = !_is3DView;
    });
    
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, _is3DView ? 19.0 : 17.0);
    }
  }
  
  void _toggleTTS() {
    setState(() {
      _ttsEnabled = !_ttsEnabled;
    });
    
    if (_ttsEnabled && _nextInstruction.isNotEmpty) {
      _speakInstruction(_nextInstruction);
    }
  }
  
  void _toggleInfoSheet() {
    if (_infoSheetController!.isAnimating) return;
    
    if (_infoSheetController!.isCompleted) {
      _infoSheetController!.reverse();
    } else {
      _infoSheetController!.forward();
    }
  }
  
  void _toggleMusicPlayer() {
    setState(() {
      _musicExpanded = !_musicExpanded;
    });
    
    if (_musicExpanded) {
      _musicController?.forward();
    } else {
      _musicController?.reverse();
    }
  }
  
  void _searchMusic(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    // Simulated music search results - integrate real API later
    setState(() {
      _searchResults = [
        {'title': 'Shape of You', 'artist': 'Ed Sheeran', 'duration': '3:53'},
        {'title': 'Blinding Lights', 'artist': 'The Weeknd', 'duration': '3:20'},
        {'title': 'Dance Monkey', 'artist': 'Tones and I', 'duration': '3:29'},
        {'title': 'Levitating', 'artist': 'Dua Lipa', 'duration': '3:23'},
        {'title': 'Watermelon Sugar', 'artist': 'Harry Styles', 'duration': '2:54'},
        {'title': 'Circles', 'artist': 'Post Malone', 'duration': '3:35'},
        {'title': 'Sunflower', 'artist': 'Post Malone, Swae Lee', 'duration': '2:38'},
        {'title': 'Someone You Loved', 'artist': 'Lewis Capaldi', 'duration': '3:02'},
      ].where((song) =>
        song['title']!.toLowerCase().contains(query.toLowerCase()) ||
        song['artist']!.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }
  
  Future<void> _playSong(String title, String artist) async {
    setState(() {
      _currentSong = title;
      _currentArtist = artist;
      _musicPlaying = true;
    });
    
    // Reset volume to normal when manually playing
    if (!_isNearDestination) {
      await _audioPlayer.setVolume(1.0);
    }
    
    // In real implementation, load and play audio from streaming API
    debugPrint('Playing: $title by $artist');
  }
  
  Future<void> _pauseMusic() async {
    setState(() {
      _musicPlaying = false;
    });
    await _audioPlayer.pause();
  }
  
  void _toggleMusic() {
    if (_musicPlaying) {
      _pauseMusic();
    } else {
      _audioPlayer.play();
      setState(() => _musicPlaying = true);
    }
  }
  
  void _shareLiveLocation() {
    if (_currentLocation != null) {
      final lat = _currentLocation!.latitude;
      final lng = _currentLocation!.longitude;
      final mapUrl = 'https://www.google.com/maps?q=$lat,$lng';
      Share.share(
        'I\'m currently at: $mapUrl\nTracking live to ${widget.destinationBuilding?.name ?? "destination"}',
        subject: 'Live Location Share',
      );
    }
  }

  Future<void> _initLocation() async {
    try {
      // Get initial position with highest accuracy
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ),
      );
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      
      // Stream position updates with highest accuracy
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1, // Update every 1 meter
        timeLimit: Duration(seconds: 10),
      );
      
      _posSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((p) {
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
    _compassSub?.cancel();
    _instructionTimer?.cancel();
    _infoSheetController?.dispose();
    _musicController?.dispose();
    _musicSearchController.dispose();
    _audioPlayer.dispose();
    _tts.stop();
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
    
    // Check if arrived
    _checkForDestinationArrival();
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

  IconData _getTransportIcon() {
    switch (widget.transportMode) {
      case 'bicycle':
        return Icons.directions_bike;
      case 'car':
        return Icons.directions_car;
      case 'bus':
        return Icons.directions_bus;
      default:
        return Icons.directions_walk;
    }
  }
  
  String _getTransportModeName() {
    switch (widget.transportMode) {
      case 'bicycle':
        return 'Cycling';
      case 'car':
        return 'Driving';
      case 'bus':
        return 'Transit';
      default:
        return 'Walking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Stack(
        children: [
          // Map with route
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? widget.routePoints.first,
              initialZoom: _is3DView ? 19.0 : 17.0,
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
                      color: AppColors.primary,
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
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing blue glow
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Inner blue dot
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        // Direction arrow (rotates with device heading)
                        Transform.rotate(
                          angle: (_userHeading) * 3.141592653589793 / 180.0,
                          child: Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 24,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Marker(
                  point: widget.destination,
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.place_rounded,
                    color: AppColors.error,
                    size: 48,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ])
            ],
          ),

          // Top control buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Exit button
                  _buildControlButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                    tooltip: 'Exit Navigation',
                  ),
                  const Spacer(),
                  // 3D/2D toggle
                  _buildControlButton(
                    icon: _is3DView ? Icons.layers_rounded : Icons.threed_rotation_rounded,
                    onTap: () {
                      setState(() => _is3DView = !_is3DView);
                      _mapController.move(_currentLocation ?? widget.routePoints.first, _is3DView ? 19.0 : 17.0);
                    },
                    tooltip: _is3DView ? '2D View' : '3D View',
                  ),
                  const SizedBox(width: 8),
                  // TTS toggle
                  _buildControlButton(
                    icon: _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    onTap: () {
                      setState(() => _ttsEnabled = !_ttsEnabled);
                      if (_ttsEnabled && _nextInstruction.isNotEmpty) {
                        _speakInstruction(_nextInstruction);
                      }
                    },
                    tooltip: 'Voice Instructions',
                    isActive: _ttsEnabled,
                  ),
                ],
              ),
            ),
          ),

          // Curved navigation info sheet at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildNavigationSheet(context),
          ),

          // Floating building info sheet (handle at very bottom)
          if (widget.destinationBuilding != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 180,
              child: _buildFloatingInfoSheet(context),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.primary : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primary : Colors.grey.shade700,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationSheet(BuildContext context) {
    final destination = widget.destinationBuilding?.name ?? 'Destination';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTransportIcon(),
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location → $destination',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.near_me_rounded, size: 14, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _remainingDistance != null
                              ? '${(_remainingDistance! / 1000).toStringAsFixed(1)} km'
                              : 'Calculating...',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.schedule_rounded, size: 14, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _etaSeconds > 0
                              ? '${(_etaSeconds / 60).ceil()} min'
                              : 'Calculating...',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingInfoSheet(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isInfoSheetExpanded = !_isInfoSheetExpanded;
        });
        if (_isInfoSheetExpanded) {
          _infoSheetController?.forward();
        } else {
          _infoSheetController?.reverse();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: _isInfoSheetExpanded ? _expandedSheetHeight : 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            if (_isInfoSheetExpanded) ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Building placeholder image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.primary.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(Icons.domain_rounded, size: 60, color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Building name
                      Text(
                        widget.destinationBuilding?.name ?? 'Destination',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Description
                      if (widget.destinationBuilding?.description != null)
                        Text(
                          widget.destinationBuilding!.description!,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: AppColors.grey,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Transport mode
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getTransportIcon(), size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _getTransportModeName(),
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
