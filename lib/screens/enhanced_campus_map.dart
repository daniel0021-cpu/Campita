// Enhanced Campus Map with Google Maps-style features
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/campus_building.dart';
import '../theme/app_theme.dart';
import '../utils/osm_data_fetcher.dart';
import 'directions_screen.dart';
import 'route_preview_screen.dart';
import 'events_screen.dart' as events_screen;
 import '../utils/preferences_service.dart';
 import '../utils/live_events_service.dart';
 import '../widgets/live_events_banner.dart';
 import '../models/campus_event.dart';
 import '../utils/favorites_service.dart';
 import '../utils/app_settings.dart';
 import 'search_screen.dart';
 import 'subscription_screen.dart';
 import 'profile_screen.dart';
 import 'premium_profile_screen.dart';
 import 'favorites_screen.dart';
 import '../utils/app_routes.dart';
 import '../widgets/modern_navbar.dart';
 import '../widgets/building_detail_sheet.dart';
 import '../widgets/animated_success_card.dart';
 import '../models/map_style.dart';

class _Tuple {
  final double item1; // distanceMeters
  final double item2; // durationSeconds
  const _Tuple(this.item1, this.item2);
}

class EnhancedCampusMap extends StatefulWidget {
  final CampusBuilding? selectedBuilding;
  
  const EnhancedCampusMap({super.key, this.selectedBuilding});

  @override
  State<EnhancedCampusMap> createState() => _EnhancedCampusMapState();
}

class _EnhancedCampusMapState extends State<EnhancedCampusMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LatLng _campusCenter = const LatLng(6.7415, 5.4055);
  LatLng? _currentLocation;
  CampusBuilding? _selectedBuilding;
  
  // Entrance animations
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final List<AnimationController> _elementControllers = [];
  bool _animationsInitialized = false;
  List<LatLng> _routePolyline = [];
  LatLng? _destinationEntrance;
  bool _showSearchResults = false;
  List<CampusBuilding> _filteredBuildings = [];
  BuildingCategory? _selectedCategory;
  double? _routeDistance;
  double? _routeDuration;
  double _mapRotation = 0.0;
  bool _is3DCompassMode = false;
  bool _isRecentering = false;
  AnimationController? _recenterAnimationController;
  double _currentZoom = 16.5;
  String _transportMode = 'foot';
  List<List<LatLng>> _footpaths = [];
  List<CampusBuilding> _osmBuildings = [];
  bool _loadingOSMData = true;
  final List<CampusBuilding> _recentSearches = [];
  double _mapBearing = 0.0;
  final LiveEventsService _eventsService = LiveEventsService();
  List<CampusEvent> _liveEvents = [];
  final bool _motionTrackingEnabled = false;
  double _deviceTiltX = 0.0;
  double _deviceTiltY = 0.0;
  double _userHeading = 0.0;
  bool _isNavigating = false;
  MapStyle _mapStyle = MapStyle.standard;
  int _selectedNavIndex = 0;
  final List<CampusBuilding> _favorites = [];
  final PreferencesService _prefs = PreferencesService();
  final FavoritesService _favService = FavoritesService();
  late AnimationController _pulseController;
  StreamSubscription<Position>? _posSub;
  bool _locationEnabled = true;
  late Animation<double> _pulseAnimation;
  double _locBtnScale = 1.0;
  bool _outsideOkadaWarned = false;
  // Route draw animation
  late AnimationController _routeDrawController;
  late Animation<double> _routeDrawProgress;
  // Precomputed ETAs/distances per mode for bottom sheet
  Map<String, double>? _etaSecsByMode; // key: foot/bicycle/car/bus
  Map<String, double>? _distByMode;
  // Temporary marker animation for search results
  AnimationController? _tempMarkerController;
  late Animation<double> _tempMarkerBounce;
  CampusBuilding? _tempMarkerBuilding;
  bool _showTempMarker = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadOSMFootpaths();
    _loadOSMBuildings();
    _loadUserPreferences();
    _initializeLiveEvents();
    // listen for live settings updates
    AppSettings.mapStyle.addListener(() {
      final s = AppSettings.mapStyle.value.toLowerCase();
      setState(() {
        _mapStyle = s == 'satellite'
            ? MapStyle.satellite
            : (s == 'terrain' ? MapStyle.topo : MapStyle.standard);
      });
    });
    AppSettings.locationServices.addListener(() {
      final enabled = AppSettings.locationServices.value;
      if (enabled) {
        _startLocation();
      } else {
        _stopLocation();
      }
    });
    
    // Initialize entrance animations
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    // Create staggered controllers for each element
    for (int i = 0; i < 8; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _elementControllers.add(controller);
    }
    
    // Start entrance animations immediately to prevent grey screen
    _entranceController.forward();
    _startStaggeredAnimations();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _recenterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _routeDrawController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _routeDrawProgress = CurvedAnimation(parent: _routeDrawController, curve: Curves.easeOut);
    _tempMarkerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tempMarkerBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tempMarkerController!, curve: Curves.elasticOut),
    );
    FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h != null && mounted) {
        setState(() => _userHeading = h);
        
        // Auto-rotate map when in 3D compass mode or navigating
        if ((_is3DCompassMode || _isNavigating) && _currentLocation != null) {
          _mapController.rotate(h);
        }
      }
    });
    
    // Device motion tracking (gyroscope) - only on mobile platforms
    if (!kIsWeb) {
      gyroscopeEventStream().listen((GyroscopeEvent event) {
        if (_motionTrackingEnabled && mounted) {
          setState(() {
            _deviceTiltX = event.x;
            _deviceTiltY = event.y;
          });
          
          // Rotate map based on device tilt (Y-axis rotation)
          final rotationSensitivity = 30.0; // Degrees per radian
          final targetRotation = -event.y * rotationSensitivity;
          
          // Smooth rotation with limits
          if (targetRotation.abs() < 45) { // Max 45 degrees tilt
            _mapController.rotate(targetRotation);
            setState(() => _mapRotation = targetRotation);
          }
        }
      });
    }
    
    // Auto-show building sheet if coming from favorites
    if (widget.selectedBuilding != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(widget.selectedBuilding!.coordinates, 18);
          // Show sheet immediately without delay
          _showBuildingSheet(widget.selectedBuilding!, fromSearch: true);
        }
      });
    } else {
      // Auto-show current location on app start (default behavior)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnUserLocation();
      });
    }
  }

  void _initializeLiveEvents() {
    _eventsService.initialize();
    _eventsService.addListener(() {
      if (mounted) {
        setState(() {
          _liveEvents = _eventsService.liveEvents;
        });
      }
    });
    // Initial load
    setState(() {
      _liveEvents = _eventsService.liveEvents;
    });
  }
  
  void _startStaggeredAnimations() {
    // Stagger animations for different UI elements
    // 0: Search bar, 1: Category filter, 2: Layers button
    // 3: Compass, 4: Location button, 5: Directions FAB
    // 6: Events FAB, 7: Bottom nav
    final delays = [100, 200, 300, 400, 450, 500, 550, 600];
    
    for (int i = 0; i < _elementControllers.length; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted && _elementControllers[i].status != AnimationStatus.completed) {
          _elementControllers[i].forward();
        }
      });
    }
    
    setState(() => _animationsInitialized = true);
  }

  Future<void> _loadUserPreferences() async {
    final mapStyle = await _prefs.getString(PreferencesKeys.mapStyle);
    final nav = await _prefs.getString(PreferencesKeys.navigationMode);
    final lastMode = await _prefs.getString(PreferencesKeys.lastTransportMode);
    final loc = await _prefs.getBool(PreferencesKeys.locationServices);
    if (!mounted) return;
    setState(() {
      switch ((mapStyle ?? '').toLowerCase()) {
        case 'satellite':
          _mapStyle = MapStyle.satellite;
          break;
        case 'satellitehybrid':
          _mapStyle = MapStyle.satelliteHybrid;
          break;
        case 'terrain':
        case 'topo':
          _mapStyle = MapStyle.topo;
          break;
        case 'terrain3d':
          _mapStyle = MapStyle.terrain3d;
          break;
        case 'dark':
          _mapStyle = MapStyle.dark;
          break;
        case 'streethd':
          _mapStyle = MapStyle.streetHD;
          break;
        default:
          _mapStyle = MapStyle.standard;
      }
      if (nav != null) {
        final lower = nav.toLowerCase();
        if (lower == 'driving') {
          _transportMode = 'car';
        } else if (lower == 'transit') {
          _transportMode = 'bus';
        } else {
          _transportMode = 'foot';
        }
      }
      if (lastMode != null && lastMode.isNotEmpty) {
        _transportMode = lastMode; // override with persisted last choice
      }
      _locationEnabled = loc ?? true;
    });
    if (_locationEnabled) {
      _startLocation();
    }
  }

  // Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    try {
      // Reload OSM buildings data
      await _loadOSMBuildings();
      
      // Refresh live events
      await _eventsService.refresh();
      
      // Refresh current location
      if (_locationEnabled) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        );
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
        }
      }
      
      // Small delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  void _navigateToEvent(CampusEvent event) {
    // Find building by venue ID
    final building = [...campusBuildings, ..._osmBuildings].firstWhere(
      (b) => b.name.toLowerCase() == event.venue.toLowerCase(),
      orElse: () => campusBuildings.first, // Fallback
    );
    
    // Show event details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16),
                const SizedBox(width: 4),
                Text(event.venue, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16),
                const SizedBox(width: 4),
                Text(event.timeRangeFormatted),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showBuildingSheet(building, fromSearch: true);
            },
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOSMBuildings() async {
    if (!mounted) return;
    setState(() => _loadingOSMData = true);
    try {
      final buildings = await OSMDataFetcher.fetchCampusBuildings().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('OSM fetch timeout - using fallback data');
          return <CampusBuilding>[];
        },
      );
      if (buildings.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _osmBuildings = buildings;
          _loadingOSMData = false;
        });
        _loadFavoritesFromPrefs();
        debugPrint('Loaded ${buildings.length} buildings from OSM');
      } else {
        if (!mounted) return;
        setState(() {
          _osmBuildings = campusBuildings;
          _loadingOSMData = false;
        });
        _loadFavoritesFromPrefs();
        debugPrint('Using static building data (${campusBuildings.length})');
      }
    } catch (e) {
      debugPrint('Error loading OSM buildings: $e');
      if (!mounted) return;
      setState(() {
        _osmBuildings = campusBuildings;
        _loadingOSMData = false;
      });
      _loadFavoritesFromPrefs();
    }
  }

  Future<void> _loadFavoritesFromPrefs() async {
    final source = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
    final favs = await _favService.loadFavorites(source);
    if (!mounted) return;
    setState(() {
      _favorites
        ..clear()
        ..addAll(favs);
    });
  }

  Future<void> _loadOSMFootpaths() async {
    try {
      final bbox = '${_campusCenter.latitude - 0.01},${_campusCenter.longitude - 0.01},'
          '${_campusCenter.latitude + 0.01},${_campusCenter.longitude + 0.01}';
      final query = '''
[out:json][bbox:$bbox];
(
  way["highway"="footway"];
  way["highway"="path"];
  way["highway"="pedestrian"];
  way["highway"="steps"];
  way["foot"="yes"];
);
out geom;
''';
      final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<List<LatLng>> paths = [];
        for (var element in data['elements']) {
          if (element['type'] == 'way' && element['geometry'] != null) {
            final geom = element['geometry'] as List;
            final line = <LatLng>[];
            for (var p in geom) {
              line.add(LatLng(p['lat'] as double, p['lon'] as double));
            }
            if (line.length > 1) paths.add(line);
          }
        }
        if (!mounted) return;
        setState(() => _footpaths = paths);
        debugPrint('Loaded ${paths.length} footpaths from OSM');
      }
    } catch (e) {
      debugPrint('Error loading footpaths: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBuildings = [];
        _showSearchResults = _recentSearches.isNotEmpty;
      } else {
        final buildingsToSearch = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
        _filteredBuildings = buildingsToSearch
            .where((b) => b.name.toLowerCase().contains(query))
            .toList();
        _showSearchResults = true;
      }
    });
  }

  Future<void> _startLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation, // Highest precision like Google Maps/Apple Maps
          distanceFilter: 1, // Update every 1 meter for smooth tracking
        ),
      );
      final userLocation = LatLng(position.latitude, position.longitude);
      if (!_isWithinOkadaBounds(userLocation)) {
        if (mounted && !_outsideOkadaWarned) {
          _showOutsideOkadaWarning();
        }
      }
      setState(() => _currentLocation = userLocation);
      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation, // Highest precision for real-time navigation
          distanceFilter: 1, // Update every 1 meter for smooth precise tracking
          timeLimit: Duration(seconds: 10), // Ensure updates even if stationary
        ),
      ).listen((position) {
        if (mounted) {
          final newLocation = LatLng(position.latitude, position.longitude);
          if (!_isWithinOkadaBounds(newLocation) && !_outsideOkadaWarned) {
            _showOutsideOkadaWarning();
          }
          setState(() => _currentLocation = newLocation);
          if (_isNavigating && _currentLocation != null) {
            _mapController.move(_currentLocation!, (_currentZoom + 0.8).clamp(16.0, 19.0));
            // Smooth continuous rotation with device heading
            _mapController.rotate(_userHeading);
          }
          // Also rotate in 3D compass mode
          if (_is3DCompassMode && _currentLocation != null) {
            _mapController.rotate(_userHeading);
          }
        }
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  void _stopLocation() {
    _posSub?.cancel();
    _posSub = null;
  }

  /// 3-Stage 3D Compass Recenter Animation
  /// Stage 1: Recenter to GPS location (300ms)
  /// Stage 2: Tilt camera to 3D view 55-60° (250ms)
  /// Stage 3: Rotate to device heading (250ms)
  Future<void> _recenterAndTilt3D() async {
    if (_currentLocation == null || _isRecentering) return;

    if (!mounted) return;
    setState(() {
      _isRecentering = true;
    });

    try {
      // Smooth single animation: Recenter + zoom + rotate simultaneously (600ms)
      final startCenter = _mapController.camera.center;
      final targetCenter = _currentLocation!;
      final startZoom = _mapController.camera.zoom;
      final targetZoom = 18.5;

      // Single fluid animation - no delays, no green screen flash
      await _animateMapTransition(
        duration: const Duration(milliseconds: 600),
        centerFrom: startCenter,
        centerTo: targetCenter,
        zoomFrom: startZoom,
        zoomTo: targetZoom,
        rotationFrom: _mapRotation,
        rotationTo: _userHeading, // Rotate to compass heading immediately
        curve: Curves.easeInOutCubic,
      );

      // Enable 3D compass tracking mode
      setState(() {
        _is3DCompassMode = true;
        _mapRotation = _userHeading;
      });

      // Auto-update rotation with compass in 3D mode
      if (_is3DCompassMode) {
        _start3DCompassTracking();
      }
    } finally {
      setState(() {
        _isRecentering = false;
      });
    }
  }

  /// Animates map transition smoothly
  Future<void> _animateMapTransition({
    required Duration duration,
    required LatLng centerFrom,
    required LatLng centerTo,
    required double zoomFrom,
    required double zoomTo,
    required double rotationFrom,
    required double rotationTo,
    required Curve curve,
  }) async {
    const steps = 30;
    final stepDuration = duration.inMilliseconds ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final t = curve.transform(i / steps);

      final lat = centerFrom.latitude + ((centerTo.latitude - centerFrom.latitude) * t);
      final lng = centerFrom.longitude + ((centerTo.longitude - centerFrom.longitude) * t);
      final zoom = zoomFrom + ((zoomTo - zoomFrom) * t);
      final rotation = rotationFrom + ((rotationTo - rotationFrom) * t);

      _mapController.move(LatLng(lat, lng), zoom);
      _mapController.rotate(rotation);

      if (mounted) {
        setState(() {
          _currentZoom = zoom;
          _mapRotation = rotation;
        });
      }

      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }

  /// Starts real-time compass tracking in 3D mode
  void _start3DCompassTracking() {
    // Smoothly update rotation as user turns device
    FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h != null && _is3DCompassMode && mounted && !_isRecentering) {
        // Low-pass filter to smooth rapid changes
        final smoothedHeading = (_mapRotation * 0.7) + (h * 0.3);
        setState(() {
          _mapRotation = smoothedHeading;
        });
        _mapController.rotate(smoothedHeading);
      }
    });
  }

  /// Exits 3D compass mode
  void _exit3DCompassMode() {
    setState(() {
      _is3DCompassMode = false;
      _mapRotation = 0.0;
    });
    _mapController.rotate(0.0);
  }

  bool _isWithinOkadaBounds(LatLng location) {
    const double okadaRadiusKm = 10.0;
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      _campusCenter,
      location,
    );
    final isWithin = distance <= okadaRadiusKm;
    debugPrint('📍 Bounds check: Location (${location.latitude}, ${location.longitude}) is ${distance.toStringAsFixed(2)}km from campus center. Within bounds: $isWithin');
    return isWithin;
  }

  void _showOutsideOkadaWarning() {
    _outsideOkadaWarned = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text('Outside Okada', style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app is intended for Igbinedion University students. You\'re outside Okada right now.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.ash,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please get closer to Igbinedion University (Okada) to use navigation. You can still view the map.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.grey),
            child: Text('OK', style: AppTextStyles.button.copyWith(fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startLocation();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text('RETRY', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  Future<void> _calculateRoute(CampusBuilding destination) async {
    debugPrint('🟢 _calculateRoute called for ${destination.name}');
    
    // Check if current location is valid (within reasonable distance from campus)
    final bool needsLocationUpdate = _currentLocation == null || 
        !_isWithinOkadaBounds(_currentLocation!);
    
    if (needsLocationUpdate) {
      if (_currentLocation != null) {
        debugPrint('🔴 Current location is invalid/out of bounds: $_currentLocation');
      } else {
        debugPrint('🟡 No current location, getting GPS position');
      }
      if (mounted) {
        showAnimatedSuccess(
          context,
          'Getting your location...',
          icon: Icons.gps_fixed,
          iconColor: AppColors.primary,
          duration: const Duration(milliseconds: 1500),
        );
      }
      
      // Check location permission first
      try {
        debugPrint('🟡 Checking location permission...');
        final permission = await Geolocator.checkPermission();
        debugPrint('🟡 Permission status: $permission');
        
        if (permission == LocationPermission.denied) {
          debugPrint('🟡 Location permission denied, requesting...');
          final newPermission = await Geolocator.requestPermission();
          debugPrint('🟡 New permission status: $newPermission');
          
          if (newPermission == LocationPermission.denied || newPermission == LocationPermission.deniedForever) {
            throw Exception('Location permission denied by user');
          }
        }
        
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permission permanently denied. Please enable in browser settings.');
        }
        
        debugPrint('🟡 Getting GPS position (15 second timeout for mobile)...');
        // Wait for GPS to be ready (15 seconds for mobile devices - they need more time)
        Position? position;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (position == null && retryCount < maxRetries) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              ),
            ).timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('🔴 GPS timeout attempt ${retryCount + 1}/$maxRetries');
                throw TimeoutException('GPS timeout');
              },
            );
            
            // Check if accuracy is good enough (< 50m for mobile)
            if (position.accuracy > 50) {
              debugPrint('⚠️ GPS accuracy poor (${position.accuracy}m), retrying...');
              if (retryCount < maxRetries - 1) {
                position = null;
                await Future.delayed(Duration(seconds: 2));
              }
            }
          } catch (e) {
            retryCount++;
            if (retryCount < maxRetries) {
              debugPrint('🟡 GPS retry ${retryCount}/$maxRetries after error: $e');
              await Future.delayed(Duration(seconds: 2));
            } else {
              throw TimeoutException('GPS took too long after $maxRetries attempts. Make sure location is enabled.');
            }
          }
        }
        
        if (position == null) {
          throw Exception('Could not get GPS position after $maxRetries attempts');
        }
        
        final detectedLocation = LatLng(position.latitude, position.longitude);
        debugPrint('🟢 Got GPS location: $detectedLocation with accuracy: ${position.accuracy}m');
        
        // Verify location is within reasonable bounds
        if (_isWithinOkadaBounds(detectedLocation)) {
          setState(() {
            _currentLocation = detectedLocation;
          });
          debugPrint('✅ Location is within campus bounds, using GPS location for routing!');
          if (mounted) {
            showAnimatedSuccess(
              context,
              'Location detected: ${position.accuracy.toStringAsFixed(0)}m accuracy',
              icon: Icons.my_location_rounded,
              iconColor: AppColors.success,
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          debugPrint('⚠️ GPS location OUTSIDE campus bounds (${detectedLocation.latitude}, ${detectedLocation.longitude}) - using campus center instead');
          setState(() {
            _currentLocation = _campusCenter;
          });
          if (mounted) {
            showAnimatedSuccess(
              context,
              'You appear to be off-campus. Using campus center.',
              icon: Icons.location_on,
              iconColor: AppColors.warning,
              duration: const Duration(seconds: 2),
            );
          }
        }
      } catch (e) {
        debugPrint('🔴 GPS error: $e - Using campus center as fallback');
        // Use campus center as fallback - don't return, continue with routing
        setState(() {
          _currentLocation = _campusCenter;
        });
        if (mounted) {
          final isPermissionError = e.toString().contains('permission');
          showAnimatedSuccess(
            context,
            isPermissionError 
                ? 'Location access denied. Using campus center.'
                : 'Could not get your location. Using campus center.',
            icon: isPermissionError ? Icons.location_disabled_rounded : Icons.location_on,
            iconColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
    
    final start = _currentLocation ?? _campusCenter;
    debugPrint('🚀 ROUTE CALCULATION STARTING:');
    debugPrint('   From: (${start.latitude}, ${start.longitude}) ${_currentLocation != null ? "[GPS]" : "[Campus Center Fallback]"}');
    debugPrint('   To: ${destination.name} at (${destination.coordinates.latitude}, ${destination.coordinates.longitude})');
    debugPrint('   Transport: $_transportMode');
    
    try {
      List<LatLng> routePoints = [];
      double distance = 0;
      double duration = 0;
      
      // Use different routing based on transport mode
      if (_transportMode == 'foot') {
        debugPrint('🚶 Calculating footpath route...');
        // Prefer dedicated footpaths; fallback to mixed pedestrian (footpaths + safe roads)
        print('Calculating walking route (footpaths preferred) from ${start.latitude},${start.longitude} to ${destination.coordinates.latitude},${destination.coordinates.longitude}');
        routePoints = await _calculateFootpathRoute(start, destination.coordinates);

        // Check if footpath route found anything
        if (routePoints.isEmpty) {
          // Fallback: allow walk on accessible roads then append building entrance
          debugPrint('⚠️ Strict footpath route empty; falling back to mixed pedestrian route');
          try {
            routePoints = await _calculateMixedPedestrianRoute(start, destination.coordinates);
            debugPrint('✅ Mixed pedestrian route returned ${routePoints.length} points');
          } catch (e) {
            debugPrint('❌ Mixed pedestrian route failed: $e');
          }
        }
        
        if (routePoints.isNotEmpty) {
          // Do NOT append building centroid; keep last footpath/road node as entrance
          // If last point equals building centroid accidentally, replace with nearest footpath node
          final distEnd = const Distance().distance(routePoints.last, destination.coordinates);
          if (distEnd < 3) {
            // Too close (likely building point). Remove and try to find previous node as entrance
            if (routePoints.length > 1) {
              routePoints.removeLast();
            }
          }
          distance = _calculateRouteDistance(routePoints);
          duration = _calculateRouteDuration(distance, _transportMode);
          print('Walking route found: ${routePoints.length} points, ${distance.toStringAsFixed(0)}m');
        } else {
          // FINAL FALLBACK: Create direct straight-line route
          debugPrint('❌ Both footpath and mixed pedestrian routes failed');
          debugPrint('🔄 Creating direct straight-line route as last resort');
          routePoints = [start, destination.coordinates];
          distance = const Distance().distance(start, destination.coordinates);
          duration = _calculateRouteDuration(distance, _transportMode);
          debugPrint('✅ Direct route created: ${distance.toStringAsFixed(0)}m');
          
          if (mounted) {
            showAnimatedSuccess(
              context,
              'Using direct route - mapped paths unavailable',
              icon: Icons.warning_rounded,
              iconColor: AppColors.warning,
              duration: const Duration(seconds: 3),
            );
          }
        }
      } else if (_transportMode == 'bicycle') {
        // STRICT: Bicycle-allowed ways only
        print('Calculating bicycle route from ${start.latitude},${start.longitude} to ${destination.coordinates.latitude},${destination.coordinates.longitude}');
        routePoints = await _calculateBicycleRoute(start, destination.coordinates);

        if (routePoints.isNotEmpty) {
          distance = _calculateRouteDistance(routePoints);
          duration = _calculateRouteDuration(distance, _transportMode);
          print('Bicycle route found: ${routePoints.length} points, ${distance.toStringAsFixed(0)}m');
        } else {
          throw Exception('No bicycle-allowed route found.');
        }
      } else {
        // CAR/BUS: Use only roads from OSM, allow OSRM fallback
        print('Calculating vehicle route from ${start.latitude},${start.longitude} to ${destination.coordinates.latitude},${destination.coordinates.longitude}');
  routePoints = await _calculateRoadRoute(start, destination.coordinates);
        
            if (routePoints.isNotEmpty) {
          // Ensure we do not end inside building: remove last point if it's the building centroid
          if (routePoints.isNotEmpty && routePoints.last == destination.coordinates) {
            routePoints.removeLast();
          }
          distance = _calculateRouteDistance(routePoints);
          duration = _calculateRouteDuration(distance, _transportMode);
          print('Vehicle route found: ${routePoints.length} points, ${distance.toStringAsFixed(0)}m');
        } else {
          print('No road route found, trying OSRM fallback');
          
          // Fallback to OSRM for car/bus if OSM road routing fails
          String routingProfile;
          switch (_transportMode) {
            case 'bus':
            case 'car':
              routingProfile = 'driving';
              break;
            case 'bicycle':
              routingProfile = 'cycling';
              break;
            case 'foot':
            default:
              routingProfile = 'walking';
          }
          
          final url = 'https://router.project-osrm.org/route/v1/$routingProfile/'
              '${start.longitude},${start.latitude};'
              '${destination.coordinates.longitude},${destination.coordinates.latitude}'
              '?overview=full&geometries=geojson';
          
          final response = await http.get(Uri.parse(url));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final coords = data['routes'][0]['geometry']['coordinates'] as List;
            routePoints = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
            // Trim final coordinate if it matches building centroid (keep road approach)
            if (routePoints.isNotEmpty && routePoints.last == destination.coordinates) {
              routePoints.removeLast();
            }
            distance = (data['routes'][0]['distance'] as num).toDouble();
            duration = (data['routes'][0]['duration'] as num).toDouble();
            print('OSRM fallback route found: ${routePoints.length} points');
          }
        }
      }
      
      if (routePoints.isNotEmpty) {
        _addToRecent(destination);
        setState(() {
          _routePolyline = routePoints;
          _routeDistance = distance;
          _routeDuration = duration;
          _selectedBuilding = destination;
          _destinationEntrance = routePoints.isNotEmpty ? routePoints.last : null;
          _isNavigating = false; // use preview screen instead
        });
        _routeDrawController.forward(from: 0);
        // Navigate to preview screen
        debugPrint('🟢 Route calculated successfully: ${routePoints.length} points, ${distance}m, mounted=$mounted');
        if (mounted) {
          debugPrint('🟢 Navigating to RoutePreviewScreen');
          final result = await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RoutePreviewScreen(
              routePoints: routePoints,
              start: _currentLocation ?? _campusCenter,
              end: destination.coordinates,
              distanceMeters: distance,
              durationSeconds: duration,
              transportMode: _transportMode,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(animation.value * 0.3)
                  ..scale(0.85 + (animation.value * 0.15)),
                alignment: Alignment.center,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ));
          debugPrint('🟢 Returned from RoutePreviewScreen');
          // Clear route if navigation was completed
          if (result is Map && result['clearRoute'] == true) {
            _clearRoute();
          }
        }
        _fitRouteBounds();
      } else {
        // No route found - show helpful message
        String message = _transportMode == 'foot' || _transportMode == 'bicycle'
            ? 'No footpath route found. The destination may not be connected to the footpath network.'
            : 'No road route found. Try a different transport mode.';
        throw Exception(message);
      }
    } catch (e) {
      print('Route calculation error: $e');
      if (mounted) {
        showAnimatedSuccess(
          context,
          e.toString().replaceAll('Exception: ', ''),
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  // Compute initial bearing (forward azimuth) from point A to B in degrees (0–360)
  double _computeBearing(LatLng from, LatLng to) {
    const rad = 3.141592653589793 / 180.0;
    final lat1 = from.latitude * rad;
    final lat2 = to.latitude * rad;
    final dLon = (to.longitude - from.longitude) * rad;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double brng = math.atan2(y, x) * 180.0 / 3.141592653589793;
    return (brng + 360.0) % 360.0;
  }

  Future<List<LatLng>> _calculateFootpathRoute(LatLng start, LatLng end) async {
    try {
      // Use Overpass API to get pedestrian/bicycle paths only
      final bbox = '${start.latitude - 0.01},${start.longitude - 0.01},${end.latitude + 0.01},${end.longitude + 0.01}';
      
      // Query for pedestrian-accessible paths ONLY (not roads)
      final query = '''
[out:json][bbox:$bbox];
(
  way["highway"="footway"];
  way["highway"="path"]["foot"!="no"];
  way["highway"="pedestrian"];
  way["highway"="steps"];
  way["highway"="cycleway"]["foot"!="no"];
  way["highway"="bridleway"]["foot"!="no"];
  way["highway"="track"]["foot"!="no"];
  way["foot"="yes"]["highway"!="motorway"]["highway"!="motorway_link"]["highway"!="trunk"]["highway"!="trunk_link"];
);
out body;
>;
out skel qt;
''';
      
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        // Build a graph of connected nodes (pedestrian paths only)
        Map<int, LatLng> nodes = {};
        Map<int, List<int>> wayNodes = {};
        Map<int, String> wayTypes = {}; // Track way type for debugging
        
        for (var element in elements) {
          if (element['type'] == 'node') {
            nodes[element['id']] = LatLng(element['lat'], element['lon']);
          } else if (element['type'] == 'way') {
            final tags = element['tags'] as Map<String, dynamic>?;
            final highway = tags?['highway'] as String?;
            
            // Only include pedestrian-appropriate ways
            if (highway == 'footway' || 
                highway == 'path' || 
                highway == 'pedestrian' || 
                highway == 'steps' ||
                (highway == 'cycleway' && tags?['foot'] != 'no') ||
                (highway == 'track' && tags?['foot'] != 'no') ||
                tags?['foot'] == 'yes') {
              wayNodes[element['id']] = List<int>.from(element['nodes']);
              wayTypes[element['id']] = highway ?? 'unknown';
            }
          }
        }
        
        print('Pedestrian network: ${nodes.length} nodes, ${wayNodes.length} ways');
        
    // Prefer routing to a mapped entrance node, if available
    LatLng? entrance = await _fetchNearestEntrance(end);
    // Find nearest nodes to start and end
    // For end node, if entrance is available, snap to it; otherwise use nearest footpath node
    int? startNode = _findNearestNodeId(start, nodes);
    int? endNode;
    
    if (entrance != null) {
      // Route to entrance node
      endNode = _findNearestNodeId(entrance, nodes);
      debugPrint('Routing to entrance: ${entrance.latitude},${entrance.longitude}');
    } else {
      // No entrance found, find nearest footpath node to building
      endNode = _findNearestNodeId(end, nodes);
      debugPrint('No entrance found, routing to nearest footpath node');
    }
        
        if (startNode != null && endNode != null) {
          // Use A* pathfinding through the pedestrian graph
          List<int>? path = _findShortestPath(startNode, endNode, nodes, wayNodes);
          
          if (path != null && path.isNotEmpty) {
            List<LatLng> route = [];
            
            // Always add user's current position as starting point
            route.add(start);
            
            for (var nodeId in path) {
              if (nodes.containsKey(nodeId)) {
                route.add(nodes[nodeId]!);
              }
            }
            
            // Set destination entrance for UI display
            if (entrance != null) {
              _destinationEntrance = entrance;
              debugPrint('Route ends at entrance: ${entrance.latitude},${entrance.longitude}');
            } else if (route.isNotEmpty) {
              _destinationEntrance = route.last;
              debugPrint('Route ends at footpath node: ${route.last.latitude},${route.last.longitude}');
            }
            
            print('Pedestrian route: ${route.length} points, ${entrance != null ? 'to building entrance' : 'to nearest footpath'}');
            
            if (route.length >= 2) {
              final newBearing = _computeBearing(route[0], route[1]);
              setState(() => _mapBearing = newBearing);
              _mapController.rotate(_mapBearing);
            }
            return route;
          } else {
            debugPrint('❌ A* pathfinding returned no path between nodes - footpath network may be disconnected');
            debugPrint('🔄 Falling back to mixed pedestrian route (roads + footpaths)...');
            // FALLBACK: Try mixed pedestrian route which includes roads
            return await _calculateMixedPedestrianRoute(start, end);
          }
        } else {
          debugPrint('❌ Could not find start or end node: start=$startNode, end=$endNode');
          debugPrint('🔄 Falling back to mixed pedestrian route (roads + footpaths)...');
          // FALLBACK: Try mixed pedestrian route which includes roads
          return await _calculateMixedPedestrianRoute(start, end);
        }
      }
    } catch (e) {
      print('Error calculating footpath route: $e');
      debugPrint('🔄 Falling back to mixed pedestrian route after error...');
      // FALLBACK: Try mixed pedestrian route on any error
      try {
        return await _calculateMixedPedestrianRoute(start, end);
      } catch (fallbackError) {
        print('Mixed pedestrian route also failed: $fallbackError');
      }
    }
    
    return [];
  }

  // Query the nearest OSM entrance node (entrance=*) around a target location
  Future<LatLng?> _fetchNearestEntrance(LatLng target) async {
    try {
      final double radiusMeters = 100; // search within ~100m around the destination
      final query = '''
[out:json];
(
  node(around:$radiusMeters,${target.latitude},${target.longitude})["entrance"];
  node(around:$radiusMeters,${target.latitude},${target.longitude})["door"];
);
out body;''';
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = (data['elements'] as List?) ?? [];
        if (elements.isEmpty) {
          debugPrint('No entrance nodes found within ${radiusMeters}m');
          return null;
        }
        
        // Prefer entrance=main if present; otherwise the closest node
        LatLng? mainEntrance;
        LatLng? closestEntrance;
        double mainDist = double.infinity;
        double closestDist = double.infinity;
        
        for (final el in elements) {
          if (el['type'] != 'node') continue;
          final lat = (el['lat'] as num).toDouble();
          final lon = (el['lon'] as num).toDouble();
          final node = LatLng(lat, lon);
          final tags = (el['tags'] as Map?) ?? {};
          final entranceType = tags['entrance']?.toString().toLowerCase();
          final d = const Distance().distance(target, node);
          
          // Track main entrance
          if (entranceType == 'main' || entranceType == 'yes') {
            if (d < mainDist) {
              mainEntrance = node;
              mainDist = d;
            }
          }
          
          // Track closest entrance
          if (d < closestDist) {
            closestEntrance = node;
            closestDist = d;
          }
        }
        
        // Return main entrance if within 80m, otherwise closest entrance
        if (mainEntrance != null && mainDist < 80) {
          debugPrint('Found main entrance at ${mainDist.toStringAsFixed(1)}m');
          return mainEntrance;
        } else if (closestEntrance != null) {
          debugPrint('Found entrance at ${closestDist.toStringAsFixed(1)}m');
          return closestEntrance;
        }
      }
    } catch (e) {
      debugPrint('Entrance lookup failed: $e');
    }
    return null;
  }

  // ignore: unused_element
  Future<List<LatLng>> _calculateMixedPedestrianRoute(LatLng start, LatLng end) async {
    try {
      // Use Overpass API to get pedestrian-accessible ways (footpaths + walkable roads)
      final bbox = '${start.latitude - 0.01},${start.longitude - 0.01},${end.latitude + 0.01},${end.longitude + 0.01}';
      
      // Query for ALL pedestrian-accessible ways (footpaths + roads without foot=no)
      final query = '''
[out:json][bbox:$bbox];
(
  way["highway"="footway"];
  way["highway"="path"]["foot"!="no"];
  way["highway"="pedestrian"];
  way["highway"="steps"];
  way["highway"="cycleway"]["foot"!="no"];
  way["highway"="track"]["foot"!="no"];
  way["highway"="residential"]["foot"!="no"];
  way["highway"="service"]["foot"!="no"];
  way["highway"="unclassified"]["foot"!="no"];
  way["highway"="tertiary"]["foot"!="no"];
  way["highway"="living_street"];
);
out body;
>;
out skel qt;
''';
      
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        // Build a graph of connected nodes (footpaths + walkable roads)
        Map<int, LatLng> nodes = {};
        Map<int, List<int>> wayNodes = {};
        
        for (var element in elements) {
          if (element['type'] == 'node') {
            nodes[element['id']] = LatLng(element['lat'], element['lon']);
          } else if (element['type'] == 'way') {
            wayNodes[element['id']] = List<int>.from(element['nodes']);
          }
        }
        
        print('Mixed pedestrian network: ${nodes.length} nodes, ${wayNodes.length} ways');
        
        // Find nearest nodes to start and end
        // For end node, require at least 15m from building to stay on footpath
        int? startNode = _findNearestNodeId(start, nodes);
        int? endNode = _findNearestNodeId(end, nodes, minDistanceFromTarget: 15.0);
        
        if (startNode != null && endNode != null) {
          // Use A* pathfinding through the mixed pedestrian graph
          List<int>? path = _findShortestPath(startNode, endNode, nodes, wayNodes);
          
          if (path != null && path.isNotEmpty) {
            List<LatLng> route = [];
            
            // Only add start if it's close to the first node (within 20m)
            if (nodes.containsKey(path.first)) {
              final distToFirstNode = const Distance().distance(start, nodes[path.first]!);
              if (distToFirstNode < 20) {
                route.add(start);
              }
            }
            
            for (var nodeId in path) {
              if (nodes.containsKey(nodeId)) {
                route.add(nodes[nodeId]!);
              }
            }
            print('Mixed pedestrian route: ${route.length} points');
            if (route.length >= 2) {
              final newBearing = _computeBearing(route[0], route[1]);
              setState(() => _mapBearing = newBearing);
              _mapController.rotate(_mapBearing);
            }
            return route;
          }
        }
      }
    } catch (e) {
      print('Error calculating mixed pedestrian route: $e');
    }
    
    return [];
  }

  Future<List<LatLng>> _calculateBicycleRoute(LatLng start, LatLng end) async {
    try {
      final bbox = '${start.latitude - 0.01},${start.longitude - 0.01},${end.latitude + 0.01},${end.longitude + 0.01}';
      final query = '''
[out:json][bbox:$bbox];
(
  way["highway"="cycleway"];
  way["highway"="path"]["bicycle"!="no"];
  way["highway"="track"]["bicycle"!="no"];
  way["highway"="residential"]["bicycle"!="no"];
  way["highway"="service"]["bicycle"!="no"];
  way["highway"="unclassified"]["bicycle"!="no"];
  way["highway"="living_street"]["bicycle"!="no"];
  way["bicycle"="yes"]["highway"!="motorway"]["highway"!="motorway_link"]["highway"!="trunk"]["highway"!="trunk_link"];
);
out body;
>;
out skel qt;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;

        Map<int, LatLng> nodes = {};
        Map<int, List<int>> wayNodes = {};

        for (var element in elements) {
          if (element['type'] == 'node') {
            nodes[element['id']] = LatLng(element['lat'], element['lon']);
          } else if (element['type'] == 'way') {
            wayNodes[element['id']] = List<int>.from(element['nodes']);
          }
        }

        print('Bicycle network: ${nodes.length} nodes, ${wayNodes.length} ways');

        int? startNode = _findNearestNodeId(start, nodes);
        int? endNode = _findNearestNodeId(end, nodes);

        if (startNode != null && endNode != null) {
          List<int>? path = _findShortestPath(startNode, endNode, nodes, wayNodes);

          if (path != null && path.isNotEmpty) {
            List<LatLng> route = [];

            if (nodes.containsKey(path.first)) {
              final distToFirstNode = const Distance().distance(start, nodes[path.first]!);
              if (distToFirstNode < 20) {
                route.add(start);
              }
            }

            for (var nodeId in path) {
              if (nodes.containsKey(nodeId)) {
                route.add(nodes[nodeId]!);
              }
            }

            if (nodes.containsKey(path.last)) {
              final distToLastNode = const Distance().distance(end, nodes[path.last]!);
              if (distToLastNode < 20) {
                route.add(end);
              }
            }

            if (route.length >= 2) {
              final newBearing = _computeBearing(route[0], route[1]);
              setState(() => _mapBearing = newBearing);
              _mapController.rotate(_mapBearing);
            }
            return route;
          }
        }
      }
    } catch (e) {
      print('Error calculating bicycle route: $e');
    }

    return [];
  }

  Future<List<LatLng>> _calculateRoadRoute(LatLng start, LatLng end) async {
    try {
      // Use Overpass API to get vehicle-accessible roads only
      final bbox = '${start.latitude - 0.01},${start.longitude - 0.01},${end.latitude + 0.01},${end.longitude + 0.01}';
      
      // Query for vehicle-accessible roads ONLY (not footpaths)
      final query = '''
[out:json][bbox:$bbox];
(
  way["highway"="residential"]["motor_vehicle"!="no"];
  way["highway"="service"]["motor_vehicle"!="no"];
  way["highway"="tertiary"]["motor_vehicle"!="no"];
  way["highway"="secondary"]["motor_vehicle"!="no"];
  way["highway"="primary"]["motor_vehicle"!="no"];
  way["highway"="unclassified"]["motor_vehicle"!="no"];
  way["highway"="road"]["motor_vehicle"!="no"];
  way["highway"="living_street"]["motor_vehicle"!="no"];
  way["highway"="track"]["motor_vehicle"="yes"];
);
out body;
>;
out skel qt;
''';
      
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        // Build a graph of connected nodes (roads only)
        Map<int, LatLng> nodes = {};
        Map<int, List<int>> wayNodes = {};
        
        for (var element in elements) {
          if (element['type'] == 'node') {
            nodes[element['id']] = LatLng(element['lat'], element['lon']);
          } else if (element['type'] == 'way') {
            wayNodes[element['id']] = List<int>.from(element['nodes']);
          }
        }
        
        print('Road network: ${nodes.length} nodes, ${wayNodes.length} ways');
        
        // Find nearest nodes to start and end
        int? startNode = _findNearestNodeId(start, nodes);
        int? endNode = _findNearestNodeId(end, nodes);
        
        if (startNode != null && endNode != null) {
          // Use A* pathfinding through the road graph
          List<int>? path = _findShortestPath(startNode, endNode, nodes, wayNodes);
          
          if (path != null) {
            List<LatLng> route = [];
            
            // Only add start if it's close to the first node (within 30m for roads)
            if (nodes.containsKey(path.first)) {
              final distToFirstNode = const Distance().distance(start, nodes[path.first]!);
              if (distToFirstNode < 30) {
                route.add(start);
              }
            }
            
            for (var nodeId in path) {
              if (nodes.containsKey(nodeId)) {
                route.add(nodes[nodeId]!);
              }
            }
            
            // Only add end if it's close to the last node (within 30m for roads)
            if (nodes.containsKey(path.last)) {
              final distToLastNode = const Distance().distance(end, nodes[path.last]!);
              if (distToLastNode < 30) {
                route.add(end);
              }
            }
            
            if (route.length >= 2) {
              final newBearing = _computeBearing(route[0], route[1]);
              setState(() => _mapBearing = newBearing);
              _mapController.rotate(_mapBearing);
            }
            return route;
          }
        }
      }
    } catch (e) {
      print('Error calculating road route: $e');
    }
    
    return [];
  }

  int? _findNearestNodeId(LatLng target, Map<int, LatLng> nodes, {double minDistanceFromTarget = 0}) {
    int? nearestId;
    double minDistance = double.infinity;
    
    nodes.forEach((id, point) {
      final dist = const Distance().distance(target, point);
      // Skip nodes that are too close to the target (e.g., inside the building)
      if (dist >= minDistanceFromTarget && dist < minDistance) {
        minDistance = dist;
        nearestId = id;
      }
    });
    
    // MOBILE FIX: Always return nearest node even if far away
    // This prevents "no route found" when GPS location is not near a mapped path
    if (nearestId != null) {
      if (minDistance < 500.0) {
        debugPrint('✅ Found nearest node at ${minDistance.toStringAsFixed(0)}m away');
      } else {
        debugPrint('⚠️ Nearest node is ${minDistance.toStringAsFixed(0)}m away (>500m) - using it anyway for mobile GPS');
      }
      return nearestId;
    }
    
    debugPrint('❌ No nodes available in graph at all!');
    return null;
  }

  List<int>? _findShortestPath(int startNode, int endNode, Map<int, LatLng> nodes, Map<int, List<int>> wayNodes) {
    // Build adjacency list from way nodes - preserve path order
    Map<int, Set<int>> graph = {};
    Map<int, int> nodeToWay = {}; // Track which way each node belongs to
    
    int wayId = 0;
    for (var way in wayNodes.values) {
      for (int i = 0; i < way.length - 1; i++) {
        // Connect consecutive nodes in the way
        graph.putIfAbsent(way[i], () => {}).add(way[i + 1]);
        graph.putIfAbsent(way[i + 1], () => {}).add(way[i]); // Bidirectional
        
        // Track way membership
        nodeToWay[way[i]] = wayId;
        nodeToWay[way[i + 1]] = wayId;
      }
      wayId++;
    }
    
    print('Graph built: ${graph.length} nodes, ${graph.values.fold(0, (sum, neighbors) => sum + neighbors.length)} edges');
    
    if (!graph.containsKey(startNode)) {
      print('Start node $startNode not in graph');
      return null; 
    }
    if (!graph.containsKey(endNode)) {
      print('End node $endNode not in graph');
      return null;
    }
    
    // A* pathfinding - optimized for shortest distance
    Map<int, double> gScore = {startNode: 0};
    Map<int, double> fScore = {
      startNode: _heuristic(nodes[startNode]!, nodes[endNode]!)
    };
    Map<int, int> cameFrom = {};
    
    // Use priority queue approach (sort by fScore)
    List<int> openSet = [startNode];
    Set<int> closedSet = {};
    Set<int> inOpenSet = {startNode};
    
    int iterations = 0;
    while (openSet.isNotEmpty && iterations < 2000) {
      iterations++;
      
      // Find node with lowest fScore (most promising path)
      openSet.sort((a, b) {
        double scoreA = fScore[a] ?? double.infinity;
        double scoreB = fScore[b] ?? double.infinity;
        // Tie-breaker: prefer nodes closer to destination
        if ((scoreA - scoreB).abs() < 0.1) {
          return _heuristic(nodes[a]!, nodes[endNode]!)
              .compareTo(_heuristic(nodes[b]!, nodes[endNode]!));
        }
        return scoreA.compareTo(scoreB);
      });
      
      int current = openSet.removeAt(0);
      inOpenSet.remove(current);
      
      if (current == endNode) {
        // Reconstruct path
        List<int> path = [current];
        while (cameFrom.containsKey(current)) {
          current = cameFrom[current]!;
          path.insert(0, current);
        }
        double totalDist = gScore[endNode] ?? 0;
        print('Path found: ${path.length} nodes, ${totalDist.toStringAsFixed(0)}m, $iterations iterations');
        return path;
      }
      
      closedSet.add(current);
      
      if (!graph.containsKey(current)) continue;
      
      for (var neighbor in graph[current]!) {
        if (closedSet.contains(neighbor)) continue;
        if (!nodes.containsKey(current) || !nodes.containsKey(neighbor)) continue;
        
        // Calculate actual distance between nodes
        double edgeDistance = const Distance().distance(nodes[current]!, nodes[neighbor]!);
        double tentativeGScore = (gScore[current] ?? double.infinity) + edgeDistance;
        
        // Only update if this path is better
        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          
          // f(n) = g(n) + h(n)
          // g(n) = actual distance from start
          // h(n) = estimated distance to end (straight line)
          double heuristicDist = _heuristic(nodes[neighbor]!, nodes[endNode]!);
          fScore[neighbor] = tentativeGScore + heuristicDist;
          
          if (!inOpenSet.contains(neighbor)) {
            openSet.add(neighbor);
            inOpenSet.add(neighbor);
          }
        }
      }
    }
    
    print('No path found after $iterations iterations (checked ${closedSet.length} nodes)');
    return null; // No path found
  }

  double _heuristic(LatLng a, LatLng b) {
    return const Distance().distance(a, b);
  }

  double _calculateRouteDistance(List<LatLng> points) {
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += const Distance().distance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  double _calculateRouteDuration(double distanceMeters, String mode) {
    // Average speeds in m/s
    double speed;
    switch (mode) {
      case 'foot':
        speed = 1.4; // 5 km/h walking
        break;
      case 'bicycle':
        speed = 4.2; // 15 km/h cycling
        break;
      case 'car':
      case 'bus':
        speed = 8.3; // 30 km/h driving
        break;
      default:
        speed = 1.4;
    }
    return distanceMeters / speed;
  }

  void _fitRouteBounds() {
    if (_routePolyline.isEmpty) return;
    
    double minLat = _routePolyline.first.latitude;
    double maxLat = _routePolyline.first.latitude;
    double minLng = _routePolyline.first.longitude;
    double maxLng = _routePolyline.first.longitude;
    
    for (final point in _routePolyline) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
    
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(50),
    ));
  }

  // Legacy _selectBuilding replaced by _showBuildingSheet; kept commented for reference
  // Removed to reduce unused code warnings.

  void _addToRecent(CampusBuilding building) {
    setState(() {
      // Deduplicate by name
      _recentSearches.removeWhere((b) => b.name == building.name);
      _recentSearches.insert(0, building);
      if (_recentSearches.length > 10) {
        _recentSearches.removeRange(10, _recentSearches.length);
      }
    });
    // Persist recent search names
    _prefs.saveRecentSearches(_recentSearches.map((b) => b.name).toList());
  }

  void _clearRoute() {
    setState(() {
      _routePolyline = [];
      _routeDistance = null;
      _routeDuration = null;
    });
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // Use OSM buildings if available, otherwise fallback to static data
    final buildingsToDisplay = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
    
    // Optimize: only show markers at appropriate zoom level
    // Use _currentZoom state variable instead of mapController to avoid accessing before render
    final showAllMarkers = _currentZoom >= 15.5;
    
    // Add building markers
    for (final building in buildingsToDisplay) {
      // Filter by category if selected
      if (_selectedCategory != null && building.category != _selectedCategory) {
        continue;
      }
      
      final isSelected = _selectedBuilding == building;
      
      // Always show selected building, but limit others at low zoom
      if (!isSelected && !showAllMarkers) continue;
      
      markers.add(
        Marker(
          point: building.coordinates,
          width: isSelected ? 36 : 28,
          height: isSelected ? 36 : 28,
          child: GestureDetector(
            onTap: () => _showBuildingSheet(building),
            // replaced by bottom sheet interaction
            child: Container(
              decoration: BoxDecoration(
                color: _getCategoryColor(building.category),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(building.category),
                  size: isSelected ? 18 : 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Add current location marker with blue glow and rotation
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 70,
          height: 70,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Animated blue glow (pulsing)
                  Container(
                    width: 50 * _pulseAnimation.value,
                    height: 50 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: (0.3 / _pulseAnimation.value)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Outer blue circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Inner location dot
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
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CustomPaint(
                        painter: _ArrowPainter(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    
    // Add temporary animated marker for search results
    if (_showTempMarker && _tempMarkerBuilding != null) {
      markers.add(
        Marker(
          point: _tempMarkerBuilding!.coordinates,
          width: 60,
          height: 80,
          child: AnimatedBuilder(
            animation: _tempMarkerBounce,
            builder: (context, child) {
              final bounceOffset = (1.0 - _tempMarkerBounce.value) * 30.0;
              return Transform.translate(
                offset: Offset(0, -bounceOffset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated pin icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withAlpha(102),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    // Pin shadow
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 20 * _tempMarkerBounce.value,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.2 * 255 * _tempMarkerBounce.value).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
    
    return markers;
  }

  IconData _getCategoryIcon(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return Icons.school_rounded;
      case BuildingCategory.administrative:
        return Icons.business_rounded;
      case BuildingCategory.library:
        return Icons.auto_stories_rounded;
      case BuildingCategory.dining:
        return Icons.restaurant_rounded;
      case BuildingCategory.banking:
        return Icons.account_balance_rounded;
      case BuildingCategory.sports:
        return Icons.sports_soccer_rounded;
      case BuildingCategory.student_services:
        return Icons.groups_rounded;
      case BuildingCategory.research:
        return Icons.biotech_rounded;
      case BuildingCategory.health:
        return Icons.medical_services_rounded;
      case BuildingCategory.residential:
        return Icons.hotel_rounded;
      case BuildingCategory.worship:
        return Icons.church_rounded;
    }
  }

  Color _getCategoryColor(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return const Color(0xFFFF9800); // Orange - bright and energetic for learning
      case BuildingCategory.administrative:
        return const Color(0xFF607D8B); // Blue-grey - professional and organized
      case BuildingCategory.library:
        return const Color(0xFF9C27B0); // Purple - knowledge and wisdom
      case BuildingCategory.dining:
        return const Color(0xFFE91E63); // Pink - appetizing and inviting
      case BuildingCategory.banking:
        return const Color(0xFF4CAF50); // Green - money and prosperity
      case BuildingCategory.sports:
        return const Color(0xFFF44336); // Red - energy and action
      case BuildingCategory.student_services:
        return const Color(0xFF00BCD4); // Cyan - helpful and supportive
      case BuildingCategory.research:
        return const Color(0xFF3F51B5); // Indigo - innovation and discovery
      case BuildingCategory.health:
        return const Color(0xFFFF5722); // Deep orange - medical urgency
      case BuildingCategory.residential:
        return const Color(0xFF795548); // Brown - home and comfort
      case BuildingCategory.worship:
        return const Color(0xFF673AB7); // Deep purple - spirituality
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    _routeDrawController.dispose();
    _tempMarkerController?.dispose();
    _entranceController.dispose();
    for (var controller in _elementControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _centerOnUserLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 18.0);
      setState(() => _mapRotation = 0.0);
      _mapController.rotate(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface(context),
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        displacement: 40.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  // Map layer - must fill entire available space
                  Positioned.fill(
                    child: Container(
                      color: AppColors.surface(context),
                      child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                initialCenter: _campusCenter,
                initialZoom: 16.5,
                maxZoom: 20, // Higher zoom for detailed building inspection
                minZoom: 13,
                initialRotation: _mapRotation,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  enableMultiFingerGestureRace: true,
                  rotationWinGestures: MultiFingerGesture.rotate,
                  pinchMoveWinGestures: MultiFingerGesture.pinchMove | MultiFingerGesture.pinchZoom,
                  // Apple Maps-like ultra-smooth scrolling with momentum
                  scrollWheelVelocity: 0.002, // Faster, more responsive zoom
                  rotationThreshold: 8.0, // Even easier rotation
                  pinchZoomThreshold: 0.2, // Faster, more responsive pinch zoom
                  pinchMoveThreshold: 15.0, // Lower threshold for instant smooth pan
                  cursorKeyboardRotationOptions: CursorKeyboardRotationOptions(
                    isKeyTrigger: null,
                  ),
                ),
                // Continuous smooth updates for fluid Apple Maps feel
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && mounted) {
                    // Exit 3D compass mode if user manually rotates
                    if (_is3DCompassMode && (_mapRotation - position.rotation).abs() > 5.0) {
                      setState(() {
                        _is3DCompassMode = false;
                      });
                    }
                    // Reduced threshold for ultra-smooth continuous updates
                    if ((_mapRotation - position.rotation).abs() > 0.2 ||
                        (_currentZoom - position.zoom).abs() > 0.05) {
                      setState(() {
                        _mapRotation = position.rotation;
                        _currentZoom = position.zoom;
                      });
                    }
                  }
                },
              ),
            children: [
              TileLayer(
                urlTemplate: _tileTemplateFor(_mapStyle),
                subdomains: (_mapStyle == MapStyle.topo || _mapStyle == MapStyle.dark || _mapStyle == MapStyle.streetHD) 
                    ? const ['a','b','c'] 
                    : const <String>[],
                userAgentPackageName: 'com.example.campus_navigation',
                tileBuilder: (context, tileWidget, tile) {
                  // Fallback visual to mitigate 'map data not available' blank tiles
                  return tileWidget;
                },
              ),
              // OSM Footpaths layer
              if (_footpaths.isNotEmpty)
                PolylineLayer(
                  polylines: _footpaths.map((path) => Polyline(
                    points: path,
                    color: Colors.brown.withValues(alpha: 0.6),
                    strokeWidth: 3.0,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.0,
                  )).toList(),
                ),
              // Navigation route layer (on top of footpaths)
              if (_routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _animatedRoutePoints(),
                      color: AppColors.routeColor,
                      strokeWidth: 6.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
                    ),
                  ),
                ),
          
                if (!_isNavigating) _buildSearchBar(),
          // Live Events Banner
          if (!_isNavigating && _liveEvents.isNotEmpty)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: LiveEventsBanner(
                liveEvents: _liveEvents,
                onEventTap: (event) => _navigateToEvent(event),
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const events_screen.EventsScreen(),
                    ),
                  );
                },
              ),
            ),
          if (!_isNavigating) _buildCategoryFilter(),
          if (!_isNavigating) _buildLayersButton(),
          if (!_isNavigating) _buildCompassButton(),
          if (!_isNavigating) _buildMyLocationButton(),
          // OSM refresh happens automatically in background - no button needed
          // Favorites overlay removed: dedicated screen now handles favorites
          // if (!_isNavigating && _selectedNavIndex == 1) _buildFavoritesPanel(),
          if (!_isNavigating && _selectedNavIndex == 3) _buildSettingsPanel(),
          if (_isNavigating) _buildNavigationHUD(),
          
          // OSM data loads silently in background for smooth UX
          
          if (!_isNavigating) _buildEventsFAB(),
          if (!_isNavigating) _buildDirectionsFAB(),
          
          // Search results
          if (_showSearchResults) _buildSearchResults(),
          
          // Selected building info - now handled by BuildingDetailSheet dialog
          // Old _buildBuildingInfo() removed to prevent duplicate sheet
          
          // Deprecated route info card replaced by navigation HUD
          
          // Attribution tag at bottom left
          Positioned(
            left: 16,
            bottom: _isNavigating ? 16 : 90,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: 0.75,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Daniels maps',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar (floating)
          if (!_isNavigating)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ModernNavBar(currentIndex: 0),
            ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<LatLng> _animatedRoutePoints() {
    if (_routePolyline.isEmpty) return _routePolyline;
    final t = _routeDrawProgress.value.clamp(0.0, 1.0);
    final count = (t * _routePolyline.length).clamp(2, _routePolyline.length.toDouble()).toInt();
    return _routePolyline.take(count).toList();
  }

  // Focused navigation HUD (Google Maps style): start/destination + ETA + actions
  Widget _buildNavigationHUD() {
    if (_routePolyline.isEmpty || _selectedBuilding == null) return const SizedBox.shrink();
    final dest = _selectedBuilding!;
    final startLabel = 'You';
    final etaMinutes = _routeDuration != null ? (_routeDuration! / 60).ceil() : null;
    final entranceText = _destinationEntrance != null
        ? '${_destinationEntrance!.latitude.toStringAsFixed(5)},${_destinationEntrance!.longitude.toStringAsFixed(5)}'
        : '';
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Column(
        children: [
          // Header card
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$startLabel → ${dest.name}', style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height:4),
                        if (_routeDistance != null)
                          Text('${_formatDistance(_routeDistance!)} • ETA ${etaMinutes ?? '--'} min', style: GoogleFonts.notoSans(fontSize:12, color: AppColors.grey)),
                        if (entranceText.isNotEmpty)
                          Text('Entrance: $entranceText', style: GoogleFonts.notoSans(fontSize:10, color: AppColors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Overview',
                    icon: const Icon(Icons.zoom_out_map, color: AppColors.primary),
                    onPressed: _fitRouteBounds,
                  ),
                  IconButton(
                    tooltip: 'Share location',
                    icon: const Icon(Icons.share_location, color: AppColors.primary),
                    onPressed: () {
                      if (_currentLocation != null) {
                        final loc = _currentLocation!;
                        Share.share('My current campus location: ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}');
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Exit navigation',
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _isNavigating = false;
                        _clearRoute();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 60,
      right: 60,
      child: Hero(
        tag: 'search_bar',
        child: GestureDetector(
          onTap: () async {
            final result = await Navigator.push<CampusBuilding>(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const SearchScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
            if (result != null && mounted) {
              // Smooth animation: move map to building location first
              _mapController.move(result.coordinates, 18);
              
              // Small delay for smooth map animation
              await Future.delayed(const Duration(milliseconds: 400));
              
              if (!mounted) return;
              
              // Show building sheet with smooth animation
              _showBuildingSheet(result, fromSearch: true);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey[900]?.withAlpha((0.95 * 255).toInt()) 
                  : Colors.white.withAlpha((0.95 * 255).toInt()),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withAlpha((0.1 * 255).toInt()) 
                    : Colors.black.withAlpha((0.08 * 255).toInt()),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(((isDark ? 0.3 : 0.1) * 255).toInt()),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Where to?',
                    style: GoogleFonts.notoSans(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showVoiceSearchDialog();
                    },
                    borderRadius: BorderRadius.circular(24),
                    splashColor: AppColors.primary.withAlpha((0.2 * 255).toInt()),
                    highlightColor: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha((0.15 * 255).toInt()),
                            AppColors.primary.withAlpha((0.1 * 255).toInt()),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha((0.2 * 255).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => 
                              const PremiumProfileScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    splashColor: Colors.black.withAlpha((0.1 * 255).toInt()),
                    highlightColor: Colors.black.withAlpha((0.05 * 255).toInt()),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[800]?.withAlpha((0.8 * 255).toInt())
                            : Colors.black.withAlpha((0.85 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withAlpha((0.1 * 255).toInt())
                              : Colors.white.withAlpha((0.2 * 255).toInt()),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.15 * 255).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceSearchDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha((0.7 * 255).toInt()),
      builder: (context) => _VoiceSearchDialog(
        isDark: isDark,
        onResult: (String result) async {
          // Search for building matching the spoken text
          final searchQuery = result.toLowerCase();
          final matchingBuilding = campusBuildings.firstWhere(
            (building) => building.name.toLowerCase().contains(searchQuery),
            orElse: () => campusBuildings.first,
          );
          
          // Smooth animation: move map first, then show sheet
          _mapController.move(matchingBuilding.coordinates, 18);
          
          // Small delay for smooth map animation
          await Future.delayed(const Duration(milliseconds: 400));
          
          if (!mounted) return;
          
          // Show building sheet with animation
          _showBuildingSheet(matchingBuilding, fromSearch: true);
        },
      ),
    );
  }

  Widget _buildLayersButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Adjust positioning to avoid category chips overlap
    // Position higher up on screen, away from category chips area
    final topPadding = MediaQuery.of(context).padding.top;
    final categoryChipsBottom = topPadding + 100 + 48; // Category chips area
    final buttonTop = categoryChipsBottom + 12; // 12px gap below category chips
    final buttonSize = isMobile ? 48.0 : 52.0; // Smaller on mobile to prevent overlaps
    
    return Positioned(
      top: buttonTop,
      right: 16,
      child: SafeArea(
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: _SmoothLayersButton(
            isDark: isDark,
            onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              enableDrag: true,
              isDismissible: true,
              useSafeArea: true,
              transitionAnimationController: AnimationController(
                vsync: Navigator.of(context),
                duration: const Duration(milliseconds: 200),
              )..forward(),
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.3,
                maxChildSize: 0.92,
                snap: true,
                snapSizes: const [0.3, 0.65, 0.92],
                expand: false,
                shouldCloseOnMinExtent: true,
                builder: (context, scrollController) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuart, // Instant and buttery smooth
                  builder: (context, animValue, child) => Transform.translate(
                    offset: Offset(0, 100 * (1 - animValue)),
                    child: Transform.scale(
                      scale: 0.90 + (0.10 * animValue),
                      child: Opacity(
                        opacity: animValue,
                        child: child,
                      ),
                    ),
                  ),
                  child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.borderAdaptive(context).withAlpha((0.15 * 255).toInt()),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.3 * 255).toInt()),
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Enhanced drag handle
                      GestureDetector(
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.transparent,
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Container(
                                  width: 36 + (8 * value),
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey.withAlpha(((0.4 + (0.2 * value)) * 255).toInt()),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4CAF50).withAlpha((0.15 * 255).toInt()),
                                    const Color(0xFF2196F3).withAlpha((0.15 * 255).toInt()),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Icon(
                                      Icons.square_rounded,
                                      color: const Color(0xFF4CAF50),
                                      size: 12,
                                    ),
                                  ),
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Icon(
                                      Icons.square_rounded,
                                      color: const Color(0xFF2196F3),
                                      size: 12,
                                    ),
                                  ),
                                  Positioned(
                                    top: 22,
                                    left: 22,
                                    child: Icon(
                                      Icons.square_rounded,
                                      color: const Color(0xFF9C27B0),
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Map Styles',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryAdaptive(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                          children: [
                            _buildMapStyleCard(MapStyle.standard, 'Standard', 'Default street map', Icons.map_rounded, const Color(0xFF4CAF50)),
                            const SizedBox(height: 12),
                            _buildMapStyleCard(MapStyle.satellite, 'Satellite', 'High-res aerial view', Icons.satellite_alt_rounded, const Color(0xFF2196F3)),
                            const SizedBox(height: 12),
                            _buildMapStyleCard(MapStyle.satelliteHybrid, 'Satellite + Labels', 'Aerial with street names', Icons.layers_rounded, const Color(0xFF9C27B0)),
                            const SizedBox(height: 12),
                            _buildMapStyleCard(MapStyle.terrain3d, '3D Terrain', 'Elevation & landforms', Icons.view_in_ar_rounded, const Color(0xFFFF9800)),
                            const SizedBox(height: 12),
                            _buildMapStyleCard(MapStyle.topo, 'Topographic', 'Detailed contour lines', Icons.terrain_rounded, const Color(0xFF795548)),
                            const SizedBox(height: 12),
                            _buildMapStyleCard(MapStyle.dark, 'Dark Mode', 'Night-friendly map', Icons.dark_mode_rounded, const Color(0xFF424242)),
                            const SizedBox(height: 12),
                            _buildMapStyleCard(MapStyle.streetHD, 'Street HD', 'Ultra-clear street view', Icons.hd_rounded, const Color(0xFFE91E63)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMapStyleCard(MapStyle style, String title, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _mapStyle == style;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Transform.scale(
            scale: 0.96 + (0.04 * value),
            child: Opacity(opacity: value, child: child),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _mapStyle = style;
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pop(context);
            });
          },
          splashColor: color.withAlpha((0.1 * 255).toInt()),
          highlightColor: color.withAlpha((0.05 * 255).toInt()),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withAlpha((0.12 * 255).toInt())
                  : (isDark ? Colors.grey[850] : AppColors.ash),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? color
                    : (isDark ? Colors.white.withAlpha((0.1 * 255).toInt()) : Colors.black.withAlpha((0.05 * 255).toInt())),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withAlpha((0.25 * 255).toInt()),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: color.withAlpha((0.1 * 255).toInt()),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withAlpha((0.3 * 255).toInt()),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : AppColors.textPrimaryAdaptive(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
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
                if (isSelected)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha((0.4 * 255).toInt()),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Calculate responsive top position with CLEAR spacing
    // Search bar: topPadding + 16 (top) + 56 (height) = topPadding + 72
    // Add generous gap: 20-28px to prevent any overlap
    double topPosition;
    if (isMobile) {
      if (screenHeight < 700) {
        // Small phones: search bar bottom (72) + 20px gap
        topPosition = topPadding + 92;
      } else if (screenHeight < 800) {
        // Regular phones: search bar bottom (72) + 24px gap
        topPosition = topPadding + 96;
      } else {
        // Large phones: search bar bottom (72) + 26px gap
        topPosition = topPadding + 98;
      }
    } else {
      // Tablets/Desktop: search bar bottom (72) + 28px gap
      topPosition = topPadding + 100;
    }
    
    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildModernCategoryChip('All', null, Icons.apps_rounded),
            const SizedBox(width: 8),
            ...BuildingCategory.values.where((category) {
              final buildingsToCheck = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
              return buildingsToCheck.any((b) => b.category == category);
            }).map((category) {
              final buildingsToCheck = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
              final building = buildingsToCheck.firstWhere((b) => b.category == category);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildModernCategoryChip(
                  building.categoryName,
                  category,
                  _getCategoryIcon(category),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Map style tile builder retained for layers modal

  Widget _mapStyleTile(MapStyle style, String label, IconData icon) {
    final selected = _mapStyle == style;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : AppColors.darkGrey),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () => Navigator.of(context).pop(style),
    );
  } 
  

  String _tileTemplateFor(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        // Google high-quality satellite imagery
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case MapStyle.satelliteHybrid:
        // Satellite with street labels overlay
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapStyle.terrain3d:
        // Google Terrain with 3D elevation data
        return 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case MapStyle.topo:
        // OpenTopoMap - detailed topographic
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapStyle.dark:
        // Dark theme map from CartoDB
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapStyle.streetHD:
        // High-definition street map from Stadia
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png';
      case MapStyle.standard:
        // Standard OpenStreetMap
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  Widget _buildModernCategoryChip(String label, BuildingCategory? category, IconData icon) {
    final isSelected = _selectedCategory == category;
    final chipColor = category != null ? _getCategoryColor(category) : AppColors.primary;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutQuart,
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.02),
          child: Material(
            elevation: isSelected ? 6 : 2,
            shadowColor: isSelected ? chipColor.withAlpha((0.4 * 255).toInt()) : chipColor.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(24),
            color: isSelected 
                ? chipColor 
                : chipColor.withAlpha((0.15 * 255).toInt()),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: isSelected 
                    ? null 
                    : Border.all(
                        color: chipColor.withAlpha((0.3 * 255).toInt()),
                        width: 1.5,
                      ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = _selectedCategory == category ? null : category;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: chipColor.withAlpha((0.2 * 255).toInt()),
                highlightColor: chipColor.withAlpha((0.1 * 255).toInt()),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutQuart,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 14, 
                    vertical: isSelected ? 10 : 8
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: isSelected ? 21 : 20,
                        color: isSelected ? Colors.white : chipColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.notoSans(
                          color: isSelected ? Colors.white : chipColor,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildModernControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: isActive ? 8 : 4,
        shadowColor: isActive 
          ? AppColors.primary.withAlpha(102) 
          : Colors.black.withAlpha(isDark ? 77 : 38),
        borderRadius: BorderRadius.circular(16),
        color: isActive 
          ? AppColors.primary 
          : (isDark ? Colors.grey[900] : Colors.white),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                  ? Colors.transparent
                  : (isDark ? Colors.white12 : Colors.black12),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive 
                ? Colors.white 
                : (isDark ? Colors.white : AppColors.darkGrey),
              size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLayersSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 128 : 51),
              blurRadius: 40,
              spreadRadius: 5,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withAlpha(38),
                          AppColors.primary.withAlpha(26),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.layers_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Map Styles',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Map style options with beautiful tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMapStyleTile(
                    'Standard',
                    'Default map with roads and labels',
                    Icons.map_rounded,
                    _mapStyle == MapStyle.standard,
                    AppColors.primary,
                    () {
                      setState(() => _mapStyle = MapStyle.standard);
                      AppSettings.mapStyle.value = 'standard';
                      Navigator.pop(context);
                    },
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildMapStyleTile(
                    'Satellite',
                    'Aerial imagery from space',
                    Icons.satellite_alt_rounded,
                    _mapStyle == MapStyle.satellite,
                    const Color(0xFF2196F3),
                    () {
                      setState(() => _mapStyle = MapStyle.satellite);
                      AppSettings.mapStyle.value = 'satellite';
                      Navigator.pop(context);
                    },
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildMapStyleTile(
                    'Terrain',
                    'Topographic view with elevation',
                    Icons.terrain_rounded,
                    _mapStyle == MapStyle.topo,
                    const Color(0xFF4CAF50),
                    () {
                      setState(() => _mapStyle = MapStyle.topo);
                      AppSettings.mapStyle.value = 'terrain';
                      Navigator.pop(context);
                    },
                    isDark,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStyleTile(
    String title,
    String description,
    IconData icon,
    bool isSelected,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withAlpha(26)
                  : (isDark ? Colors.grey[850] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [color, color.withAlpha(204)]
                          : [
                              (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(102),
                              blurRadius: 12,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.black54),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? color
                              : (isDark ? Colors.white : AppColors.darkGrey),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(38),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerOffset = screenHeight / 2 - 10;
    
    return Positioned(
      bottom: centerOffset,
      right: 16,
      child: AnimatedScale(
        scale: _locBtnScale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Material(
          elevation: 6,
          shape: const CircleBorder(),
          color: AppColors.cardBackground(context),
          shadowColor: Colors.black.withAlpha(isDark ? (0.5 * 255).toInt() : (0.15 * 255).toInt()),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 18.0);
                setState(() => _mapRotation = 0.0);
                _mapController.rotate(0.0);
              }
              setState(() => _locBtnScale = 0.88);
              Future.delayed(const Duration(milliseconds: 160), () {
                if (mounted) setState(() => _locBtnScale = 1.0);
              });
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha((0.1 * 255).toInt())
                      : Colors.black.withAlpha((0.08 * 255).toInt()),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompassButton() {
    final isRotated = _mapRotation.abs() > 0.1;
    final isActive = _is3DCompassMode;
    final topPadding = MediaQuery.of(context).padding.top;
    // Position below layers button with proper spacing (layers button + gap + this button)
    final buttonTop = topPadding + 100 + 48 + 12 + 52 + 16; // Below layers button
    
    return Positioned(
      top: buttonTop,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutQuart,
        child: Material(
          elevation: isActive ? 8 : (isRotated ? 6 : 4),
          shape: const CircleBorder(),
          color: isActive
              ? const Color(0xFFFF5722).withAlpha((0.15 * 255).toInt())
              : AppColors.cardBackground(context),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isRecentering ? null : _recenterAndTilt3D,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutQuart,
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: const Color(0xFFFF5722), width: 2)
                    : null,
              ),
              child: Stack(
                children: [
                  // Rotating compass icon
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _isRecentering ? 1 : 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: (-_mapRotation * 3.14159 / 180) + (value * 3.14159 * 2),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                const Color(0xFFFF5722),
                                const Color(0xFFFF9800),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // 3D indicator badge
                  if (isActive)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5722).withAlpha((0.4 * 255).toInt()),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          '3D',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // North indicator (stays fixed)
                  if (!isActive)
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isRotated ? AppColors.error : AppColors.grey,
                          ),
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

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 460,
      right: 16,
      child: Column(
        children: [
          Material(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: Colors.white,
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    // Smooth zoom increment (Apple Maps style)
                    final newZoom = (_currentZoom + 0.5).clamp(13.0, 20.0);
                    _mapController.move(_mapController.camera.center, newZoom);
                    setState(() => _currentZoom = newZoom);
                  },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add, color: AppColors.primary),
                  ),
                ),
                Divider(height: 1, color: AppColors.lightGrey),
                InkWell(
                  onTap: () {
                    // Smooth zoom decrement (Apple Maps style)
                    final newZoom = (_currentZoom - 0.5).clamp(13.0, 20.0);
                    _mapController.move(_mapController.camera.center, newZoom);
                    setState(() => _currentZoom = newZoom);
                  },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.remove, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsFAB() {
    return Positioned(
      bottom: 210,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'events',
        backgroundColor: const Color(0xFFE91E63),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const events_screen.EventsScreen(),
            ),
          );
        },
        tooltip: 'Campus Events',
        child: const Icon(Icons.event_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildDirectionsFAB() {
    return Positioned(
      bottom: 140,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'directions',
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DirectionsScreen(),
            ),
          );
          
          if (result != null && result is Map) {
            final start = result['start'] as CampusBuilding?;
            final end = result['end'] as CampusBuilding?;
            final transportMode = result['transportMode'] as String?;
            
            if (start != null && end != null) {
              // Update transport mode if provided
              if (transportMode != null) {
                setState(() {
                  _transportMode = transportMode;
                });
              }
              
              // Update current location if start is specified
              if (start.coordinates != _campusCenter) {
                setState(() {
                  _currentLocation = start.coordinates;
                });
              }
              
              // Calculate route using our routing system
              await _calculateRoute(end);
            }
          }
        },
        tooltip: 'Directions',
        child: const Icon(Icons.directions, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchResults() {
    final bool showingRecents = _searchController.text.isEmpty;
    final List<CampusBuilding> list = showingRecents ? _recentSearches : _filteredBuildings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (list.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 140,
      left: 16,
      right: 16,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.35,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showingRecents)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: AppColors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recent searches',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _recentSearches.clear();
                          _showSearchResults = false;
                        });
                      },
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(4),
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final building = list[index];
                  final distance = _currentLocation != null
                      ? const Distance().distance(_currentLocation!, building.coordinates)
                      : null;
                  
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(building.category).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(building.category),
                          size: 16,
                          color: _getCategoryColor(building.category),
                        ),
                      ),
                    ),
                    title: Text(
                      building.name,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Flexible(
                          child: Text(
                            building.categoryName,
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              color: AppColors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distance != null) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.grey, fontSize: 11)),
                          Text(
                            _formatDistance(distance),
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      setState(() => _showSearchResults = false);
                      _showBuildingSheet(building, fromSearch: true);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingInfo() {
    if (_selectedBuilding == null) return const SizedBox.shrink();
    final b = _selectedBuilding!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distance = _currentLocation != null
        ? const Distance().distance(_currentLocation!, b.coordinates)
        : null;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXLarge)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(b.category).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(_getCategoryIcon(b.category), color: _getCategoryColor(b.category)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name,
                              style: GoogleFonts.notoSans(fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(b.categoryName, style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
                            if (distance != null) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.place, size: 12, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(_formatDistance(distance), style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.primary)),
                            ]
                          ])
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedBuilding = null),
                    ),
                  ],
                ),
                if (b.description != null) ...[
                  const SizedBox(height: 14),
                  Text(b.description!, style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.darkGrey)),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _calculateRoute(b);
                      },
                      icon: Icon(_getTransportIcon()),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _selectedBuilding = b);
                        _calculateRoute(b);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showAnimatedSuccess(
                        context,
                        'Share coming soon',
                        icon: Icons.share_rounded,
                        iconColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // _buildRouteInfoCard removed (superseded by _buildNavigationHUD)

  // Transport chips removed (simplified UI); you can re-introduce if multi-mode quick switching is desired.

  IconData _getTransportIcon() {
    switch (_transportMode) {
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

  // Bottom navigation bar — floating pill with rounded background and highlight
  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          constraints: const BoxConstraints(minHeight: 60),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.borderAdaptive(context).withAlpha((0.3 * 255).toInt()),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? (0.5 * 255).toInt() : (0.15 * 255).toInt()),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.explore_outlined, 'Explore', 0),
              _navItem(Icons.favorite_border_rounded, 'Favorites', 1),
              _navItem(Icons.diamond_outlined, 'Premium', 2),
              _navItem(Icons.person_outline_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _selectedNavIndex == index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.08),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (index == 1) {
                  // Dedicated Favorites screen
                  Navigator.push(
                    context,
                    AppRoutes.slideRoute(const FavoritesScreen()),
                  ).then((result) {
                    if (result is CampusBuilding) {
                      setState(() => _selectedBuilding = result);
                      _mapController.move(result.coordinates, 18);
                    }
                  });
                } else if (index == 2) {
                  // Subscription screen replaces Layers
                  Navigator.push(
                    context,
                    AppRoutes.scaleRoute(const SubscriptionScreen()),
                  );
                } else if (index == 3) {
                  // Profile screen
                  Navigator.push(
                    context,
                    AppRoutes.slideRoute(const ProfileScreen()),
                  ).then((result) {
                    if (result is CampusBuilding) {
                      setState(() => _selectedBuilding = result);
                      _mapController.move(result.coordinates, 18);
                    }
                  });
                } else {
                  setState(() => _selectedNavIndex = index);
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withAlpha((0.85 * 255).toInt()),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha((0.3 * 255).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: selected ? Colors.white : AppColors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Layers button and modal removed per new spec

  // Favorites panel
  Widget _buildFavoritesPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(
          key: ValueKey(_favorites.length),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _favorites.isEmpty
              ? Row(
                  children: [
                    const Icon(Icons.star_border, color: AppColors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No favorites yet. Tap the star on a building to add.',
                        style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final building = _favorites[index];
                      return InkWell(
                        onTap: () => _showBuildingSheet(building),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.ash,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getCategoryIcon(building.category), size: 16, color: _getCategoryColor(building.category)),
                                  const Spacer(),
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                building.name,
                                style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                building.categoryName,
                                style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  // Simple settings panel placeholder
  Widget _buildSettingsPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Settings', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('More settings coming soon...', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(CampusBuilding building) {
    setState(() {
      if (_favorites.any((b) => b.name == building.name)) {
        _favorites.removeWhere((b) => b.name == building.name);
        _favService.removeFavorite(building.name);
      } else {
        _favorites.add(building);
        _favService.addFavorite(building.name);
      }
    });
  }

  void _showBuildingSheet(CampusBuilding building, {bool fromSearch = false}) async {
    _addToRecent(building);
    setState(() {
      _selectedBuilding = building;
      if (fromSearch) {
        _showTempMarker = true;
        _tempMarkerBuilding = building;
      }
    });
    
    // Smooth 3D animation to building location
    if (fromSearch) {
      // Animate map with smooth zoom and rotation
      final startZoom = _mapController.camera.zoom;
      final targetZoom = 18.5;
      final startRotation = _mapRotation;
      const steps = 30;
      const duration = Duration(milliseconds: 800);
      final stepDuration = duration.inMilliseconds ~/ steps;
      
      for (int i = 0; i <= steps; i++) {
        final t = Curves.easeInOutCubic.transform(i / steps);
        final zoom = startZoom + ((targetZoom - startZoom) * t);
        final rotation = startRotation * (1 - t); // Smooth rotation to 0
        
        _mapController.move(building.coordinates, zoom);
        _mapController.rotate(rotation);
        
        if (mounted) {
          setState(() {
            _currentZoom = zoom;
            _mapRotation = rotation;
          });
        }
        
        await Future.delayed(Duration(milliseconds: stepDuration));
      }
      
      // Animate temporary marker with bounce
      _tempMarkerController?.reset();
      _tempMarkerController?.forward();
    } else {
      // Standard move for non-search selections
      _mapController.move(building.coordinates, 18.0);
    }
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (ctx) {
        return BuildingDetailSheet(
          building: building,
          onClose: () {
            Navigator.pop(ctx);
            setState(() {
              _selectedBuilding = null;
              _showTempMarker = false;
              _tempMarkerBuilding = null;
            });
          },
          onStartNavigation: (building) async {
            debugPrint('🔵 Start button clicked for ${building.name}');
            Navigator.pop(ctx);
            debugPrint('🔵 Dialog closed, calling _calculateRoute');
            await _calculateRoute(building);
            debugPrint('🔵 _calculateRoute completed');
          },
          onGetDirections: (building) async {
            Navigator.pop(ctx);
            setState(() {
              _selectedBuilding = building;
            });
            await _calculateRoute(building);
          },
          onShare: (building) {
            Share.share(
              'Check out ${building.name} on Campus Navigator!\nCategory: ${building.categoryName}',
              subject: building.name,
            );
          },
          onFavoriteToggle: (building, isFavorite) {
            setState(() {
              if (isFavorite) {
                if (!_favorites.any((b) => b.name == building.name)) {
                  _favorites.add(building);
                }
              } else {
                _favorites.removeWhere((b) => b.name == building.name);
              }
            });
            if (mounted) {
              showAnimatedSuccess(
                context,
                isFavorite ? '${building.name} added to favorites' : '${building.name} removed from favorites',
                icon: isFavorite ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                iconColor: isFavorite ? Colors.red : AppColors.grey,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildTransportSelector(CampusBuilding building, double? straightDistance) {
    final modes = const [
      {'key': 'foot', 'icon': Icons.directions_walk, 'label': 'Walk'},
      {'key': 'bicycle', 'icon': Icons.directions_bike, 'label': 'Bike'},
      {'key': 'car', 'icon': Icons.directions_car, 'label': 'Car'},
      {'key': 'bus', 'icon': Icons.directions_bus, 'label': 'Bus'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode & ETA', style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: modes.map((m) {
            final key = m['key'] as String;
            final selected = _transportMode == key;
            final eta = _etaLabelFor(key, straightDistance);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () async {
                    setState(() => _transportMode = key);
                    await _prefs.saveSettings(lastTransportMode: key);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.ash,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.borderAdaptive(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(m['icon'] as IconData, color: selected ? Colors.white : AppColors.darkGrey),
                        const SizedBox(height: 4),
                        Text(m['label'] as String, style: GoogleFonts.notoSans(fontSize: 11, color: selected ? Colors.white : AppColors.darkGrey)),
                        if (eta.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(eta, style: GoogleFonts.notoSans(fontSize: 10, color: selected ? Colors.white70 : AppColors.grey)),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatEtaApprox(double meters, String mode) {
    double speed; // m/s
    switch (mode) {
      case 'bicycle': speed = 4.2; break;
      case 'car':
      case 'bus': speed = 8.3; break;
      default: speed = 1.4; break;
    }
    final secs = meters / speed;
    final mins = (secs / 60).ceil();
    return mins < 60 ? '$mins min' : '${mins ~/ 60}h ${mins % 60}m';
  }

  Future<void> _precomputeEtas(LatLng start, LatLng end) async {
    setState(() {
      _etaSecsByMode = null; // mark loading
      _distByMode = null;
    });
    final Map<String, double> etas = {};
    final Map<String, double> dists = {};
    // profiles mapping
    final profiles = <String, String>{
      'foot': 'walking',
      'bicycle': 'cycling',
      'car': 'driving',
      'bus': 'driving',
    };
    for (final entry in profiles.entries) {
      try {
        final res = await _fetchOsrmRoute(entry.value, start, end);
        if (res != null) {
          dists[entry.key] = res.item1; // meters
          etas[entry.key] = res.item2; // seconds
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _etaSecsByMode = etas;
        _distByMode = dists;
      });
    }
  }

  // Returns (distanceMeters, durationSeconds)
  Future<_Tuple?> _fetchOsrmRoute(String profile, LatLng start, LatLng end) async {
    final url = 'https://router.project-osrm.org/route/v1/$profile/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=false';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final routes = data['routes'] as List?;
      if (routes != null && routes.isNotEmpty) {
        final r = routes.first as Map;
        final dist = (r['distance'] as num).toDouble();
        final dur = (r['duration'] as num).toDouble();
        return _Tuple(dist, dur);
      }
    }
    return null;
  }

  String _etaLabelFor(String mode, double? straightLineMeters) {
    final etaMap = _etaSecsByMode;
    if (etaMap != null && etaMap.containsKey(mode) && (etaMap[mode] ?? 0) > 0) {
      final secs = etaMap[mode]!;
      final mins = (secs / 60).ceil();
      return mins < 60 ? '$mins min' : '${mins ~/ 60}h ${mins % 60}m';
    }
    // fallback approximate if not yet loaded
    if (straightLineMeters != null) return _formatEtaApprox(straightLineMeters, mode);
    return '…';
  }
}

// Custom painter for direction arrow
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(size.width * 0.7, size.height * 0.5); // Right
    path.lineTo(size.width / 2, size.height * 0.4); // Middle
    path.lineTo(size.width * 0.3, size.height * 0.5); // Left
    path.close();

    canvas.drawPath(path, paint);
    
    // Add shadow
    canvas.drawShadow(path, Colors.black45, 2, true);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => false;
}

// Ultra-Smooth Layers Button with Advanced Animations
class _SmoothLayersButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _SmoothLayersButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SmoothLayersButton> createState() => _SmoothLayersButtonState();
}

class _SmoothLayersButtonState extends State<_SmoothLayersButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() => _isPressed = false);
            widget.onTap();
          }
        });
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.grey[850]?.withAlpha((0.95 * 255).toInt())
                    : Colors.white.withAlpha((0.95 * 255).toInt()),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withAlpha((0.12 * 255).toInt())
                      : Colors.black.withAlpha((0.08 * 255).toInt()),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(widget.isDark ? (0.5 * 255).toInt() : (0.15 * 255).toInt()),
                    blurRadius: 20 * _glowAnimation.value,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(widget.isDark ? (0.3 * 255).toInt() : (0.08 * 255).toInt()),
                    blurRadius: 30 * _glowAnimation.value,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.layers_rounded,
                    color: _isPressed
                        ? AppColors.primary
                        : (widget.isDark
                            ? Colors.white.withAlpha(230)
                            : Colors.black.withAlpha(204)),
                    size: 24,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Element Wrapper for Staggered Entrance Animations (Currently Unused)
/* 
class _AnimatedElement extends StatelessWidget {
  final Widget child;
  final AnimationController? controller;
  final int delay;

  const _AnimatedElement({
    required this.child,
    this.controller,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null) return child;

    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) {
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller!,
          curve: Curves.easeOut,
        ));

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller!,
          curve: Curves.easeOutCubic,
        ));

        final scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller!,
          curve: Curves.easeOutBack,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
*/

// Apple Maps-style Voice Search Dialog with Speech Recognition
class _VoiceSearchDialog extends StatefulWidget {
  final bool isDark;
  final Function(String) onResult;

  const _VoiceSearchDialog({
    required this.isDark,
    required this.onResult,
  });

  @override
  State<_VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<_VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  String _listeningText = 'Initializing...';
  String _spokenText = '';
  bool _isListening = true;
  html.SpeechRecognition? _recognition;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    // Initialize web speech recognition
    _initializeSpeech();
  }

  void _initializeSpeech() {
    try {
      // Create web Speech Recognition instance (uses device microphone)
      _recognition = html.SpeechRecognition();
      
      if (_recognition == null) {
        if (mounted) {
          setState(() {
            _listeningText = 'Speech not supported in browser';
            _isListening = false;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
        return;
      }
      
      // Configure for optimal device microphone usage
      // continuous: false for single command (better for location search)
      // interimResults: true for real-time feedback
      _recognition!.continuous = false; // Single command mode
      _recognition!.interimResults = true; // Show partial results
      _recognition!.lang = 'en-US';
      
      // Set max alternatives for better recognition accuracy
      try {
        _recognition!.maxAlternatives = 3;
      } catch (e) {
        debugPrint('maxAlternatives not supported: $e');
      }
      
      // Handle results
      _recognition!.onResult.listen((event) {
        try {
          final results = event.results;
          if (results != null && results.isNotEmpty) {
            final result = results[results.length - 1];
            // Handle both iOS and standard browser formats
            String? transcript;
            bool isFinal = false;
            
            try {
              // Try standard format first
              final alternatives = result as List<dynamic>;
              if (alternatives.isNotEmpty) {
                transcript = alternatives[0].transcript as String?;
                isFinal = result.isFinal ?? false;
              }
            } catch (e) {
              // iOS Safari format - direct access
              try {
                transcript = (result as dynamic).transcript as String?;
                isFinal = (result as dynamic).isFinal ?? false;
              } catch (e2) {
                debugPrint('Error parsing result: $e2');
              }
            }
            
            if (transcript != null && transcript.isNotEmpty && mounted) {
              setState(() {
                _spokenText = transcript!;
                if (isFinal) {
                  _listeningText = 'Searching for "$transcript"...';
                  _isListening = false;
                } else {
                  _listeningText = 'Listening: "$transcript"';
                }
              });
              
              // If final result, immediately search and animate to location
              if (isFinal) {
                try {
                  _recognition?.stop();
                } catch (e) {
                  debugPrint('Error stopping recognition: $e');
                }
                // Immediately trigger search with animation
                _finalizeSpeech();
              }
            }
                    }
        } catch (e) {
          debugPrint('Result handling error: $e');
        }
      });
      
      // Handle errors with clear microphone permission prompts
      _recognition!.onError.listen((error) {
        debugPrint('Speech error: ${error.error}');
        
        // Stop and clean up microphone access
        try {
          _recognition?.stop();
          _recognition?.abort();
        } catch (e) {
          debugPrint('Error cleaning up: $e');
        }
        
        if (mounted) {
          String message = 'Error occurred';
          if (error.error == 'not-allowed' || error.error == 'service-not-allowed') {
            message = 'Microphone access denied.\n\nPlease enable microphone permissions in your browser settings to use voice search.';
          } else if (error.error == 'network') {
            message = 'Network error. Please check your connection.';
          } else if (error.error == 'no-speech') {
            message = 'No speech detected.\n\nTap the microphone to try again.';
          } else if (error.error == 'aborted') {
            // Don't show error for intentional abort
            return;
          } else if (error.error == 'audio-capture') {
            message = 'Microphone not found.\n\nPlease check your device microphone.';
          }
          setState(() {
            _listeningText = message;
            _isListening = false;
          });
          if (error.error != 'no-speech') {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) Navigator.pop(context);
            });
          }
        }
      });
      
      // Handle end
      _recognition!.onEnd.listen((_) {
        debugPrint('Speech recognition ended');
        
        // Ensure microphone is fully released
        try {
          _recognition?.abort();
        } catch (e) {
          debugPrint('Error aborting: $e');
        }
        
        if (mounted && _spokenText.isEmpty && _isListening) {
          setState(() {
            _listeningText = 'No speech detected - tap to try again';
            _isListening = false;
          });
        }
      });
      
      _speechAvailable = true;
      _startListening();
      
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      if (mounted) {
        setState(() {
          _listeningText = 'Speech not available';
          _isListening = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  void _startListening() async {
    if (!_speechAvailable || _recognition == null) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _listeningText = 'Speak now...';
      _spokenText = '';
      _isListening = true;
    });

    // iOS Safari requires immediate start without delay
    // Delay causes the API to timeout and fail
    try {
      // Start web speech recognition immediately
      _recognition!.start();
      
      // Update UI after start
      if (mounted) {
        setState(() {
          _listeningText = 'Listening...';
        });
      }
      
      // Auto-stop after 10 seconds to release microphone
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isListening) {
          try {
            _recognition?.stop();
            _recognition?.abort();
          } catch (e) {
            debugPrint('Timeout stop error: $e');
          }
          if (_spokenText.isNotEmpty) {
            _finalizeSpeech();
          } else if (mounted) {
            setState(() {
              _listeningText = 'Timeout - tap to try again';
              _isListening = false;
            });
          }
        }
      });
      
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (mounted) {
        setState(() {
          _listeningText = 'Failed to start - tap mic again';
          _isListening = false;
        });
      }
    }
  }

  void _finalizeSpeech() async {
    if (_spokenText.isEmpty) {
      // Clean up microphone before closing
      try {
        _recognition?.stop();
        _recognition?.abort();
      } catch (e) {
        debugPrint('Cleanup error: $e');
      }
      Navigator.pop(context);
      return;
    }

    setState(() {
      _listeningText = 'Processing...';
      _isListening = false;
    });
    
    // Stop and release microphone immediately
    try {
      _recognition?.stop();
      _recognition?.abort();
    } catch (e) {
      debugPrint('Stop error: $e');
    }

    HapticFeedback.lightImpact();

    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    Navigator.pop(context);
    widget.onResult(_spokenText);
  }

  @override
  void dispose() {
    // Fully release microphone access
    try {
      _recognition?.stop();
      _recognition?.abort();
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.3 * 255).toInt()),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: AppColors.primary.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Microphone with Pulsing Circles
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulsing circles
                  if (_isListening) ...[
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 140 * _pulseAnimation.value,
                          height: 140 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(
                              (0.1 * 255 / _pulseAnimation.value).toInt(),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 110 * _pulseAnimation.value,
                          height: 110 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(
                              (0.15 * 255 / _pulseAnimation.value).toInt(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  // Main microphone container
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isListening
                                  ? [
                                      AppColors.primary,
                                      const Color(0xFF0052CC),
                                    ]
                                  : (_listeningText.toLowerCase().contains('no speech') || 
                                     _listeningText.toLowerCase().contains('error') ||
                                     _listeningText.toLowerCase().contains('denied') ||
                                     _listeningText.toLowerCase().contains('not found'))
                                      ? [
                                          const Color(0xFFFF3B30),
                                          const Color(0xFFCC0000),
                                        ]
                                      : [
                                          AppColors.success,
                                          AppColors.success.withAlpha(204),
                                        ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? AppColors.primary
                                        : AppColors.success)
                                    .withAlpha(102),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening 
                                ? Icons.mic_rounded 
                                : (_listeningText.toLowerCase().contains('no speech') || 
                                   _listeningText.toLowerCase().contains('error') ||
                                   _listeningText.toLowerCase().contains('denied') ||
                                   _listeningText.toLowerCase().contains('not found'))
                                    ? Icons.error_outline_rounded
                                    : Icons.check_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Listening text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _listeningText,
                  key: ValueKey(_listeningText),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : const Color(0xFF1C1C1E),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Spoken text or instruction
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _spokenText.isEmpty
                    ? Text(
                        'Say your destination',
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '"$_spokenText"',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(height: 32),
              
              // Cancel button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withAlpha(25)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
