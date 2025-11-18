import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../models/campus_building.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';
import 'subscription_screen.dart';
import 'profile_edit_screen.dart';

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
    if (!mounted) return;
    setState(() => _recentNames = names);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSectionHeader('Recent Searches'),
          _buildRecentList(),
          const SizedBox(height: 20),
          _buildSectionHeader('Quick Links'),
          _buildQuickLinks(),
          const SizedBox(height: 20),
          Center(
            child: Text('Version 1.0.0', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<Map<String, String?>>(
      future: _prefs.loadProfileData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final name = data['name'] ?? 'Guest User';
        final dept = data['department'] ?? 'Igbinedion University';
        final avatarBase64 = data['avatar'];
        ImageProvider avatarProvider;
        if (avatarBase64 != null && avatarBase64.isNotEmpty) {
          try {
            avatarProvider = MemoryImage(Base64Decoder().convert(avatarBase64));
          } catch (_) {
            avatarProvider = const AssetImage('assets/logo/app_logo.png');
          }
        } else {
          avatarProvider = const AssetImage('assets/logo/app_logo.png');
        }
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.borderAdaptive(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundImage: avatarProvider,
                backgroundColor: AppColors.primary.withOpacity(0.12),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryAdaptive(context))),
                    const SizedBox(height: 6),
                    Text(dept, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondaryAdaptive(context))),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
                  if (updated == true && mounted) setState(() {});
                },
                icon: const Icon(Icons.edit, color: AppColors.grey),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
    );
  }

  Widget _buildRecentList() {
    if (_recentNames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Text('No recent searches yet', style: GoogleFonts.notoSans(color: AppColors.grey)),
      );
    }
    // try to match names to buildings so we can return a building on tap
    final List<CampusBuilding> source = campusBuildings; // fallback dataset
    final items = _recentNames.map((n) {
      final match = source.where((b) => b.name == n).toList();
      return match.isNotEmpty ? match.first : null;
    }).toList();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentNames.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final name = _recentNames[index];
          final building = index < items.length ? items[index] : null;
          return ListTile(
            leading: const Icon(Icons.history, color: AppColors.grey),
            title: Text(name, style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
            onTap: () {
              if (building != null) {
                Navigator.pop(context, building);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Column(
      children: [
        _linkCard('Settings', 'App preferences and map options', Icons.settings, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }),
        const SizedBox(height: 12),
        _linkCard('Subscription', 'Premium plans and benefits', Icons.workspace_premium, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
        }),
        const SizedBox(height: 12),
        _linkCard('Help & Support', 'FAQs and contact', Icons.help_outline, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
        }),
        const SizedBox(height: 12),
        _linkCard('Privacy Policy', 'How we handle your data', Icons.privacy_tip_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
        }),
        const SizedBox(height: 12),
        _linkCard('About', 'About this app', Icons.info_outline, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
        }),
      ],
    );
  }

  Widget _linkCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderAdaptive(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryAdaptive(context))),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondaryAdaptive(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}
