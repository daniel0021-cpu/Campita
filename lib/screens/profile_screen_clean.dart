import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../widgets/modern_navbar.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';
import 'subscription_screen.dart';
import 'profile_edit_screen.dart';
import 'badges_screen.dart';
import 'home_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PreferencesService _prefs = PreferencesService();
  List<String> _recentNames = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final names = await _prefs.loadRecentSearches();
    if (mounted) {
      setState(() => _recentNames = names);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Compact header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(isDark),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                tooltip: 'Dashboard',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeDashboardScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                tooltip: 'Edit',
                onPressed: () async {
                  final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
                  if (updated == true && mounted) setState(() {});
                },
              ),
            ],
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                _buildStats(isDark),
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildSection('Quick Actions', Icons.flash_on, isDark),
                const SizedBox(height: 12),
                _buildQuickActions(isDark),
                const SizedBox(height: 24),
                
                // Settings
                _buildSection('Settings', Icons.settings_rounded, isDark),
                const SizedBox(height: 12),
                _buildSettings(isDark),
                const SizedBox(height: 32),
                
                // Version
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 3),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withAlpha(0xD9)],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<Map<String, String?>>(
          future: _prefs.loadProfileData(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            final name = data['name'] ?? 'Guest User';
            final dept = data['department'] ?? 'Igbinedion University';
            final avatarBase64 = data['avatar'];
            
            ImageProvider avatarProvider = const AssetImage('assets/logo/app_logo.png');
            if (avatarBase64 != null && avatarBase64.isNotEmpty) {
              try {
                avatarProvider = MemoryImage(Base64Decoder().convert(avatarBase64));
              } catch (_) {}
            }
            
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(0x33), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 41,
                      backgroundImage: avatarProvider,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, color: Colors.white.withAlpha(0xE6), size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          dept,
                          style: GoogleFonts.notoSans(fontSize: 12, color: Colors.white.withAlpha(0xF3), fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('24', 'Places', Icons.place_rounded, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('18', 'Routes', Icons.route_rounded, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('12', 'Favorites', Icons.favorite_rounded, isDark)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(0x0D), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryAdaptive(context))),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.textSecondaryAdaptive(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryAdaptive(context))),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'icon': Icons.badge_rounded, 'label': 'Badges', 'route': const BadgesScreen(badges: [])},
      {'icon': Icons.workspace_premium, 'label': 'Premium', 'route': const SubscriptionScreen()},
      {'icon': Icons.help_outline, 'label': 'Help', 'route': const HelpSupportScreen()},
    ];
    
    return Row(
      children: actions.map((action) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildActionCard(action['icon'] as IconData, action['label'] as String, action['route'] as Widget, isDark),
        ),
      )).toList(),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Widget route, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => route));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(0x0D), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimaryAdaptive(context)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(bool isDark) {
    final settings = [
      {'icon': Icons.settings, 'title': 'Settings', 'route': const SettingsScreen()},
      {'icon': Icons.lock_outline, 'title': 'Privacy Policy', 'route': const PrivacyPolicyScreen()},
      {'icon': Icons.info_outline, 'title': 'About', 'route': const AboutScreen()},
    ];
    
    return Column(
      children: settings.map((setting) => _buildSettingsTile(setting['icon'] as IconData, setting['title'] as String, setting['route'] as Widget, isDark)).toList(),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, Widget route, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(0x0D), blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(title, style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimaryAdaptive(context))),
        trailing: Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => route));
        },
      ),
    );
  }
}
