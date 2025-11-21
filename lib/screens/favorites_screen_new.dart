import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/favorites_service.dart';
import '../models/campus_building.dart';
import 'enhanced_campus_map.dart';
import '../widgets/animated_success_card.dart';

class FavoritesScreenNew extends StatefulWidget {
  const FavoritesScreenNew({super.key});

  @override
  State<FavoritesScreenNew> createState() => _FavoritesScreenNewState();
}

class _FavoritesScreenNewState extends State<FavoritesScreenNew> {
  final FavoritesService _favoritesService = FavoritesService();
  List<String> _favoriteIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favorites = await _favoritesService.loadFavorites(campusBuildings);
    setState(() {
      _favoriteIds = favorites.map((b) => b.name).toList();
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String buildingName) async {
    await _favoritesService.removeFavorite(buildingName);
    await _loadFavorites();
    if (mounted) {
      showAnimatedSuccess(
        context,
        'Removed "$buildingName" from favorites',
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
      );
    }
  }

  List<CampusBuilding> get _favoriteBuildings {
    return campusBuildings
        .where((b) => _favoriteIds.contains(b.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteBuildings.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _favoriteBuildings.length,
                  itemBuilder: (context, index) {
                    final building = _favoriteBuildings[index];
                    return _buildFavoriteCard(building);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 100,
            color: AppColors.grey.withAlpha(128),
          ),
          const SizedBox(height: 24),
          Text(
            'No Favorites Yet',
            style: GoogleFonts.notoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start adding your favorite locations to quickly access them',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EnhancedCampusMap()),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Explore Campus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(CampusBuilding building) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnhancedCampusMap()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(building.category).withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(building.category),
                        color: _getCategoryColor(building.category),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            building.name,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            building.categoryName,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () => _removeFavorite(building.name),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return Icons.school;
      case BuildingCategory.administrative:
        return Icons.business;
      case BuildingCategory.library:
        return Icons.local_library;
      case BuildingCategory.dining:
        return Icons.restaurant;
      case BuildingCategory.banking:
        return Icons.account_balance;
      case BuildingCategory.sports:
        return Icons.sports_basketball;
      default:
        return Icons.place;
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
      default:
        return AppColors.primary;
    }
  }
}
