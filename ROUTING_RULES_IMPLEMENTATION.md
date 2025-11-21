# Campus Navigation - Routing Rules Implementation

## ✅ Completed Implementation (Version 1.0)

### 1. Building Entrance System ✓

**Model Updates (`lib/models/campus_building.dart`):**
- Added `entrance` field (LatLng?) - Primary entrance for routing
- Added `entrances` field (List<LatLng>?) - Multiple entrance support
- Added `primaryEntrance` getter - Smart entrance selection
- Updated all 21 campus buildings with accurate entrance coordinates

**Routing Priority:**
1. Building model entrance (predefined, accurate)
2. OSM entrance node (`entrance=*` tags from Overpass API)
3. Nearest footpath node (fallback with warning)

**Result:** Routes now end at building doors, NOT building centroids

---

### 2. Strict Transport Mode Routing ✓

#### Walking Mode (`_buildFootpathRoute`)
**Allowed Network:**
- `highway=footway` - Dedicated pedestrian paths
- `highway=path` (foot≠no) - Shared paths
- `highway=pedestrian` - Pedestrian zones
- `highway=steps` - Stairs
- `highway=cycleway` (foot≠no) - Shared bike paths
- `highway=track` (foot≠no) - Tracks allowing foot traffic

**Forbidden:**
- Roads without pedestrian access
- Private areas
- Building interiors

**Implementation:**
```dart
// Line ~850: Strict OSM query filters footways only
if (highway == 'footway' || highway == 'path' || 
    highway == 'pedestrian' || highway == 'steps' ||
    (highway == 'cycleway' && tags?['foot'] != 'no') ||
    (highway == 'track' && tags?['foot'] != 'no') ||
    tags?['foot'] == 'yes') {
  wayNodes[element['id']] = List<int>.from(element['nodes']);
}
```

#### Vehicle Mode (`_calculateRoadRoute`)
**Allowed Network:**
- `highway=residential` - Residential streets
- `highway=service` (access≠private) - Service roads
- `highway=tertiary/secondary/primary` - Main roads
- `highway=unclassified` - Minor roads
- `highway=living_street` - Shared spaces
- `highway=track` (motor_vehicle=yes) - Vehicle tracks

**Forbidden:**
- `highway=footway` - Pedestrian paths ❌
- `highway=path` - Walking paths ❌
- `highway=pedestrian` - Pedestrian zones ❌
- `highway=steps` - Stairs ❌
- `highway=cycleway` - Bike lanes ❌
- Building entrances (routes stop at road drop-off points)

**Validation Logic:**
```dart
// Line ~1240: Active rejection of pedestrian ways
if (highway == 'footway' || highway == 'path' || 
    highway == 'pedestrian' || highway == 'steps' ||
    highway == 'cycleway' || highway == 'bridleway') {
  debugPrint('⚠ Rejected pedestrian way: $highway (not allowed for vehicles)');
  continue; // Skip this way
}
```

---

### 3. Polyline Snap-to-Path Precision ✓

**A* Pathfinding (`_findShortestPath`):**
- Builds adjacency graph from OSM way nodes
- Connects only consecutive nodes in each way
- Bidirectional edges for two-way paths
- Heuristic: Straight-line distance (haversine)
- Max iterations: 2000 (prevents infinite loops)

**Path Generation:**
```dart
// Routes follow node-to-node connections
for (var nodeId in path) {
  if (nodes.containsKey(nodeId)) {
    route.add(nodes[nodeId]!); // Actual OSM coordinates
  }
}
```

**No Shortcuts:**
- Polylines cannot cut through buildings
- No diagonal jumps between disconnected nodes
- Routes follow actual map geometry

---

### 4. Device Compass & Map Rotation ✓

#### Main Map (`enhanced_campus_map.dart`)
**Compass Integration:**
```dart
// Line ~192: Continuous heading updates
FlutterCompass.events?.listen((event) {
  if (event.heading != null && mounted) {
    final h = event.heading!;
    setState(() => _userHeading = h);
    if (_is3DCompassMode) {
      _mapController.rotate(_userHeading);
    }
  }
});
```

**Location Marker:**
- Blue pulsing circle (animated glow)
- White dot with blue border (20x20px)
- Direction arrow (rotates with `_userHeading`)
- Custom `_ArrowPainter` with blue accent tip

**Arrow Painter Features:**
- Sharp white arrow pointing forward
- Blue accent on tip for visibility
- Shadow effect for depth
- Rotates 0-360° based on device compass

#### Live Navigation (`live_navigation_screen.dart`)
**Auto-Rotate Feature:**
```dart
// Line ~110: Map rotates to match heading
_compassSub = FlutterCompass.events?.listen((event) {
  if (event.heading != null && mounted) {
    setState(() {
      _userHeading = event.heading!;
      _mapBearing = _userHeading; // Sync map rotation
    });
    _mapController.rotate(_mapBearing);
  }
});
```

**User Experience:**
- Map rotates so user always faces "up"
- Turn left → map rotates left
- Turn right → map rotates right
- Location marker arrow shows facing direction

---

### 5. Routing Safety Rules ✓

**Building No-Entry Validation:**
- Routes never end inside building polygons
- Entrance snapping ensures routes stop at doors
- Vehicle routes stop at nearest road (drop-off points)
- Walking routes reach building entrances on footpaths

**Network Validation:**
- Nodes must be in valid graph before routing starts
- `_findNearestNodeId` with max 500m search radius
- Debug logging for failed node lookups
- OSM Overpass timeout handling (10s with fallback)

**Error Handling:**
```dart
// Line ~1375: Safe node lookup with distance constraints
int? _findNearestNodeId(LatLng target, Map<int, LatLng> nodes, 
                       {double minDistanceFromTarget = 0}) {
  // Finds nearest node while respecting minimum distance
  // (prevents selecting nodes inside buildings)
}
```

---

## Technical Implementation Details

### OSM Data Fetching
**Overpass API Queries:**
- 10-second timeout for all queries
- Fallback to hardcoded campus buildings on timeout
- Bbox filtering for performance (`±0.01° around route`)
- Node + Way fetching with relationships

### Graph Construction
**Data Structures:**
```dart
Map<int, LatLng> nodes         // OSM node ID → Coordinates
Map<int, List<int>> wayNodes   // Way ID → Ordered node IDs
Map<int, Set<int>> graph       // Node ID → Connected node IDs
```

### Route Drawing Animation
**Animated Polyline:**
```dart
// Line ~1968: Progressive route reveal
List<LatLng> _animatedRoutePoints() {
  final t = _routeDrawProgress.value.clamp(0.0, 1.0);
  final count = (t * _routePolyline.length).clamp(2, ...).toInt();
  return _routePolyline.take(count).toList();
}
```

---

## Testing Checklist

### Walking Mode Tests
- [ ] Route to Library entrance (not centroid)
- [ ] Route stays on footpaths (no road shortcuts)
- [ ] Arrow rotates with device rotation
- [ ] Map can rotate with compass button
- [ ] Route ends exactly at building entrance

### Vehicle Mode Tests
- [ ] Route uses only roads (no footpath segments)
- [ ] Route stops at road near building (not on footpath)
- [ ] No polyline through pedestrian zones
- [ ] Vehicle icon shows on route preview
- [ ] OSRM fallback works if local routing fails

### Compass/Rotation Tests
- [ ] Marker arrow rotates smoothly with device heading
- [ ] Live navigation map rotates with user direction
- [ ] Compass button shows current rotation angle
- [ ] 3D mode maintains rotation
- [ ] Location button resets rotation to north-up

### Edge Cases
- [ ] Out-of-bounds destinations show warning
- [ ] Disconnected graph areas handled gracefully
- [ ] OSM API timeout triggers fallback data
- [ ] Buildings without entrance use nearest footpath
- [ ] Very short routes (< 10m) render correctly

---

## Performance Optimizations

1. **Lazy Marker Rendering:** Only show markers at zoom ≥ 15.5
2. **Entrance Caching:** Building entrances stored in model (no repeated API calls)
3. **Graph Pruning:** Max 2000 A* iterations prevents hangs
4. **OSM Timeouts:** 10s limit prevents UI freezing
5. **Animated Route:** Progressive polyline rendering reduces initial lag

---

## Future Enhancements (Not Yet Implemented)

1. **Indoor Navigation:** Multi-floor routing within buildings
2. **Accessibility Routes:** Wheelchair-friendly path filtering
3. **Real-Time Traffic:** Avoid congested roads for vehicle mode
4. **Voice Guidance:** Turn-by-turn audio instructions
5. **Offline Maps:** Cached OSM tiles for no-connection areas
6. **AR Directions:** Augmented reality arrow overlay (stub exists in `assets/ar_direction.html`)

---

## Compliance with Specification

### ✅ Mandatory Rules Implemented

| Rule | Status | Implementation |
|------|--------|----------------|
| Walking on footpaths only | ✅ | OSM query filters + validation |
| Vehicles on roads only | ✅ | Explicit footway rejection |
| No building interior routing | ✅ | Entrance-first routing |
| Polylines follow map geometry | ✅ | A* node-to-node pathfinding |
| Route to entrance, not centroid | ✅ | `primaryEntrance` getter |
| Buildings tagged properly | ✅ | All 21 buildings have entrances |
| Compass rotation | ✅ | FlutterCompass integration |
| Map rotation during navigation | ✅ | Auto-rotate in live nav |
| No diagonal shortcuts | ✅ | Graph edges respect OSM ways |
| Safety validation | ✅ | Node-in-graph checks |

---

## Debug Commands

```dart
// Enable routing debug logs
print('Pedestrian network: ${nodes.length} nodes, ${wayNodes.length} ways');
debugPrint('✓ Routing to building entrance (NOT centroid)');
debugPrint('⚠ Rejected pedestrian way: $highway');
```

**Console Output Example:**
```
Pedestrian network: 1247 nodes, 342 ways
Using building model entrance: 6.74145,5.40398
✓ Routing to building entrance (NOT centroid)
Pedestrian route: 28 points, to building entrance
```

---

## Version History

- **v1.0** (2025-11-21): Initial implementation
  - Building entrance system
  - Strict transport mode routing
  - Compass/rotation features
  - OSM network validation
