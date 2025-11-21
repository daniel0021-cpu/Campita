import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/campus_building.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_success_card.dart';

class DirectionsScreen extends StatefulWidget {
  const DirectionsScreen({super.key});

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  CampusBuilding? _startLocation;
  CampusBuilding? _endLocation;
  String _transportMode = 'foot'; // foot, bicycle, car, bus
  bool _useCurrentLocation = true;
  Position? _currentPosition;
  bool _loadingLocation = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }
  
  Future<void> _loadCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _loadingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingLocation = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  void _navigateWithDirections() {
    // ALWAYS allow if destination is set (current location is default)
    if (_endLocation == null) {
      showAnimatedSuccess(
        context,
        'Please select a destination',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
      );
      return;
    }
    
    // If using current location but don't have it yet, load it
    if (_useCurrentLocation && _currentPosition == null) {
      showAnimatedSuccess(
        context,
        'Getting your location...',
        icon: Icons.location_searching,
        iconColor: AppColors.primary,
      );
      _loadCurrentLocation();
      // Continue with navigation anyway - map will use current location
    }
    
    // If NOT using current location, must have start location
    if (!_useCurrentLocation && _startLocation == null) {
      showAnimatedSuccess(
        context,
        'Please select a start location',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    
    // Return to map and let it calculate the route
    // If useCurrentLocation is true, map will use its own _currentLocation
    Navigator.pop(context, {
      'start': _useCurrentLocation ? null : _startLocation,
      'end': _endLocation,
      'transportMode': _transportMode,
      'useCurrentLocation': _useCurrentLocation,
      'currentPosition': _currentPosition,
    });
  }

  void _swapLocations() {
    setState(() {
      final temp = _startLocation;
      _startLocation = _endLocation;
      _endLocation = temp;
    });
  }

  Widget _buildTransportChip(String mode, IconData icon, String label) {
    final isSelected = _transportMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transportMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey.withAlpha(77),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkGrey : AppColors.ash,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Get Directions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.darkGrey,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? AppColors.white : AppColors.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current Location Toggle
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _useCurrentLocation ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Current Location',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loadingLocation
                                  ? 'Getting location...'
                                  : _currentPosition != null
                                      ? 'Location ready'
                                      : 'Tap to enable',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useCurrentLocation,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() => _useCurrentLocation = value);
                          if (value && _currentPosition == null) {
                            _loadCurrentLocation();
                          }
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Start Location Card (only if not using current location)
                if (!_useCurrentLocation)
                  _buildLocationCard(
                    icon: Icons.location_on_outlined,
                    title: 'Start Location',
                    selectedBuilding: _startLocation,
                    onTap: () => _selectLocation(true),
                    color: AppColors.success,
                  ),
                
                // Swap Button
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.ash,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.swap_vert, color: AppColors.primary),
                      onPressed: _swapLocations,
                      tooltip: 'Swap locations',
                    ),
                  ),
                ),
                
                // End Location Card
                _buildLocationCard(
                  icon: Icons.place,
                  title: 'Destination',
                  selectedBuilding: _endLocation,
                  onTap: () => _selectLocation(false),
                  color: AppColors.error,
                ),
                
                const SizedBox(height: 24),
                
                // Transport Mode Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Transport Mode',
                            style: AppTextStyles.heading3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTransportChip('foot', Icons.directions_walk, 'Walk')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTransportChip('bicycle', Icons.directions_bike, 'Bike')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTransportChip('car', Icons.directions_car, 'Car')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTransportChip('bus', Icons.directions_bus, 'Bus')),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Route Info Preview
                if (_startLocation != null && _endLocation != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.ash,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Route Summary',
                              style: AppTextStyles.heading3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.route, 'From', _startLocation!.name),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.location_on, 'To', _endLocation!.name),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.directions_walk,
                          'Distance',
                          _calculateStraightDistance(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Calculate Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_startLocation != null && _endLocation != null)
                      ? _navigateWithDirections
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation),
                      const SizedBox(width: 8),
                            Text(
                              'Show Route on Map',
                              style: AppTextStyles.button,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required CampusBuilding? selectedBuilding,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedBuilding?.name ?? 'Select location',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selectedBuilding != null
                            ? AppColors.textPrimary
                            : AppColors.grey,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (selectedBuilding != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            selectedBuilding.categoryIcon,
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selectedBuilding.categoryName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey,
            decoration: TextDecoration.none,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _calculateStraightDistance() {
    if (_startLocation == null || _endLocation == null) return '-';
    
    final distance = const Distance().as(
      LengthUnit.Meter,
      _startLocation!.coordinates,
      _endLocation!.coordinates,
    );
    
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m (approx)';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km (approx)';
    }
  }

  Future<void> _selectLocation(bool isStart) async {
    final selected = await showModalBottomSheet<CampusBuilding>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSelectionSheet(
        title: isStart ? 'Select Start Location' : 'Select Destination',
        currentSelection: isStart ? _startLocation : _endLocation,
      ),
    );

    if (selected != null) {
      setState(() {
        if (isStart) {
          _startLocation = selected;
        } else {
          _endLocation = selected;
        }
      });
    }
  }
}

class _LocationSelectionSheet extends StatefulWidget {
  final String title;
  final CampusBuilding? currentSelection;

  const _LocationSelectionSheet({
    required this.title,
    this.currentSelection,
  });

  @override
  State<_LocationSelectionSheet> createState() => _LocationSelectionSheetState();
}

class _LocationSelectionSheetState extends State<_LocationSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CampusBuilding> _filteredBuildings = campusBuildings;
  BuildingCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBuildings);
  }

  void _filterBuildings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBuildings = campusBuildings.where((b) {
        final matchesSearch = query.isEmpty || 
            b.name.toLowerCase().contains(query) ||
            b.categoryName.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == null || 
            b.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.heading2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search buildings...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.ash,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              // Category filter chips
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _buildCategoryChip('All', null),
                    ...BuildingCategory.values.map((cat) {
                      return _buildCategoryChip(
                        CampusBuilding(
                          name: '',
                          coordinates: const LatLng(0, 0),
                          category: cat,
                        ).categoryName,
                        cat,
                      );
                    }),
                  ],
                ),
              ),
              
              // Buildings list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredBuildings.length,
                  itemBuilder: (context, index) {
                    final building = _filteredBuildings[index];
                    final isSelected = building == widget.currentSelection;
                    
                    return Card(
                      elevation: isSelected ? 4 : 1,
                      color: isSelected ? AppColors.primary.withAlpha(26) : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(building.category).withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            building.categoryIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        title: Text(
                          building.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(
                          building.categoryName,
                          style: AppTextStyles.caption.copyWith(
                            decoration: TextDecoration.none,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppColors.primary)
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pop(context, building),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, BuildingCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
            _filterBuildings();
          });
        },
        backgroundColor: AppColors.ash,
        selectedColor: AppColors.primary.withAlpha(51),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.darkGrey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
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
}
