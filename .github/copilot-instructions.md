# Campus Navigation - AI Coding Agent Instructions

## Project Overview
Flutter-based campus navigation app for Igbinedion University Okada, featuring OSM-powered routing, live navigation, AR directions, and multi-modal transport. Web-first deployment to Vercel.

## Architecture & Key Components

### Core Structure
- **Entry**: `main.dart` → `SplashScreen` → `EnhancedCampusMap` (main map screen)
- **Data Model**: `CampusBuilding` with `BuildingCategory` enum (11 categories: academic, administrative, library, dining, banking, sports, etc.)
- **Routing Engine**: Custom A* pathfinding on OSM footpath/road graphs fetched at runtime
- **State Management**: `ValueNotifier` pattern in `AppSettings` for reactive UI (dark mode, map style, navigation mode)

### Map & Navigation System (`lib/screens/enhanced_campus_map.dart`)
**Critical**: This 3000+ line file is the heart of the app. Key patterns:
- **Dual Data Sources**: Fetches OSM buildings/footpaths via Overpass API, falls back to hardcoded `campusBuildings` list on timeout
- **Transport-Aware Routing**: 
  - `foot`: Snaps to building entrances, uses footpath-only A* graph
  - `bicycle`: Mixed pedestrian+road network
  - `car/bus`: Road-only graph, falls back to OSRM (`router.project-osrm.org`) if local routing fails
- **Entrance Routing**: Buildings have designated entrance coordinates; walking mode routes to nearest entrance, not centroid
- **Live Navigation**: `LiveNavigationScreen` tracks GPS position along route, displays ETA/distance
- **Map Styles**: `MapStyle` enum (standard/satellite/topo) switches tile providers

### State & Persistence
- **Preferences**: `PreferencesService` wraps `shared_preferences` (map style, nav mode, favorites)
- **Favorites**: `FavoritesService` serializes building IDs to prefs
- **Live Settings**: `AppSettings` with `ValueNotifier` fields listened by UI for instant updates

### Routing Algorithm Details
**A* Implementation** (`_aStarPath` method ~line 1034):
- Builds graph from OSM footpaths (each path segment = bidirectional edge)
- Node IDs: sequential index in merged coordinate list
- Heuristic: straight-line distance (`Distance().distance`)
- Max iterations: 2000 (prevents infinite loops on disconnected graphs)
- Returns node index path → converted to `LatLng` coordinates

**Mode-Specific Behavior**:
- Foot: `_buildFootpathRoute` → entrance snapping → A* on footpath graph
- Car/Bus: `_buildRoadRoute` → road-only A* → OSRM fallback
- Bicycle: Mixed graph (footpaths + roads)

## Development Workflows

### Build & Deploy
**Primary Command**: Use VS Code tasks over manual commands
- **Build**: Task `"Build Flutter web (release)"` → `flutter build web --release --no-tree-shake-icons --dart-define=BUILD_STAMP=...`
- **Deploy**: Task `"Build and Deploy to Vercel"` → builds then runs `vercel --prod --yes` from `build\web`
- **Key Flags**: 
  - `--no-tree-shake-icons`: Prevents missing icon errors in web builds
  - `--dart-define=BUILD_STAMP=...`: Version tracking in HTML comment
  - `--no-wasm-dry-run`: Avoids experimental WASM issues

**Vercel Config** (`vercel.json`):
```json
{
  "buildCommand": "flutter build web --release --no-tree-shake-icons --no-wasm-dry-run",
  "outputDirectory": "build/web"
}
```

### Testing
**Status**: Test file exists (`test/widget_test.dart`) but references non-existent `MyApp` - tests not functional. When adding tests:
- Use `flutter test` command
- Mock OSM API calls (tests will fail without network)
- Test routing edge cases (disconnected graphs, out-of-bounds)

### Running Locally
```powershell
flutter run -d chrome  # Web development
flutter run            # Hot reload on connected device/emulator
```

## Project Conventions

### File Organization
- **Screens**: `lib/screens/*_screen.dart` - full-page UI components
- **Models**: `lib/models/campus_building.dart` - data structures only
- **Utils**: `lib/utils/` - services, API fetchers, preferences
- **Theme**: `lib/theme/app_theme.dart` - `AppColors`, `AppTextStyles`, `AppSizes` constants
- **Widgets**: `lib/widgets/` - reusable UI components (minimal usage)

### Styling Patterns
**Always use theme constants**:
```dart
// ✅ Correct
Container(
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
  ),
  child: Text('Label', style: AppTextStyles.bodyMedium),
)

// ❌ Avoid
Container(
  decoration: BoxDecoration(
    color: Color(0xFF0366FC),  // Use AppColors.primary
    borderRadius: BorderRadius.circular(12),  // Use AppSizes.radiusMedium
  ),
)
```

**Dark Mode Adaptive Colors**: Use helper methods from `AppColors`:
```dart
AppColors.textPrimaryAdaptive(context)  // Auto-switches white/black
AppColors.cardBackground(context)       // Auto-switches surface colors
```

### Naming Conventions
- **Private State**: `_routePolyline`, `_selectedBuilding` (prefix `_`)
- **Services**: `PreferencesService`, `FavoritesService` (suffix `Service`)
- **Fetchers**: `OSMDataFetcher` (suffix `Fetcher`)
- **Enums**: PascalCase (`BuildingCategory.academic`)

### Data Fetching Pattern
**OSM Overpass API** (`lib/utils/osm_data_fetcher.dart`):
- Query format: Overpass QL with bbox filtering
- Timeout handling: `.timeout(Duration(seconds: 8))` with fallback data
- Error handling: Always provide fallback to hardcoded `campusBuildings`

Example:
```dart
final buildings = await OSMDataFetcher.fetchCampusBuildings().timeout(
  const Duration(seconds: 8),
  onTimeout: () {
    debugPrint('OSM fetch timeout - using fallback data');
    return campusBuildings;
  },
);
```

## Integration Points

### External Dependencies
- **Mapping**: `flutter_map` package (OSM tiles, not Google Maps)
- **Location**: `geolocator` (requires web permissions setup)
- **Routing API**: OSRM public instance (`router.project-osrm.org`) - no API key needed
- **OSM Data**: Overpass API (`overpass-api.de`) - rate limited, handle timeouts

### Critical Bounds Check
**Geographic Restriction** (`_isWithinOkadaBounds`):
- Campus center: `LatLng(6.7415, 5.4055)`
- Max radius: 10km
- Shows warning dialog if user outside bounds (still allows map view)

### Asset Requirements
- **Buildings**: `assets/buildings/danny.jpeg` (profile placeholder)
- **Videos**: `assets/videos/` (referenced but may be empty)
- **AR**: `assets/ar_direction.html` (stub - AR feature incomplete)
- **Fonts**: `assets/fonts/` (custom fonts if needed)

## Common Pitfalls

1. **Don't modify routing without testing both modes**: Foot and car routing use different graphs; changes affect both
2. **Always provide fallback data**: OSM API can timeout or be unavailable
3. **Preserve entrance snapping logic**: Walking navigation depends on `_destinationEntrance` being set
4. **Don't break A* termination**: Ensure `iterations < 2000` check remains to prevent hangs
5. **Web build flags are mandatory**: Omitting `--no-tree-shake-icons` causes icon failures in production
6. **ValueNotifier listeners must be disposed**: Check `initState`/`dispose` pairs when adding listeners

## Key Files Reference
- **Main routing logic**: `lib/screens/enhanced_campus_map.dart` lines 396-1034
- **Building data**: `lib/models/campus_building.dart` (hardcoded fallback list at bottom)
- **OSM queries**: `lib/utils/osm_data_fetcher.dart`
- **Theme system**: `lib/theme/app_theme.dart`
- **Live settings**: `lib/utils/app_settings.dart` (reactive state)
- **Build tasks**: `.vscode/tasks.json` (not in context but referenced in workspace)

## Deployment Notes
- **Target Platform**: Web (Vercel hosting)
- **Build Output**: `build/web/` (committed to repo for some reason - not best practice)
- **Deploy Folders**: `campita_deploy/`, `deploy_fresh/` contain previous build artifacts
- **Vercel CLI**: Required for deployment (`vercel --prod --yes`)
- **No CI/CD**: Manual deployment workflow via tasks

---

**When modifying routing**: Test all 4 transport modes (foot/bicycle/car/bus) and verify entrance snapping still works for pedestrians.  
**When adding screens**: Follow `*_screen.dart` naming, use `AppRoutes` helper if adding navigation routes.  
**When styling**: Always check dark mode appearance using `AppColors.*Adaptive(context)` methods.
