import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/campus_building.dart';
import '../utils/favorites_service.dart';
import '../utils/app_routes.dart';
import '../widgets/modern_navbar.dart';
import 'enhanced_campus_map.dart';
import '../widgets/animated_success_card.dart';
import '../utils/page_transitions.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  // This would normally come from a provider/state management
  List<CampusBuilding> _favorites = [];
  final FavoritesService _favService = FavoritesService();
  final Set<String> _pinnedBuildings = {};
  StreamSubscription<List<String>>? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    // Listen to favorites changes for auto-update
    _favoritesSubscription = _favService.favoritesStream.listen((_) {
      _loadFavorites();
    });
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final list = await _favService.loadFavorites(campusBuildings);
    if (!mounted) return;
    setState(() {
      _favorites = list;
      debugPrint('✅ Loaded ${_favorites.length} favorites from ${campusBuildings.length} total buildings');
    });
  }

  Widget _buildCurvedHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE91E63), // Pink for love/heart theme
            Color(0xFFC2185B), // Darker pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipPath(
        clipper: CurvedBottomClipper(),
        child: Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE91E63), // Pink/heart color
                Color(0xFFC2185B), // Darker pink for depth
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Favorites',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All your hearted buildings in one place',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.white.withAlpha(242),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmark_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_favorites.length} ${_favorites.length == 1 ? "Building" : "Buildings"} Saved',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 1200));
              await _loadFavorites();
            },
          ),
          _favorites.isEmpty
            ? SliverFillRemaining(
                child: _buildEmptyState(),
              )
            : SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildCurvedHeaderCard(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: _buildFavoritesList(),
                    ),
                  ],
                ),
              ),
        ],
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_border,
                size: 60,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding your favorite locations by tapping the star icon on building cards',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  AppRoutes.fadeRoute(const EnhancedCampusMap()),
                );
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Campus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    // Sort: pinned items first
    final sortedFavorites = List<CampusBuilding>.from(_favorites)
      ..sort((a, b) {
        final aPinned = _pinnedBuildings.contains(a.name);
        final bPinned = _pinnedBuildings.contains(b.name);
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return 0;
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedFavorites.length,
      itemBuilder: (context, index) {
        final building = sortedFavorites[index];
        return _buildSwipeableFavoriteCard(building, index);
      },
    );
  }

  Widget _buildSwipeableFavoriteCard(CampusBuilding building, int index) {
    final isPinned = _pinnedBuildings.contains(building.name);
    
    return Dismissible(
      key: ValueKey('${building.name}-$index'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left to delete (30%)
          setState(() {
            _favorites.removeWhere((b) => b.name == building.name);
          });
          await _favService.removeFavorite(building.name);
          if (mounted) {
            showAnimatedSuccess(
              context,
              '${building.name} removed',
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.error,
            );
          }
          return true;
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right to pin/unpin (30%)
          setState(() {
            if (isPinned) {
              _pinnedBuildings.remove(building.name);
            } else {
              _pinnedBuildings.add(building.name);
            }
          });
          if (mounted) {
            showAnimatedSuccess(
              context,
              isPinned ? 'Unpinned' : 'Pinned to top',
              icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              iconColor: AppColors.primary,
            );
          }
          return false;
        }
        return false;
      },
      dismissThresholds: const {
        DismissDirection.endToStart: 0.3,
        DismissDirection.startToEnd: 0.3,
      },
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.primary,
        icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
        label: isPinned ? 'Unpin' : 'Pin',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red.shade600,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: _buildFavoriteCard(building, isPinned),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(CampusBuilding building, bool isPinned) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Hero(
      tag: 'building_${building.name}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.grey[850]!,
                    Colors.grey[900]!,
                  ]
                : [
                    Colors.white,
                    const Color(0xFFFAFAFA),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: isPinned
              ? Border.all(
                  color: const Color(0xFFE91E63).withAlpha(102),
                  width: 2,
                )
              : Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(26)
                      : Colors.black.withAlpha(13),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 77 : 20),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
            if (isPinned)
              BoxShadow(
                color: const Color(0xFFE91E63).withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showBuildingDetails(building);
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(building.category).withAlpha(51),
                            _getCategoryColor(building.category).withAlpha(26),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _getCategoryColor(building.category).withAlpha(77),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(building.category).withAlpha(38),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(building.category),
                        color: _getCategoryColor(building.category),
                        size: 32,
                      ),
                    ),
                    if (isPinned)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE91E63),
                                Color(0xFFC2185B),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withAlpha(128),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.push_pin,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        building.categoryName,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _showBuildingDetails(CampusBuilding building) {
    // Navigate to map screen with building data - map will handle showing sheet
    Navigator.pushReplacement(
      context,
      PageTransitions.fadeRoute(
        EnhancedCampusMap(selectedBuilding: building),
      ),
    );
  }

  IconData _getCategoryIcon(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return Icons.school_rounded;
      case BuildingCategory.administrative:
        return Icons.admin_panel_settings_rounded;
      case BuildingCategory.library:
        return Icons.local_library_rounded;
      case BuildingCategory.residential:
        return Icons.hotel_rounded;
      case BuildingCategory.dining:
        return Icons.restaurant_rounded;
      case BuildingCategory.sports:
        return Icons.sports_tennis_rounded;
      case BuildingCategory.health:
        return Icons.local_hospital_rounded;
      case BuildingCategory.worship:
        return Icons.church_rounded;
      case BuildingCategory.banking:
        return Icons.account_balance_rounded;
      case BuildingCategory.student_services:
        return Icons.support_agent_rounded;
      case BuildingCategory.research:
        return Icons.biotech_rounded;
    }
  }

  Color _getCategoryColor(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return const Color(0xFF2196F3); // Blue
      case BuildingCategory.administrative:
        return const Color(0xFF9C27B0); // Purple
      case BuildingCategory.library:
        return const Color(0xFF00BCD4); // Cyan
      case BuildingCategory.residential:
        return const Color(0xFFFF9800); // Orange
      case BuildingCategory.dining:
        return const Color(0xFF4CAF50); // Green
      case BuildingCategory.sports:
        return const Color(0xFFE91E63); // Pink
      case BuildingCategory.health:
        return const Color(0xFFF44336); // Red
      case BuildingCategory.worship:
        return const Color(0xFF795548); // Brown
      case BuildingCategory.banking:
        return const Color(0xFF009688); // Teal
      case BuildingCategory.student_services:
        return const Color(0xFFFF5722); // Deep Orange
      case BuildingCategory.research:
        return const Color(0xFF673AB7); // Deep Purple
    }
  }
}

// Custom clipper with beautiful arcs on both sides at the bottom
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from top-left
    path.moveTo(0, 0);
    
    // Right side straight down
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 50);
    
    // Right side arc (curves inward)
    path.quadraticBezierTo(
      size.width - 30, size.height - 35,
      size.width - 50, size.height - 20,
    );
    
    // Create flowing bottom curve with multiple waves
    path.quadraticBezierTo(
      size.width * 0.85, size.height - 10,
      size.width * 0.75, size.height - 15,
    );
    
    path.quadraticBezierTo(
      size.width * 0.65, size.height - 20,
      size.width * 0.5, size.height,
    );
    
    path.quadraticBezierTo(
      size.width * 0.35, size.height - 20,
      size.width * 0.25, size.height - 15,
    );
    
    path.quadraticBezierTo(
      size.width * 0.15, size.height - 10,
      50, size.height - 20,
    );
    
    // Left side arc (curves inward)
    path.quadraticBezierTo(
      30, size.height - 35,
      0, size.height - 50,
    );
    
    // Close path
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
