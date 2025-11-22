import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';
import '../widgets/modern_navbar.dart';
import 'dart:html' as html;

/// Completely Redesigned Profile Screen - Modern, Clean, User-Friendly
/// NO glass morphism, NO auto-refresh, Beautiful pill shapes
class ProfileScreenRedesigned extends StatefulWidget {
  const ProfileScreenRedesigned({super.key});

  @override
  State<ProfileScreenRedesigned> createState() => _ProfileScreenRedesignedState();
}

class _ProfileScreenRedesignedState extends State<ProfileScreenRedesigned> with SingleTickerProviderStateMixin {
  final PreferencesService _prefs = PreferencesService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  
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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _loadUserData();
    _loadPreferences();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
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
      if (data['avatar'] != null && data['avatar'].isNotEmpty) {
        try {
          _avatarBytes = base64Decode(data['avatar']);
        } catch (e) {
          _avatarBytes = null;
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
      _notifications = notif;
      _locationServices = loc;
      _darkMode = dark;
      _hapticFeedback = haptic;
      _mapStyle = mapStyle;
      _transportMode = transport;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Button
            _buildTopBar(isDark),
            
            // Scrollable Content (NO PULL TO REFRESH)
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                physics: const ClampingScrollPhysics(), // NO BOUNCE - NO AUTO REFRESH
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile Header Card
                  _buildProfileCard(isDark),
                  
                  const SizedBox(height: 24),
                  
                  // Personal Info Section
                  _buildSectionTitle('Personal Information', Icons.person_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildInfoPill('Student ID', _studentId.isEmpty ? 'Add Student ID' : _studentId, Icons.badge_rounded, isDark, () => _showEditSheet('studentId')),
                  const SizedBox(height: 10),
                  _buildInfoPill('Department', _department, Icons.school_rounded, isDark, () => _showEditSheet('department')),
                  const SizedBox(height: 10),
                  _buildInfoPill('Level', _level.isEmpty ? 'Add Level' : _level, Icons.stairs_rounded, isDark, () => _showEditSheet('level')),
                  
                  const SizedBox(height: 24),
                  
                  // Contact Section
                  _buildSectionTitle('Contact Information', Icons.mail_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildInfoPill('Email', _email.isEmpty ? 'Add Email' : _email, Icons.email_rounded, isDark, () => _showEditSheet('email')),
                  const SizedBox(height: 10),
                  _buildInfoPill('Phone', _phone.isEmpty ? 'Add Phone Number' : _phone, Icons.phone_rounded, isDark, () => _showEditSheet('phone')),
                  
                  const SizedBox(height: 24),
                  
                  // Campus Living Section
                  _buildSectionTitle('Campus Living', Icons.home_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildInfoPill('Hostel', _dorm.isEmpty ? 'Add Hostel' : _dorm, Icons.apartment_rounded, isDark, () => _showEditSheet('dorm')),
                  const SizedBox(height: 10),
                  _buildInfoPill('Room Number', _room.isEmpty ? 'Add Room Number' : _room, Icons.door_front_door_rounded, isDark, () => _showEditSheet('room')),
                  
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  _buildSectionTitle('App Settings', Icons.settings_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildTogglePill('Notifications', _notifications, Icons.notifications_active_rounded, isDark, (val) => _updatePref('notifications', val)),
                  const SizedBox(height: 10),
                  _buildTogglePill('Location Services', _locationServices, Icons.location_on_rounded, isDark, (val) => _updatePref('location', val)),
                  const SizedBox(height: 10),
                  _buildTogglePill('Dark Mode', _darkMode, Icons.dark_mode_rounded, isDark, (val) => _updatePref('darkMode', val)),
                  const SizedBox(height: 10),
                  _buildTogglePill('Haptic Feedback', _hapticFeedback, Icons.vibration_rounded, isDark, (val) => _updatePref('haptic', val)),
                  
                  const SizedBox(height: 24),
                  
                  // Navigation Preferences
                  _buildSectionTitle('Navigation', Icons.explore_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildSelectionPill('Map Style', _mapStyle, Icons.map_rounded, isDark, ['Standard', 'Satellite', 'Terrain'], (val) => _updateSelection('mapStyle', val)),
                  const SizedBox(height: 10),
                  _buildSelectionPill('Transport Mode', _transportMode, Icons.directions_walk_rounded, isDark, ['Walking', 'Bicycle', 'Car', 'Bus'], (val) => _updateSelection('transport', val)),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Out Button
                  _buildSignOutButton(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 3),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Text(
              'My Profile',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      image: _avatarBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_avatarBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _avatarBytes == null
                        ? const Center(child: Text('📷', style: TextStyle(fontSize: 40)))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name (Editable)
          GestureDetector(
            onTap: () => _showEditSheet('name'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _userName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Department
          Text(
            _department,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPill(String label, String value, IconData icon, bool isDark, VoidCallback onTap) {
    final isEmpty = value.startsWith('Add ');
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmpty ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.1)) : AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isEmpty ? Colors.transparent : AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEmpty ? (isDark ? Colors.white10 : Colors.black05) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEmpty ? Colors.grey : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTogglePill(String label, bool value, IconData icon, bool isDark, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? AppColors.primary.withOpacity(0.3) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value ? AppColors.primary.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.black05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          _SmoothSwitch(
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

  Widget _buildSelectionPill(String label, String value, IconData icon, bool isDark, List<String> options, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSelectionSheet(label, options, value, onChanged, isDark);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Add sign out logic
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade600,
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

  void _showEditSheet(String field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BeautifulEditSheet(
        field: field,
        currentValue: _getFieldValue(field),
        onSave: (value) async {
          await _saveField(field, value);
          await _loadUserData();
        },
      ),
    );
  }

  void _showSelectionSheet(String title, List<String> options, String current, ValueChanged<String> onSelect, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                ),
                title: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
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

// Smooth Modern Switch
class _SmoothSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SmoothSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
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
                  color: Colors.black12,
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

// Beautiful Rounded Pill Edit Sheet
class _BeautifulEditSheet extends StatefulWidget {
  final String field;
  final String currentValue;
  final ValueChanged<String> onSave;

  const _BeautifulEditSheet({
    required this.field,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<_BeautifulEditSheet> createState() => _BeautifulEditSheetState();
}

class _BeautifulEditSheetState extends State<_BeautifulEditSheet> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getFieldIcon(widget.field),
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit ${_getFieldLabel(widget.field)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Beautiful rounded input
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
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
                      hintText: 'Enter ${_getFieldLabel(widget.field).toLowerCase()}...',
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
                
                const SizedBox(height: 20),
                
                // Action buttons in rounded pills
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
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 15,
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
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
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
    );
  }

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'name': return Icons.person_rounded;
      case 'studentId': return Icons.badge_rounded;
      case 'department': return Icons.school_rounded;
      case 'level': return Icons.stairs_rounded;
      case 'email': return Icons.email_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'dorm': return Icons.apartment_rounded;
      case 'room': return Icons.door_front_door_rounded;
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
      case 'phone': return 'Phone Number';
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
