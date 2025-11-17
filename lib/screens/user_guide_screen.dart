import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text('User Guide', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _headerCard(context),
          const SizedBox(height: 28),
          _sectionLabel('Features'),
          _featureCard(context, Icons.search, 'Search Buildings', 'Tap the search bar at the top of the map. Type any building name or category (e.g., "Admin", "Library") to instantly locate it.'),
          _featureCard(context, Icons.directions, 'Get Directions', 'Select a building from search results, then tap "Directions". Choose your transport mode (walking, driving, transit) for optimized routes.'),
          _featureCard(context, Icons.star, 'Save Favorites', 'Tap the star icon on any building card to add it to your Favorites. Access them quickly from the bottom nav bar.'),
          _featureCard(context, Icons.my_location, 'Live Location', 'Grant location permissions to see your real-time position on the map. The app tracks you as you move.'),
          _featureCard(context, Icons.map, 'Map Styles', 'Go to Settings > Map Style to switch between Standard, Satellite, and Terrain views.'),
          _featureCard(context, Icons.layers, 'Navigation Modes', 'Settings > Navigation Mode lets you pick Walking, Driving, or Transit. Routes adapt based on your choice.'),
          const SizedBox(height: 28),
          _sectionLabel('Tips & Tricks'),
          _tipCard(context, '💡', 'Pinch-to-Zoom', 'Use two fingers to zoom in/out. No zoom buttons clutter your view!'),
          _tipCard(context, '🧭', 'Compass Button', 'Tap the compass icon to reorient the map to north or follow your heading in navigation mode.'),
          _tipCard(context, '🌙', 'Dark Mode', 'Enable Dark Mode in Settings > Appearance to reduce eye strain at night.'),
          _tipCard(context, '🚶', 'Entrance Routing', 'Walking mode snaps routes to building entrances (main entrance preferred) for accurate pedestrian guidance.'),
          _tipCard(context, '🚗', 'Road Snapping', 'Driving and Transit modes use nearest roads. Entrance routing applies only to pedestrians.'),
          _tipCard(context, '⚙️', 'Quick Settings', 'Access Settings from the Profile tab or bottom nav. Toggle notifications, location services, and more.'),
          const SizedBox(height: 28),
          _sectionLabel('Need More Help?'),
          _linkCard(context, Icons.help_outline, 'Help & Support', 'Visit the Help & Support section for FAQs and contact options.', () {}),
        ],
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.school, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('Welcome to Campus Navigation', style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimaryAdaptive(context))),
          const SizedBox(height: 10),
          Text('Navigate Igbinedion University with ease. Learn features, tips, and shortcuts below.', textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textSecondaryAdaptive(context), height: 1.5)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 14),
        child: Text(text, style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGrey)),
      );

  Widget _featureCard(BuildContext context, IconData icon, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 6),
                Text(desc, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondaryAdaptive(context), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(BuildContext context, String emoji, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryAdaptive(context))),
                const SizedBox(height: 6),
                Text(desc, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondaryAdaptive(context), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderAdaptive(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondaryAdaptive(context))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
