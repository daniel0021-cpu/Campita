// Enhanced Campus Map with Google Maps-style features
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../models/campus_building.dart';
import '../theme/app_theme.dart';
import '../utils/osm_data_fetcher.dart';
import 'directions_screen.dart';

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
  
  bool _showSearchResults = false;
  List<CampusBuilding> _filteredBuildings = [];
  BuildingCategory? _selectedCategory;
  
  double? _routeDistance;
  double? _routeDuration;
  double _mapRotation = 0.0;
  double _currentZoom = 16.5; // Match initial zoom for 3D view
  String _transportMode = 'foot'; // foot, bicycle, car, bus
  bool _is3DView = true; // Start with 3D view for modern look
  List<List<LatLng>> _footpaths = [];
  List<CampusBuilding> _osmBuildings = [];
  bool _loadingOSMData = true;
  
  double _mapTilt = 0.0;
  double _mapBearing = 0.0; // Rotation angle (0° = North up)
  double _mapZoom = 15.0;   // Zoom level
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getCurrentLocation();
    _loadOSMFootpaths();
    _loadOSMBuildings();
  }
  
  Future<void> _loadOSMBuildings() async {
    setState(() => _loadingOSMData = true);
    
    try {
      final buildings = await OSMDataFetcher.fetchCampusBuildings();
      
      if (buildings.isNotEmpty) {
        setState(() {
          _osmBuildings = buildings;
          _loadingOSMData = false;
        });
        print('Loaded ${buildings.length} buildings from OSM');
      } else {
        // Fallback to static data if OSM fetch fails
        setState(() {
          _osmBuildings = campusBuildings;
          _loadingOSMData = false;
        });
        print('Using static building data (${campusBuildings.length} buildings)');
      }
    } catch (e) {
      print('Error loading OSM buildings: $e');
      setState(() {
        _osmBuildings = campusBuildings;
        _loadingOSMData = false;
      });
    }
  }

  Future<void> _loadOSMFootpaths() async {
    try {
      // Fetch footpath data from Overpass API for campus area
      final bbox = '${_campusCenter.latitude - 0.01},${_campusCenter.longitude - 0.01}'
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
            final List<LatLng> path = [];
            for (var node in element['geometry']) {
              path.add(LatLng(node['lat'], node['lon']));
            }
            if (path.isNotEmpty) {
              paths.add(path);
            }
          }
        }
        
        setState(() {
          _footpaths = paths;
        });
        
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
        _showSearchResults = false;
      } else {
        final buildingsToSearch = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
        _filteredBuildings = buildingsToSearch
            .where((b) => b.name.toLowerCase().contains(query))
            .toList();
        _showSearchResults = true;
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      );
      
      final userLocation = LatLng(position.latitude, position.longitude);
      
      // Check if user is within campus bounds
      if (!_isWithinCampusBounds(userLocation)) {
        if (mounted) {
          _showOutOfCampusError();
        }
        return;
      }
      
      setState(() {
        _currentLocation = userLocation;
      });
      
      // Continue listening for updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (mounted) {
          final newLocation = LatLng(position.latitude, position.longitude);
          
          // Check if user left campus
          if (!_isWithinCampusBounds(newLocation)) {
            _showOutOfCampusError();
            setState(() {
              _currentLocation = null;
            });
          } else {
            setState(() {
              _currentLocation = newLocation;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  bool _isWithinCampusBounds(LatLng location) {
    // Campus boundary: approximately 2km radius from campus center
    const double campusRadiusKm = 2.0;
    
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      _campusCenter,
      location,
    );
    
    return distance <= campusRadiusKm;
  }

  void _showOutOfCampusError() {
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
            Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Outside Campus',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You must be inside Igbinedion University campus to use the navigation system.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
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
                  Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please move to campus to access the map',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Allow user to continue without location verification
              setState(() {
                _currentLocation = _campusCenter;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.grey,
            ),
            child: Text(
              'CONTINUE ANYWAY',
              style: AppTextStyles.button.copyWith(
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry location check
              _getCurrentLocation();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: Text(
              'RETRY',
              style: AppTextStyles.button,
            ),
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
      if (_transportMode == 'foot' || _transportMode == 'bicycle') {
        // PEDESTRIAN/BICYCLE: Try footpaths first, then allow roads as fallback
        print('Calculating pedestrian route from ${start.latitude},${start.longitude} to ${destination.coordinates.latitude},${destination.coordinates.longitude}');
        routePoints = await _calculateFootpathRoute(start, destination.coordinates);
        
        if (routePoints.isNotEmpty) {
          distance = _calculateRouteDistance(routePoints);
          duration = _calculateRouteDuration(distance, _transportMode);
          print('Pedestrian route found: ${routePoints.length} points, ${distance.toStringAsFixed(0)}m');
        } else {
          print('No footpath-only route found, trying pedestrian-accessible roads');
          // Fallback: try roads that pedestrians can use
          routePoints = await _calculateMixedPedestrianRoute(start, destination.coordinates);
          if (routePoints.isNotEmpty) {
            distance = _calculateRouteDistance(routePoints);
            duration = _calculateRouteDuration(distance, _transportMode);
            print('Mixed pedestrian route found: ${routePoints.length} points');
          }
        }
      } else {
        // CAR/BUS: Use only roads from OSM
        print('Calculating vehicle route from ${start.latitude},${start.longitude} to ${destination.coordinates.latitude},${destination.coordinates.longitude}');
        routePoints = await _calculateRoadRoute(start, destination.coordinates);
        
        if (routePoints.isNotEmpty) {
          distance = _calculateRouteDistance(routePoints);
          duration = _calculateRouteDuration(distance, _transportMode);
          print('Vehicle route found: ${routePoints.length} points, ${distance.toStringAsFixed(0)}m');
        } else {
          print('No road route found, trying OSRM fallback');
          
          // Fallback to OSRM for car/bus if OSM road routing fails
          String routingProfile = _transportMode == 'bus' ? 'car' : _transportMode;
          
          final url = 'https://router.project-osrm.org/route/v1/$routingProfile/'
              '${start.longitude},${start.latitude};'
              '${destination.coordinates.longitude},${destination.coordinates.latitude}'
              '?overview=full&geometries=geojson';
          
          final response = await http.get(Uri.parse(url));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final coords = data['routes'][0]['geometry']['coordinates'] as List;
            routePoints = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
            distance = (data['routes'][0]['distance'] as num).toDouble();
            duration = (data['routes'][0]['duration'] as num).toDouble();
            print('OSRM fallback route found: ${routePoints.length} points');
          }
        }
      }
      
      if (routePoints.isNotEmpty) {
        setState(() {
          _routePolyline = routePoints;
          _routeDistance = distance;
          _routeDuration = duration;
          _selectedBuilding = destination;
        });
        
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
        
        // Find nearest nodes to start and end
        // For end node, require at least 15m from building to stay on footpath
        int? startNode = _findNearestNodeId(start, nodes);
        int? endNode = _findNearestNodeId(end, nodes, minDistanceFromTarget: 15.0);
        
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
            print('Pedestrian route: ${route.length} points, ending at footpath');
            return route;

          }
        }
      }
    } catch (e) {
      print('Error calculating footpath route: $e');
    }
    
    return [];
  }

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
            return route;
          }
        }
      }
    } catch (e) {
      print('Error calculating mixed pedestrian route: $e');
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

  void _selectBuilding(CampusBuilding building) {
    setState(() {
      _selectedBuilding = building;
      _showSearchResults = false;
    });
    _mapController.move(building.coordinates, 18.0);
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

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
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
            onTap: () => _selectBuilding(building),
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
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  building.categoryIcon,
                  style: TextStyle(fontSize: isSelected ? 16 : 14),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }
    
    return markers;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map with RepaintBoundary for better performance
          RepaintBoundary(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _campusCenter,
                initialZoom: 16.5, // Slightly higher zoom for 3D view
                maxZoom: 19,
                minZoom: 14,
                initialRotation: _mapRotation,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  enableMultiFingerGestureRace: true,
                  rotationWinGestures: MultiFingerGesture.rotate,
                  pinchMoveWinGestures: MultiFingerGesture.pinchMove | MultiFingerGesture.pinchZoom,
                ),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && mounted) {
                  // Only update if significantly changed to reduce redraws
                  if ((_mapRotation - position.rotation).abs() > 0.5 ||
                      (_currentZoom - position.zoom).abs() > 0.1) {
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_navigation',
              ),
              // OSM Footpaths layer
              if (_footpaths.isNotEmpty)
                PolylineLayer(
                  polylines: _footpaths.map((path) => Polyline(
                    points: path,
                    color: Colors.brown.withOpacity(0.6),
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
                      points: _routePolyline,
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
          
          // Top search bar
          _buildSearchBar(),
          
          // Category filter
          _buildCategoryFilter(),
          
          // My location button
          _buildMyLocationButton(),
          
          // Compass button
          _buildCompassButton(),
          
          // Zoom controls
          _buildZoomControls(),
          
          // 2D/3D toggle
          _build2D3DToggle(),
          
          // OSM Data refresh button
          _buildRefreshButton(),
          
          // Loading indicator
          if (_loadingOSMData)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading building data from OpenStreetMap...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          
          // Directions FAB
          _buildDirectionsFAB(),
          
          // Search results
          if (_showSearchResults) _buildSearchResults(),
          
          // Selected building info (only show if no active route)
          if (_selectedBuilding != null && _routePolyline.isEmpty) 
            _buildBuildingInfo(),
          
          // Route info card (show when navigating)
          if (_routePolyline.isNotEmpty) _buildRouteInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                : null,
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
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildCategoryChip('All', null),
            const SizedBox(width: 8),
            ...BuildingCategory.values.where((category) {
              final buildingsToCheck = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
              return buildingsToCheck.any((b) => b.category == category);
            }).map((category) {
              final buildingsToCheck = _osmBuildings.isNotEmpty ? _osmBuildings : campusBuildings;
              final building = buildingsToCheck.firstWhere((b) => b.category == category);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(
                  building.categoryName,
                  category,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, BuildingCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: AppColors.ash,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.notoSans(
        color: isSelected ? Colors.white : AppColors.darkGrey,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 180,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'myLocation',
        backgroundColor: Colors.white,
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 18.0);
          }
        },
        child: const Icon(Icons.my_location, color: AppColors.primary),
      ),
    );
  }

  Widget _buildCompassButton() {
    final isRotated = _mapRotation.abs() > 0.1;
    
    return Positioned(
      bottom: 310,
      right: 16,
      child: Material(
        elevation: isRotated ? 6 : 4,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() {
              _mapRotation = 0.0;
              if (_is3DView) {
                _mapTilt = 0.0;
              }
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
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 380,
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
                    final newZoom = (_currentZoom + 1).clamp(14.0, 19.0);
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
                    final newZoom = (_currentZoom - 1).clamp(14.0, 19.0);
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
      child: Material(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: _is3DView ? AppColors.primary : Colors.white,
        child: InkWell(
          onTap: () {
            setState(() {
              _is3DView = !_is3DView;
              _mapTilt = _is3DView ? 45.0 : 0.0;
              // Zoom in slightly for 3D view for better depth perception
              if (_is3DView) {
                _mapController.move(_mapController.camera.center, _currentZoom + 0.5);
              } else {
                _mapController.move(_mapController.camera.center, _currentZoom - 0.5);
              }
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
    );
  }

  Widget _buildRefreshButton() {
    return Positioned(
      bottom: 300,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withOpacity(0.3),
        color: Colors.white,
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
      child: FloatingActionButton.extended(
        heroTag: 'directions',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
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
        icon: const Icon(Icons.directions),
        label: const Text('Directions'),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 140,
      left: 16,
      right: 16,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.35,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(4),
          itemCount: _filteredBuildings.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final building = _filteredBuildings[index];
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
                  color: _getCategoryColor(building.category).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(building.categoryIcon, style: const TextStyle(fontSize: 16)),
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
              onTap: () => _selectBuilding(building),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBuildingInfo() {
    final building = _selectedBuilding!;
    final distance = _currentLocation != null
        ? const Distance().distance(_currentLocation!, building.coordinates)
        : null;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Building name and icon
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(building.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                          child: Center(
                            child: Text(
                              building.categoryIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                building.name,
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      building.categoryName,
                                      style: GoogleFonts.notoSans(
                                        fontSize: 12,
                                        color: AppColors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (distance != null) ...[
                                    const Text(
                                      ' • ',
                                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                                    ),
                                    const Icon(
                                      Icons.directions_walk,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDistance(distance),
                                      style: GoogleFonts.notoSans(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedBuilding = null;
                            // Don't clear route, user might want to keep navigating
                          });
                        },
                      ),
                    ],
                  ),
                  
                  if (building.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      building.description!,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                  
                  if (building.openingHours != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          building.openingHours!,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (building.amenities != null && building.amenities!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: building.amenities!.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ash,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          child: Text(
                            amenity,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Transport mode selector
                  Row(
                    children: [
                      Text(
                        'Travel by:',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTransportChip('foot', Icons.directions_walk, 'Walk'),
                              const SizedBox(width: 8),
                              _buildTransportChip('bicycle', Icons.directions_bike, 'Bike'),
                              const SizedBox(width: 8),
                              _buildTransportChip('car', Icons.directions_car, 'Car'),
                              const SizedBox(width: 8),
                              _buildTransportChip('bus', Icons.directions_bus, 'Bus'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _calculateRoute(building);
                          },
                          icon: Icon(_getTransportIcon()),
                          label: const Text('Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Share functionality
                          },
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 140,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Icon(
                    _getTransportIcon(),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navigation Active',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // Transport mode indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_transportMode == 'foot' || _transportMode == 'bicycle') 
                                  ? Colors.green.withOpacity(0.2) 
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTransportIcon(),
                                  size: 12,
                                  color: (_transportMode == 'foot' || _transportMode == 'bicycle')
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (_transportMode == 'foot' || _transportMode == 'bicycle')
                                      ? 'Footpath'
                                      : 'Road',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: (_transportMode == 'foot' || _transportMode == 'bicycle')
                                        ? Colors.green.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_routeDistance != null) ...[
                            Text(
                              _formatDistance(_routeDistance!),
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (_routeDuration != null) ...[
                            const Text(' • ', style: TextStyle(color: AppColors.grey)),
                            Text(
                              _formatDuration(_routeDuration!),
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.grey),
                  onPressed: () {
                    setState(() {
                      _clearRoute();
                      // Keep building selected if user wants to see info
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Fit route bounds to show entire path
                      _fitRouteBounds();
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                if (_selectedBuilding != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Clear route to show building info again
                        setState(() {
                          _clearRoute();
                        });
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportChip(String mode, IconData icon, String label) {
    final isSelected = _transportMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _transportMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.ash,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.darkGrey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
