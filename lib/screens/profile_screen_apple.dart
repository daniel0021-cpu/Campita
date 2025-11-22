import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';
import '../widgets/modern_navbar.dart';
import 'package:latlong2/latlong.dart';
import '../models/campus_building.dart';
import 'dart:html' as html;

/// Apple-inspired Profile Screen with Modern Pill-shaped Designs
/// Smooth 3D animations, responsive design, campus-relevant settings
class ProfileScreenApple extends StatefulWidget {
  const ProfileScreenApple({super.key});

  @override
  State<ProfileScreenApple> createState() => _ProfileScreenAppleState();
}

class _ProfileScreenAppleState extends State<ProfileScreenApple> with TickerProviderStateMixin {
  final PreferencesService _prefs = PreferencesService();
  final ScrollController _scrollController = ScrollController();
  
  // Animation controllers
  late AnimationController _headerController;
  late AnimationController _settingsController;
  late Animation<double> _headerAnimation;
  late Animation<double> _settingsAnimation;
  
  // User data
  String _userName = 'Campus Explorer';
  String _studentId = '';
  String _department = 'Student';
  String _email = '';
  String _phone = '';
  String _level = '';
  String _dorm = '';
  String _room = '';
  Uint8List? _avatarBytes;
  
  // Preferences
  bool _notifications = true;
  bool _locationServices = true;
  bool _darkMode = false;
  bool _hapticFeedback = true;
  bool _voiceNavigation = false;
  bool _autoRouting = true;
  bool _offlineMode = false;
  String _mapStyle = 'Standard';
  String _transportMode = 'Walking';
  String _homeBuilding = 'Select Building';
  
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
    _loadPreferences();
    _scrollController.addListener(_onScroll);
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _settingsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    _settingsAnimation = CurvedAnimation(
      parent: _settingsController,
      curve: Curves.easeOutQuart,
    );
    
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _settingsController.forward();
    });
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
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
      
      final avatarBase64 = data['avatar'];
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          _avatarBytes = Base64Decoder().convert(avatarBase64);
        } catch (_) {}
      }
    });
  }

  Future<void> _loadPreferences() async {
    final notif = await _prefs.getBool(PreferencesKeys.notifications) ?? true;
    final loc = await _prefs.getBool(PreferencesKeys.locationServices) ?? true;
    final dark = await _prefs.getBool(PreferencesKeys.darkMode) ?? false;
    final mapStyle = await _prefs.getString(PreferencesKeys.mapStyle) ?? 'Standard';
    final navMode = await _prefs.getString(PreferencesKeys.lastTransportMode) ?? 'Walking';
    
    if (!mounted) return;
    setState(() {
      _notifications = notif;
      _locationServices = loc;
      _darkMode = dark;
      _mapStyle = mapStyle;
      _transportMode = navMode;
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _settingsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1200));
    await _loadUserData();
    await _loadPreferences();
    if (mounted) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Dynamic header opacity based on scroll
    final headerOpacity = (1 - (_scrollOffset / 200)).clamp(0.0, 1.0);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // iOS-style pull-to-refresh
              CupertinoSliverRefreshControl(
                onRefresh: _refreshProfile,
              ),
              
              // Floating header
              SliverToBoxAdapter(
                child: Opacity(
                  opacity: headerOpacity,
                  child: _buildFloatingHeader(isDark),
                ),
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    
                    // Personal Info Section
                    _buildAnimatedSection(
                      'Personal Information',
                      Icons.person_outline_rounded,
                      [
                        _buildInfoPill('Student ID', _studentId.isEmpty ? 'Not set' : _studentId, Icons.badge_outlined, isDark, onTap: () => _editField('studentId')),
                        _buildInfoPill('Department', _department, Icons.school_outlined, isDark, onTap: () => _editField('department')),
                        _buildInfoPill('Level', _level.isEmpty ? 'Not set' : _level, Icons.stairs_outlined, isDark, onTap: () => _editField('level')),
                        _buildInfoPill('Email', _email.isEmpty ? 'Not set' : _email, Icons.email_outlined, isDark, onTap: () => _editField('email')),
                        _buildInfoPill('Phone', _phone.isEmpty ? 'Not set' : _phone, Icons.phone_outlined, isDark, onTap: () => _editField('phone')),
                      ],
                      isDark,
                      delay: 0,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Campus Living Section
                    _buildAnimatedSection(
                      'Campus Living',
                      Icons.home_outlined,
                      [
                        _buildInfoPill('Hostel', _dorm.isEmpty ? 'Not set' : _dorm, Icons.hotel_outlined, isDark, onTap: () => _editField('dorm')),
                        _buildInfoPill('Room Number', _room.isEmpty ? 'Not set' : _room, Icons.door_front_door_outlined, isDark, onTap: () => _editField('room')),
                        _buildInfoPill('Home Building', _homeBuilding, Icons.location_on_outlined, isDark, onTap: _selectHomeBuilding),
                      ],
                      isDark,
                      delay: 100,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App Preferences Section
                    _buildAnimatedSection(
                      'App Preferences',
                      Icons.tune_outlined,
                      [
                        _buildTogglePill('Notifications', _notifications, Icons.notifications_outlined, isDark, (val) => _updatePref('notifications', val)),
                        _buildTogglePill('Location Services', _locationServices, Icons.location_on_outlined, isDark, (val) => _updatePref('location', val)),
                        _buildTogglePill('Dark Mode', _darkMode, Icons.dark_mode_outlined, isDark, (val) => _updatePref('darkMode', val)),
                        _buildTogglePill('Haptic Feedback', _hapticFeedback, Icons.vibration_outlined, isDark, (val) => _updatePref('haptic', val)),
                        _buildTogglePill('Voice Navigation', _voiceNavigation, Icons.record_voice_over_outlined, isDark, (val) => _updatePref('voice', val)),
                      ],
                      isDark,
                      delay: 200,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Navigation Settings Section
                    _buildAnimatedSection(
                      'Navigation Settings',
                      Icons.navigation_outlined,
                      [
                        _buildSelectionPill('Map Style', _mapStyle, Icons.map_outlined, isDark, ['Standard', 'Satellite', 'Terrain', '3D Terrain'], (val) => _updateSelection('mapStyle', val)),
                        _buildSelectionPill('Transport Mode', _transportMode, Icons.directions_walk_outlined, isDark, ['Walking', 'Bicycle', 'Car', 'Bus'], (val) => _updateSelection('transport', val)),
                        _buildTogglePill('Auto-Routing', _autoRouting, Icons.alt_route_outlined, isDark, (val) => _updatePref('autoRoute', val)),
                        _buildTogglePill('Offline Mode', _offlineMode, Icons.cloud_off_outlined, isDark, (val) => _updatePref('offline', val)),
                      ],
                      isDark,
                      delay: 300,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Out Button
                    _buildSignOutButton(isDark),
                  ]),
                ),
              ),
            ],
          ),
          
          // Floating navigation bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(isDark),
          ),
        ],
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 3),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final topBarOpacity = (_scrollOffset / 100).clamp(0.0, 1.0);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 100,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCard : Colors.white).withOpacity(topBarOpacity * 0.95),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white24 : Colors.black12).withOpacity(topBarOpacity),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: _AnimatedIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: topBarOpacity,
                  child: Center(
                    child: Text(
                      'Profile',
                      style: GoogleFonts.sfProDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
              ),
              _AnimatedIconButton(
                icon: Icons.edit_outlined,
                onTap: _editProfile,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(bool isDark) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(_headerAnimation),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
          child: Column(
            children: [
              // Avatar with 3D effect
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(0.3 * (1 - value))
                        ..rotateY(0.1 * (1 - value)),
                      alignment: Alignment.center,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkCard : Colors.white,
                        image: _avatarBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_avatarBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _avatarBytes == null
                          ? Icon(
                              Icons.person_outline_rounded,
                              size: 60,
                              color: AppColors.primary.withOpacity(0.5),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Name
              Text(
                _userName,
                style: GoogleFonts.sfProDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Department badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _department,
                      style: GoogleFonts.sfProText(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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

  Widget _buildAnimatedSection(String title, IconData icon, List<Widget> children, bool isDark, {int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.sfProText(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: -0.2,
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

  Widget _buildInfoPill(String label, String value, IconData icon, bool isDark, {VoidCallback? onTap}) {
    return _AnimatedPill(
      onTap: onTap,
      isDark: isDark,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.sfProText(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.sfProText(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildTogglePill(String label, bool value, IconData icon, bool isDark, ValueChanged<bool> onChanged) {
    return _AnimatedPill(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value ? AppColors.primary.withOpacity(0.15) : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? AppColors.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sfProText(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _ModernSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPill(String label, String value, IconData icon, bool isDark, List<String> options, ValueChanged<String> onChanged) {
    return _AnimatedPill(
      onTap: () => _showSelectionSheet(label, options, value, onChanged, isDark),
      isDark: isDark,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.sfProText(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.sfProText(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(bool isDark) {
    return _AnimatedPill(
      onTap: _signOut,
      isDark: isDark,
      backgroundColor: Colors.red.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 20, color: Colors.red),
          const SizedBox(width: 10),
          Text(
            'Sign Out',
            style: GoogleFonts.sfProText(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _editProfile() {
    // TODO: Navigate to full profile edit screen
    HapticFeedback.mediumImpact();
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

  void _editField(String field) {
    HapticFeedback.lightImpact();
    // Show input dialog
    showDialog(
      context: context,
      builder: (context) => _buildEditDialog(field),
    );
  }

  void _selectHomeBuilding() {
    HapticFeedback.lightImpact();
    // TODO: Show building selection sheet
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
          // TODO: Trigger theme change
          break;
        case 'haptic':
          _hapticFeedback = value;
          break;
        case 'voice':
          _voiceNavigation = value;
          break;
        case 'autoRoute':
          _autoRouting = value;
          break;
        case 'offline':
          _offlineMode = value;
          break;
      }
    });
  }

  Future<void> _updateSelection(String key, String value) async {
    HapticFeedback.lightImpact();
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

  void _showSelectionSheet(String title, List<String> options, String current, ValueChanged<String> onSelect, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectionSheet(
        title: title,
        options: options,
        current: current,
        onSelect: (value) {
          onSelect(value);
          Navigator.pop(context);
        },
        isDark: isDark,
      ),
    );
  }

  Widget _buildEditDialog(String field) {
    final controller = TextEditingController(text: _getFieldValue(field));
    return Dialog(
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(field, controller),
    );
  }

  Widget _buildDialogContent(String field, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit ${_getFieldLabel(field)}',
            style: GoogleFonts.sfProText(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _saveField(field, controller.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFieldValue(String field) {
    switch (field) {
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

  String _getFieldLabel(String field) {
    switch (field) {
      case 'studentId': return 'Student ID';
      case 'department': return 'Department';
      case 'level': return 'Level';
      case 'email': return 'Email';
      case 'phone': return 'Phone';
      case 'dorm': return 'Hostel';
      case 'room': return 'Room Number';
      default: return '';
    }
  }

  Future<void> _saveField(String field, String value) async {
    setState(() {
      switch (field) {
        case 'studentId': _studentId = value; break;
        case 'department': _department = value; break;
        case 'level': _level = value; break;
        case 'email': _email = value; break;
        case 'phone': _phone = value; break;
        case 'dorm': _dorm = value; break;
        case 'room': _room = value; break;
      }
    });
    
    await _prefs.saveProfileData(
      studentId: field == 'studentId' ? value : null,
      department: field == 'department' ? value : null,
      level: field == 'level' ? value : null,
      email: field == 'email' ? value : null,
      phone: field == 'phone' ? value : null,
      dorm: field == 'dorm' ? value : null,
      room: field == 'room' ? value : null,
    );
  }

  void _signOut() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement sign out
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// Animated Pill Widget
class _AnimatedPill extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? backgroundColor;

  const _AnimatedPill({
    required this.child,
    this.onTap,
    required this.isDark,
    this.backgroundColor,
  });

  @override
  State<_AnimatedPill> createState() => _AnimatedPillState();
}

class _AnimatedPillState extends State<_AnimatedPill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) widget.onTap!();
        });
      } : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? (widget.isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDark 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.05),
                    blurRadius: 12 + _elevationAnimation.value,
                    offset: Offset(0, 4 + _elevationAnimation.value * 0.5),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Modern Switch Widget
class _ModernSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: value ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        builder: (context, animation, child) {
          return Container(
            width: 51,
            height: 31,
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.grey.withOpacity(0.3),
                AppColors.primary,
                animation,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  left: value ? 22 : 2,
                  top: 2,
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Animated Icon Button
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _AnimatedIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _isPressed ? 0.9 : 1.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (widget.isDark ? Colors.white : Colors.black).withOpacity(_isPressed ? 0.15 : 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Selection Sheet
class _SelectionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String current;
  final ValueChanged<String> onSelect;
  final bool isDark;

  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.sfProText(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((option) {
              final isSelected = option == current;
              return ListTile(
                title: Text(
                  option,
                  style: GoogleFonts.sfProText(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect(option);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
