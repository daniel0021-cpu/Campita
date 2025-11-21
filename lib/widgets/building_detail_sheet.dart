import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/campus_building.dart';
import '../utils/favorites_service.dart';

class BuildingDetailSheet extends StatefulWidget {
  final CampusBuilding building;
  final VoidCallback? onClose;
  final Function(CampusBuilding)? onStartNavigation;
  final Function(CampusBuilding)? onGetDirections;
  final Function(CampusBuilding)? onShare;
  final Function(CampusBuilding, bool)? onFavoriteToggle;

  const BuildingDetailSheet({
    super.key,
    required this.building,
    this.onClose,
    this.onStartNavigation,
    this.onGetDirections,
    this.onShare,
    this.onFavoriteToggle,
  });

  @override
  State<BuildingDetailSheet> createState() => _BuildingDetailSheetState();
}

class _BuildingDetailSheetState extends State<BuildingDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;
  double _dragPosition = 0.4; // Start at 40% of screen
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final FavoritesService _favService = FavoritesService();

  // Dummy images - replace with actual building images
  List<String> get _buildingImages => [
        'assets/buildings/danny.jpeg',
        'assets/buildings/danny.jpeg',
        'assets/buildings/danny.jpeg',
      ];

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.34, 1.56, 0.64, 1.0), // Spring-like bounce
      reverseCurve: Curves.easeInQuart,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _controller.forward();

    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentImageIndex = _pageController.page!.round();
        });
      }
    });
  }

  Future<void> _loadFavoriteStatus() async {
    final favorites = await _favService.loadFavoriteNames();
    if (mounted) {
      setState(() {
        _isFavorite = favorites.contains(widget.building.name);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double screenHeight) {
    setState(() {
      _dragPosition -= details.delta.dy / screenHeight;
      _dragPosition = _dragPosition.clamp(0.4, 0.92);
    });
  }

  void _handleDragEnd(DragEndDetails details, double screenHeight) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    
    if (velocity > 700) {
      // Fast downward swipe - close
      _close();
    } else if (velocity < -700) {
      // Fast upward swipe - expand
      setState(() => _dragPosition = 0.92);
    } else if (_dragPosition < 0.5) {
      // Below threshold - close
      _close();
    } else if (_dragPosition > 0.7) {
      // Above threshold - expand
      setState(() => _dragPosition = 0.92);
    } else {
      // Return to default
      setState(() => _dragPosition = 0.4);
    }
  }

  void _close() async {
    await _controller.reverse();
    if (mounted && widget.onClose != null) {
      widget.onClose!();
    }
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
        return AppColors.academic;
      case BuildingCategory.residential:
        return const Color(0xFFE91E63);
      case BuildingCategory.administrative:
        return const Color(0xFF9C27B0);
      case BuildingCategory.library:
        return const Color(0xFF2196F3);
      case BuildingCategory.student_services:
        return const Color(0xFFFF9800);
      case BuildingCategory.sports:
        return const Color(0xFF4CAF50);
      case BuildingCategory.dining:
        return const Color(0xFFFF5722);
      case BuildingCategory.health:
        return const Color(0xFFF44336);
      case BuildingCategory.banking:
        return const Color(0xFF00BCD4);
      case BuildingCategory.research:
        return const Color(0xFF673AB7);
      case BuildingCategory.worship:
        return const Color(0xFF795548);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withAlpha((102 * _animation.value).round()),
          child: GestureDetector(
            onTap: () {}, // Prevent tap through to background
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_animation),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateX(-0.05 * (1 - _animation.value)) // Slight tilt during entrance
                    ..translate(0.0, 0.0, 20.0 * (1 - _animation.value)), // Depth translation
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: screenHeight * _dragPosition,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(77),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      // Drag handle
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) =>
                            _handleDragUpdate(details, screenHeight),
                        onVerticalDragEnd: (details) =>
                            _handleDragEnd(details, screenHeight),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.grey[800]?.withAlpha(77)
                                : AppColors.grey.withAlpha(13),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withAlpha(153)
                                    : AppColors.grey.withAlpha(179),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImageCarousel(screenWidth),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(isDark),
                                    const SizedBox(height: 20),
                                    _buildActionButtons(),
                                    const SizedBox(height: 24),
                                    _buildTransportModes(),
                                    const SizedBox(height: 24),
                                    _buildFeatures(isDark),
                                    const SizedBox(height: 24),
                                    _buildAmenities(isDark),
                                    const SizedBox(height: 24),
                                    _buildDetails(isDark),
                                  ],
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(double screenWidth) {
    return Stack(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _buildingImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(_buildingImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        // Indicators
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_buildingImages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentImageIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentImageIndex == index
                      ? Colors.white
                      : Colors.white.withAlpha(102),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: _currentImageIndex == index
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ),
        // Favorite button
        Positioned(
          top: 16,
          right: 36,
          child: Material(
            color: Colors.black.withAlpha(77),
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              onTap: () async {
                final newFavoriteState = !_isFavorite;
                setState(() => _isFavorite = newFavoriteState);
                
                if (newFavoriteState) {
                  await _favService.addFavorite(widget.building.name);
                } else {
                  await _favService.removeFavorite(widget.building.name);
                }
                
                if (widget.onFavoriteToggle != null) {
                  widget.onFavoriteToggle!(widget.building, newFavoriteState);
                }
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_isFavorite),
                    color: _isFavorite ? Colors.red : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final categoryColor = _getCategoryColor(widget.building.category);
    final categoryIcon = _getCategoryIcon(widget.building.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.building.name,
                style: GoogleFonts.notoSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkGrey,
                  decoration: TextDecoration.none, // Remove yellow underline
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: categoryColor.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(categoryIcon, size: 16, color: categoryColor),
                  const SizedBox(width: 6),
                  Text(
                    widget.building.categoryName,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildPrimaryButton(
            'Start',
            Icons.navigation_rounded,
            () {
              if (widget.onStartNavigation != null) {
                widget.onStartNavigation!(widget.building);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSecondaryButton(
            'Directions',
            Icons.directions_rounded,
            () {
              if (widget.onGetDirections != null) {
                widget.onGetDirections!(widget.building);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        _buildIconButton(Icons.share_rounded, () {
          if (widget.onShare != null) {
            widget.onShare!(widget.building);
          }
        }),
      ],
    );
  }

  Widget _buildPrimaryButton(String label, IconData icon, VoidCallback onTap) {
    bool isStartButton = label == 'Start';
    bool isLoadingLocation = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(50),
            elevation: isLoadingLocation ? 8 : 4,
            shadowColor: AppColors.primary.withAlpha(isLoadingLocation ? 153 : 102),
            child: InkWell(
              onTap: isLoadingLocation ? null : () async {
                if (isStartButton) {
                  setState(() => isLoadingLocation = true);
                  
                  // Get location instantly with highest accuracy
                  try {
                    await Future.delayed(const Duration(milliseconds: 50)); // Minimal delay for animation
                    onTap();
                  } finally {
                    if (context.mounted) {
                      setState(() => isLoadingLocation = false);
                    }
                  }
                } else {
                  onTap();
                }
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: isLoadingLocation
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: 0.5 + (value * 0.5),
                                  child: Text(
                                    'Getting location...',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.primary.withAlpha(31),
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.grey.withAlpha(38),
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: AppColors.darkGrey, size: 20),
        ),
      ),
    );
  }

  Widget _buildTransportModes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Time',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGrey,
            decoration: TextDecoration.none,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTransportCard('Walk', Icons.directions_walk_rounded, '5 min', AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildTransportCard('Bike', Icons.directions_bike_rounded, '2 min', const Color(0xFF4CAF50))),
            const SizedBox(width: 12),
            Expanded(child: _buildTransportCard('Car', Icons.directions_car_rounded, '1 min', const Color(0xFFFF9800))),
          ],
        ),
      ],
    );
  }

  Widget _buildTransportCard(String mode, IconData icon, String eta, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            eta,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            mode,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              color: color.withAlpha(204),
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(bool isDark) {
    final features = [
      {'icon': Icons.wifi_rounded, 'label': 'Free WiFi'},
      {'icon': Icons.ac_unit_rounded, 'label': 'AC'},
      {'icon': Icons.accessible_rounded, 'label': 'Accessible'},
      {'icon': Icons.local_parking_rounded, 'label': 'Parking'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkGrey,
            decoration: TextDecoration.none,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[800]?.withAlpha(153)
                    : AppColors.grey.withAlpha(31),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    feature['label'] as String,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.darkGrey,
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenities(bool isDark) {
    final amenities = [
      {'icon': Icons.menu_book_rounded, 'label': 'Study Areas', 'color': const Color(0xFF2196F3)},
      {'icon': Icons.computer_rounded, 'label': 'Computer Lab', 'color': const Color(0xFF9C27B0)},
      {'icon': Icons.school_rounded, 'label': 'Lecture Halls', 'color': const Color(0xFFFF9800)},
      {'icon': Icons.restaurant_rounded, 'label': 'Cafeteria', 'color': const Color(0xFFE91E63)},
      {'icon': Icons.wc_rounded, 'label': 'Restrooms', 'color': const Color(0xFF4CAF50)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkGrey,
            decoration: TextDecoration.none,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        ...amenities.map((amenity) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (amenity['color'] as Color).withAlpha(31),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    amenity['icon'] as IconData,
                    size: 20,
                    color: amenity['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    amenity['label'] as String,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : AppColors.darkGrey,
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetails(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'About',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkGrey,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.grey[800]?.withAlpha(128)
                : AppColors.primary.withAlpha(13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.grey[700]!
                  : AppColors.primary.withAlpha(38),
              width: 1,
            ),
          ),
          child: Text(
            'This building is a key facility on campus, providing essential services and amenities to students and staff. It features modern infrastructure and is easily accessible from various points on campus.',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : AppColors.darkGrey,
              decoration: TextDecoration.none,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        _buildContactCard(Icons.access_time_rounded, 'Hours', 'Open 24/7', const Color(0xFF4CAF50), isDark),
        const SizedBox(height: 12),
        _buildContactCard(Icons.phone_rounded, 'Phone', '+234 123 456 7890', const Color(0xFF2196F3), isDark),
        const SizedBox(height: 12),
        _buildContactCard(Icons.email_rounded, 'Email', 'info@iuokada.edu.ng', const Color(0xFF9C27B0), isDark),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildContactCard(IconData icon, String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey[800]?.withAlpha(128)
            : color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(77),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.darkGrey,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
