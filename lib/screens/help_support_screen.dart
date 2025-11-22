import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'video_tutorials_screen.dart';
import 'tips_tricks_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.ash,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            pinned: true,
            expandedHeight: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : AppColors.ash).withOpacity(0.95),
              ),
            ),
            title: Text(
              'Help & Support',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Frequently Asked Questions'),
            _buildFAQItem(
              context,
              'How do I search for a building?',
              'Use the search bar at the top of the map screen to type the building name. Select from the suggestions to view its location.',
            ),
            _buildFAQItem(
              context,
              'How do I get directions?',
              'Tap on any building marker or search result, then tap the "Directions" button. Choose your starting point and navigation mode.',
            ),
            _buildFAQItem(
              context,
              'Can I save favorite locations?',
              'Yes! Tap the star icon on any building info card to add it to your favorites. Access them from the Favorites tab.',
            ),
            _buildFAQItem(
              context,
              'How do I enable location services?',
              'Go to your device Settings > Privacy > Location Services and enable it for Campus Navigation app.',
            ),
            _buildFAQItem(
              context,
              'What are the different map styles?',
              'You can switch between Standard, Satellite, and Terrain views using the layers button on the map screen.',
            ),
            _buildFAQItem(
              context,
              'How do I report an issue?',
              'Contact us using the information below, and we\'ll respond as soon as possible.',
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Contact Us'),
            _buildContactCard(
              Icons.email,
              'Email Support',
              'admin@dmanapp.com',
              'Send us an email',
              onTap: () => _launchEmail('admin@dmanapp.com'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              Icons.phone,
              'Phone Support',
              '+234 XXX XXX XXXX',
              'Call us for immediate help',
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              Icons.location_on,
              'Visit Us',
              'Igbinedion University Okada',
              'Edo State, Nigeria',
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Helpful Resources'),
            _buildResourceCard(
              Icons.book,
              'User Guide',
              'Learn how to use all features',
              () {},
            ),
            const SizedBox(height: 12),
            _buildResourceCard(
              Icons.video_library,
              'Video Tutorials',
              'Watch step-by-step guides',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoTutorialsScreen())),
            ),
            const SizedBox(height: 12),
            _buildResourceCard(
              Icons.tips_and_updates,
              'Tips & Tricks',
              'Get the most out of the app',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TipsTricksScreen())),
            ),
            
            const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String to) async {
    final uri = Uri(scheme: 'mailto', path: to, queryParameters: {
      'subject': 'Campus Navigation Support',
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'How can we help you?',
            style: GoogleFonts.notoSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find answers to common questions or contact our support team',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              question,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryAdaptive(context),
              ),
            ),
            children: [
              Text(
                answer,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: AppColors.textSecondaryAdaptive(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String primary, String secondary, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    primary,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    secondary,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
