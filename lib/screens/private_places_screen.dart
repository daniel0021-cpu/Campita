import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/private_place.dart';
import '../utils/private_places_service.dart';
import '../theme/app_theme.dart';

/// Private Places Screen - Users can save places they want to visit with reminders
class PrivatePlacesScreen extends StatefulWidget {
  const PrivatePlacesScreen({super.key});

  @override
  State<PrivatePlacesScreen> createState() => _PrivatePlacesScreenState();
}

class _PrivatePlacesScreenState extends State<PrivatePlacesScreen> with TickerProviderStateMixin {
  final PrivatePlacesService _service = PrivatePlacesService();
  List<PrivatePlace> _places = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadPlaces();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    final places = await _service.loadPrivatePlaces();
    setState(() {
      _places = places;
      _isLoading = false;
    });
    _fadeController.forward();
  }

  List<PrivatePlace> get _filteredPlaces {
    if (_selectedCategory == 'All') return _places;
    return _places.where((p) => p.category == _selectedCategory.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'My Places',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled_solid, color: AppColors.primary),
            onPressed: () => _showAddPlaceDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildCategoryFilter(),
                  Expanded(
                    child: _places.isEmpty
                        ? _buildEmptyState()
                        : _buildPlacesList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Personal', 'Academic', 'Social', 'Other'];
    
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlacesList() {
    final filtered = _filteredPlaces;
    
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No places in this category',
          style: GoogleFonts.openSans(
            fontSize: 16,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildPlaceCard(filtered[index], index),
    );
  }

  Widget _buildPlaceCard(PrivatePlace place, int index) {
    final hasReminder = place.reminderEnabled && place.reminderTime != null;
    final isPast = place.reminderTime?.isBefore(DateTime.now()) ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPlaceDetails(place),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: place.isVisited
                    ? Colors.green.withOpacity(0.3)
                    : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(place.category),
                            _getCategoryColor(place.category).withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(place.category),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            place.description,
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (place.isVisited)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Visited',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (hasReminder) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.orange.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.bell_fill,
                          size: 16,
                          color: isPast ? Colors.orange : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatReminderTime(place.reminderTime!),
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.orange : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (place.notes != null && place.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    place.notes!,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.map_pin_ellipse,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Places Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add places you want to visit\nand set reminders',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddPlaceDialog(),
            icon: const Icon(CupertinoIcons.add),
            label: const Text('Add Your First Place'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlaceDialog() {
    // TODO: Implement add place dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add place dialog coming soon!')),
    );
  }

  void _showPlaceDetails(PrivatePlace place) {
    // TODO: Implement place details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Details for ${place.name}')),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Colors.purple;
      case 'academic':
        return Colors.blue;
      case 'social':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return CupertinoIcons.person_fill;
      case 'academic':
        return CupertinoIcons.book_fill;
      case 'social':
        return CupertinoIcons.person_3_fill;
      default:
        return CupertinoIcons.location_fill;
    }
  }

  String _formatReminderTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.isNegative) {
      return 'Reminder passed';
    }
    
    if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    }
    
    if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    }
    
    return 'In ${difference.inMinutes} min';
  }
}
