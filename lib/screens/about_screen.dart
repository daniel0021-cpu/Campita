import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text(
          'About',
          style: AppTextStyles.heading2.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppCard(context),
            const SizedBox(height: 24),
            
            _buildSectionHeader('About Campus Navigation'),
            _buildInfoCard(
              context,
              'Campus Navigation is an innovative mobile application designed to help students, staff, and visitors navigate Igbinedion University Okada campus with ease. The app provides real-time directions, building information, and interactive maps to ensure you never get lost on campus.',
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Features'),
            _buildFeatureItem(context, Icons.map, 'Interactive Campus Map', 'Explore the entire campus with detailed, interactive maps'),
            _buildFeatureItem(context, Icons.directions, 'Turn-by-Turn Directions', 'Get step-by-step navigation to any location'),
            _buildFeatureItem(context, Icons.my_location, 'Real-Time Location', 'Track your position in real-time on campus'),
            _buildFeatureItem(context, Icons.search, 'Smart Search', 'Quickly find buildings, departments, and facilities'),
            _buildFeatureItem(context, Icons.star, 'Save Favorites', 'Bookmark frequently visited locations'),
            _buildFeatureItem(context, Icons.layers, 'Multiple Map Styles', 'Choose from standard, satellite, or terrain views'),
            // AR temporarily disabled
            
            const SizedBox(height: 24),
            _buildSectionHeader('University Information'),
            _buildUniversityCard(context),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Development Team'),
            _buildDeveloperCard(context),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Version & Legal'),
            _buildVersionCard(context),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Acknowledgments'),
            _buildInfoCard(
              context,
              'We would like to thank Igbinedion University Okada for their support and all the students and staff who provided feedback during development. Special thanks to the open-source community for their amazing tools and libraries.',
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Made with ❤️ for IUO',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: AppColors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'DEPLOY MARKER • ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')} ${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}',
                  style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(Icons.explore, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('Campus Navigation', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimaryAdaptive(context))),
          const SizedBox(height: 10),
          Text('Version 1.0.0', style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textSecondaryAdaptive(context))),
          const SizedBox(height: 6),
          Text('Build ${DateTime.now().year}.${DateTime.now().month}', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.grey)),
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

  Widget _buildInfoCard(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Text(
        text,
        style: GoogleFonts.notoSans(
          fontSize: 14,
          color: AppColors.textSecondaryAdaptive(context),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(20),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryAdaptive(context))),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondaryAdaptive(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversityCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Igbinedion University Okada',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'KM 10 Benin-Lagos Road, Okada, Edo State'),
          _buildInfoRow(Icons.phone, '+234 XXX XXX XXXX'),
          _buildInfoRow(Icons.email, 'info@iuokada.edu.ng'),
          _buildInfoRow(Icons.language, 'www.iuokada.edu.ng'),
          const SizedBox(height: 12),
          Text(
            'The first private university in Nigeria, committed to excellence in education, research, and service.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.code, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Development Team',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IUO Computer Science Department',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This application was developed as part of the university\'s initiative to enhance campus experience through technology.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVersionRow('Version', '1.0.0'),
          _buildVersionRow('Build Number', '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}'),
          _buildVersionRow('Release Date', 'January 2025'),
          _buildVersionRow('Platform', 'Flutter Web'),
          const Divider(height: 24),
          Text(
            '© 2025 Igbinedion University Okada. All rights reserved.',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {},
            child: Text(
              'Terms of Service',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {},
            child: Text(
              'Privacy Policy',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}
