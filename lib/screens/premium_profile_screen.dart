import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_navbar.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';
import '../utils/page_transitions.dart';
import 'favorites_screen.dart';
import 'profile_edit_screen.dart';

/// Premium Profile Screen with Buttery Smooth Animations
/// Features: Animated waves, glass morphism, parallax, spring physics
class PremiumProfileScreen extends StatefulWidget {
  const PremiumProfileScreen({super.key});

  @override
  State<PremiumProfileScreen> createState() => _PremiumProfileScreenState();
}

class _PremiumProfileScreenState extends State<PremiumProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _waveController;
  late AnimationController _sheetController;
  late AnimationController _statsController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _avatarScaleAnimation;
  late Animation<Offset> _sheetSlideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final PreferencesService _prefsService = PreferencesService();
  final AppSettings _appSettings = AppSettings();
  
  bool _isRefreshing = false;
  double _scrollOffset = 0.0;
  
  // User data
  String _userName = 'Campus Explorer';
  String _userRole = 'Student';
  String? _avatarBase64;
  
  // Stats
  final int _buildingsVisited = 12;
  final int _stepsOnCampus = 8547;
  final int _savedLocations = 5;
  
  // Settings
  bool _notificationsEnabled = true;
  bool _hapticEnabled = true;
  bool _voiceNavEnabled = false;
  String _mapStyle = 'Standard';
  bool _darkMode = false;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _scrollController.addListener(_onScroll);
  }
  
  void _initAnimations() {
    // Header fade and avatar scale
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerController,
      curve: const Cubic(0.19, 1.0, 0.22, 1.0),
    );
    _avatarScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0), // Spring effect
      ),
    );
    
    // Continuous wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    // Sheet slide up with ripple
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sheetSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sheetController,
      curve: const Cubic(0.19, 1.0, 0.22, 1.0),
    ));
    
    // Stats cards stagger animation
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Start entrance animations
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _headerController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _sheetController.forward();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _statsController.forward();
        });
      }
    });
  }
  
  Future<void> _loadData() async {
    final profileData = await _prefsService.loadProfileData();
    if (!mounted) return;
    
    setState(() {
      _userName = profileData['name'] ?? 'Campus Explorer';
      _userRole = profileData['department'] ?? 'Student';
      _avatarBase64 = profileData['avatar'];
      
      // Load settings
      _darkMode = Theme.of(context).brightness == Brightness.dark;
    });
  }
  
  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset.clamp(0.0, 100.0);
    });
  }
  
  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();
    
    await Future.delayed(const Duration(milliseconds: 1500));
    await _loadData();
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      HapticFeedback.selectionClick();
    }
  }
  
  void _handleHaptic() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }
  
  @override
  void dispose() {
    _headerController.dispose();
    _waveController.dispose();
    _sheetController.dispose();
    _statsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.32;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main scrollable content
          RefreshIndicator(
            onRefresh: _refreshProfile,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            strokeWidth: 2.5,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Animated gradient header
                SliverToBoxAdapter(
                  child: _buildGradientHeader(headerHeight),
                ),
                
                // Wavy profile sheet
                SliverToBoxAdapter(
                  child: _buildWavyProfileSheet(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 3),
    );
  }
  
  // Gradient header with parallax effect
  Widget _buildGradientHeader(double height) {
    final parallaxOffset = _scrollOffset * 0.5;
    
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: Transform.translate(
        offset: Offset(0, -parallaxOffset),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
                const Color(0xFF60A5FA),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                
                // Avatar with scale animation
                ScaleTransition(
                  scale: _avatarScaleAnimation,
                  child: _buildAvatar(),
                ),
                
                const SizedBox(height: 12),
                
                // Name and role
                Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _userRole,
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Quick stats row
                _buildStatsRow(),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAvatar() {
    ImageProvider avatarProvider;
    if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
      try {
        avatarProvider = MemoryImage(Base64Decoder().convert(_avatarBase64!));
      } catch (_) {
        avatarProvider = const AssetImage('assets/logo/app_logo.png');
      }
    } else {
      avatarProvider = const AssetImage('assets/logo/app_logo.png');
    }
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
        ),
        child: CircleAvatar(
          radius: 42,
          backgroundImage: avatarProvider,
          backgroundColor: AppColors.primary.withOpacity(0.2),
        ),
      ),
    );
  }
  
  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _statsController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Buildings\nVisited', _buildingsVisited, 0),
            _buildStatCard('Steps on\nCampus', _stepsOnCampus, 1),
            _buildStatCard('Saved\nLocations', _savedLocations, 2),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String label, int value, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 1 + (index * 0.2)),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _statsController,
        curve: Interval(
          index * 0.1,
          0.5 + (index * 0.1),
          curve: const Cubic(0.19, 1.0, 0.22, 1.0),
        ),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Wavy bottom sheet with complex ripples
  Widget _buildWavyProfileSheet() {
    return SlideTransition(
      position: _sheetSlideAnimation,
      child: Stack(
        children: [
          // Wavy top edge
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 40),
                  painter: _WavePainter(
                    animation: _waveController.value,
                    scrollOffset: _scrollOffset,
                  ),
                );
              },
            ),
          ),
          
          // Sheet content with curved arcs
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Curved arcs decoration at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 120),
                    painter: _BottomArcsPainter(),
                  ),
                ),
                
                // Main content
                Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildSheetContent(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSheetContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Account'),
          const SizedBox(height: 16),
          _buildMenuItem(
            'Edit Profile',
            'Update your information',
            CupertinoIcons.person_crop_circle,
            () async {
              _handleHaptic();
              final updated = await Navigator.push(
                context,
                PageTransitions.slideRightRoute(const ProfileEditScreen()),
              );
              if (updated == true) _loadData();
            },
          ),
          _buildMenuItem(
            'Saved Locations',
            'Your favorite places',
            CupertinoIcons.placemark_fill,
            () {
              _handleHaptic();
              Navigator.push(
                context,
                PageTransitions.fadeRoute(const FavoritesScreen()),
              );
            },
          ),
          _buildMenuItem(
            'My Routes',
            'Frequently traveled paths',
            CupertinoIcons.map_fill,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          
          const SizedBox(height: 32),
          _buildSectionTitle('App Settings'),
          const SizedBox(height: 16),
          
          _buildToggleItem(
            'Notifications',
            'Get navigation updates',
            CupertinoIcons.bell_fill,
            _notificationsEnabled,
            (value) {
              _handleHaptic();
              setState(() => _notificationsEnabled = value);
            },
          ),
          _buildToggleItem(
            'Haptic Feedback',
            'Vibration on interactions',
            CupertinoIcons.hand_raised_fill,
            _hapticEnabled,
            (value) {
              setState(() => _hapticEnabled = value);
              if (value) HapticFeedback.mediumImpact();
            },
          ),
          _buildToggleItem(
            'Voice Navigation',
            'Audio turn-by-turn directions',
            CupertinoIcons.speaker_3_fill,
            _voiceNavEnabled,
            (value) {
              _handleHaptic();
              setState(() => _voiceNavEnabled = value);
            },
          ),
          _buildToggleItem(
            'Dark Mode',
            'Switch to dark theme',
            CupertinoIcons.moon_fill,
            _darkMode,
            (value) {
              _handleHaptic();
              setState(() => _darkMode = value);
              _showComingSoon();
            },
          ),
          
          _buildPickerItem(
            'Map Style',
            _mapStyle,
            CupertinoIcons.map,
            ['Standard', 'Satellite', 'Terrain', '3D'],
            (value) {
              _handleHaptic();
              setState(() => _mapStyle = value);
            },
          ),
          
          const SizedBox(height: 32),
          _buildSectionTitle('Campus Features'),
          const SizedBox(height: 16),
          
          _buildMenuItem(
            'My Private Places',
            'Save places with reminders',
            CupertinoIcons.map_pin_ellipse,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'Class Schedule',
            'Sync your class timetable',
            CupertinoIcons.calendar,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'Shuttle Tracking',
            'Track campus shuttle buses',
            CupertinoIcons.car_fill,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'Parking Preferences',
            'Set preferred parking spots',
            CupertinoIcons.car_detailed,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'Cafeteria Menu',
            'Daily meal notifications',
            CupertinoIcons.bag_fill,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'Study Rooms',
            'Book study spaces',
            CupertinoIcons.book_fill,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'Rate Campita',
            'Share your feedback',
            CupertinoIcons.star_fill,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          
          const SizedBox(height: 32),
          _buildSectionTitle('About'),
          const SizedBox(height: 16),
          
          _buildMenuItem(
            'Privacy Policy',
            'How we handle your data',
            CupertinoIcons.lock_shield_fill,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'Terms & Conditions',
            'Usage guidelines',
            CupertinoIcons.doc_text_fill,
            () {
              _handleHaptic();
              _showComingSoon();
            },
          ),
          _buildMenuItem(
            'About CampusNav',
            'Version 1.0.0',
            CupertinoIcons.info_circle_fill,
            () {
              _handleHaptic();
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                const Color(0xFF111827),
                const Color(0xFF374151),
              ],
            ).createShader(bounds),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withOpacity(0.15),
          highlightColor: AppColors.primary.withOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFAFAFA),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.12),
                        const Color(0xFF60A5FA).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 24,
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildToggleItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPickerItem(
    String title,
    String currentValue,
    IconData icon,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _handleHaptic();
            _showPicker(title, options, currentValue, onChanged);
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentValue,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
  
  void _showPicker(String title, List<String> options, String currentValue, ValueChanged<String> onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    onChanged(options[index]);
                    HapticFeedback.selectionClick();
                  },
                  scrollController: FixedExtentScrollController(
                    initialItem: options.indexOf(currentValue),
                  ),
                  children: options.map((option) {
                    return Center(
                      child: Text(
                        option,
                        style: GoogleFonts.openSans(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showComingSoon() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('This feature will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('CampusNav'),
        content: const Text(
          'Version 1.0.0\n\n'
          'Navigate your campus with ease.\n'
          'Built with ❤️ for Igbinedion University.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for beautiful bottom arcs decoration
class _BottomArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Large arc on the left
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withOpacity(0.05),
          AppColors.primary.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.6, size.height))
      ..style = PaintingStyle.fill;
    
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.15,
      size.width * 0.4,
      size.height * 0.5,
    );
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.75,
      size.width * 0.3,
      size.height,
    );
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);
    
    // Medium arc on the right
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF60A5FA).withOpacity(0.06),
          const Color(0xFF60A5FA).withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.5, size.height))
      ..style = PaintingStyle.fill;
    
    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.2);
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.4,
      size.width * 0.7,
      size.height * 0.65,
    );
    path2.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.9,
      size.width * 0.8,
      size.height,
    );
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
    
    // Small accent arc in the center
    final paint3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, size.height))
      ..style = PaintingStyle.fill;
    
    final path3 = Path();
    path3.moveTo(size.width * 0.4, size.height * 0.5);
    path3.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.3,
      size.width * 0.6,
      size.height * 0.5,
    );
    path3.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.8,
      size.width * 0.5,
      size.height,
    );
    path3.lineTo(size.width * 0.4, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);
  }
  
  @override
  bool shouldRepaint(_BottomArcsPainter oldDelegate) => false;
}

/// Custom painter for buttery smooth animated waves
class _WavePainter extends CustomPainter {
  final double animation;
  final double scrollOffset;
  
  _WavePainter({required this.animation, required this.scrollOffset});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final waveHeight = 30.0 - (scrollOffset * 0.1).clamp(0.0, 10.0);
    final waveLength = size.width / 4;
    
    path.moveTo(0, size.height);
    
    // Create smooth wave pattern
    for (var i = 0; i <= 4; i++) {
      final x = i * waveLength;
      final y = size.height - waveHeight * math.sin((animation * 2 * math.pi) + (i * math.pi / 2));
      
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = (i - 1) * waveLength;
        final prevY = size.height - waveHeight * math.sin((animation * 2 * math.pi) + ((i - 1) * math.pi / 2));
        final controlX1 = prevX + waveLength / 3;
        final controlY1 = prevY;
        final controlX2 = x - waveLength / 3;
        final controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }
    
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      animation != oldDelegate.animation || scrollOffset != oldDelegate.scrollOffset;
}
