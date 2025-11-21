import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: AppTextStyles.heading2.copyWith(color: AppColors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildBodyContent(context),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Last updated: November 2025',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: AppColors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 115 : 20),
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
              color: AppColors.primary.withAlpha(31),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.privacy_tip, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('Your Privacy Matters', style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimaryAdaptive(context))),
          const SizedBox(height: 8),
          Text('We respect your privacy and protect your data', style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textSecondaryAdaptive(context))),
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderAdaptive(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 102 : 18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionText(context, 'Information We Collect', 'We collect location data to provide navigation services. This includes your device location, search queries, and navigation history.'),
          const SizedBox(height: 20),
          _buildSectionText(context, 'How We Use Your Information', 'Your information is used to:\n• Provide accurate navigation\n• Improve app functionality\n• Enhance user experience\n• Display relevant campus information'),
          const SizedBox(height: 20),
          _buildSectionText(context, 'Data Storage', 'All data is stored securely on your device. We do not share your personal information with third parties without your consent.'),
          const SizedBox(height: 20),
          _buildSectionText(context, 'Location Services', 'Location services can be disabled at any time through your device settings or app preferences. Some features may be limited without location access.'),
          const SizedBox(height: 20),
          _buildSectionText(context, 'Your Rights', 'You have the right to:\n• Access your personal data\n• Request data deletion\n• Opt out of data collection\n• Update your preferences'),
          const SizedBox(height: 20),
          _buildSectionText(context, 'Updates to Privacy Policy', 'We may update this privacy policy from time to time. Continued use of the app after changes constitutes acceptance of the updated policy.'),
          const SizedBox(height: 20),
          _buildSectionText(context, 'Contact Us', 'If you have questions about this privacy policy, please contact us at:\nsupport@campusnav.edu.ng'),
        ],
      ),
    );
  }

  Widget _buildSectionText(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimaryAdaptive(context))),
        const SizedBox(height: 10),
        Text(content, style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textSecondaryAdaptive(context), height: 1.6)),
      ],
    );
  }
}
