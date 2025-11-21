import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/campus_building.dart';
import 'premium_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CampusBuilding> _searchResults = [];
  final List<String> _recentSearches = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      final source = campusBuildings; // could be replaced by OSM list via injection
      _searchResults = source
          .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Sort alphabetically

      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ash,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildSearchSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
            color: isDark ? Colors.white : AppColors.darkGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Hero(
              tag: 'search_bar',
              child: Material(
                color: Colors.transparent,
                child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[900]?.withOpacity(0.95) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search buildings...',
                  hintStyle: GoogleFonts.notoSans(
                    fontSize: 15,
                    color: AppColors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.grey, size: 20),
                          onPressed: _clearSearch,
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.mic_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Voice search - Say your destination'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.darkGrey,
                ),
              ),
            ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
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
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0052CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Academic'),
                _buildCategoryChip('Administrative'),
                _buildCategoryChip('Library'),
                _buildCategoryChip('Dining'),
                _buildCategoryChip('Sports'),
                _buildCategoryChip('Banking'),
                _buildCategoryChip('Student Services'),
                _buildCategoryChip('Research'),
                _buildCategoryChip('Health'),
                _buildCategoryChip('Residential'),
                _buildCategoryChip('Worship'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader('Recent Searches'),
            ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
            const SizedBox(height: 24),
          ] else ...[
            _buildEmptyRecentSearches(),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('Popular Locations'),
          _buildQuickSearchCard(
            Icons.auto_stories_rounded,
            'University Library',
            'Main library with study areas',
            const Color(0xFF9C27B0),
          ),
          _buildQuickSearchCard(
            Icons.business_rounded,
            'Administrative Block',
            'Main administration offices',
            const Color(0xFF607D8B),
          ),
          _buildQuickSearchCard(
            Icons.restaurant_rounded,
            'Cafeteria',
            'Main dining facility',
            const Color(0xFFE91E63),
          ),
          _buildQuickSearchCard(
            Icons.school_rounded,
            'Computer Lab',
            'Computer science facilities',
            const Color(0xFFFF9800),
          ),
          _buildQuickSearchCard(
            Icons.medical_services_rounded,
            'Medical Center',
            'Campus health services',
            const Color(0xFFFF5722),
          ),
          _buildQuickSearchCard(
            Icons.sports_soccer_rounded,
            'Sports Complex',
            'Athletic facilities and stadium',
            const Color(0xFFF44336),
          ),
          _buildQuickSearchCard(
            Icons.account_balance_rounded,
            'Banking Services',
            'Campus banking facilities',
            const Color(0xFF4CAF50),
          ),
          _buildQuickSearchCard(
            Icons.groups_rounded,
            'Student Services',
            'Student affairs and support',
            const Color(0xFF00BCD4),
          ),
          _buildQuickSearchCard(
            Icons.biotech_rounded,
            'Research Labs',
            'Research and innovation center',
            const Color(0xFF3F51B5),
          ),
          _buildQuickSearchCard(
            Icons.hotel_rounded,
            'Student Hostels',
            'Campus residential facilities',
            const Color(0xFF795548),
          ),
          _buildQuickSearchCard(
            Icons.church_rounded,
            'Chapel',
            'Campus worship center',
            const Color(0xFF673AB7),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.search_off_rounded,
                  size: 80,
                  color: AppColors.grey.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or browse categories',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader('Recent Searches'),
            ..._recentSearches.take(3).map((search) => _buildRecentSearchItem(search)),
            const SizedBox(height: 16),
            _buildSectionHeader('Results'),
            const SizedBox(height: 4),
          ],
          ..._searchResults.asMap().entries.map((entry) {
            final index = entry.key;
            final building = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 250 + (index * 35)),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: RepaintBoundary(child: child),
                  ),
                );
              },
              child: _buildResultCard(building, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      child: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  Widget _buildEmptyRecentSearches() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Searches',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start searching for buildings and your recent searches will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.history_rounded, color: isDark ? Colors.white70 : AppColors.grey),
        title: Text(
          search,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.darkGrey,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : AppColors.grey, size: 18),
          onPressed: () {
            setState(() {
              _recentSearches.remove(search);
            });
          },
          splashRadius: 20,
        ),
        onTap: () {
          _searchController.text = search;
          _performSearch(search);
        },
      ),
    );
  }

  Widget _buildQuickSearchCard(IconData icon, String title, String subtitle, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Search for this location
            _searchController.text = title;
            _performSearch(title);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white54 : AppColors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(String label) {
    switch (label) {
      case 'All':
        return {'icon': Icons.apps_rounded, 'color': AppColors.primary};
      case 'Academic Buildings':
        return {'icon': Icons.menu_book_rounded, 'color': AppColors.academic};
      case 'Hostels':
        return {'icon': Icons.hotel_rounded, 'color': const Color(0xFFE91E63)};
      case 'Facilities':
        return {'icon': Icons.business_rounded, 'color': const Color(0xFF9C27B0)};
      case 'Departments':
        return {'icon': Icons.account_balance_rounded, 'color': const Color(0xFF2196F3)};
      case 'Services':
        return {'icon': Icons.groups_rounded, 'color': const Color(0xFFFF9800)};
      case 'Recreation':
        return {'icon': Icons.sports_soccer_rounded, 'color': const Color(0xFF4CAF50)};
      default:
        return {'icon': Icons.category_rounded, 'color': AppColors.primary};
    }
  }

  Widget _buildCategoryChip(String label) {
    final info = _getCategoryInfo(label);
    final color = info['color'] as Color;
    final icon = info['icon'] as IconData;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: () {
            if (label == 'All') {
              _searchController.clear();
              setState(() {
                _searchResults = [];
                _isSearching = false;
              });
            } else {
              _searchController.text = label;
              _performSearch(label);
            }
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIconForBuilding(BuildingCategory category) {
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

  Color _getCategoryColorForBuilding(BuildingCategory category) {
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

  Widget _buildResultCard(CampusBuilding building, int index) {
    final categoryColor = _getCategoryColorForBuilding(building.category);
    final categoryIcon = _getCategoryIconForBuilding(building.category);
    
    return Hero(
      tag: 'building-${building.name}-$index',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.pop(context, building);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          building.name,
                          style: GoogleFonts.notoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                building.categoryName,
                                style: GoogleFonts.notoSans(
                                  fontSize: 11,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 18, color: categoryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
