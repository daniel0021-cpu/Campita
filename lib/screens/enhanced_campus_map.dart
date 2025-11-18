// Enhanced Campus Map with Google Maps-style features
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/campus_building.dart';
import '../theme/app_theme.dart';
import '../utils/osm_data_fetcher.dart';
import 'directions_screen.dart';
import 'route_preview_screen.dart';
import 'live_navigation_screen.dart';
 import '../utils/preferences_service.dart';
 import '../utils/favorites_service.dart';
 import '../utils/app_settings.dart';
 import 'search_screen.dart';
 import 'subscription_screen.dart';
 import 'profile_screen.dart';
 import 'favorites_screen.dart';
 import '../utils/app_routes.dart';
 enum MapStyle { standard, satellite, topo }

class _Tuple {
  final double item1; // distanceMeters
  final double item2; // durationSeconds
  const _Tuple(this.item1, this.item2);
}

class EnhancedCampusMap extends StatefulWidget {
  const EnhancedCampusMap({super.key});

  @override
  State<EnhancedCampusMap> createState() => _EnhancedCampusMapState();
}

class _EnhancedCampusMapState extends State<EnhancedCampusMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LatLng _campusCenter = const LatLng(6.7415, 5.4055);
  LatLng? _currentLocation;
  CampusBuilding? _selectedBuilding;
  List<LatLng> _routePolyline = [];
  LatLng? _destinationEntrance;
  bool _showSearchResults = false;
  List<CampusBuilding> _filteredBuildings = [];
  BuildingCategory? _selectedCategory;
  double? _routeDistance;
  double? _routeDuration;
  double _mapRotation = 0.0;
  double _currentZoom = 16.5;
  String _transportMode = 'foot';
  bool _is3DView = true;
  List<List<LatLng>> _footpaths = [];
  List<CampusBuilding> _osmBuildings = [];
  bool _loadingOSMData = true;
  final List<CampusBuilding> _recentSearches = [];
  double _mapBearing = 0.0;
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
  double _viewToggleScale = 1.0;
  bool _outsideOkadaWarned = false;
  // Route draw animation
  late AnimationController _routeDrawController;
  late Animation<double> _routeDrawProgress;
  // Precomputed ETAs/distances per mode for bottom sheet
  Map<String, double>? _etaSecsByMode; // key: foot/bicycle/car/bus
  Map<String, double>? _distByMode;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadOSMFootpaths();
    _loadOSMBuildings();
    _loadUserPreferences();
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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _routeDrawController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _routeDrawProgress = CurvedAnimation(parent: _routeDrawController, curve: Curves.easeOut);
    FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h != null && mounted) {
        setState(() => _userHeading = h);
      }
    });
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
        case 'terrain':
          _mapStyle = MapStyle.topo;
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

  Future<void> _loadOSMBuildings() async {
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
        setState(() {
          _osmBuildings = buildings;
          _loadingOSMData = false;
        });
        _loadFavoritesFromPrefs();
        debugPrint('Loaded ${buildings.length} buildings from OSM');
      } else {
        setState(() {
          _osmBuildings = campusBuildings;
          _loadingOSMData = false;
        });
        _loadFavoritesFromPrefs();
        debugPrint('Using static building data (${campusBuildings.length})');
      }
    } catch (e) {
      debugPrint('Error loading OSM buildings: $e');
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
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
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
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
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

  bool _isWithinOkadaBounds(LatLng location) {
    const double okadaRadiusKm = 10.0;
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      _campusCenter,
      location,
    );
    return distance <= okadaRadiusKm;
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
    final start = _currentLocation ?? _campusCenter;
    
    try {
      List<LatLng> routePoints = [];
      double distance = 0;
      double duration = 0;
      
      // Use different routing based on transport mode
      if (_transportMode == 'foot') {
        // Prefer dedicated footpaths; fallback to mixed pedestrian (footpaths + safe roads)
        print('Calculating walking route (footpaths preferred) from ${start.latitude},${start.longitude} to ${destination.coordinates.latitude},${destination.coordinates.longitude}');
        routePoints = await _calculateFootpathRoute(start, destination.coordinates);

        if (routePoints.isEmpty) {
          // Fallback: allow walk on accessible roads then append building entrance
            print('Strict footpath route not found; falling back to mixed pedestrian route');
            routePoints = await _calculateMixedPedestrianRoute(start, destination.coordinates);
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
          throw Exception('No walkable route found.');
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
        if (mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RoutePreviewScreen(
              routePoints: routePoints,
              start: _currentLocation ?? _campusCenter,
              end: destination.coordinates,
              distanceMeters: distance,
              durationSeconds: duration,
              transportMode: _transportMode,
            ),
          ));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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
    // For end node, if entrance is available, snap to it; otherwise require at least 15m from building to stay on footpath
    int? startNode = _findNearestNodeId(start, nodes);
    int? endNode = entrance != null
      ? _findNearestNodeId(entrance, nodes)
      : _findNearestNodeId(end, nodes, minDistanceFromTarget: 15.0);
        
        if (startNode != null && endNode != null) {
          // Use A* pathfinding through the pedestrian graph
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
            // End at the nearest footpath node, not the building 
            // If we found an entrance, remember it for UI display; end stays on the nearest footpath node
            if (entrance != null) {
              _destinationEntrance = entrance;
            }
            print('Pedestrian route: ${route.length} points, ending at ${entrance != null ? 'building entrance' : 'footpath'}');
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
      print('Error calculating footpath route: $e');
    }
    
    return [];
  }

  // Query the nearest OSM entrance node (entrance=*) around a target location
  Future<LatLng?> _fetchNearestEntrance(LatLng target) async {
    try {
      final double radiusMeters = 60; // search within ~60m around the destination
      final query = '''
[out:json];
node(around:${radiusMeters},${target.latitude},${target.longitude})["entrance"];
out body;''';
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = (data['elements'] as List?) ?? [];
        if (elements.isEmpty) return null;
        // Prefer entrance=main if present; otherwise the closest node
        LatLng? best;
        double bestDist = double.infinity;
        for (final el in elements) {
          if (el['type'] != 'node') continue;
          final lat = (el['lat'] as num).toDouble();
          final lon = (el['lon'] as num).toDouble();
          final node = LatLng(lat, lon);
          final tags = (el['tags'] as Map?) ?? {};
          final isMain = (tags['entrance']?.toString().toLowerCase() == 'main');
          final d = const Distance().distance(target, node);
          if (isMain) {
            // pick first main or closer main
            if (d < bestDist) {
              best = node;
              bestDist = d;
            }
          } else if (best == null) {
            // track the closest if no main found yet
            if (d < bestDist) {
              best = node;
              bestDist = d;
            }
          }
        }
        return best;
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
    
    final maxDistance = 500.0; // Increased to 500m to find nodes better
    if (minDistance < maxDistance && nearestId != null) {
      print('Found nearest node at ${minDistance.toStringAsFixed(0)}m away');
      return nearestId;
    }
    print('No node found within ${maxDistance}m (closest: ${minDistance.toStringAsFixed(0)}m)');
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
                    child: Container(
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
    
    return markers;
  }

  IconData _getCategoryIcon(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return Icons.school;
      case BuildingCategory.administrative:
        return Icons.apartment;
      case BuildingCategory.library:
        return Icons.local_library;
      case BuildingCategory.dining:
        return Icons.restaurant_menu;
      case BuildingCategory.banking:
        return Icons.account_balance;
      case BuildingCategory.sports:
        return Icons.fitness_center;
      case BuildingCategory.student_services:
        return Icons.support;
      case BuildingCategory.research:
        return Icons.science;
      case BuildingCategory.health:
        return Icons.local_hospital;
      case BuildingCategory.residential:
        return Icons.home;
      case BuildingCategory.worship:
        return Icons.church;
    }
  }

  Color _getCategoryColor(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return AppColors.academic;
      case BuildingCategory.administrative:
        return AppColors.administrative;
      case BuildingCategory.library:
        return AppColors.library;
      case BuildingCategory.dining:
        return AppColors.dining;
      case BuildingCategory.banking:
        return AppColors.banking;
      case BuildingCategory.sports:
        return AppColors.sports;
      case BuildingCategory.student_services:
        return AppColors.studentServices;
      case BuildingCategory.research:
        return AppColors.research;
      case BuildingCategory.health:
        return Colors.red;
      case BuildingCategory.residential:
        return Colors.purple;
      case BuildingCategory.worship:
        return Colors.deepPurple;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    _routeDrawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('EnhancedCampusMap: Building with navIndex=$_selectedNavIndex');
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme color
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Theme.of(context).colorScheme.surface, // Ensure visible background
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Map layer - must fill entire available space
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                  initialCenter: _campusCenter,
                  initialZoom: 16.5,
                  maxZoom: 20, // Higher zoom for detailed building inspection
                  minZoom: 13,
                  initialRotation: _mapRotation,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                  enableMultiFingerGestureRace: true,
                  rotationWinGestures: MultiFingerGesture.rotate,
                  pinchMoveWinGestures: MultiFingerGesture.pinchMove | MultiFingerGesture.pinchZoom,
                  // Apple Maps-like ultra-smooth scrolling
                  scrollWheelVelocity: 0.002, // Smoother mouse wheel
                  rotationThreshold: 15.0, // Easier rotation
                  pinchZoomThreshold: 0.4, // Smoother pinch zoom
                  pinchMoveThreshold: 30.0,
                ),
                // Continuous smooth updates for fluid Apple Maps feel
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && mounted) {
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
                subdomains: _mapStyle == MapStyle.topo ? const ['a','b','c'] : const <String>[],
                userAgentPackageName: 'com.example.campus_navigation',
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
                  ), // FlutterMap
                ), // Positioned.fill
          
                if (!_isNavigating) _buildSearchBar(),
          if (!_isNavigating) _buildCategoryFilter(),
          if (!_isNavigating) _buildCompassButton(),
          if (!_isNavigating) _build2D3DToggle(),
          _buildMyLocationButton(), // Keep location button always
          if (!_isNavigating) _buildRefreshButton(),
          // Layers button removed per new UI spec
          // Favorites overlay removed: dedicated screen now handles favorites
          // if (!_isNavigating && _selectedNavIndex == 1) _buildFavoritesPanel(),
          if (!_isNavigating && _selectedNavIndex == 3) _buildSettingsPanel(),
          if (_isNavigating) _buildNavigationHUD(),
          
          // Loading indicator - non-blocking, positioned at bottom
          if (_loadingOSMData)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading campus data...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          if (!_isNavigating) _buildDirectionsFAB(),
          
          // Search results
          if (_showSearchResults) _buildSearchResults(),
          
          // Selected building info (only show if no active route)
          if (_selectedBuilding != null && _routePolyline.isEmpty) 
            _buildBuildingInfo(),
          
          // Deprecated route info card replaced by navigation HUD
                ],
              ), // Stack
            ); // Container
          },
        ), // LayoutBuilder
      ), // SafeArea
      bottomNavigationBar: _isNavigating ? null : _buildBottomNavBar(),
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
      left: 16,
      right: 80, // Give more space for buttons on right
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search campus buildings...',
            hintStyle: GoogleFonts.notoSans(color: AppColors.grey),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _showSearchResults = false;
                        _filteredBuildings = [];
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.primary),
                    tooltip: 'Open full search',
                    onPressed: () async {
                      final result = await Navigator.push<CampusBuilding>(
                        context,
                        AppRoutes.fadeRoute(const SearchScreen()),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedBuilding = result;
                        });
                        _mapController.move(result.coordinates, 18);
                      }
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildModernCategoryChip('All', null, Icons.explore_rounded),
            const SizedBox(width: 10),
            ...BuildingCategory.values.where((category) {
              final buildingsToCheck = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
              return buildingsToCheck.any((b) => b.category == category);
            }).map((category) {
              final buildingsToCheck = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
              final building = buildingsToCheck.firstWhere((b) => b.category == category);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
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
        // Google's high-quality satellite imagery (best available)
        // Fallback to Esri World Imagery if Google is unavailable
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case MapStyle.topo:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  Widget _buildModernCategoryChip(String label, BuildingCategory? category, IconData icon) {
    final isSelected = _selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Material(
        elevation: isSelected ? 8 : 3,
        shadowColor: isSelected ? AppColors.primary.withOpacity(0.4) : Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        color: isSelected 
            ? AppColors.primary 
            : (isDark ? AppColors.darkCard : Colors.white),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = _selectedCategory == category ? null : category;
            });
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    color: isSelected ? Colors.white : AppColors.textPrimaryAdaptive(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
    return Positioned(
      bottom: 240,
      right: 16,
      child: AnimatedScale(
        scale: _locBtnScale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Material(
          elevation: 8,
          shape: const CircleBorder(),
          color: AppColors.cardBackground(context),
          shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
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
                border: Border.all(color: AppColors.borderAdaptive(context).withOpacity(0.5)),
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
    
    return Positioned(
      bottom: 380,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Material(
          elevation: isRotated ? 6 : 4,
          shape: const CircleBorder(),
          color: AppColors.cardBackground(context),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              // Smooth rotation back to north with animation
              setState(() {
                _mapRotation = 0.0;
              });
              _mapController.rotate(0.0);
            },
            child: Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  // Rotating compass icon
                  Center(
                    child: Transform.rotate(
                      angle: -_mapRotation * 3.14159 / 180,
                      child: Icon(
                        Icons.navigation,
                        color: isRotated ? AppColors.primary : AppColors.grey,
                        size: 36,
                      ),
                    ),
                  ),
                  // North indicator (stays fixed)
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

  Widget _build2D3DToggle() {
    return Positioned(
      bottom: 490,
      right: 16,
      child: AnimatedScale(
        scale: _viewToggleScale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Material(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: _is3DView ? AppColors.primary : AppColors.cardBackground(context),
          child: InkWell(
            onTap: () {
              setState(() {
                _is3DView = !_is3DView;
                if (_is3DView) {
                  // 3D View: Switch to high-quality satellite imagery for building inspection
                  // Zoom in closer to see building details and real dimensions
                  final target = _currentLocation ?? _mapController.camera.center;
                  _mapStyle = MapStyle.satellite; // Switch to satellite for 3D
                  _mapController.move(target, (_currentZoom + 1.5).clamp(17.0, 20.0));
                  // Apply heading-based rotation for perspective
                  _mapController.rotate(_userHeading);
                } else {
                  // 2D View: Return to standard map for navigation clarity
                  // Users can still rotate/zoom freely in 2D mode
                  final target = _currentLocation ?? _mapController.camera.center;
                  _mapStyle = MapStyle.standard; // Switch to standard for 2D
                  _mapController.move(target, (_currentZoom - 1.5).clamp(14.0, 18.0));
                  // Reset rotation to north-up for 2D clarity
                  _mapController.rotate(0);
                }
                _viewToggleScale = 0.85;
              });
              Future.delayed(const Duration(milliseconds: 160), () {
                if (mounted) setState(() => _viewToggleScale = 1.0);
              });
            },
            child: SizedBox(
              width: 48,
              height: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _is3DView ? Icons.threed_rotation : Icons.map,
                    color: _is3DView ? Colors.white : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _is3DView ? '3D' : '2D',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _is3DView ? Colors.white : AppColors.primary,
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

  Widget _buildRefreshButton() {
    return Positioned(
      bottom: 320,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        color: AppColors.cardBackground(context),
        child: InkWell(
          onTap: _loadingOSMData ? null : _loadOSMBuildings,
          child: SizedBox(
            width: 48,
            height: 48,
            child: _loadingOSMData
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'OSM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionsFAB() {
    return Positioned(
      bottom: 100,
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
                    onTap: () => _showBuildingSheet(building),
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
                      onPressed: () => _calculateRoute(b),
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
                      onPressed: () => setState(() => _currentLocation = b.coordinates),
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
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share coming soon'))),
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
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 12),
      child: SafeArea(
        top: false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.borderAdaptive(context).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _navItem(Icons.home_rounded, 'Home', 0),
                const SizedBox(width: 4),
                _navItem(Icons.star_rounded, 'Favorites', 1),
                const SizedBox(width: 4),
                _navItem(Icons.workspace_premium_rounded, 'Pro', 2),
                const SizedBox(width: 4),
                _navItem(Icons.person_rounded, 'Profile', 3),
              ],
            ),
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
                            AppColors.primary.withOpacity(0.85),
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
                            color: AppColors.primary.withOpacity(0.3),
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

  void _showBuildingSheet(CampusBuilding building) async {
    _addToRecent(building);
    setState(() => _selectedBuilding = building);
    final isFav = _favorites.any((b) => b.name == building.name);
    final distance = _currentLocation != null
        ? const Distance().distance(_currentLocation!, building.coordinates)
        : null;
    // Precompute precise ETAs via OSRM in background for all modes
    final start = _currentLocation ?? _campusCenter;
    _precomputeEtas(start, building.coordinates);
    await Future.delayed(const Duration(milliseconds: 90));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DraggableScrollableSheet(
          expand: false,
            initialChildSize: 0.40,
            minChildSize: 0.30,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(building.category).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(_getCategoryIcon(building.category), color: _getCategoryColor(building.category), size: 26),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(building.name, style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(building.categoryName, style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
                                  if (distance != null) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.place, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 2),
                                    Text(_formatDistance(distance), style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.primary)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : AppColors.grey),
                          onPressed: () {
                            _toggleFavorite(building);
                            Navigator.pop(context);
                            _showBuildingSheet(building);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (building.description != null)
                      Text(building.description!, style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.darkGrey)),
                    const SizedBox(height: 18),
                    // Transport selector with quick ETAs
                    _buildTransportSelector(building, distance),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _calculateRoute(building);
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
                          onPressed: () async {
                            Navigator.pop(context);
                            // compute and go to live navigation directly
                            await _calculateRoute(building);
                            if (!mounted || _routePolyline.isEmpty) return;
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => LiveNavigationScreen(
                                routePoints: _routePolyline,
                                destination: building.coordinates,
                                transportMode: _transportMode,
                              ),
                            ));
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
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share coming soon'))),
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
                    const SizedBox(height: 22),
                    if (building.openingHours != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: AppColors.grey),
                          const SizedBox(width: 8),
                          Text(building.openingHours!, style: GoogleFonts.notoSans(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (building.amenities != null && building.amenities!.isNotEmpty) ...[
                      Text('Amenities', style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: building.amenities!.map((a) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.ash,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(a, style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.darkGrey)),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              );
            }
          ),
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
