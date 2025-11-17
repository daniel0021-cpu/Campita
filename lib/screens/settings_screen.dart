import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'map_style_screen.dart';
import 'navigation_mode_screen.dart';
import 'user_guide_screen.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';

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
  final PreferencesService _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _prefs.loadSettings();
    setState(() {
      _notifications = (s[PreferencesKeys.notifications] as bool?) ?? _notifications;
      _locationServices = (s[PreferencesKeys.locationServices] as bool?) ?? _locationServices;
      _darkMode = (s[PreferencesKeys.darkMode] as bool?) ?? _darkMode;
      _mapStyle = (s[PreferencesKeys.mapStyle] as String?) ?? _mapStyle;
      _navigationMode = (s[PreferencesKeys.navigationMode] as String?) ?? _navigationMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading2.copyWith(color: AppColors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 28),
          _sectionLabel('Appearance'),
          _modernCard([
            _settingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Reduce glare & save battery',
              trailing: Switch(
                value: _darkMode,
                activeColor: AppColors.primary,
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
                final selected = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const MapStyleScreen()));
                if (selected != null) {
                  setState(() => _mapStyle = selected);
                }
              },
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
          ]),
          const SizedBox(height: 32),
          _sectionLabel('Navigation'),
            _modernCard([
            _settingTile(
              icon: Icons.my_location_outlined,
              title: 'Location Services',
              subtitle: _locationServices ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _locationServices,
                activeColor: AppColors.primary,
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
                final selected = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const NavigationModeScreen()));
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
                activeColor: AppColors.primary,
                onChanged: (val) async {
                  setState(() => _notifications = val);
                  await _prefs.saveSettings(notifications: val);
                },
              ),
            ),
          ]),
          const SizedBox(height: 32),
          _sectionLabel('App Info'),
          _modernCard([
            _settingTile(
              icon: Icons.menu_book,
              title: 'User Guide',
              subtitle: 'Features & tips',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGuideScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
            _divider(),
            _settingTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'FAQs & contact',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
            _divider(),
            _settingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Your data & rights',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
            _divider(),
            _settingTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App details',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            ),
          ]),
          const SizedBox(height: 40),
          Center(
            child: Text('Version 1.0.0', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
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
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
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
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest User', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryAdaptive(context))),
                const SizedBox(height: 6),
                Text('Igbinedion University', style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondaryAdaptive(context))),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit, color: AppColors.grey))
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
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.07),
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
                color: AppColors.primary.withOpacity(0.12),
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

  Widget _divider() => Container(height: 1, color: AppColors.grey.withOpacity(0.15));

}
