import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/campus_building.dart';
import '../widgets/advanced_animations.dart';
import 'live_navigation_screen.dart';

class RoutePreviewScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final LatLng start;
  final LatLng end;
  final double distanceMeters;
  final double durationSeconds;
  final String transportMode;
  final CampusBuilding? destination;

  const RoutePreviewScreen({
    super.key,
    required this.routePoints,
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.transportMode,
    this.destination,
  });

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _entryController;
  late AnimationController _errorPillController;
  late Animation<Offset> _errorSlideAnimation;
  late Animation<double> _errorFadeAnimation;
  
  String _selectedTransportMode = 'foot';
  bool _showTransportError = false;
  double _sheetHeight = 0.45; // 45% expanded by default

  @override
  void initState() {
    super.initState();
    _selectedTransportMode = widget.transportMode;
    
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _errorPillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _errorSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _errorPillController,
      curve: Curves.easeOutBack,
    ));

    _errorFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorPillController,
      curve: const Interval(0.0, 0.3),
    ));

    _entryController.forward();

    // Auto-fit bounds when map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  void _fitBounds() {
    if (widget.routePoints.isEmpty) return;
    
    final bounds = LatLngBounds.fromPoints(
      widget.routePoints.isNotEmpty ? widget.routePoints : [widget.start, widget.end],
    );
    
    // Add padding to bounds
    final latPadding = (bounds.north - bounds.south) * 0.2;
    final lngPadding = (bounds.east - bounds.west) * 0.2;
    
    final paddedBounds = LatLngBounds(
      LatLng(bounds.south - latPadding, bounds.west - lngPadding),
      LatLng(bounds.north + latPadding, bounds.east + lngPadding),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: paddedBounds,
        padding: const EdgeInsets.only(
          top: 100,
          bottom: 350,
          left: 40,
          right: 40,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _errorPillController.dispose();
    super.dispose();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'bicycle':
        return Icons.directions_bike_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'bus':
        return Icons.directions_bus_rounded;
      default:
        return Icons.directions_walk_rounded;
    }
  }

  void _showTransportErrorMessage() {
    if (!mounted) return;
    
    setState(() => _showTransportError = true);
    
    _errorPillController.forward().catchError((error) {
      debugPrint('Error pill animation error: $error');
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      
      _errorPillController.reverse().then((_) {
        if (mounted) {
          setState(() => _showTransportError = false);
        }
      }).catchError((error) {
        debugPrint('Error pill reverse animation error: $error');
        if (mounted) {
          setState(() => _showTransportError = false);
        }
      });
    });
  }

  void _handleStartNavigation() {
    if (_selectedTransportMode.isEmpty || _selectedTransportMode == widget.transportMode) {
      // Immediate navigation - no unnecessary delays
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LiveNavigationScreen(
              routePoints: widget.routePoints,
              destination: widget.end,
              transportMode: _selectedTransportMode,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } else {
      _showTransportErrorMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      body: Stack(
        children: [
          // Modern map with clean styling
          _buildModernMap(isDark),

          // Error pill at top
          if (_showTransportError) _buildErrorPill(),

          // Floating destination info sheet at bottom
          _buildFloatingBottomSheet(isDark, screenHeight),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? Colors.black.withAlpha(153)
                    : Colors.white.withAlpha(242),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : AppColors.darkGrey,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMap(bool isDark) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.start,
        initialZoom: 15,
        minZoom: 12,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Modern map tiles (switch based on app theme)
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.campus_navigation',
          maxZoom: 19,
        ),

        // Route line with modern styling
        if (widget.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Outer glow
              Polyline(
                points: widget.routePoints,
                color: AppColors.primary.withAlpha(77),
                strokeWidth: 12,
              ),
              // Main route line
              Polyline(
                points: widget.routePoints,
                color: AppColors.primary,
                strokeWidth: 6,
                gradientColors: [
                  AppColors.primary,
                  AppColors.primary.withAlpha(204),
                ],
              ),
            ],
          ),

        // Markers with modern design
        MarkerLayer(
          markers: [
            // Start marker (current location)
            Marker(
              point: widget.start,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(102),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ),
            ),
            // End marker (destination)
            Marker(
              point: widget.end,
              width: 50,
              height: 50,
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.location_on_rounded,
                color: Colors.red,
                size: 50,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(77),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorPill() {
    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _errorSlideAnimation,
        child: FadeTransition(
          opacity: _errorFadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(50),
            shadowColor: AppColors.error.withAlpha(128),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error,
                    AppColors.error.withAlpha(204),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Select transport mode for accurate calculation',
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildFloatingBottomSheet(bool isDark, double screenHeight) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _sheetHeight -= details.delta.dy / screenHeight;
            _sheetHeight = _sheetHeight.clamp(0.25, 0.7);
          });
        },
        onVerticalDragEnd: (details) {
          // Snap to nearest position based on velocity
          final velocity = details.primaryVelocity ?? 0;
          setState(() {
            if (velocity > 500) {
              _sheetHeight = 0.35; // Snap to collapsed
            } else if (velocity < -500) {
              _sheetHeight = 0.75; // Snap to expanded
            } else {
              // Snap to nearest
              _sheetHeight = _sheetHeight < 0.55 ? 0.45 : 0.75;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          height: screenHeight * _sheetHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle with tap to expand
              GestureDetector(
                onTap: () {
                  setState(() {
                    _sheetHeight = _sheetHeight < 0.5 ? 0.7 : 0.35;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(102)
                              : AppColors.grey.withAlpha(153),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(51),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content - wrapped with ClipRect to prevent overflow
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route info header
                      _buildRouteHeader(isDark),
                      const SizedBox(height: 24),

                      // Transport mode selector
                      _buildTransportModeSelector(isDark),
                      const SizedBox(height: 24),

                      // Destination info (if available)
                      if (widget.destination != null)
                        _buildDestinationInfo(isDark),

                      const SizedBox(height: 24),

                      // Action buttons
                      _buildActionButtons(),
                    ],
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

  Widget _buildRouteHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withAlpha(179),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _modeIcon(_selectedTransportMode),
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Preview',
                style: GoogleFonts.notoSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDistance(widget.distanceMeters),
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(widget.durationSeconds),
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransportModeSelector(bool isDark) {
    final modes = [
      {'key': 'foot', 'icon': Icons.directions_walk_rounded, 'label': 'Walk'},
      {'key': 'bicycle', 'icon': Icons.directions_bike_rounded, 'label': 'Bike'},
      {'key': 'car', 'icon': Icons.directions_car_rounded, 'label': 'Car'},
      {'key': 'bus', 'icon': Icons.directions_bus_rounded, 'label': 'Bus'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Transport Mode',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: modes.asMap().entries.map((entry) {
            final index = entry.key;
            final mode = entry.value;
            final key = mode['key'] as String;
            final isSelected = _selectedTransportMode == key;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ElasticScaleIn(
                  duration: const Duration(milliseconds: 500),
                  delay: Duration(milliseconds: 100 + (index * 50)),
                  child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedTransportMode = key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withAlpha(204),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : isDark
                              ? Colors.grey[800]?.withAlpha(128)
                              : AppColors.grey.withAlpha(38),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isDark
                                ? Colors.grey[700]!
                                : AppColors.grey.withAlpha(77),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(77),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          mode['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? Colors.white70
                                  : AppColors.darkGrey,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mode['label'] as String,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isDark
                                    ? Colors.white70
                                    : AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildDestinationInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[850]?.withAlpha(128)
            : AppColors.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.grey[700]!
              : AppColors.primary.withAlpha(51),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.place_rounded,
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
                  'Destination',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.destination!.name,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElasticScaleIn(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 200),
            child: AnimatedButton(
              onTap: () => Navigator.pop(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(77),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Cancel',
                      style: GoogleFonts.notoSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElasticScaleIn(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 300),
            child: AnimatedButton(
              onTap: _handleStartNavigation,
              backgroundColor: AppColors.primary,
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Start Navigation',
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
