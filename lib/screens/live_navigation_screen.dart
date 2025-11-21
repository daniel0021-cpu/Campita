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
  late Animation<double> _infoSheetAnimation;
  bool _isInfoSheetExpanded = false;
  final double _collapsedSheetHeight = 8.0; // Just the handle
  final double _expandedSheetHeight = 400.0; // Full info card
  
  // Music player - enhanced with smooth animations
  AnimationController? _musicController;
  AnimationController? _musicSearchController;
  late Animation<double> _musicExpandAnimation;
  late Animation<double> _musicSearchAnimation;
  late Animation<Offset> _musicSlideAnimation;
  bool _musicExpanded = false;
  bool _musicSearchExpanded = false;
  bool _musicPlaying = false;
  String _currentSong = '';
  String _currentArtist = '';
  List<Map<String, String>> _searchResults = [];
  List<Map<String, String>> _allSongs = [];
  final String _currentLocationName = 'Your Location';
  bool _isNearDestination = false;
  double _currentSongProgress = 0.0;
  Timer? _songProgressTimer;
  
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
    _songProgressTimer?.cancel();
    _infoSheetController?.dispose();
    _musicController?.dispose();
    _musicSearchController?.dispose();
    _musicSearchTextController.dispose();
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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_navigation',
                additionalOptions: const {
                  'attribution': 'Stadia Maps',
                },
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
                  const SizedBox(width: 8),
                  // Music player button - removed from top (now in center-right)
                  // See _buildFloatingMusicButton() for new implementation
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

          // Floating music player (center-right)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 30,
            child: MusicPlayerSheet(),
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
