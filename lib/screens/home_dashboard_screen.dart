import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/campus_building.dart';
import '../models/campus_event.dart';
import 'enhanced_campus_map.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'recent_searches_screen.dart';
import 'events_screen.dart';
import '../widgets/modern_navbar.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final List<String> _quickAccessCategories = [
    'Academic',
    'Administrative',
    'Library',
    'Dining',
    'Sports',
    'Banking',
    'Student Services',
    'Research',
    'Health',
    'Residential',
    'Worship',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Campus Navigation',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryAdaptive(context),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: AppColors.grey),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            // Live Events Banner
            _buildLiveEventsBanner(),
            const SizedBox(height: 20),

            // Stats Overview
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Events Button
            _buildEventsButton(),
            const SizedBox(height: 28),

            // Quick Access
            Text(
              'Quick Access',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickAccessGrid(),
            const SizedBox(height: 24),

            // Recent Searches
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecentSearchesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.notoSans(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecentSearches(),
            const SizedBox(height: 24),

            // Popular Locations
            Text(
              'Popular Locations',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildPopularLocations(),
          ],
        ),
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 0),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.notoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore Igbinedion University campus with ease',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnhancedCampusMap(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Open Map',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.map_outlined,
            size: 80,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveEventsBanner() {
    // Get live events (happening now)
    final liveEvents = sampleEvents.where((e) => e.isHappening).toList();
    
    if (liveEvents.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final event = liveEvents.first;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.flame_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LIVE NOW',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        event.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        event.venue,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      CupertinoIcons.clock_fill,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.timeRangeFormatted,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.arrow_right,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsButton() {
    return _AnimatedPressButton(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const EventsScreen(),
            transitionDuration: const Duration(milliseconds: 450),
            reverseTransitionDuration: const Duration(milliseconds: 350),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: const Cubic(0.34, 1.56, 0.64, 1.0),
              );
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..scale(0.92 + (0.08 * curvedAnimation.value)),
                alignment: Alignment.center,
                child: FadeTransition(
                  opacity: curvedAnimation,
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.event_rounded,
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
                    'Campus Events',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check out what\'s happening on campus',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Buildings',
            '30+',
            Icons.domain,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Routes',
            '100+',
            Icons.route,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Users',
            '2.8K',
            Icons.people,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _quickAccessCategories.length,
      itemBuilder: (context, index) {
        final category = _quickAccessCategories[index];
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 450),
          curve: const Cubic(0.34, 1.56, 0.64, 1.0), // Spring bounce
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..translate(0.0, 20.0 * (1 - value), -10.0 * (1 - value))
                ..scale(0.8 + (0.2 * value)),
              alignment: Alignment.center,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildQuickAccessCard(category),
        );
      },
    );
  }

  Widget _buildQuickAccessCard(String category) {
    IconData icon;
    Color color;

    switch (category) {
      case 'Academic':
        icon = Icons.school_rounded;
        color = const Color(0xFFFF9800);
        break;
      case 'Administrative':
        icon = Icons.business_rounded;
        color = const Color(0xFF607D8B);
        break;
      case 'Library':
        icon = Icons.auto_stories_rounded;
        color = const Color(0xFF9C27B0);
        break;
      case 'Dining':
        icon = Icons.restaurant_rounded;
        color = const Color(0xFFE91E63);
        break;
      case 'Sports':
        icon = Icons.sports_soccer_rounded;
        color = const Color(0xFFF44336);
        break;
      case 'Banking':
        icon = Icons.account_balance_rounded;
        color = const Color(0xFF4CAF50);
        break;
      case 'Student Services':
        icon = Icons.groups_rounded;
        color = const Color(0xFF00BCD4);
        break;
      case 'Research':
        icon = Icons.biotech_rounded;
        color = const Color(0xFF3F51B5);
        break;
      case 'Health':
        icon = Icons.medical_services_rounded;
        color = const Color(0xFFFF5722);
        break;
      case 'Residential':
        icon = Icons.hotel_rounded;
        color = const Color(0xFF795548);
        break;
      case 'Worship':
        icon = Icons.church_rounded;
        color = const Color(0xFF673AB7);
        break;
      default:
        icon = Icons.place;
        color = AppColors.primary;
    }

    return _QuickAccessButton(
      icon: icon,
      color: color,
      category: category,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EnhancedCampusMap(),
          ),
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    final recentBuildings = campusBuildings.take(3).toList();

    return Column(
      children: recentBuildings.asMap().entries.map((entry) {
        final index = entry.key;
        final building = entry.value;
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 350 + (index * 80)),
          curve: Curves.easeOutQuart,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(-20.0 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history, color: AppColors.primary),
            ),
            title: Text(
              building.name,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              building.categoryName,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EnhancedCampusMap(),
                ),
              );
            },
          ),
        ),
        );
      }).toList(),
    );
  }

  Widget _buildPopularLocations() {
    final popularBuildings = [
      campusBuildings.firstWhere((b) => b.name.contains('Library')),
      campusBuildings.firstWhere((b) => b.name.contains('Admin')),
      campusBuildings.firstWhere((b) => b.name.contains('Law')),
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: popularBuildings.length,
        itemBuilder: (context, index) {
          final building = popularBuildings[index];
          final categoryColor = _getCategoryColor(building.category);
          final categoryIcon = _getCategoryIcon(building.category);
          
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 80)),
            curve: Curves.easeOutQuart,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translate(30.0 * (1 - value), 0.0, -15.0 * (1 - value)),
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _PopularLocationCard(
              building: building,
              categoryColor: categoryColor,
              categoryIcon: categoryIcon,
            ),
          );
        },
      ),
    );
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
        return const Color(0xFFFF9800);
      case BuildingCategory.administrative:
        return const Color(0xFF607D8B);
      case BuildingCategory.library:
        return const Color(0xFF9C27B0);
      case BuildingCategory.dining:
        return const Color(0xFFE91E63);
      case BuildingCategory.banking:
        return const Color(0xFF4CAF50);
      case BuildingCategory.sports:
        return const Color(0xFFF44336);
      case BuildingCategory.student_services:
        return const Color(0xFF00BCD4);
      case BuildingCategory.research:
        return const Color(0xFF3F51B5);
      case BuildingCategory.health:
        return const Color(0xFFFF5722);
      case BuildingCategory.residential:
        return const Color(0xFF795548);
      case BuildingCategory.worship:
        return const Color(0xFF673AB7);
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EnhancedCampusMap()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}

class _PopularLocationCard extends StatefulWidget {
  final CampusBuilding building;
  final Color categoryColor;
  final IconData categoryIcon;

  const _PopularLocationCard({
    required this.building,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  State<_PopularLocationCard> createState() => _PopularLocationCardState();
}

class _PopularLocationCardState extends State<_PopularLocationCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        Future.delayed(const Duration(milliseconds: 80), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EnhancedCampusMap(),
            ),
          );
        });
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_scale == 1.0 ? 0.05 : 0.15),
                blurRadius: _scale == 1.0 ? 8 : 12,
                offset: Offset(0, _scale == 1.0 ? 2 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.categoryIcon,
                    color: widget.categoryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.building.name,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  widget.building.categoryName,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String category;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.icon,
    required this.color,
    required this.category,
    required this.onTap,
  });

  @override
  State<_QuickAccessButton> createState() => _QuickAccessButtonState();
}

class _QuickAccessButtonState extends State<_QuickAccessButton> {
  double _scale = 1.0;
  double _depth = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _scale = 0.94;
          _depth = -8.0;
        });
      },
      onTapUp: (_) {
        setState(() {
          _scale = 1.0;
          _depth = 0.0;
        });
        Future.delayed(const Duration(milliseconds: 80), widget.onTap);
      },
      onTapCancel: () {
        setState(() {
          _scale = 1.0;
          _depth = 0.0;
        });
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..translate(0.0, 0.0, _depth),
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_depth == 0.0 ? 0.05 : 0.15),
                  blurRadius: _depth == 0.0 ? 8 : 12,
                  offset: Offset(0, _depth == 0.0 ? 2 : 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 32),
                const SizedBox(height: 8),
                Text(
                  widget.category,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedPressButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;
  double _depth = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
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
        setState(() {
          _scale = 0.96;
          _depth = -5.0;
        });
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() {
          _scale = 1.0;
          _depth = 0.0;
        });
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () {
        setState(() {
          _scale = 1.0;
          _depth = 0.0;
        });
        _controller.reverse();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(0.0, 0.0, _depth),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
