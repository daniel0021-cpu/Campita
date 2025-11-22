import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async' as async;
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
import '../widgets/music_player_sheet.dart';

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
  final TextEditingController _musicSearchTextController = TextEditingController();
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
  bool _isInfoSheetExpanded = false;
  final double _expandedSheetHeight = 400.0; // Full info card
  
  // Music player - enhanced with smooth animations
  AnimationController? _musicController;
  AnimationController? _musicSearchController;
  late Animation<double> _musicSearchAnimation;
  late Animation<Offset> _musicSlideAnimation;
  bool _musicExpanded = false;
  bool _musicSearchExpanded = false;
  bool _musicPlaying = false;
  String _currentSong = '';
  String _currentArtist = '';
  List<Map<String, String>> _searchResults = [];
  List<Map<String, String>> _allSongs = [];
  bool _isNearDestination = false;
  double _currentSongProgress = 0.0;
  Timer? _songProgressTimer;
  
  // Arrival state
  bool _hasShownArrivalDialog = false;
  
  // Music sheet expansion state
  bool _isMusicSheetExpanded = false;
  
  // 3D tilt view control state
  bool _is3DTiltView = false;
  bool _isTilting = false;
  
  // OSM turn directions with auto-slide
  List<Map<String, dynamic>> _osmDirections = [];
  PageController? _directionsPageController;
  int _currentDirectionIndex = 0;
  
  // Destination building carousel
  PageController? _destinationCarouselController;
  int _destinationCarouselIndex = 0;
  
  // Real-time arrival tracking
  DateTime? _estimatedArrivalTime;
  
  // Map dragging control
  bool _userIsDraggingMap = false;
  Timer? _resetDraggingTimer;
  
  // Gyroscope rotation
  async.StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  double _deviceRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initCompass();
    _initializeTTS();
    _startInstructionUpdates();
    _initGyroscope();
    
    _infoSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _musicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    
    _musicSearchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _musicSearchAnimation = CurvedAnimation(
      parent: _musicSearchController!,
      curve: const Cubic(0.25, 0.8, 0.25, 1.0),
    );
    _musicSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_musicSearchAnimation);
    
    // Extract OSM-based turn directions from route
    _extractOsmDirections();
    
    // Initialize directions carousel controller
    _directionsPageController = PageController(initialPage: 0);
    
    // Initialize destination carousel controller
    _destinationCarouselController = PageController(initialPage: 0);
    
    // Preload song library with diverse collection
    _allSongs = [
      {'title': 'Shape of You', 'artist': 'Ed Sheeran', 'duration': '3:53', 'url': 'https://example.com/song1.mp3'},
      {'title': 'Blinding Lights', 'artist': 'The Weeknd', 'duration': '3:20', 'url': 'https://example.com/song2.mp3'},
      {'title': 'Dance Monkey', 'artist': 'Tones and I', 'duration': '3:29', 'url': 'https://example.com/song3.mp3'},
      {'title': 'Levitating', 'artist': 'Dua Lipa', 'duration': '3:23', 'url': 'https://example.com/song4.mp3'},
      {'title': 'Watermelon Sugar', 'artist': 'Harry Styles', 'duration': '2:54', 'url': 'https://example.com/song5.mp3'},
      {'title': 'Circles', 'artist': 'Post Malone', 'duration': '3:35', 'url': 'https://example.com/song6.mp3'},
      {'title': 'Sunflower', 'artist': 'Post Malone, Swae Lee', 'duration': '2:38', 'url': 'https://example.com/song7.mp3'},
      {'title': 'Someone You Loved', 'artist': 'Lewis Capaldi', 'duration': '3:02', 'url': 'https://example.com/song8.mp3'},
      {'title': 'Starboy', 'artist': 'The Weeknd', 'duration': '3:50', 'url': 'https://example.com/song9.mp3'},
      {'title': 'Perfect', 'artist': 'Ed Sheeran', 'duration': '4:23', 'url': 'https://example.com/song10.mp3'},
      {'title': 'Senorita', 'artist': 'Shawn Mendes, Camila Cabello', 'duration': '3:11', 'url': 'https://example.com/song11.mp3'},
      {'title': 'Bad Guy', 'artist': 'Billie Eilish', 'duration': '3:14', 'url': 'https://example.com/song12.mp3'},
      {'title': 'Happier', 'artist': 'Marshmello, Bastille', 'duration': '3:34', 'url': 'https://example.com/song13.mp3'},
      {'title': 'Thunder', 'artist': 'Imagine Dragons', 'duration': '3:07', 'url': 'https://example.com/song14.mp3'},
      {'title': 'Lovely', 'artist': 'Billie Eilish, Khalid', 'duration': '3:20', 'url': 'https://example.com/song15.mp3'},
    ];
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
  
  void _initGyroscope() {
    _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          // Use Z-axis rotation (rotation around vertical axis)
          _deviceRotation += event.z * 0.5; // Adjust sensitivity
          // Keep rotation in 0-360 range
          _deviceRotation = _deviceRotation % 360;
          if (_deviceRotation < 0) _deviceRotation += 360;
        });
        // Smoothly rotate map to match device rotation
        _mapController.rotate(-_deviceRotation);
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
                        colors: [AppColors.primary, AppColors.primary.withAlpha(179)],
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
  
  // Extract turn-by-turn directions from OSM route points
  void _extractOsmDirections() {
    if (widget.routePoints.length < 2) {
      _osmDirections = _getMockDirections();
      return;
    }
    
    final directions = <Map<String, dynamic>>[];
    double accumulatedDistance = 0;
    
    for (int i = 0; i < widget.routePoints.length - 1; i++) {
      final current = widget.routePoints[i];
      final next = widget.routePoints[i + 1];
      final distance = const Distance().distance(current, next);
      accumulatedDistance += distance;
      
      // Determine turn type based on bearing change
      if (i > 0) {
        final prev = widget.routePoints[i - 1];
        final bearing1 = _calculateBearing(prev, current);
        final bearing2 = _calculateBearing(current, next);
        final angle = (bearing2 - bearing1).abs();
        
        if (angle > 45 && angle < 135) {
          directions.add({
            'icon': angle > 90 ? Icons.turn_right_rounded : Icons.turn_slight_right_rounded,
            'text': angle > 90 ? 'Turn right' : 'Bear right',
            'distance': _formatDistanceShort(accumulatedDistance),
          });
          accumulatedDistance = 0;
        } else if (angle > 225 && angle < 315) {
          directions.add({
            'icon': angle > 270 ? Icons.turn_left_rounded : Icons.turn_slight_left_rounded,
            'text': angle > 270 ? 'Turn left' : 'Bear left',
            'distance': _formatDistanceShort(accumulatedDistance),
          });
          accumulatedDistance = 0;
        }
      }
      
      // Add waypoint every 200m if no turn
      if (accumulatedDistance > 200 && i < widget.routePoints.length - 2) {
        directions.add({
          'icon': Icons.straight_rounded,
          'text': 'Continue straight',
          'distance': _formatDistanceShort(accumulatedDistance),
        });
        accumulatedDistance = 0;
      }
    }
    
    // Final destination
    directions.add({
      'icon': Icons.place_rounded,
      'text': 'Arrive at destination',
      'distance': _formatDistanceShort(accumulatedDistance),
    });
    
    setState(() {
      _osmDirections = directions.isEmpty ? _getMockDirections() : directions;
    });
  }
  
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * (3.14159265359 / 180);
    final lat2 = to.latitude * (3.14159265359 / 180);
    final dLon = (to.longitude - from.longitude) * (3.14159265359 / 180);
    
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * (180 / 3.14159265359);
    
    return (bearing + 360) % 360;
  }
  
  String _formatDistanceShort(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
  
  List<Map<String, dynamic>> _getMockDirections() {
    return [
      {'icon': Icons.straight_rounded, 'text': 'Continue straight', 'distance': '200m'},
      {'icon': Icons.turn_right_rounded, 'text': 'Turn right at Main Gate', 'distance': '500m'},
      {'icon': Icons.place_rounded, 'text': 'Arrive at destination', 'distance': '800m'},
    ];
  }
  
  // Toggle 3D tilt view with smooth animations
  Future<void> _toggle3DTiltView() async {
    if (_isTilting) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isTilting = true;
      _is3DTiltView = !_is3DTiltView;
    });
    
    try {
      final currentLocation = _currentLocation ?? widget.routePoints.first;
      final targetZoom = _is3DTiltView ? 19.0 : 15.0;
      final targetRotation = _is3DTiltView ? 45.0 : 0.0;
      
      // Smooth animation: zoom + rotate simultaneously
      final startZoom = _mapController.camera.zoom;
      final startRotation = _mapController.camera.rotation;
      const steps = 20;
      const duration = Duration(milliseconds: 350);
      final stepDuration = duration.inMilliseconds ~/ steps;
      
      for (int i = 0; i <= steps; i++) {
        final t = Curves.easeInOutCubic.transform(i / steps);
        final zoom = startZoom + ((targetZoom - startZoom) * t);
        final rotation = startRotation + ((targetRotation - startRotation) * t);
        
        _mapController.move(currentLocation, zoom);
        _mapController.rotate(rotation);
        
        await Future.delayed(Duration(milliseconds: stepDuration));
      }
    } finally {
      if (mounted) {
        setState(() => _isTilting = false);
      }
    }
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
      // Check and request location permissions first (critical for mobile)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        return;
      }
      
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
        // Only auto-center if user hasn't manually moved the map recently
        if (!_userIsDraggingMap) {
          _mapController.move(loc, _mapController.camera.zoom);
        }
      });
      _updateStats();
    } catch (_) {}
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _compassSub?.cancel();
    _instructionTimer?.cancel();
    _songProgressTimer?.cancel();
    _resetDraggingTimer?.cancel();
    _infoSheetController?.dispose();
    _musicController?.dispose();
    _musicSearchController?.dispose();
    _musicSearchTextController.dispose();
    _directionsPageController?.dispose();
    _destinationCarouselController?.dispose();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  void _updateStats() {
    if (_currentLocation == null) return;
    // Calculate remaining distance from current location along route
    double dist = 0;
    LatLng prev = _currentLocation!;
    for (final p in widget.routePoints) {
      dist += const Distance().distance(prev, p);
      prev = p;
    }
    dist += const Distance().distance(prev, widget.destination);
    _remainingDistance = dist;
    
    // Calculate ETA based on transport mode speed
    final speed = _modeSpeed(widget.transportMode);
    _etaSeconds = dist / speed;
    
    // Calculate actual arrival time (current time + ETA)
    _estimatedArrivalTime = DateTime.now().add(Duration(seconds: _etaSeconds.toInt()));
    
    // Auto-advance directions carousel based on proximity to turn points
    _updateDirectionCarousel();
    
    setState(() {});
    
    // Check if arrived
    _checkForDestinationArrival();
  }
  
  // Auto-advance carousel when user reaches each turn
  void _updateDirectionCarousel() {
    if (_currentLocation == null || _osmDirections.isEmpty) return;
    if (_directionsPageController == null || !_directionsPageController!.hasClients) return;
    
    // Check distance to next direction point
    if (_currentDirectionIndex < _osmDirections.length) {
      final nextDirection = _osmDirections[_currentDirectionIndex];
      final targetLocation = nextDirection['location'] as LatLng?;
      
      if (targetLocation != null) {
        final distanceToTurn = const Distance().distance(_currentLocation!, targetLocation);
        
        // Auto-advance when within 20 meters of turn point
        if (distanceToTurn < 20 && _currentDirectionIndex < _osmDirections.length - 1) {
          setState(() {
            _currentDirectionIndex++;
          });
          
          // Smoothly animate to next page
          _directionsPageController!.animateToPage(
            _currentDirectionIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
          
          // Haptic feedback for turn arrival
          HapticFeedback.mediumImpact();
          
          // Speak next instruction if TTS enabled
          if (_ttsEnabled && _currentDirectionIndex < _osmDirections.length) {
            final instruction = _osmDirections[_currentDirectionIndex]['text'] as String;
            _tts.speak(instruction);
          }
        }
      }
    }
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
  
  String _formatArrivalTime() {
    if (_estimatedArrivalTime == null) return '...';
    final hour = _estimatedArrivalTime!.hour;
    final minute = _estimatedArrivalTime!.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
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

  // Floating music button on center-right that expands horizontally
  Widget _buildFloatingMusicButton(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Positioned(
      right: 16,
      top: screenHeight / 2 - 28,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _musicSearchExpanded = !_musicSearchExpanded;
          });
          if (_musicSearchExpanded) {
            _musicSearchController?.forward();
          } else {
            _musicSearchController?.reverse();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: const Cubic(0.34, 1.56, 0.64, 1.0),
          width: _musicSearchExpanded ? 260 : 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _musicPlaying 
                  ? [const Color(0xFFE91E63), const Color(0xFFF48FB1)]
                  : [AppColors.primary, AppColors.primary.withAlpha(204)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (_musicPlaying ? const Color(0xFFE91E63) : AppColors.primary).withAlpha(102),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: _musicSearchExpanded
              ? Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      _musicPlaying ? Icons.music_note_rounded : Icons.music_note_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: _musicSearchTextController,
                          onChanged: (query) {
                            setState(() {
                              if (query.isEmpty) {
                                _searchResults = [];
                              } else {
                                _searchResults = _allSongs.where((song) =>
                                  song['title']!.toLowerCase().contains(query.toLowerCase()) ||
                                  song['artist']!.toLowerCase().contains(query.toLowerCase())
                                ).toList();
                              }
                            });
                          },
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search music...',
                            hintStyle: GoogleFonts.notoSans(
                              color: Colors.white.withAlpha(179),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : Icon(
                  _musicPlaying ? Icons.music_note_rounded : Icons.music_note_outlined,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ),
    );
  }
  
  // Beautiful rounded floating sheet for music search results
  Widget _buildMusicSearchSheet(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _musicSlideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFFE91E63), const Color(0xFFF48FB1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Music Library',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_allSongs.length} songs available',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _musicSearchExpanded = false;
                        });
                        _musicSearchController?.reverse();
                      },
                      icon: const Icon(Icons.close_rounded, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Song list
              Expanded(
                child: _searchResults.isEmpty && _musicSearchTextController.text.isEmpty
                    ? _buildAllSongsList()
                    : _searchResults.isEmpty
                        ? _buildNoResultsWidget()
                        : _buildSearchResultsList(),
              ),
              
              // Now playing bar (if song is playing)
              if (_musicPlaying) _buildNowPlayingBar(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAllSongsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _allSongs.length,
      itemBuilder: (context, index) {
        return _buildSongTile(_allSongs[index], index);
      },
    );
  }
  
  Widget _buildSearchResultsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSongTile(_searchResults[index], index);
      },
    );
  }
  
  Widget _buildSongTile(Map<String, String> song, int index) {
    final isCurrentSong = _currentSong == song['title'] && _currentArtist == song['artist'];
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isCurrentSong 
              ? const Color(0xFFE91E63).withAlpha(26)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentSong 
                ? const Color(0xFFE91E63).withAlpha(77)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await _playSongFromLibrary(song['title']!, song['artist']!, song['url']!);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Album art placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color((index * 50) % 360).withAlpha(204),
                          Color((index * 80) % 360).withAlpha(153),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCurrentSong && _musicPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song['title']!,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w600,
                            color: isCurrentSong ? const Color(0xFFE91E63) : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song['artist']!,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Duration
                  Text(
                    song['duration']!,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Playing indicator
                  if (isCurrentSong && _musicPlaying)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Color(0xFFE91E63),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No songs found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different keyword',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNowPlayingBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE91E63), const Color(0xFFF48FB1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Album art
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          
          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentSong,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _currentArtist,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: Colors.white.withAlpha(204),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Play/Pause button
          Material(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              onTap: _togglePlayPause,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _musicPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _playSongFromLibrary(String title, String artist, String url) async {
    // If same song, toggle play/pause
    if (_currentSong == title && _currentArtist == artist) {
      _togglePlayPause();
      return;
    }
    
    setState(() {
      _currentSong = title;
      _currentArtist = artist;
      _musicPlaying = true;
      _currentSongProgress = 0.0;
    });
    
    // Start song progress timer
    _songProgressTimer?.cancel();
    _songProgressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_musicPlaying && mounted) {
        setState(() {
          _currentSongProgress += 1.0 / 180.0; // Assume 3min songs
          if (_currentSongProgress >= 1.0) {
            _currentSongProgress = 0.0;
            // Auto-play next song
          }
        });
      }
    });
    
    // Reset volume to normal when manually playing (not near destination)
    if (!_isNearDestination) {
      await _audioPlayer.setVolume(1.0);
    }
    
    // In production, load actual audio from URL
    debugPrint('Now playing: $title by $artist from $url');
  }
  
  void _togglePlayPause() {
    setState(() {
      _musicPlaying = !_musicPlaying;
    });
    
    if (_musicPlaying) {
      _audioPlayer.play();
    } else {
      _audioPlayer.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Stack(
        children: [
          // Map with route
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? widget.routePoints.first,
              initialZoom: _is3DView ? 19.0 : 17.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  // User is dragging the map
                  setState(() => _userIsDraggingMap = true);
                  // Reset after 5 seconds of no interaction
                  _resetDraggingTimer?.cancel();
                  _resetDraggingTimer = Timer(const Duration(seconds: 5), () {
                    if (mounted) {
                      setState(() => _userIsDraggingMap = false);
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.campus_navigation',
                maxZoom: 19,
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
                    width: 80,
                    height: 80,
                    child: Transform.rotate(
                      angle: _deviceRotation * 3.141592653589793 / 180.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer pulsing glow (Apple-style)
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            tween: Tween(begin: 0.8, end: 1.2),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                            onEnd: () {
                              if (mounted) setState(() {});
                            },
                          ),
                          // Middle glow
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Inner circle (Apple blue)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF007AFF).withValues(alpha: 0.6),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          // Direction chevron (Apple-style)
                          Positioned(
                            top: 0,
                            child: Transform.rotate(
                              angle: (_userHeading - _deviceRotation) * 3.141592653589793 / 180.0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Marker(
                  point: widget.destination,
                  width: 44,
                  height: 54,
                  alignment: Alignment.topCenter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shadow
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      // Apple-style pin
                      Positioned(
                        top: 0,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFF3B30),
                                    Color(0xFFDC143C),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(8, 12),
                              painter: _PinTailPainter(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ])
            ],
          ),

          // Top directions carousel - swipeable turn-by-turn with OSM data
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildDirectionsCarousel(),
          ),

          // Right-side controls (3D tilt button)
          Positioned(
            top: MediaQuery.of(context).padding.top + 120,
            right: 16,
            child: Column(
              children: [
                // 3D Tilt toggle button with advanced animations
                _build3DTiltButton(),
              ],
            ),
          ),

          // Floating navigation button/sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
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

          // Floating music player (center-right) with proper error handling
          Positioned(
            right: 16,
            bottom: 240,
            child: Builder(
              key: const ValueKey('music_player_builder'),
              builder: (context) {
                return RepaintBoundary(
                  key: const ValueKey('music_player'),
                  child: MusicPlayerSheet(
                    key: const ValueKey('music_sheet'),
                    onExpandedChanged: (isExpanded) {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _isMusicSheetExpanded = isExpanded);
                          }
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // Modern TTS control button (right side, above music) - hide when music is expanded
          if (!_isMusicSheetExpanded)
            Positioned(
              right: 16,
              bottom: 330,
              child: _buildModernTTSButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildModernTTSButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.8 + (0.2 * clampedValue),
          child: Opacity(
            opacity: clampedValue,
            child: child,
          ),
        );
      },
      child: AnimatedScale(
        scale: _ttsEnabled ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuart,
        child: Material(
          elevation: _ttsEnabled ? 12 : 6,
          shadowColor: _ttsEnabled 
            ? AppColors.primary.withAlpha(128) 
            : Colors.black.withAlpha(isDark ? 64 : 32),
          borderRadius: BorderRadius.circular(20),
          color: _ttsEnabled 
            ? AppColors.primary 
            : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              _toggleTTS();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutQuart,
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _ttsEnabled
                    ? Colors.transparent
                    : (isDark ? Colors.white.withAlpha(26) : Colors.black.withAlpha(13)),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _ttsEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
                color: _ttsEnabled 
                  ? Colors.white 
                  : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Get color for turn type
  Color _getTurnColor(IconData icon) {
    if (icon == Icons.turn_right_rounded || icon == Icons.turn_sharp_right_rounded) {
      return const Color(0xFF2196F3); // Blue for right turns
    } else if (icon == Icons.turn_left_rounded || icon == Icons.turn_sharp_left_rounded) {
      return const Color(0xFF9C27B0); // Purple for left turns
    } else if (icon == Icons.turn_slight_right_rounded) {
      return const Color(0xFF00BCD4); // Cyan for slight right
    } else if (icon == Icons.turn_slight_left_rounded) {
      return const Color(0xFF673AB7); // Deep purple for slight left
    } else if (icon == Icons.place_rounded) {
      return const Color(0xFFFF3B30); // Red for destination
    } else {
      return const Color(0xFF4CAF50); // Green for straight
    }
  }
  
  // Building image carousel with animated indicators
  int _carouselIndex = 0;
  
  Widget _buildBuildingCarousel() {
    final building = widget.destinationBuilding!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mock images - replace with actual building images
    final images = [
      'assets/buildings/danny.jpeg',
      'assets/buildings/danny.jpeg',
      'assets/buildings/danny.jpeg',
    ];
    
    return Column(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _carouselIndex = index);
              },
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withAlpha(180),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 48,
                              color: Colors.white.withAlpha(128),
                            ),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(77),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Building name at bottom
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        building.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(128),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Animated carousel indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            final isActive = _carouselIndex == index;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : (isDark ? Colors.white.withAlpha(77) : Colors.black.withAlpha(51)),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(102),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
  
  // Destination image carousel for navigation sheet with 3D animated indicators
  Widget _buildDestinationImageCarousel(bool isDark) {
    final building = widget.destinationBuilding!;
    
    // Mock images - replace with actual building images from assets or network
    final images = [
      'assets/buildings/danny.jpeg',
      'assets/buildings/danny.jpeg',
      'assets/buildings/danny.jpeg',
    ];
    
    return Column(
      children: [
        // PageView carousel with smooth animations
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(51),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _destinationCarouselController,
              physics: const BouncingScrollPhysics(),
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _destinationCarouselIndex = index;
                });
                HapticFeedback.lightImpact();
              },
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: Opacity(
                        opacity: 0.7 + (0.3 * value),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Building image
                      Image.asset(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withAlpha(51),
                                  AppColors.primary.withAlpha(26),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.business_rounded,
                              size: 48,
                              color: AppColors.primary.withAlpha(128),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(179),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Building name at bottom
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              building.name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(128),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Colors.white.withAlpha(204),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  building.category.toString().split('.').last.toUpperCase(),
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withAlpha(204),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 3D Animated Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            final isActive = _destinationCarouselIndex == index;
            final distance = (_destinationCarouselIndex - index).abs();
            
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) {
                // 3D scale effect based on distance from active indicator
                final scale = isActive ? (0.9 + (0.1 * value)) : (0.5 - (distance * 0.1));
                
                return Transform.scale(
                  scale: scale.clamp(0.3, 1.0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 32 : 10,
                    height: isActive ? 10 : 10,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withAlpha(179),
                              ],
                            )
                          : null,
                      color: !isActive
                          ? (isDark ? Colors.white.withAlpha(77) : Colors.black.withAlpha(77))
                          : null,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(128),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // Smooth zoom toggle button with buttery 200ms animation
  Widget _build3DTiltButton() {
    final isActive = _is3DTiltView;
    
    return Tooltip(
      message: isActive ? 'Exit 3D Tilt' : '3D Tilt View',
      child: TweenAnimationBuilder<double>(
        key: const ValueKey('3d_tilt_button'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.92 + (0.08 * value),
            child: Opacity(
              opacity: 0.7 + (0.3 * value),
              child: child,
            ),
          );
        },
        child: Material(
          color: isActive 
              ? const Color(0xFF7C3AED).withAlpha((0.15 * 255).toInt())
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: isActive ? 8 : 4,
          child: InkWell(
            onTap: _isTilting ? null : _toggle3DTiltView,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive 
                    ? const Color(0xFF7C3AED).withAlpha((0.1 * 255).toInt())
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? const Color(0xFF7C3AED) : Colors.grey.shade300,
                  width: isActive ? 2.5 : 2,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withAlpha((0.3 * 255).toInt()),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _isTilting ? 1 : 0),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      builder: (context, animValue, child) {
                        return Transform.rotate(
                          angle: animValue * 3.14159 / 4, // 45 degrees rotation
                          child: Icon(
                            isActive ? Icons.threed_rotation_rounded : Icons.view_in_ar_rounded,
                            color: isActive ? const Color(0xFF7C3AED) : Colors.grey.shade700,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  // Active indicator badge
                  if (isActive)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withAlpha((0.5 * 255).toInt()),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return GestureDetector(
      onTap: () {
        setState(() => _isInfoSheetExpanded = !_isInfoSheetExpanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          maxHeight: _isInfoSheetExpanded ? screenHeight * 0.6 : 56,
          minHeight: 56,
        ),
        decoration: BoxDecoration(
          gradient: _isInfoSheetExpanded
              ? LinearGradient(
                  colors: isDark
                      ? [AppColors.darkCard, AppColors.darkCard.withAlpha(230)]
                      : [Colors.white, Colors.grey[50]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(230),
                  ],
                ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(_isInfoSheetExpanded ? 77 : 153),
              blurRadius: _isInfoSheetExpanded ? 24 : 20,
              spreadRadius: _isInfoSheetExpanded ? 2 : 3,
            ),
          ],
        ),
        child: _isInfoSheetExpanded
            ? _buildExpandedNavigationContent(destination, isDark)
            : _buildCollapsedGlowingLine(),
      ),
    );
  }

  Widget _buildCollapsedGlowingLine() {
    final destination = widget.destinationBuilding?.name ?? 'Destination';
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 400;
            
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha((204 + value * 51).toInt()),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha((128 + value * 77).toInt()),
                    blurRadius: 16 + (value * 8),
                    spreadRadius: 2 + (value * 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Transport mode icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTransportIcon(),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Destination name
                  Expanded(
                    child: Text(
                      destination,
                      style: GoogleFonts.notoSans(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Distance icon + value
                  if (_remainingDistance != null && !isCompact) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.straighten_rounded,
                      color: Colors.white.withAlpha(204),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(_remainingDistance! / 1000).toStringAsFixed(1)}km',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                  
                  // ETA icon + value
                  if (_etaSeconds > 0) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withAlpha(204),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(_etaSeconds / 60).ceil()}min',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                  
                  const SizedBox(width: 8),
                  Icon(
                    Icons.expand_less_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            );
          },
        );
      },
      onEnd: () {
        if (mounted && !_isInfoSheetExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {}); // Restart animation
            }
          });
        }
      },
    );
  }

  Widget _buildExpandedNavigationContent(String destination, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clampedValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - clampedValue)),
            child: child,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 400;
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Building image carousel with indicators
                if (widget.destinationBuilding != null) ...[
                  _buildBuildingCarousel(),
                  const SizedBox(height: 16),
                ],
                
                // Location route info with icons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(26),
                        AppColors.primary.withAlpha(13),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(51),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // From location
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withAlpha(77),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11,
                                    color: AppColors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Current Position',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getTransportIcon(),
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      
                      // Connecting line
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Container(
                              width: 2,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withAlpha(128),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Distance and ETA badges
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(13),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.straighten_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _remainingDistance != null
                                              ? '${(_remainingDistance! / 1000).toStringAsFixed(1)} km'
                                              : '...',
                                          style: GoogleFonts.notoSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(13),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 14,
                                          color: const Color(0xFFFF9800),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _etaSeconds > 0
                                              ? '${(_etaSeconds / 60).ceil()} min'
                                              : '...',
                                          style: GoogleFonts.notoSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // To destination
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3B30).withAlpha(77),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destination',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11,
                                    color: AppColors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destination,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Building image carousel (new)
                if (widget.destinationBuilding != null) ...[
                  Text(
                    'Destination Preview',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDestinationImageCarousel(isDark),
                  const SizedBox(height: 20),
                ],
                
                // Exit Navigation button with smooth animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutQuart,
                  builder: (context, animValue, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFF3B30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        // 3D exit animation
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => Container(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(animation),
                                child: Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateX(animation.value * 1.5)
                                    ..scale(1.0 - (animation.value * 0.3)),
                                  alignment: Alignment.center,
                                  child: Builder(builder: (context) => Container()),
                                ),
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 400),
                          ),
                        ).then((_) => Navigator.pop(context));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutQuart,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Exit Navigation',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          );
        },
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

  // New directions carousel widget for turn-by-turn swipeable instructions with OSM data
  Widget _buildDirectionsCarousel() {
    if (!mounted) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final directions = _osmDirections.isNotEmpty ? _osmDirections : _getMockDirections();
    
    return TweenAnimationBuilder<double>(
      key: const ValueKey('directions_carousel'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 77 : 26),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: PageView.builder(
            controller: _directionsPageController,
            itemCount: directions.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentDirectionIndex = index;
              });
            },
            itemBuilder: (context, index) {
              if (index >= directions.length) return const SizedBox.shrink();
              
              final direction = directions[index];
              final icon = direction['icon'] as IconData? ?? Icons.straight_rounded;
              
              // Get turn color for background
              final turnColor = _getTurnColor(icon);
              
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      turnColor.withAlpha((0.25 * 255).toInt()),
                      turnColor.withAlpha((0.15 * 255).toInt()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [turnColor, turnColor.withAlpha(180)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: turnColor.withAlpha(153),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              direction['text'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten_rounded,
                                  size: 14,
                                  color: turnColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  direction['distance'] as String,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: turnColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Page indicator dots
                      if (directions.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}/${directions.length}',
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Custom painter for Apple-style pin tail
class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDC143C)
      ..style = PaintingStyle.fill;

    final uiPath = ui.Path();
    uiPath.moveTo(size.width / 2, 0);
    uiPath.lineTo(0, size.height);
    uiPath.lineTo(size.width, size.height);
    uiPath.close();

    canvas.drawPath(uiPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
