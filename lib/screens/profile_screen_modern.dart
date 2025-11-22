import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';
import '../widgets/modern_navbar.dart';
import 'dart:html' as html;

/// Ultra-Modern Profile Screen with Stunning UI/UX
/// Gradient headers, glass morphism, smooth animations
class ProfileScreenModern extends StatefulWidget {
  const ProfileScreenModern({super.key});

  @override
  State<ProfileScreenModern> createState() => _ProfileScreenModernState();
}

class _ProfileScreenModernState extends State<ProfileScreenModern> with TickerProviderStateMixin {
  final PreferencesService _prefs = PreferencesService();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  
  String _userName = 'Campus Explorer';
  String _studentId = '';
  String _department = 'Student';
  String _email = '';
  String _phone = '';
  String _level = '';
  String _dorm = '';
  String _room = '';
  Uint8List? _avatarBytes;
  
  bool _notifications = true;
  bool _locationServices = true;
  bool _darkMode = false;
  bool _hapticFeedback = true;
  String _mapStyle = 'Standard';
  String _transportMode = 'Walking';
  
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
    _loadPreferences();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  void _initAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final data = await _prefs.loadProfileData();
    if (!mounted) return;
    setState(() {
      _userName = data['name'] ?? 'Campus Explorer';
      _studentId = data['studentId'] ?? '';
      _department = data['department'] ?? 'Student';
      _email = data['email'] ?? '';
      _phone = data['phone'] ?? '';
      _level = data['level'] ?? '';
      _dorm = data['dorm'] ?? '';
      _room = data['room'] ?? '';
      if (data['avatar'] != null) {
        final avatarData = data['avatar'] as String;
        if (avatarData.isNotEmpty) {
          try {
            _avatarBytes = base64Decode(avatarData);
          } catch (e) {
            _avatarBytes = null;
          }
        }
      }
    });
  }

  Future<void> _loadPreferences() async {
    final notif = await _prefs.getBool(PreferencesKeys.notifications);
    final loc = await _prefs.getBool(PreferencesKeys.locationServices);
    final dark = await _prefs.getBool(PreferencesKeys.darkMode);
    final haptic = await _prefs.getBool('haptic_feedback');
    final mapStyle = await _prefs.getString(PreferencesKeys.mapStyle);
    final transport = await _prefs.getString(PreferencesKeys.lastTransportMode);
    
    if (!mounted) return;
    setState(() {
      _notifications = notif ?? true;
      _locationServices = loc ?? true;
      _darkMode = dark ?? false;
      _hapticFeedback = haptic ?? true;
      _mapStyle = mapStyle ?? 'standard';
      _transportMode = transport ?? 'foot';
    });
  }

  Future<void> _refreshProfile() async {
    HapticFeedback.mediumImpact();
    await _loadUserData();
    await _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerHeight = 280.0;
    final headerOpacity = (1.0 - (_scrollOffset / headerHeight)).clamp(0.0, 1.0);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Stunning Gradient Header
              CupertinoSliverRefreshControl(
                onRefresh: _refreshProfile,
              ),
              
              SliverToBoxAdapter(
                child: _buildMagneticGradientHeader(isDark, headerOpacity),
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    
                    // Quick Stats Cards
                    _buildQuickStats(isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Personal Info Glass Card
                    _buildGlassSection(
                      'Personal Information',
                      Icons.person_rounded,
                      [
                        _buildModernInfoRow('Student ID', _studentId.isEmpty ? 'Add ID' : _studentId, Icons.badge_rounded, isDark, () => _showEditModal('studentId')),
                        _buildModernInfoRow('Department', _department, Icons.school_rounded, isDark, () => _showEditModal('department')),
                        _buildModernInfoRow('Level', _level.isEmpty ? 'Add Level' : _level, Icons.stairs_rounded, isDark, () => _showEditModal('level')),
                      ],
                      isDark,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contact Glass Card
                    _buildGlassSection(
                      'Contact',
                      Icons.phone_android_rounded,
                      [
                        _buildModernInfoRow('Email', _email.isEmpty ? 'Add Email' : _email, Icons.email_rounded, isDark, () => _showEditModal('email')),
                        _buildModernInfoRow('Phone', _phone.isEmpty ? 'Add Phone' : _phone, Icons.call_rounded, isDark, () => _showEditModal('phone')),
                      ],
                      isDark,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campus Living Glass Card
                    _buildGlassSection(
                      'Campus Living',
                      Icons.home_rounded,
                      [
                        _buildModernInfoRow('Hostel', _dorm.isEmpty ? 'Add Hostel' : _dorm, Icons.hotel_rounded, isDark, () => _showEditModal('dorm')),
                        _buildModernInfoRow('Room', _room.isEmpty ? 'Add Room' : _room, Icons.meeting_room_rounded, isDark, () => _showEditModal('room')),
                      ],
                      isDark,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Preferences Section
                    _buildGlassSection(
                      'Preferences',
                      Icons.tune_rounded,
                      [
                        _buildToggleRow('Notifications', _notifications, Icons.notifications_rounded, isDark, (val) => _updatePref('notifications', val)),
                        _buildToggleRow('Location', _locationServices, Icons.location_on_rounded, isDark, (val) => _updatePref('location', val)),
                        _buildToggleRow('Dark Mode', _darkMode, Icons.dark_mode_rounded, isDark, (val) => _updatePref('darkMode', val)),
                        _buildToggleRow('Haptic', _hapticFeedback, Icons.vibration_rounded, isDark, (val) => _updatePref('haptic', val)),
                      ],
                      isDark,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Navigation Settings
                    _buildGlassSection(
                      'Navigation',
                      Icons.navigation_rounded,
                      [
                        _buildSelectionRow('Map Style', _mapStyle, Icons.map_rounded, isDark, ['Standard', 'Satellite', 'Terrain'], (val) => _updateSelection('mapStyle', val)),
                        _buildSelectionRow('Transport', _transportMode, Icons.directions_walk_rounded, isDark, ['Walking', 'Bicycle', 'Car', 'Bus'], (val) => _updateSelection('transport', val)),
                      ],
                      isDark,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Out Button
                    _buildModernButton(
                      'Sign Out',
                      Icons.logout_rounded,
                      () {},
                      isDark,
                      isDestructive: true,
                    ),
                  ]),
                ),
              ),
            ],
          ),
          
          // Floating Back Button
          Positioned(
            top: 50,
            left: 20,
            child: _buildFloatingBackButton(isDark),
          ),
        ],
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 3),
    );
  }

  Widget _buildMagneticGradientHeader(bool isDark, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF7C3AED),
                    const Color(0xFFEC4899),
                  ]
                : [
                    const Color(0xFF3B82F6),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated shimmer effect
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _shimmerAnimation.value * MediaQuery.of(context).size.width,
                  child: Container(
                    width: 200,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withAlpha((0.0 * 255).toInt()),
                          Colors.white.withAlpha((0.2 * 255).toInt()),
                          Colors.white.withAlpha((0.0 * 255).toInt()),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Avatar with glow
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = 1.0 + (_pulseController.value * 0.05);
                          return Transform.scale(
                            scale: pulse,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withAlpha((0.3 * 255).toInt()),
                                    blurRadius: 30 * pulse,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                  image: _avatarBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(_avatarBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _avatarBytes == null
                                    ? const Center(
                                        child: Text(
                                          '📸',
                                          style: TextStyle(fontSize: 48),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Name
                    GestureDetector(
                      onTap: () => _showEditModal('name'),
                      child: Text(
                        _userName,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Department
                    Text(
                      _department,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha((0.9 * 255).toInt()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('12', 'Places\nVisited', Icons.location_on_rounded, isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('8', 'Favorites', Icons.favorite_rounded, isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('24', 'Routes\nTaken', Icons.route_rounded, isDark),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withAlpha((0.6 * 255).toInt()),
                  const Color(0xFF334155).withAlpha((0.4 * 255).toInt()),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha((0.1 * 255).toInt()) : Colors.black.withAlpha((0.05 * 255).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha((0.3 * 255).toInt()) : Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSection(String title, IconData icon, List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withAlpha((0.5 * 255).toInt()),
                  const Color(0xFF334155).withAlpha((0.3 * 255).toInt()),
                ]
              : [
                  Colors.white.withAlpha((0.9 * 255).toInt()),
                  const Color(0xFFF8FAFC).withAlpha((0.8 * 255).toInt()),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha((0.1 * 255).toInt()) : Colors.black.withAlpha((0.05 * 255).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha((0.3 * 255).toInt()) : Colors.black.withAlpha((0.06 * 255).toInt()),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withAlpha((0.7 * 255).toInt())],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon, bool isDark, VoidCallback onTap) {
    final isEmpty = value.startsWith('Add ');
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withAlpha((0.05 * 255).toInt()) : Colors.black.withAlpha((0.05 * 255).toInt()),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withAlpha((0.05 * 255).toInt()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isEmpty ? Colors.grey : AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, IconData icon, bool isDark, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withAlpha((0.05 * 255).toInt()) : Colors.black.withAlpha((0.05 * 255).toInt()),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withAlpha((0.05 * 255).toInt()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          _ModernSwitch(
            value: value,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRow(String label, String value, IconData icon, bool isDark, List<String> options, ValueChanged<String> onChanged) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSelectionModal(label, options, value, onChanged, isDark);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withAlpha((0.05 * 255).toInt()) : Colors.black.withAlpha((0.05 * 255).toInt()),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withAlpha((0.05 * 255).toInt()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBackButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(((isDark ? 0.2 : 0.95) * 255).toInt()),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withAlpha(((isDark ? 0.3 : 1.0) * 255).toInt()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : Colors.black,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildModernButton(String label, IconData icon, VoidCallback onTap, bool isDark, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isDestructive
              ? LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                )
              : LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withAlpha((0.8 * 255).toInt())],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDestructive ? Colors.red : AppColors.primary).withAlpha((0.3 * 255).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickAvatar() {
    HapticFeedback.lightImpact();
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) async {
          final bytes = reader.result as Uint8List?;
          if (bytes != null) {
            setState(() => _avatarBytes = bytes);
            await _prefs.saveProfileData(avatarBase64: base64Encode(bytes));
          }
        });
      }
    });
  }

  void _showEditModal(String field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileModal(
        field: field,
        currentValue: _getFieldValue(field),
        onSave: (value) async {
          await _saveField(field, value);
          await _loadUserData();
        },
      ),
    );
  }

  void _showSelectionModal(String title, List<String> options, String current, ValueChanged<String> onSelect, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((option) {
              final isSelected = option == current;
              return ListTile(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect(option);
                  Navigator.pop(context);
                },
                leading: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
                title: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getFieldValue(String field) {
    switch (field) {
      case 'name': return _userName;
      case 'studentId': return _studentId;
      case 'department': return _department;
      case 'level': return _level;
      case 'email': return _email;
      case 'phone': return _phone;
      case 'dorm': return _dorm;
      case 'room': return _room;
      default: return '';
    }
  }

  Future<void> _saveField(String field, String value) async {
    final data = await _prefs.loadProfileData();
    data[field] = value;
    await _prefs.saveProfileData(
      name: data['name'],
      studentId: data['studentId'],
      department: data['department'],
      level: data['level'],
      email: data['email'],
      phone: data['phone'],
      dorm: data['dorm'],
      room: data['room'],
    );
  }

  Future<void> _updatePref(String key, bool value) async {
    HapticFeedback.lightImpact();
    setState(() {
      switch (key) {
        case 'notifications':
          _notifications = value;
          _prefs.saveBool(PreferencesKeys.notifications, value);
          break;
        case 'location':
          _locationServices = value;
          _prefs.saveBool(PreferencesKeys.locationServices, value);
          AppSettings.locationServices.value = value;
          break;
        case 'darkMode':
          _darkMode = value;
          _prefs.saveBool(PreferencesKeys.darkMode, value);
          break;
        case 'haptic':
          _hapticFeedback = value;
          break;
      }
    });
  }

  Future<void> _updateSelection(String key, String value) async {
    setState(() {
      switch (key) {
        case 'mapStyle':
          _mapStyle = value;
          _prefs.saveString(PreferencesKeys.mapStyle, value);
          AppSettings.mapStyle.value = value;
          break;
        case 'transport':
          _transportMode = value;
          _prefs.saveString(PreferencesKeys.lastTransportMode, value);
          break;
      }
    });
  }
}

// Modern Switch Widget
class _ModernSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withAlpha((0.8 * 255).toInt())])
              : null,
          color: value ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Edit Profile Modal
class _EditProfileModal extends StatefulWidget {
  final String field;
  final String currentValue;
  final ValueChanged<String> onSave;

  const _EditProfileModal({
    required this.field,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<_EditProfileModal> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.3 * 255).toInt()),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withAlpha((0.7 * 255).toInt())],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(_getFieldIcon(widget.field), color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit ${_getFieldLabel(widget.field)}',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Beautiful input field
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF334155), const Color(0xFF475569)]
                              : [const Color(0xFFF1F5F9), Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha((0.3 * 255).toInt()),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter ${_getFieldLabel(widget.field).toLowerCase()}',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixIcon: Icon(
                            _getFieldIcon(widget.field),
                            color: AppColors.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        keyboardType: _getKeyboardType(widget.field),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              widget.onSave(_controller.text);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary.withAlpha((0.8 * 255).toInt())],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha((0.4 * 255).toInt()),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'name': return Icons.person_rounded;
      case 'studentId': return Icons.badge_rounded;
      case 'department': return Icons.school_rounded;
      case 'level': return Icons.stairs_rounded;
      case 'email': return Icons.email_rounded;
      case 'phone': return Icons.call_rounded;
      case 'dorm': return Icons.hotel_rounded;
      case 'room': return Icons.meeting_room_rounded;
      default: return Icons.edit_rounded;
    }
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'name': return 'Name';
      case 'studentId': return 'Student ID';
      case 'department': return 'Department';
      case 'level': return 'Level';
      case 'email': return 'Email';
      case 'phone': return 'Phone';
      case 'dorm': return 'Hostel';
      case 'room': return 'Room Number';
      default: return field;
    }
  }

  TextInputType _getKeyboardType(String field) {
    switch (field) {
      case 'email': return TextInputType.emailAddress;
      case 'phone': return TextInputType.phone;
      case 'studentId':
      case 'room': return TextInputType.number;
      default: return TextInputType.text;
    }
  }
}
