import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  double? _remainingDistance;
  double _etaSeconds = 0;
  
  // Navigation features
  bool _is3DView = false;
  bool _ttsEnabled = false;
  String _nextInstruction = '';
  int _currentRouteIndex = 0;
  Timer? _instructionTimer;
  
  // Building info sheet
  AnimationController? _infoSheetController;
  late Animation<double> _infoSheetAnimation;
  
  // Music player
  AnimationController? _musicController;
  late Animation<double> _musicExpandAnimation;
  bool _musicExpanded = false;
  bool _musicPlaying = false;
  String _currentSong = '';
  String _currentArtist = '';
  List<Map<String, String>> _searchResults = [];
  String _currentLocationName = 'Your Location';
  bool _isNearDestination = false;
  
  // Arrival state
  bool _hasShownArrivalDialog = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
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
    return Scaffold(
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
