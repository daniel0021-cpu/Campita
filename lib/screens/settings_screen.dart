import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'map_style_screen.dart';
import 'navigation_mode_screen.dart';
import 'user_guide_screen.dart';
import 'home_dashboard_screen.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';
import '../utils/app_routes.dart';
import 'video_tutorials_screen.dart';
import 'tips_tricks_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _locationServices = true;
  bool _darkMode = false;
  String _mapStyle = 'Standard';
  String _navigationMode = 'Walking';
  String _userName = 'Guest User';
  String _userEmail = '';
  final PreferencesService _prefs = PreferencesService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await _prefs.loadSettings();
    setState(() {
      _notifications = (s[PreferencesKeys.notifications] as bool?) ?? _notifications;
      _locationServices = (s[PreferencesKeys.locationServices] as bool?) ?? _locationServices;
      _darkMode = (s[PreferencesKeys.darkMode] as bool?) ?? _darkMode;
      _mapStyle = (s[PreferencesKeys.mapStyle] as String?) ?? _mapStyle;
      _navigationMode = (s[PreferencesKeys.navigationMode] as String?) ?? _navigationMode;
      _userName = (s[PreferencesKeys.userName] as String?) ?? 'Guest User';
      _userEmail = _userName != 'Guest User' ? (s['email'] as String?) ?? '' : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading2.copyWith(color: AppColors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 28),
          if (_matchesSearch('Appearance') || _matchesSearch('Dark Mode') || _matchesSearch('Map Style')) ...[
            _sectionLabel('Appearance'),
          _modernCard([
            _settingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Reduce glare & save battery',
              trailing: Switch(
                value: _darkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  setState(() => _darkMode = val);
                  await _prefs.saveSettings(darkMode: val);
                  AppSettings.darkMode.value = val;
                },
              ),
            ),
            _divider(),
            _settingTile(
              icon: Icons.map_outlined,
              title: 'Map Style',
              subtitle: _mapStyle,
              onTap: () async {
                final selected = await Navigator.push<String>(context, AppRoutes.flipRoute(const MapStyleScreen()));
                if (selected != null) {
                  setState(() => _mapStyle = selected);
                }
              },
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
          ]),
          const SizedBox(height: 32),
          ],
          if (_matchesSearch('Navigation') || _matchesSearch('Location') || _matchesSearch('Notifications')) ...[
            _sectionLabel('Navigation'),
            _modernCard([
            _settingTile(
              icon: Icons.my_location_outlined,
              title: 'Location Services',
              subtitle: _locationServices ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _locationServices,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  setState(() => _locationServices = val);
                  await _prefs.saveSettings(locationServices: val);
                  AppSettings.locationServices.value = val;
                },
              ),
            ),
            _divider(),
            _settingTile(
              icon: Icons.directions_walk,
              title: 'Navigation Mode',
              subtitle: _navigationMode,
              onTap: () async {
                final selected = await Navigator.push<String>(context, AppRoutes.flipRoute(const NavigationModeScreen()));
                if (selected != null) {
                  setState(() => _navigationMode = selected);
                  await _prefs.saveSettings(navigationMode: selected);
                  AppSettings.navigationMode.value = selected.toLowerCase();
                }
              },
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
            _divider(),
            _settingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: _notifications ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _notifications,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  setState(() => _notifications = val);
                  await _prefs.saveSettings(notifications: val);
                },
              ),
            ),
          ]),
          const SizedBox(height: 32),
          ],
          if (_matchesSearch('Developer') || _matchesSearch('Dashboard')) ...[
            _sectionLabel('Developer'),
            _modernCard([
            _settingTile(
              icon: Icons.dashboard_outlined,
              title: 'Home Dashboard (Preview)',
              subtitle: 'View experimental dashboard',
              onTap: () => Navigator.push(context, AppRoutes.depthSlideRoute(const HomeDashboardScreen())),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withAlpha(77)),
                    ),
                    child: Text(
                      'TEMP',
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.grey),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 32),
          ],
          if (_matchesSearch('App Info') || _matchesSearch('User Guide') || _matchesSearch('Help') || _matchesSearch('Privacy') || _matchesSearch('About')) ...[
            _sectionLabel('App Info'),
            _modernCard([
            _settingTile(
              icon: Icons.menu_book,
              title: 'User Guide',
              subtitle: 'Features & tips',
              onTap: () => Navigator.push(context, AppRoutes.flipRoute(const UserGuideScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
            _divider(),
            _settingTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'FAQs & contact',
              onTap: () => Navigator.push(context, AppRoutes.flipRoute(const HelpSupportScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
            _divider(),
            _settingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Your data & rights',
              onTap: () => Navigator.push(context, AppRoutes.flipRoute(const PrivacyPolicyScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
            _divider(),
            _settingTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App details',
              onTap: () => Navigator.push(context, AppRoutes.flipRoute(const AboutScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
          ]),
          const SizedBox(height: 40),
          ],
          if (_searchQuery.isEmpty)
            Center(
              child: Text('Version 1.0.0', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
            ),
          if (_searchQuery.isNotEmpty && !_hasAnyMatches())
            _buildNoResults(),
        ],
      ),
    );
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery);
  }

  bool _hasAnyMatches() {
    final searchTerms = [
      'Appearance', 'Dark Mode', 'Map Style',
      'Navigation', 'Location', 'Notifications',
      'Developer', 'Dashboard',
      'App Info', 'User Guide', 'Help', 'Privacy', 'About'
    ];
    return searchTerms.any((term) => term.toLowerCase().contains(_searchQuery));
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.cardBackground(context)
            : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _searchQuery.isNotEmpty 
              ? AppColors.primary.withAlpha(128)
              : AppColors.borderAdaptive(context),
          width: _searchQuery.isNotEmpty ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _searchQuery.isNotEmpty
                ? AppColors.primary.withAlpha(51)
                : Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.notoSans(
          fontSize: 15,
          color: AppColors.textPrimaryAdaptive(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search settings...',
          hintStyle: GoogleFonts.notoSans(
            fontSize: 15,
            color: AppColors.grey,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchQuery.isNotEmpty 
                ? AppColors.primary 
                : AppColors.grey,
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.grey.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryAdaptive(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 115 : 20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryAdaptive(context))),
                const SizedBox(height: 6),
                Text(
                  _userEmail.isNotEmpty ? _userEmail : 'Igbinedion University',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryAdaptive(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 14),
        child: Text(text, style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGrey)),
      );

  Widget _modernCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 102 : 18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(31),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGrey)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: AppColors.grey.withAlpha(38));

}
