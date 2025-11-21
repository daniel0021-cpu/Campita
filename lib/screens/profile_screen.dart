import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../utils/app_routes.dart';
import '../models/campus_building.dart';
import '../widgets/modern_navbar.dart';
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryAdaptive(context),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) {
              await _loadRecents();
              setState(() {});
            }
          },
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 3),
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
                  final updated = await Navigator.push(context, AppRoutes.slideRoute(const ProfileEditScreen()));
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
        // Subscription at TOP with PRO badge
        _pillShapedLink(
          'Subscription',
          'Unlock premium features',
          Icons.workspace_premium,
          () {
            Navigator.push(context, AppRoutes.slideRoute(const SubscriptionScreen()));
          },
          showProBadge: true,
        ),
        const SizedBox(height: 14),
        // Settings in its own separate pill
        _pillShapedLink(
          'Settings',
          'App preferences and map options',
          Icons.settings_rounded,
          () {
            Navigator.push(context, AppRoutes.slideRoute(const SettingsScreen()));
          },
        ),
        const SizedBox(height: 14),
        _pillShapedLink(
          'Help & Support',
          'FAQs and contact',
          Icons.help_outline_rounded,
          () {
            Navigator.push(context, AppRoutes.slideRoute(const HelpSupportScreen()));
          },
        ),
        const SizedBox(height: 14),
        _pillShapedLink(
          'Privacy Policy',
          'How we handle your data',
          Icons.privacy_tip_outlined,
          () {
            Navigator.push(context, AppRoutes.slideRoute(const PrivacyPolicyScreen()));
          },
        ),
        const SizedBox(height: 14),
        _pillShapedLink(
          'About',
          'About this app',
          Icons.info_outline_rounded,
          () {
            Navigator.push(context, AppRoutes.slideRoute(const AboutScreen()));
          },
        ),
      ],
    );
  }

  Widget _pillShapedLink(String title, String subtitle, IconData icon, VoidCallback onTap, {bool showProBadge = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: showProBadge ? AppColors.primary.withOpacity(0.3) : AppColors.borderAdaptive(context),
              width: showProBadge ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: showProBadge
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: showProBadge ? null : AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: showProBadge ? Colors.white : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryAdaptive(context),
                          ),
                        ),
                        if (showProBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'PRO',
                              style: GoogleFonts.notoSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryAdaptive(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.grey.withOpacity(0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
